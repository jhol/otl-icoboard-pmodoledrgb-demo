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
 * A module that generates an interesting video pattern on the fly. 
 */
module video_hack_1(clk, reset, frame_begin, x, y, pixel_data);
parameter Width = 96;
parameter Height = 64;
input clk, reset, frame_begin;
input [$clog2(Width-1)-1:0] x;
input [$clog2(Height-1)-1:0] y;
output [15:0] pixel_data;

reg [10:0] t;

wire [6:0] t_sum = y + (t >> 4);
wire [5:0] a_sum = t_sum + x;
wire [5:0] b_sum = t_sum - x;

wire [4:0] r = a_sum[5] ? a_sum[4:0] : ~a_sum[4:0];
wire [5:0] g = t_sum[6] ? t_sum[5:0] : ~t_sum[5:0];
wire [4:0] b = b_sum[5] ? b_sum[4:0] : ~b_sum[4:0];

assign pixel_data = {r, g, b};

always @(negedge clk) begin
  if (reset)
    t <= 0;
  else if (frame_begin)
    t <= t + 1;
end

endmodule
