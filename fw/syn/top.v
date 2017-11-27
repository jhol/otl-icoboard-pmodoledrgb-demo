/*
 * Copyright (c) 2017 Joel Holdsworth <joel@airwebreathe.org.uk>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

module clkgen(in_clk, in_reset, out_clk, out_reset);
parameter Period = 1;
input in_clk, in_reset;
output out_clk, out_reset;

localparam PeriodWidth = $clog2(Period);

reg [PeriodWidth-1:0] counter;
reg clk_reg;
reg [1:0] reset_gen;
reg reset_reg;

assign out_clk = clk_reg;
assign out_reset = reset_reg;

always @(posedge in_clk) begin
  if (in_reset) begin
    counter <= 0;
    clk_reg <= 0;
    reset_gen <= 0;
  end else begin
    if (counter == 0) begin
      reset_reg <= 0;
      counter <= Period - 1;
      clk_reg <= !clk_reg;
      reset_gen <= {reset_gen, 1'b1};
    end else
      counter <= counter - 1;
  end
  reset_reg <= !(&reset_gen);
end

endmodule


module top(input clk_100mhz, output pmod1_1, output pmod1_2, output pmod1_3,
  output pmod1_4, output pmod1_7, output pmod1_8, output pmod1_9,
  output pmod1_10, input rpi_sck, input rpi_cs, input rpi_mosi);
parameter ClkFreq = 50000000; // Hz

// Clock Generator
wire clk_50mhz;
wire pll_locked;

SB_PLL40_PAD #(
  .FEEDBACK_PATH("SIMPLE"),
  .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
  .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
  .PLLOUT_SELECT("GENCLK"),
  .FDA_FEEDBACK(4'b1111),
  .FDA_RELATIVE(4'b1111),
  .DIVR(4'b0000),
  .DIVF(7'b0000111),
  .DIVQ(3'b100),
  .FILTER_RANGE(3'b101)
) pll (
  .PACKAGEPIN(clk_100mhz),
  .PLLOUTGLOBAL(clk_50mhz),
  .LOCK(pll_locked),
  .BYPASS(1'b0),
  .RESETB(1'b1)
);

wire clk = clk_50mhz;

// Reset Generator
reg [3:0] resetn_gen = 0;
reg reset;

always @(posedge clk) begin
  reset <= !&resetn_gen;
  resetn_gen <= {resetn_gen, pll_locked};
end

// SPI Clock Generator
localparam SpiDesiredFreq = 6250000; // Hz
localparam SpiPeriod = (ClkFreq + (SpiDesiredFreq * 2) - 1) / (SpiDesiredFreq * 2);
localparam SpiFreq = ClkFreq / (SpiPeriod * 2);

wire spi_clk, spi_reset;
clkgen #(SpiPeriod) spi_clkgen(clk, reset, spi_clk, spi_reset);

// PmodOLEDrgb
wire pmodoldedrgb_cs = pmod1_1;
wire pmodoldedrgb_sdin = pmod1_2;
assign pmod1_3 = 0;
wire pmodoldedrgb_sclk = pmod1_4;
wire pmodoldedrgb_d_cn = pmod1_7;
wire pmodoldedrgb_resn = pmod1_8;
wire pmodoldedrgb_vccen = pmod1_9;
wire pmodoldedrgb_pmoden = pmod1_10;

wire frame_begin, sending_pixels, sample_pixel;
wire [12:0] pixel_index;
wire [15:0] pixel_data;

wire ram_wr;
wire [12:0] ram_addr;
wire [15:0] ram_data;

spi_ram_slave spi_ram_slave(clk, rpi_sck, rpi_cs, rpi_mosi,
  ram_addr, ram_data, ram_wr);

ram_source ram_source(spi_clk, spi_reset, frame_begin, sample_pixel,
  pixel_index, pixel_data, clk, ram_wr, ram_addr, ram_data);

pmodoledrgb_controller #(SpiFreq) pmodoledrgb_controller(spi_clk, spi_reset,
  frame_begin, sending_pixels, sample_pixel, pixel_index, pixel_data,
  pmodoldedrgb_cs, pmodoldedrgb_sdin, pmodoldedrgb_sclk, pmodoldedrgb_d_cn,
  pmodoldedrgb_resn, pmodoldedrgb_vccen, pmodoldedrgb_pmoden);

endmodule
