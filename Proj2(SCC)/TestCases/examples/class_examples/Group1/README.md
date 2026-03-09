# Sine Lookup Table (LUT)

## Setup

- This test depends on what's loaded into memory. In this directory there is a lut.mem file. This contains the values of sine from 0-90 (results multiplied by 100 to get a decimal value). Make sure you're loading this into your memory module
- There is a sine_value_generator.py file included (generated courtesy of Gemini). This is used to generate the lut.mem file. You can change the scaling here by updating the value of SCALE_FACTOR at the top

## Running the Test

- R1 represents the angle you'd like to calculate sine for. There are some examples for each quadrant, but you can change the value. The version uploaded should run the program with the angle set to 150 degrees.
- Address to save to is being stored in R9. Default is 0x190. Our testbench is checking this address for the result
