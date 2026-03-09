module test_uC(
    input clk,
    input rst,
    input  [31:0] orig_instruction,          // From IF
    input  [31:0] reg_data1,                 // Data for MUL Regs
    input  [31:0] reg_data2,                 // ^^^^^^^^^^^^^^^^^
    input  [31:0] data_in,
    input  [1:0] mov_flag,
    input  [2:0] destReg_sel,
    input  [2:0] op1Reg_sel,
    input  [2:0] op2Reg_sel,
    input branchFlag,
    input write_to_reg_Flag,
    input   setCatch,
    input [31:0] rom_instruction,
    output reg [31:0] instruction,      // Go to ID
    output reg [15:0] rom_programCounter,    // Go to ROM
    output reg romRegWrite_flag,
    output reg romRegRead_flag,
    output reg [31:0] data_out1,
    output reg [31:0] data_out2



);

    wire set_Flags;                         // Do we set Flags
    wire imm_Flag;                          // Is MUL an IMM
    wire zero_result;                       // Is MUL result a Zero?

    wire op1_reg = orig_instruction[20:17];
    wire op2_reg = orig_instruction[16:13];
    wire immediate = orig_instruction[15:0];

    reg temp_Zero;
    reg temp_Negative;
    reg [6:0] orig_opcode;

    reg [1:0] branchOp;
    reg [3:0] branchDefine;
    reg [31:0] branchImmediate;
    reg [31:0] romReg[0:7];

    wire [31:0] dbg_reg0,dbg_reg1,dbg_reg2,dbg_reg3,dbg_reg4,dbg_reg5,dbg_reg6,dbg_reg7;
    assign dbg_reg0=romReg[0];
    assign dbg_reg1=romReg[1];
    assign dbg_reg2=romReg[2];
    assign dbg_reg3=romReg[3];
    assign dbg_reg4=romReg[4];
    assign dbg_reg5=romReg[5];
    assign dbg_reg6=romReg[6];
    assign dbg_reg7=romReg[7];


    // Shorthand for opcodes
    localparam MULI  = 'b0010000;
    localparam MULSI = 'b0011000;
    localparam MUL   = 'b0110000;
    localparam MULS  = 'b0111000;

    localparam ADD1 = 0;
    localparam ADD2 = 4;
    localparam ADD3 = 120;

    assign set_Flags = ((orig_opcode == MULSI) || (orig_opcode == MULS));       // Set flags if instuction is MULS/MULSI
    assign imm_Flag  = ((orig_opcode == MULI) || (orig_opcode == MULSI));       // Set flag if instruction is MULI/MULSI


    //always @(*) begin
    //    orig_opcode <= orig_instruction[31:25];

    //    if(set_Flags) begin                                                     // Following knowing which flags to set, after MULS/MULSI, need to run ALU instructions to set the flags
    //        if(imm_Flag) begin                                                  // We don't care about C or V flags for MUL operations
    //            temp_Zero <= ((reg_data1 == 32'b0) || (immediate == 16'b0));    // Set 1 if either operand is zero
    //            temp_Negative <= ((reg_data1[31]) ^ (immediate[15]));           // Set 1 if only 1 MSB is 1
    //        end
    //        else begin
    //            temp_Zero <= ((reg_data1 == 32'b0) || (reg_data2 == 32'b0));    // Set 1 if either operand is zero
    //            temp_Negative <= (reg_data1[31] ^ reg_data2[31]);               // Set 1 if only 1 MSB is 1
    //        end
    //    end

    //end

    initial begin
        romRegRead_flag <= 0;
        romRegWrite_flag <= 1;
    end

    // Pulled from IF
    always @(*) begin
        branchOp = rom_instruction[31:30];
        branchDefine = rom_instruction[28:25];
        branchImmediate = {{16{rom_instruction[15]}}, rom_instruction[15:0]};

        if (branchOp == 3 && (branchDefine == 0 )) begin //take branch for unconditional
                rom_programCounter = rom_programCounter + branchImmediate;
        end
        else begin
                rom_programCounter = rom_programCounter;
        end
        
        case(rom_programCounter)
            ADD1: begin                 //for first add over write reg to be the reg from mul instruct and set flags to read from normal regs into rom regs
                romRegRead_flag <= 0;
                romRegWrite_flag <= 1;
                instruction = rom_instruction;
                instruction[16:13] = orig_instruction[20:17];
            end

            ADD2: begin
                romRegRead_flag <= 0;      //for second add again set to read from normal to rom regs and copy over opperand 2 from mul be that a reg or immediate
                romRegWrite_flag <= 1;
                instruction = rom_instruction;
                instruction[16:0] = orig_instruction[16:0];
                instruction[30] = orig_instruction[30] ;
            end
            ADD3: begin
                romRegRead_flag <= 1;       //for third add set to read from rom regs into normal regs and write back to the destination from original mul
                romRegWrite_flag <= 0;
                instruction = rom_instruction;
                instruction[24:21] = orig_instruction[24:21];
                instruction[28] = orig_instruction[28];
            end
            16'b1111111111111100: begin        //when in the simi reset state stay as no op with read and write on normal regs
                instruction = {{7'b1100100}, {25'b0}};
                romRegRead_flag <= 0;
                romRegWrite_flag <= 0;
            end
            default: begin                   //all other instruction read as normal and read write set to rom regs only
                romRegRead_flag <= 1;
                romRegWrite_flag <= 1;
                instruction = rom_instruction;
            end
        endcase

        
    end

    wire [31:0] write_reg;
    assign write_reg = romReg[destReg_sel];

    //Regs pasted from rom.v
    always@(posedge clk) begin
        if (rst == 0 && setCatch) begin
            if (romRegWrite_flag == 1 && write_to_reg_Flag) begin
                if(mov_flag==2) begin
                    romReg[destReg_sel] = {data_in[31:16], write_reg[15:0]};
                end
                else begin
                    romReg[destReg_sel] = data_in; //if write_Flag is enabled, write the input data to the chosen register
                end
            end
            else begin
                romReg[destReg_sel] = romReg[destReg_sel]; //if write_Flag is disabled, the chosen register saves its current value
            end
        end
        else begin
            {romReg[0], romReg[1], romReg[2], romReg[3], romReg[4], romReg[5], romReg[6], romReg[7]} = 0; //sets all regs to 0
        end
    end



   always @(posedge clk) begin
    if (rst == 0 && setCatch) begin
        if (branchOp == 3 && branchFlag == 1 && branchDefine == 1) begin //take branch for conditional
            rom_programCounter = rom_programCounter + branchImmediate;
        end
        else begin
            rom_programCounter = rom_programCounter + 4;
        end
    end
    else begin
        rom_programCounter = 16'b1111111111111100;
    end
end

    //REGS
    always @(*) begin
        data_out1 = romReg[op1Reg_sel]; //reading the associated register number
        data_out2 = romReg[op2Reg_sel];
    end
endmodule
