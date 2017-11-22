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

module pmodoledrgb_clkgen(in_clk, in_reset, out_clk, out_reset);
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


module pmodoledrgb_controller(clk, reset, frame_begin, cs, sdin, sclk, d_cn,
  resn, vccen, pmoden);
parameter ClkFreq = 25000000; // Hz
input clk, reset;
output frame_begin;
output cs, sdin, sclk, d_cn, resn, vccen, pmoden;

localparam SpiDesiredFreq = 6250000; // Hz
localparam SpiPeriod = (ClkFreq + (SpiDesiredFreq * 2) - 1) / (SpiDesiredFreq * 2);
localparam SpiFreq = ClkFreq / (SpiPeriod * 2);

wire spi_clk, spi_reset;
pmodoledrgb_clkgen #(SpiPeriod) spi_clkgen(clk, reset, spi_clk, spi_reset);

// Frame begin event
localparam FrameFreq = 30;
localparam FrameDiv = SpiFreq / FrameFreq;
localparam FrameDivWidth = $clog2(FrameDiv);

reg [FrameDivWidth:0] frame_counter;
assign frame_begin = (frame_counter == 0);

// Video
localparam Width = 96;
localparam Height = 64;
localparam PixelCount = Width * Height;
localparam PixelCountWidth = $clog2(PixelCount-1);

reg [PixelCountWidth-1:0] pixels_remain;

// State Machine
localparam PowerDelay = 20000000; // ns
localparam ResetDelay = 3000; // ns
localparam VccEnDelay = 25000000; // ns
localparam StartupCompleteDelay = 100000000; // ns

localparam MaxDelay = StartupCompleteDelay; // ns
localparam MaxDelayCount = (SpiFreq * MaxDelay) / 1000000000;
reg [$clog2(MaxDelayCount-1)-1:0] delay;

localparam StateCount = 31;

localparam PowerUp = (31'h1 << 0);
localparam Reset = (31'h1 << 1);
localparam ReleaseReset = (31'h1 << 2);
localparam EnableDriver = (31'h1 << 3);
localparam DisplayOff = (31'h1 << 4);
localparam SetRemapDisplayFormat = (31'h1 << 5);
localparam SetStartLine = (31'h1 << 6);
localparam SetOffset = (31'h1 << 7);
localparam SetNormalDisplay = (31'h1 << 8);
localparam SetMultiplexRatio = (31'h1 << 9);
localparam SetMasterConfiguration = (31'h1 << 10);
localparam DisablePowerSave = (31'h1 << 11);
localparam SetPhaseAdjust = (31'h1 << 12);
localparam SetDisplayClock = (31'h1 << 13);
localparam SetSecondPrechargeA = (31'h1 << 14);
localparam SetSecondPrechargeB = (31'h1 << 15);
localparam SetSecondPrechargeC = (31'h1 << 16);
localparam SetPrechargeLevel = (31'h1 << 17);
localparam SetVCOMH = (31'h1 << 18);
localparam SetMasterCurrent = (31'h1 << 19);
localparam SetContrastA = (31'h1 << 20);
localparam SetContrastB = (31'h1 << 21);
localparam SetContrastC = (31'h1 << 22);
localparam DisableScrolling = (31'h1 << 23);
localparam ClearScreen = (31'h1 << 24);
localparam VccEn = (31'h1 << 25);
localparam DisplayOn = (31'h1 << 26);
localparam WaitNextFrame = (31'h1 << 27);
localparam SetColAddress = (31'h1 << 28);
localparam SetRowAddress = (31'h1 << 29);
localparam SendPixel = (31'h1 << 30);

assign resn = state != Reset;
assign d_cn = state == SendPixel;
assign vccen = state == VccEn || state == DisplayOn || state == WaitNextFrame ||
  state == SetColAddress || state == SetRowAddress || state == SendPixel;
assign pmoden = !reset;

reg [15:0] color;

reg [StateCount-1:0] state;
wire [StateCount-1:0] next_state = fsm_next_state(state, frame_begin, pixels_remain);

function [StateCount-1:0] fsm_next_state;
  input [StateCount-1:0] state;
  input frame_begin;
  input [PixelCountWidth-1:0] pixels_remain;
  case (state)
    PowerUp: fsm_next_state = Reset;
    Reset: fsm_next_state = ReleaseReset;
    ReleaseReset: fsm_next_state = EnableDriver;
    EnableDriver: fsm_next_state = DisplayOff;
    DisplayOff: fsm_next_state = SetRemapDisplayFormat;
    SetRemapDisplayFormat: fsm_next_state = SetStartLine;
    SetStartLine: fsm_next_state = SetOffset;
    SetOffset: fsm_next_state = SetNormalDisplay;
    SetNormalDisplay: fsm_next_state = SetMultiplexRatio;
    SetMultiplexRatio: fsm_next_state = SetMasterConfiguration;
    SetMasterConfiguration: fsm_next_state = DisablePowerSave;
    DisablePowerSave: fsm_next_state = SetPhaseAdjust;
    SetPhaseAdjust: fsm_next_state = SetDisplayClock;
    SetDisplayClock: fsm_next_state = SetSecondPrechargeA;
    SetSecondPrechargeA: fsm_next_state = SetSecondPrechargeB;
    SetSecondPrechargeB: fsm_next_state = SetSecondPrechargeC;
    SetSecondPrechargeC: fsm_next_state = SetPrechargeLevel;
    SetPrechargeLevel: fsm_next_state = SetVCOMH;
    SetVCOMH: fsm_next_state = SetMasterCurrent;
    SetMasterCurrent: fsm_next_state = SetContrastA;
    SetContrastA: fsm_next_state = SetContrastB;
    SetContrastB: fsm_next_state = SetContrastC;
    SetContrastC: fsm_next_state = DisableScrolling;
    DisableScrolling: fsm_next_state = ClearScreen;
    ClearScreen: fsm_next_state = VccEn;
    VccEn: fsm_next_state = DisplayOn;
    DisplayOn: fsm_next_state = WaitNextFrame;
    WaitNextFrame: fsm_next_state = frame_begin ? SetColAddress : WaitNextFrame;
    SetColAddress: fsm_next_state = SetRowAddress;
    SetRowAddress: fsm_next_state = SendPixel;
    SendPixel: fsm_next_state = (pixels_remain == 0) ? WaitNextFrame : SendPixel;
    default: fsm_next_state = PowerUp;
  endcase
endfunction

// SPI Master
localparam SpiCommandMaxWidth = 40;
localparam SpiCommandBitCountWidth = $clog2(SpiCommandMaxWidth-1);

reg [SpiCommandBitCountWidth-1:0] spi_word_bit_count;
reg [SpiCommandMaxWidth-1:0] spi_word;

wire spi_busy = spi_word_bit_count != 0;
assign cs = !spi_busy;
assign sclk = spi_clk | !spi_busy;
assign sdin = spi_word[SpiCommandMaxWidth-1] & spi_busy;

always @(negedge spi_clk) begin
  if (spi_reset) begin
    frame_counter <= 0;
    delay <= 0;
    state <= 0;
    spi_word <= 0;
    spi_word_bit_count <= 0;
    color <= 0;
  end else begin
    frame_counter <= frame_begin ? FrameDiv : frame_counter - 1;

    if (frame_begin)
      color <= color + 1;

    if (spi_busy) begin
      spi_word_bit_count <= spi_word_bit_count - 1;
      spi_word <= {spi_word[SpiCommandMaxWidth-2:0], 1'b0};
    end else if (delay != 0)
      delay <= delay - 1;
    else begin
      state <= next_state;
      case (next_state)
        PowerUp: begin
          spi_word <= 0;
          spi_word_bit_count <= 0;
          delay <= (SpiFreq * PowerDelay) / 1000000000 + 1;
        end
        Reset: begin
          spi_word <= 0;
          spi_word_bit_count <= 0;
          delay <= (SpiFreq * ResetDelay) / 1000000000 + 1;
        end
        ReleaseReset: begin
          spi_word <= 0;
          spi_word_bit_count <= 0;
          delay <= (SpiFreq * ResetDelay) / 1000000000 + 1;
        end
        EnableDriver: begin
          // Enable the driver
          spi_word <= {16'hFD12, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        DisplayOff: begin
          // Turn the display off
          spi_word <= {8'hAE, {SpiCommandMaxWidth-8{1'b0}}};
          spi_word_bit_count <= 8;
          delay <= 0;
        end
        SetRemapDisplayFormat: begin
          // Set the remap and display formats
          spi_word <= {16'hA072, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetStartLine: begin
          // Set the display start line to the top line
          spi_word <= {16'hA100, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetOffset: begin
          // Set the display offset to no vertical offset
          spi_word <= {16'hA200, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetNormalDisplay: begin
          // Make it a normal display with no color inversion or forcing
          // pixels on/off
          spi_word <= {8'hA4, {SpiCommandMaxWidth-8{1'b0}}};
          spi_word_bit_count <= 8;
          delay <= 0;
        end
        SetMultiplexRatio: begin
          // Set the multiplex ratio to enable all of the common pins
          // calculated by thr 1+register value
          spi_word <= {16'hA83F, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetMasterConfiguration: begin
          // Set the master configuration to use a required a required
          // external Vcc supply.
          spi_word <= {16'hAD8E, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        DisablePowerSave: begin
          // Disable power saving mode.
          spi_word <= {16'hB00B, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetPhaseAdjust: begin
          // Set the phase length of the charge and dischare rates of
          // an OLED pixel.
          spi_word <= {16'hB131, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetDisplayClock: begin
          // Set the display clock divide ration and oscillator frequency
          spi_word <= {16'hB3F0, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetSecondPrechargeA: begin
          // Set the second pre-charge speed of color A
          spi_word <= {16'h8A64, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetSecondPrechargeB: begin
          // Set the second pre-charge speed of color B
          spi_word <= {16'h8B78, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetSecondPrechargeC: begin
          // Set the second pre-charge speed of color C
          spi_word <= {16'h8C64, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetPrechargeLevel: begin
          // Set the pre-charge voltage to approximately 45% of Vcc
          spi_word <= {16'hBB3A, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetVCOMH: begin
          // Set the VCOMH deselect level
          spi_word <= {16'hBE3E, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetMasterCurrent: begin
          // Set the master current attenuation
          spi_word <= {16'h8706, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetContrastA: begin
          // Set the contrast for color A
          spi_word <= {16'h8191, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetContrastB: begin
          // Set the contrast for color B
          spi_word <= {16'h8250, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        SetContrastC: begin
          // Set the contrast for color C
          spi_word <= {16'h837D, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        DisableScrolling: begin
          // Disable scrolling
          spi_word <= {8'h25, {SpiCommandMaxWidth-8{1'b0}}};
          spi_word_bit_count <= 8;
          delay <= 0;
        end
        ClearScreen: begin
          // Clear the screen
          spi_word <= {40'h2500005F3F, {SpiCommandMaxWidth-40{1'b0}}};
          spi_word_bit_count <= 40;
          delay <= 0;
        end
        VccEn: begin
          spi_word <= 0;
          spi_word_bit_count <= 0;
          delay <= (SpiFreq * VccEnDelay) / 1000000000 + 1;
        end
        DisplayOn: begin
          // Turn the display on
          spi_word <= {8'hAF, {SpiCommandMaxWidth-8{1'b0}}};
          spi_word_bit_count <= 8;
          delay <= (SpiFreq * StartupCompleteDelay) / 1000000000 + 1;
        end
        SetColAddress: begin
          // Set the column address
          spi_word <= {24'h15005F, {SpiCommandMaxWidth-24{1'b0}}};
          spi_word_bit_count <= 24;
          delay <= 0;
        end
        SetRowAddress: begin
          // Set the row address
          spi_word <= {24'h75003F, {SpiCommandMaxWidth-24{1'b0}}};
          spi_word_bit_count <= 24;
          delay <= 0;
        end
        SendPixel: begin
          spi_word <= {color, {SpiCommandMaxWidth-16{1'b0}}};
          spi_word_bit_count <= 16;
          delay <= 0;
        end
        default: begin
          spi_word <= 0;
          spi_word_bit_count <= 0;
          delay <= 0;
        end
      endcase

      if (state == SendPixel)
        pixels_remain <= pixels_remain - 1;
      else
        pixels_remain <= PixelCount - 1;
    end
  end
end

endmodule
