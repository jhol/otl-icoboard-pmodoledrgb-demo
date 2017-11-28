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

module top(clk_100mhz, pmod1_1, pmod1_2, pmod1_3, pmod1_4, pmod1_7, pmod1_8,
  pmod1_9, pmod1_10, pmod2_7, pmod2_8, pmod2_9, pmod2_10, rpi_sck, rpi_cs,
  rpi_mosi);
parameter ClkFreq = 50000000; // Hz

input clk_100mhz;
output pmod1_1, pmod1_2, pmod1_3, pmod1_4, pmod1_7, pmod1_8, pmod1_9, pmod1_10;
input pmod2_7, pmod2_8, pmod2_9, pmod2_10;
input rpi_sck, rpi_cs, rpi_mosi;

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
clock_generator #(SpiPeriod) spi_clkgen(clk, reset, spi_clk, spi_reset);

// Buttons
wire [3:0] btns = {pmod2_10, pmod2_9, pmod2_8, pmod2_7};
reg [1:0] video_source;

always @(posedge spi_clk) begin
  if (spi_reset)
    video_source <= 0;
  else if (frame_begin) begin
    if (btns[0])
      video_source <= 0;
    else if(btns[1])
      video_source <= 1;
    else if (btns[2])
      video_source <= 2;
    else if(btns[3])
      video_source <= 3;
  end
end

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
wire [15:0] pixel_data, ram_pixel_data, prbs_pixel_data;
wire [6:0] x;
wire [5:0] y;

wire ram_wr;
wire [12:0] ram_addr;
wire [15:0] ram_data;

coordinate_decoder coordinate_decoder(spi_clk, sending_pixels, sample_pixel,
  x, y);

spi_ram_slave spi_ram_slave(clk, rpi_sck, rpi_cs, rpi_mosi,
  ram_addr, ram_data, ram_wr);

ram_source ram_source(spi_clk, spi_reset, frame_begin, sample_pixel,
  pixel_index, ram_pixel_data, clk, ram_wr, ram_addr, ram_data);

prbs_source prbs_source(spi_clk, spi_reset, frame_begin, sample_pixel,
  prbs_pixel_data);

always @(*) begin
  case (video_source)
    0: pixel_data = ram_pixel_data;
    1: pixel_data = prbs_pixel_data;
    2: pixel_data = {5'b11111, 6'b000000, 5'b00000};
    3: pixel_data = {5'b00000, 6'b000000, 5'b11111};
  endcase
end

pmodoledrgb_controller #(SpiFreq) pmodoledrgb_controller(spi_clk, spi_reset,
  frame_begin, sending_pixels, sample_pixel, pixel_index, pixel_data,
  pmodoldedrgb_cs, pmodoldedrgb_sdin, pmodoldedrgb_sclk, pmodoldedrgb_d_cn,
  pmodoldedrgb_resn, pmodoldedrgb_vccen, pmodoldedrgb_pmoden);

endmodule
