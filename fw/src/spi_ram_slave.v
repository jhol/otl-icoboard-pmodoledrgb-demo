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

/**
 * A SPI receive-only slave with a RAM interface as an output. The RAM can be
 * asynchronously rewritten by a random-access write-only interface.
 *
 * The module uses 24x iCE40 block-RAMs internally. In the iCE40, block-RAMs
 * have two independently clocked ports, with one read-only port and one
 * write-only port. Therefore, the read-port is clocked by the pixel clock,
 * while the read-port
 */
module spi_ram_slave(clk, sck, cs, mosi, ram_addr, ram_data, ram_wr);
localparam WordWidth = 16;
localparam WordCount = 64 * 96;

input clk, sck, cs, mosi;
output [$clog2(WordCount)-1:0] ram_addr;
output [WordWidth-1:0] ram_data;
output ram_wr;

reg [2:0] sckr, csr;
reg [1:0] mosir;

always @(negedge clk) sckr <= {sckr[1:0], sck};
wire sck_rising = sckr[2:1] == 2'b01;

always @(negedge clk) csr <= {csr[1:0], cs};
wire cs_active = !csr[1];

always @(negedge clk) mosir <= {mosir[0], mosi};
wire mosi_data = mosir[1];

reg word_received;
reg [$clog2(WordWidth)-1:0] bits_remain;
reg [$clog2(WordCount)-1:0] addr;
reg [WordWidth-1:0] data;

assign ram_addr = addr;
assign ram_data = {data[7:0], data[15:8]};
assign ram_wr = word_received;

always @(negedge clk) begin
  if(!cs_active) begin
    bits_remain <= WordWidth - 1;
    addr <= 0;
    data <= 0;
  end else if(sck_rising) begin
    data <= {data[WordWidth-2:0], mosi_data};
    bits_remain <= (bits_remain == 0) ? WordWidth - 1 : bits_remain - 1;
  end

  word_received <= (cs_active && sck_rising && bits_remain == 0);

  if (word_received)
      addr <= addr + 1;
end

endmodule
