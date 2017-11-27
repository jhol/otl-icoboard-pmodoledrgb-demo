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

`timescale 1ns/1ns

module test;
parameter ClkFreq = 50000000; // Hz

reg cs = 1;
reg sck = 0;
reg mosi = 0;

initial begin
  $dumpfile("spi_ram_slave.vcd");
  $dumpvars(0, test);

  #456 cs = 0;

  // Word 1
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;

  // Word 2
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b0;
  #32 sck = 1;
  #32 sck = 0;
  mosi = 1'b1;

  cs = 1;
  #100 $finish;
end

reg clk = 0;
always #10 clk = !clk;

wire ram_wr;
wire [12:0] ram_addr;
wire [15:0] ram_data;

spi_ram_slave spi_ram_slave(clk, sck, cs, mosi, ram_addr, ram_data, ram_wr);

endmodule
