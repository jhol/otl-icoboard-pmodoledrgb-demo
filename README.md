otl-icoboard-pmodrgboled-demo
=============================

A simple demo for the IcoBoard involving the PmodOLEDrgb, which is synthesized
using the fully Open Source IceStorm tool-chain.

Build Requisites
----------------

The following tools must be installed...

 * [IceStorm tool-chain](http://www.clifford.at/icestorm/) (needed for synthesis)
   * [Yosys](http://www.clifford.at/yosys/)
   * [IceStorm](http://www.clifford.at/icestorm/)
   * [arachne-pnr](https://github.com/cseed/arachne-pnr)
 * [FFmpeg](http://ffmpeg.org/) (needed for 16-bit image conversion)
 * [Icarus Verilog](http://iverilog.icarus.com/) (needed for simulation)
 * [GTKWave](http://gtkwave.sourceforge.net/) (needed for visualization of simulation results)

Synthesize Bitstream
--------------------

To synthesize bitstream...
```
$ cd fw/
$ make
```
Output is stored in `demo.bin`.

Run Simulation
--------------

```
$ cd fw/
$ make simulate-XXX
```
...where the available simulations are:

 * simulate-pmodoledrgb_controller
 * simulate-spi_ram_slave

Results will be displayed in GTKWave.
