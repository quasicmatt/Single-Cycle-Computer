module alu (
    input  [31:0] operand1,
    input  [31:0] operand2,
    input  [2:0]  alu_Instruction,
    input flagFlag,
    output reg [31:0] result,
    output reg zero,
    output reg overflow,
    output reg carry,
    output reg negative
);

    // ALU operation codes
    localparam ADD = 1;
    localparam SUB = 2;
    localparam AND = 3;
    localparam OR  = 4;
    localparam XOR = 5;
    localparam NOT = 6;

    // Intermediate signal for carry and overflow
    reg [32:0] temp_result;
    reg zero_temp;
    reg carry_temp;
    reg overflow_temp;
    reg negative_temp;

    // ALU Logic
    always @(*) begin
        carry_temp = 1'b0; // Default
        overflow_temp = 1'b0;

        case (alu_Instruction)
            ADD: begin
                temp_result <= {1'b0, operand1} + {1'b0, operand2};
                result <= temp_result[31:0];
                carry_temp = temp_result[32];  // Carry out
                // Overflow detect for pos/neg add
                overflow_temp = (operand1[31] == operand2[31]) && (result[31] != operand1[31]);
            end

            SUB: begin
                temp_result = {1'b0, operand1} - {1'b0, operand2};
                result = temp_result[31:0];
                carry_temp = ~temp_result[32];  //Inverse carry for sub
                // Overflow for pos/neg sub
                overflow_temp = (operand1[31] != operand2[31]) && (result[31] != operand1[31]);
            end

            AND: begin
                result = operand1 & operand2;
            end

            OR: begin
                result = operand1 | operand2;
            end

            XOR: begin
                result = operand1 ^ operand2;
            end

            NOT: begin
                result = ~operand1;
            end

            default: begin
                result = 0;
            end
        endcase

        zero_temp = (result == 0);  // Check if output is 32'b0
        negative_temp = result[31];     // Check MSB for 1

        if(flagFlag) begin
            zero = zero_temp;
            overflow = overflow_temp;
            carry = carry_temp;
            negative = negative_temp;
        end
    end

endmodule
