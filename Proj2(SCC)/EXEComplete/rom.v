module rom(
    input clk,
    input rst,
    input  [31:0] original_instruct,
    output reg [31:0] instruction,
    output [31:0] data_out1,
    output [31:0] data_out2,
    input  [31:0] data_in,
    input  [1:0] destReg_sel,
    input  [1:0] op1Reg_sel,
    input  [1:0] op2Reg_sel,
    output reg romRegWrite_flag,
    output reg romRegRead_flag,
    input branchFlag,
    input [3:0] flags,
    output reg romCatch,
    input setCatch,
    input [1:0] mov_flag
); 

    reg [31:0] romReg[0:3];
    wire [31:0] romreg0Veiw;
    wire [31:0] romreg1Veiw;
    wire [31:0] romreg2Veiw;
    wire [31:0] romreg3Veiw;
    
    assign romreg0Veiw=romReg[0];
    assign romreg1Veiw=romReg[1];
    assign romreg2Veiw=romReg[2];
    assign romreg3Veiw=romReg[3];
    reg [15:0] programCounter;
    reg negFlag;
    reg internalCarry;
    reg internalOverflow;
    reg internalZero;
    reg internalNeg;
    reg [3:0] originalFlags;
    reg preventCatch;
    
    initial begin
     romCatch=0;
     preventCatch=0;
     negFlag=0;
    end
    always @(*) begin
       
        if(romCatch==0 && setCatch==0) begin 
            romRegRead_flag = 0;
            romRegWrite_flag = 0;
        end
        else begin
        case(programCounter) 
            0: begin
                romRegRead_flag = 0;
                romRegWrite_flag = 1;
                negFlag=0;
                internalCarry=0;
                originalFlags=flags;
                instruction = {7'b0010001,4'b0000,original_instruct[20:17],17'b0}; //using add instruction to mov original instruction reg 1 to reg 0
            end
            4: begin
                romRegRead_flag = 0;
                romRegWrite_flag = 1;
                if(original_instruct[30])begin //checking if immediate instruction or not
                    instruction = {7'b0010001,4'b0001,original_instruct[16:13],17'b0}; //using add instruction to mov original instruction reg 2 to reg 1
                end
                else begin
                    instruction = {7'b0000000,4'b0001,5'b00000,original_instruct[15:0]};   //using mov to mov immediate to reg 1
                end 

            end
            8: begin
                romRegRead_flag = 1;
                romRegWrite_flag = 0;
                instruction = {7'b0011010,4'b1110,4'b0000,17'b0};
            end
            12: begin //branch to done if 0
                romRegRead_flag = 0;
                romRegWrite_flag = 0;
                instruction = {7'b1100001,4'b0000,5'b0,16'b0000000001000100};
            end
            16: begin //branch to 28 if not Neg
                romRegRead_flag = 0;
                romRegWrite_flag = 0;
                instruction = {7'b1100001,4'b0101,5'b0,16'b0000000000001100};
            end
            20: begin //invert
                negFlag=negFlag+1;
                romRegRead_flag=1;
                romRegWrite_flag=1;
                instruction= {7'b0110110,4'b0000,4'b0000,17'b0};
            end
            24: begin
                romRegRead_flag=1;
                romRegWrite_flag=1;
                instruction = {7'b0010001,4'b0001,4'b0001,15'b0,1'b1};
            end
            28: begin       //cmp reg 1 to 0
                romRegRead_flag = 1;
                romRegWrite_flag = 0;
                instruction = {7'b0011010,4'b1110,4'b0001,17'b0};
            end
            32: begin //branch to done if 0
                romRegRead_flag = 0;
                romRegWrite_flag = 0;
                instruction = {7'b1100001,4'b0000,5'b0,16'b0000000000110000};
            end
            36: begin //branch to 48 if not Neg
                romRegRead_flag = 0;
                romRegWrite_flag = 0;
                instruction = {7'b1100001,4'b0101,5'b0,16'b0000000000001100};
            end
            40: begin //invert
                negFlag=negFlag+1;
                romRegRead_flag=1;
                romRegWrite_flag=1;
                instruction= {7'b0110110,4'b0001,4'b0001,17'b0};
            end
            44: begin
                romRegRead_flag=1;
                romRegWrite_flag=1;
                instruction = {7'b0010001,4'b0001,4'b0001,16'b0,1'b1};
            end
            48: begin //start of mul loop (r1 ands 1)
                romRegRead_flag=1;
                romRegWrite_flag=0;
                instruction = {7'b0011011,4'b1110,4'b0001,16'b0,1'b1};
            end
            52: begin //branch ahead if 0
                romRegRead_flag = 0;
                romRegWrite_flag = 0;
                instruction = {7'b1100001,4'b0000,5'b0,16'b0000000000001000};
            end

            56: begin //add r0 to r3
                romRegRead_flag=1;
                romRegWrite_flag=1;
                instruction = {7'b0110001,4'b0011,4'b0011,4'b0000,13'b0};
                if(flags[1]) begin
                    internalCarry=1;
                end
            end
            60: begin //shift r0
                romRegRead_flag=1;
                romRegWrite_flag=1;
                instruction = {7'b0000100,4'b0000,4'b0000,16'b0,1'b1};
            end
            64: begin //shift r1
                romRegRead_flag=1;
                romRegWrite_flag=1;
                instruction = {7'b0000101,4'b0001,4'b0001,16'b0,1'b1};
            end
            68: begin //cmp r1 to 0
                romRegRead_flag = 1;
                romRegWrite_flag = 0;
                instruction = {7'b0011010,4'b1110,4'b0001,17'b0};
            end
            72:begin //if 0 branch done
            
                romRegRead_flag = 0;
                romRegWrite_flag = 0;
                instruction = {7'b1100001,4'b0000,5'b0,16'b0000000000001000};
            end
            76: begin //branch to 48
                 romRegRead_flag = 0;
                romRegWrite_flag = 0;
                instruction ={7'b1100000,9'b0,16'b1111111111100100};
            end
            //"the done part"
            80: begin //cmp 0 to neg flag from earlier
                romRegRead_flag = 0;
                romRegWrite_flag = 0;
                instruction = {7'b0011010,4'b1110,4'b1110,16'b0,negFlag};
            end
            84: begin //branch if 0
                romRegRead_flag = 0;
                romRegWrite_flag = 0;
                instruction = {7'b1100001,4'b0000,5'b0,16'b0000000000001100};
            end
            88: begin
                romRegRead_flag=1;
                romRegWrite_flag=1;
                instruction= {7'b0110110,4'b0011,4'b0011,17'b0};
            end
            92: begin
                romRegRead_flag=1;
                romRegWrite_flag=1;
                instruction = {7'b0010001,4'b0011,4'b0011,16'b0,1'b1};
            end
            96: begin
                romRegWrite_flag=0;
                romRegRead_flag=1;
                instruction = {7'b0010001,original_instruct[24:21],4'b0011,17'b0};
            end
            100: begin
                //if flags need to be set they are getting changed
                if(original_instruct[28]) begin
                    if(romReg[3]==0) begin
                        originalFlags[2]=1;
                    end
                    else begin
                        originalFlags[2]=1;
                    end
                    if(romreg3Veiw[31]==1)begin
                        originalFlags[3]=1;
                    end
                    else begin
                        originalFlags[3]=0;
                    end
                    originalFlags[1]=internalCarry;
                    if(romreg3Veiw[31]==negFlag) begin
                        originalFlags=0;
                    end
                    else begin
                        originalFlags=1;
                    end
                    
                end
                romRegRead_flag=0;
                romRegWrite_flag=1;
                case(originalFlags) 
                        0:instruction = {7'b0000000,4'b0000,5'b0,16'b0}; //mov 0 into 0
                        1:instruction = {7'b0000000,4'b0000,5'b0,16'b1}; //start mov of -1 into 0
                        2:instruction = {7'b0000000,4'b0000,5'b0,15'b0,1'b1}; //mov  1 into 0
                        3:instruction = {7'b0000000,4'b0000,5'b0,16'b0}; //start mov most neg into 0
                        4:instruction = {7'b0000000,4'b0000,5'b0,16'b0}; //mov 0 into 0
                        6:instruction = {7'b0000000,4'b0000,5'b0,16'b1}; //start mov of -1 into 0
                        7:instruction = {7'b0000000,4'b0000,5'b0,16'b0}; //start mov most neg into 0
                        8:instruction = {7'b0000000,4'b0000,5'b0,15'b1,1'b0}; //start mov of -2 into 0
                        9:instruction = {7'b0000000,4'b0000,5'b0,15'b0,1'b1}; //mov  1 into 0
                        10:instruction = {7'b0000000,4'b0000,5'b0,16'b1}; //start mov of -1 into 0
                        default:instruction = {7'b0000000,4'b0000,5'b0,15'b0,1'b1}; //mov  1 into 0
                endcase
                
            end
            104: begin
                romRegRead_flag=0;
                romRegWrite_flag=1;
                case(originalFlags) 
                        0:instruction = {7'b0000001,4'b0000,5'b0,16'b0}; //mov 0 into 0
                        1:instruction = {7'b0000001,4'b0000,5'b0,16'b1}; //mov of -1 into 0
                        2:instruction = {7'b0000001,4'b0000,5'b0,16'b0}; //mov  1 into 0
                        3:instruction = {7'b0000001,4'b0000,5'b0,1'b1,15'b0}; //mov most neg into 0
                        4:instruction = {7'b0000001,4'b0000,5'b0,16'b0}; //mov 0 into 0
                        6:instruction = {7'b0000001,4'b0000,5'b0,16'b1}; //mov -1 into 0
                        7:instruction = {7'b0000001,4'b0000,5'b0,1'b1,15'b0}; //mov most neg into 0
                        8:instruction = {7'b0000001,4'b0000,5'b0,16'b1}; //mov -2 into 0
                        9:instruction = {7'b0000001,4'b0000,5'b0,16'b0}; //mov  1 into 0
                        10:instruction = {7'b0000001,4'b0000,5'b0,16'b1}; //mov -1 into 0
                        default:instruction = {7'b0000001,4'b0000,5'b0,16'b0}; //mov  1 into 0
                endcase
            end

            108: begin
                romRegRead_flag=0;
                romRegWrite_flag=1;
                case(originalFlags) 
                        0:instruction = {7'b0000000,4'b0001,5'b0,15'b0,1'b1}; //mov  1 into 1
                        1:instruction = {7'b0000000,4'b0001,5'b0,16'b0}; //mov of most neg into 1
                        2:instruction = {7'b0000000,4'b0001,5'b0,16'b0}; //mov  0 into 1
                        3:instruction = {7'b0000000,4'b0001,5'b0,16'b1}; //mov -1 into 1
                        4:instruction = {7'b0000000,4'b0001,5'b0,16'b0}; //mov 0 into 1
                        6:instruction = {7'b0000000,4'b0001,5'b0,15'b0,1'b1}; //mov 1 into 1
                        7:instruction = {7'b0000000,4'b0001,5'b0,16'b0}; //mov most neg into 1
                        8:instruction = {7'b0000000,4'b0001,5'b0,15'b0,1'b1}; //mov 1 into 1
                        9:instruction = {7'b0000000,4'b0001,5'b0,16'b1}; //mov  most pos into 1
                        10:instruction = {7'b0000000,4'b0001,5'b0,16'b1}; //mov -1 into 0
                        default:instruction = {7'b0000000,4'b0001,5'b0,16'b0}; //mov  0 into 1
                endcase
                
            end
            112: begin
                romRegRead_flag=0;
                romRegWrite_flag=1;
                case(originalFlags) 
                        0:instruction = {7'b0000001,4'b0001,5'b0,16'b0}; //mov 1 into 1
                        1:instruction = {7'b0000001,4'b0001,5'b0,1'b1,15'b0}; //mov of most neg into 1
                        2:instruction = {7'b0000001,4'b0001,5'b0,16'b0}; //mov  0 into 1
                        3:instruction = {7'b0000001,4'b0001,5'b0,16'b1}; //mov -1 into 1
                        4:instruction = {7'b0000001,4'b0001,5'b0,16'b0}; //mov 0 into 1
                        6:instruction = {7'b0000001,4'b0001,5'b0,16'b0}; //mov 1 into 1
                        7:instruction = {7'b0000001,4'b0001,5'b0,1'b1,15'b0}; //mov most neg into 1
                        8:instruction = {7'b0000001,4'b0001,5'b0,16'b0}; //mov 1 into 1
                        9:instruction = {7'b0000001,4'b0001,5'b0,1'b0,15'b1}; //mov  most pos into 1
                        10:instruction = {7'b0000001,4'b0001,5'b0,16'b1}; //mov -1 into 1
                        default:instruction = {7'b0000001,4'b0001,5'b0,16'b0}; //mov  0 into 1
                endcase
                
            end
            116: begin
                romRegRead_flag=1;
                romRegWrite_flag=0;
                case(originalFlags) 
                        0:instruction = {7'b0111001,4'b1110,4'b0000,4'b0001,13'b0}; //adds 0 and 1 store in 14
                        1:instruction = {7'b0111010,4'b1110,4'b0000,4'b0001,13'b0}; //subs 0 and 1 store in 14
                        2:instruction = {7'b0111010,4'b1110,4'b0000,4'b0001,13'b0}; //subs 0 and 1 store in 14
                        3:instruction = {7'b0111001,4'b1110,4'b0000,4'b0001,13'b0}; //adds 0 and 1 store in 14
                        4:instruction = {7'b0111001,4'b1110,4'b0000,4'b0001,13'b0}; //adds 0 and 1 store in 14
                        6:instruction = {7'b0111001,4'b1110,4'b0000,4'b0001,13'b0}; //adds 0 and 1 store in 14
                        7:instruction = {7'b0111001,4'b1110,4'b0000,4'b0001,13'b0}; //adds 0 and 1 store in 14
                        8:instruction = {7'b0111001,4'b1110,4'b0000,4'b0001,13'b0}; //adds 0 and 1 store in 14
                        9:instruction = {7'b0111001,4'b1110,4'b0000,4'b0001,13'b0}; //adds 0 and 1 store in 14
                        10:instruction = {7'b0111001,4'b1110,4'b0000,4'b0001,13'b0}; //adds 0 and 1 store in 14
                        default:instruction = {7'b0111001,4'b1110,4'b0000,4'b0001,13'b0}; //adds 0 and 1 store in 14
                endcase
            end
            120: begin
                romCatch=0;
                preventCatch=1;
            end
            default: begin
                romCatch=0;
            end
        endcase
        end
    end

//New variables IF
reg [1:0] branchOpRom;
reg [3:0] branchDefineRom;
reg [15:0] branchImmediateRom;
wire [31:0] write_reg;
assign write_reg = romReg[destReg_sel];
//REGS
reg [31:0] data_out1, data_out2;

//IF
always @(*) begin
    branchOpRom = instruction[31:30];
    branchDefineRom = instruction[28:25];
    branchImmediateRom = {instruction[15:0]};
    if (branchOpRom == 3 && (branchDefineRom == 0 )) begin //take branch for unconditional
            programCounter = programCounter + branchImmediateRom;
    end
    else begin
            programCounter = programCounter;
    end
end

always@(posedge clk) begin
    if (rst == 0 && romCatch) begin
        if (romRegWrite_flag == 1) begin
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
        {romReg[0], romReg[1], romReg[2], romReg[3]} = 0; //sets all regs to 0
    end
end

always @(posedge clk) begin
     if(setCatch) begin
            if(preventCatch==0)begin
                romCatch=1;
            end
            else begin
                romCatch=0;
            end
        end
    if (rst == 0 && romCatch) begin
        if (branchOpRom == 3 && branchFlag == 1 && branchDefineRom == 1) begin //take branch for conditional
            programCounter = programCounter + branchImmediateRom;
        end
        else begin
            programCounter = programCounter + 4;
        end
    end
    else begin
        programCounter = 16'b1111111111111100;
        preventCatch=0;
        negFlag=0;
    end
end

//REGS
always @(*) begin
    data_out1 = romReg[op1Reg_sel]; //reading the associated register number
    data_out2 = romReg[op2Reg_sel];
end


endmodule