import math

SCALE_FACTOR = 100.0

# We only need to store 91 values (for 0 to 90 degrees)
TABLE_SIZE = 91
FILENAME = "lut.mem"

# --- Generation ---

sine_table = []
for i in range(TABLE_SIZE):
    # 'i' is the angle in degrees

    # Convert degrees to radians
    radians = math.radians(i)

    # Calculate the floating-point sine
    float_sin = math.sin(radians)

    # Convert to our Q31 fixed-point integer format
    # We use round() to get the closest integer value
    fixed_point_sin = int(round(float_sin * SCALE_FACTOR))

    # Handle two's complement just in case (though not needed for 0-90)
    if fixed_point_sin < 0:
        fixed_point_sin = (1 << 32) + fixed_point_sin

    sine_table.append(fixed_point_sin)

# --- Write the .mem file ---
with open(FILENAME, 'w') as f:
    f.write(f"@00000000\n")
    for val in sine_table:
        # Format as an 8-digit hex number (32 bits)
        hex_str = f"{val:08X}"
        # Add a space every 2 digits
        formatted_str = " ".join(hex_str[i:i+2] for i in range(0, len(hex_str), 2))
        f.write(f"{formatted_str}\n")

print(f"Successfully generated '{FILENAME}' with {len(sine_table)} values.")

# Format the example print statements to match
hex_str_30 = f"{sine_table[30]:08X}"
formatted_str_30 = " ".join(hex_str_30[i:i+2] for i in range(0, len(hex_str_30), 2))
print(f"Example: sin(30) = {formatted_str_30} (Decimal: {sine_table[30]})")

hex_str_90 = f"{sine_table[90]:08X}"
formatted_str_90 = " ".join(hex_str_90[i:i+2] for i in range(0, len(hex_str_90), 2))
print(f"Example: sin(90) = {formatted_str_90} (Decimal: {sine_table[90]})")

