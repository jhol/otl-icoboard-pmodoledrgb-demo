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

module pmodoledrgb_controller(clk, reset, cs, sdin, sclk, d_cn, resn, vccen, pmoden);
parameter ClkFreq = 100000000; // Hz
input clk, reset;
output cs, sdin, sclk, d_cn, resn, vccen, pmoden;

// SPI Clock
localparam SpiDesiredFreq = 6000000; // Hz
localparam SpiPeriod = (ClkFreq + (SpiDesiredFreq * 2) - 1) / (SpiDesiredFreq * 2);
localparam SpiFreq = ClkFreq / (SpiPeriod * 2);
localparam SpiPeriodWidth = $clog2(SpiPeriod);

reg [SpiPeriodWidth:0] spi_counter;
reg spi_clk;

// Frame begin event
localparam FrameFreq = 60;
localparam FrameDiv = SpiFreq / FrameFreq;
localparam FrameDivWidth = $clog2(FrameDiv);

reg [FrameDivWidth:0] frame_counter;
wire frame_begin = (frame_counter == 0);

// SPI Master
localparam SpiCommandMaxWidth = 40;
localparam SpiCommandBitCountWidth = $clog2(SpiCommandMaxWidth-1);

localparam SpiIdle = 3'b001;
localparam SpiTransfer = 3'b010;
localparam SpiDeselect = 3'b100;

localparam SpiStateCount = 3;

wire [SpiStateCount-1:0] spi_next_state = spi_fsm_next_state(spi_state, spi_word_bit_count);
reg [SpiStateCount-1:0] spi_state;

reg [SpiCommandBitCountWidth-1:0] spi_word_bit_count;
reg [SpiCommandMaxWidth-1:0] spi_word;

assign cs = spi_state != SpiTransfer;
assign sclk = spi_clk | cs;
assign sdin = spi_word[SpiCommandMaxWidth-1] & !cs;

function [SpiStateCount-1:0] spi_fsm_next_state;
  input [SpiStateCount-1:0] state;
  input [SpiCommandBitCountWidth-1:0] bit_count;
  case (state)
    SpiIdle: spi_fsm_next_state = (bit_count == 0) ? SpiIdle : SpiTransfer;
    SpiTransfer: spi_fsm_next_state = (bit_count == 1) ? SpiDeselect : SpiTransfer;
    default: spi_fsm_next_state = SpiIdle;
  endcase
endfunction

always @(posedge clk) begin
  if (reset) begin
    spi_counter <= 0;
    spi_clk <= 0;
    frame_counter <= 0;
    spi_state <= SpiIdle;
    spi_word <= 40'h2500005F3F;
    spi_word_bit_count <= 40;
  end else begin
    if (spi_counter == 0) begin
      spi_counter <= SpiPeriod - 1;
      spi_clk <= !spi_clk;

      if (spi_clk)
        frame_counter <= frame_begin ? FrameDiv : frame_counter - 1;

      // Implements the Mode 3 SPI master
      if (spi_clk) begin
        if (spi_state == SpiTransfer) begin
          spi_word_bit_count <= spi_word_bit_count - 1;
          spi_word <= {spi_word[SpiCommandMaxWidth-2:0], 1'b0};
        end
        spi_state <= spi_next_state;
      end
    end else
      spi_counter <= spi_counter - 1;
  end
end

endmodule
