#
# Copyright (c) 2017 Joel Holdsworth <joel@airwebreathe.org.uk>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

src=\
	src/clock_generator.v \
	src/coordinate_decoder.v \
	src/pmodoledrgb_controller.v \
	src/prbs_source.v \
	src/ram_source.v \
	src/spi_ram_slave.v \
	src/video_hack_1.v \
	src/video_hack_2.v

synthesize: demo.bin

image.hex: src/image.png
	ffmpeg -i $< -f rawvideo -pix_fmt rgb565 - | od -An -vtx2 -w2 > $@

demo.blif: syn/top.v syn/demo.pcf $(src) src/ram_template.hex
	yosys -q -p "synth_ice40 -blif demo.blif" syn/top.v $(src)

demo.asc.template: demo.blif
	arachne-pnr -d 8k -p syn/demo.pcf $< -o $@
	icetime -d hx8k -c 50 $@

demo.asc: demo.asc.template src/ram_template.hex image.hex
	icebram src/ram_template.hex image.hex < $< > $@

demo.bin: demo.asc
	icepack $< $@

simulate-pmodoledrgb_controller: pmodoledrgb_controller.vcd
	gtkwave $< >/dev/null 2>/dev/null &

pmodoledrgb_controller-sim: src/pmodoledrgb_controller.v \
  sim/pmodoledrgb_controller.v
	iverilog -o $@ $^

simulate-spi_ram_slave: spi_ram_slave.vcd
	gtkwave $< >/dev/null 2>/dev/null &

spi_ram_slave-sim: src/spi_ram_slave.v sim/spi_ram_slave.v
	iverilog -o $@ $^

%.vcd: %-sim
	cd $(dir $<); ./$(notdir $<)

.PHONY: \
  synthesize \
  simulate-pmodoledrgb_controller \
  simulate
