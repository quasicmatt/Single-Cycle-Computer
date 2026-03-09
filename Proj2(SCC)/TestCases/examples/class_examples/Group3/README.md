### Basic Encryption and Decryption
# Overview
This algorithm uses XOR to encrypt a value and conditional offsetting to generate an output value that
can be back-calculated if the encryption key is known, and we know which conditional instructions were executed.


# Usage
- Change the value at memory address 0x400 to be your input to hash.
- Optionally, you can change the encryption key which is the immediate stored in R2.
- Test case is designed for input = 0x39 and encryption key = 0x19

# Memory Interpretation
```
0x400: input value
0x404: encrypted value
0x408: decrypted value (should be original input)
```