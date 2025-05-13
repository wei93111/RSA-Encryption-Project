# RSA Encryption Project

## Overview
- This is a verilog project completed in the Integrated Circuits Design class at National Taiwan University, the design is synthesized using Synopsys Design Compiler and underwent P&R using Cadence Innovus.
- This verilog project implements a FIFO to store serial intructions sent in, then implements the Montgomery algorithm to decrypt the encoded instructions for execution on the design's specific register value.

## File Hierarchy

- The RTL code is all under the directory 01_RTL/, where RSA.v is the top module controlling the fifo pipeline, RsaCore.v is the module implementing Montgomery's algorithm, and Fifo.v is the fifo module.
- Testbenches for RTL code can be run under the 00_TESTBENCH/ directory (change pat0 to desired input pattern):
<pre>```$ vcs ./tb_RSA.v ../01_RTL/RSA.v ../01_RTL/RsaCore.v ../01_RTL/Fifo.v -full64-R-debug_access+all +define+pat0 ```</pre>
- Synthesis can be run under 02_SYN/ directory:
<pre>```$ dc_shell -f syn.tcl```</pre>
- Files needed for APR are all under 04_APR/ directory, use Cadence Innovus for P&R