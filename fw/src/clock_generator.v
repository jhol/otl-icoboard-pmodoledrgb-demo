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
 * A module that divides an input clock to a lower frequencty, and generates
 * a synchronous reset from the input reset.
 */
module clock_generator(in_clk, in_reset, out_clk, out_reset);
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
