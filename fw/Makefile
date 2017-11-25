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

outdir=_out/
src=\
	src/pmodoledrgb_controller.v \
	src/prbs_source.v \
	src/ram_source.v

synthesize: $(outdir)demo.bin

$(outdir)image.hex: src/image.png
	ffmpeg -i $< -f rawvideo -pix_fmt rgb565 - | \
	  od -An -vtx2 -w2 > $@

$(outdir)demo.blif: syn/top.v syn/demo.pcf $(src) src/ram_template.hex
	mkdir -p $(outdir)
	yosys -q -p "synth_ice40 -blif $(outdir)demo.blif" syn/top.v $(src)

$(outdir)demo.asc.template: $(outdir)demo.blif
	arachne-pnr -d 8k -p syn/demo.pcf $< -o $@
	icetime -d hx8k -c 25 $@

$(outdir)demo.asc: $(outdir)demo.asc.template src/ram_template.hex  \
  $(outdir)image.hex
	icebram src/ram_template.hex $(outdir)image.hex < $< > $@

$(outdir)demo.bin: $(outdir)demo.asc
	icepack $< $@

simulate: $(outdir)pmod_oled.vcd
	gtkwave $< >/dev/null 2>/dev/null &

$(outdir)pmod_oled.vcd: $(outdir)pmod_oled-sim
	cd $(outdir); ./pmod_oled-sim

$(outdir)pmod_oled-sim: src/pmodoledrgb_controller.v sim/main.v
	mkdir -p $(outdir)
	iverilog -o $@ $^

.PHONY: synthesize simulate
