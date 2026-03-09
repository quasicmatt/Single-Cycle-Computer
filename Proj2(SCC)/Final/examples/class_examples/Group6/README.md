Group 6 Testcase, Shift Counter  
  
Input a 32-bit number into R1. Expected memory outputs:  
0x0800 = 32-bit input  
0x0880 = # of ones in input  
0x0884 = # of zeros in input  
0x0888 = (zeros << 16) | ones  
0x088C = input inverted  
0x0890 = (# of ones) ^ 2  
0x0894 = (# of zeros) ^ 2  
  
Included tb checks for outputs of default input, 0xF0F0F0F0  
You'll have to change target_v_x in the tb for self-checking other inputs

