SCC Simple CRC Testbench

## Overview
This project verifies a **bit-logic checksum routine** implemented in assembly (`simple_crc.ASM`) using a self-checking Verilog testbench (`scc_tb_simple_crc.v`).  
It ensures both the forward checksum and the reverse (“undo”) checksum logic behave as expected.

---

## Purpose of the Program
The test validates a simple **checksum algorithm** that combines six 32-bit words in memory using XOR and bit-shift operations.  
The checksum is then stored in memory, and the same logic is reversed to restore the original starting value.

This tests:
- Arithmetic/Logic Unit (ALU) correctness (XOR, AND, shifts)
- Memory load/store instructions
- Branch and flag behavior (`B.NE`, `CMP`, `MOVF`, `SAVF`)
- Program flow and HALT handling
- Self-checking memory verification after HALT

Note: 
- You can change the initial value for the checksum to be computed from by changing it in 2 places: 
1) edit the line `SET R1` (line 20 in simple_crc.asm file) to your intended initial value. 
2) edit the line `initial_value = 32'hFFFFFFFF;` (line 103 in scc_tb_simple_crc.v). This will automatically change the self-check and compute the correct values. 
- The program should work as intended for any initial value. 
