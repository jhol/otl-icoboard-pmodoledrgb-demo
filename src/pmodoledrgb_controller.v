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

always @(posedge clk) begin
  if (reset) begin
    spi_counter <= 0;
    spi_clk <= 0;
    frame_counter <= 0;
  end else begin
    if (spi_counter == 0) begin
      spi_counter <= SpiPeriod - 1;
      spi_clk <= !spi_clk;
      if (spi_clk)
        frame_counter <= frame_begin ? FrameDiv : frame_counter - 1;
    end else
      spi_counter <= spi_counter - 1;
  end
end

endmodule
