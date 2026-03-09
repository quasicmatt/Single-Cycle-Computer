module id(
    input [31:0] instruction,
    output [3:0] b_cond,
    output [3:0] destination_reg,
    output [3:0] op1_reg,
    output [3:0] op2_reg,
    output [15:0] immediate,
    output reg alu_Flag,
    output reg flag_Flag,   //flag to say if we are setting flags
    output reg immediate_Flag, //flag to say if we are using an immediate
    output reg load_Flag,  //flag for if storing from alu or mem
    output reg store_Flag,  //flag for if writing to reg or mem
    output reg branch_Flag, //flag for if branching
    output reg write_to_reg_Flag, //flag for writing to a reg 
    output [2:0] alu_Instruct  //flag for what alu instruction
    );

assign b_cond = instruction[24:21];
assign destination_reg = instruction[24:21];
assign op1_reg = instruction[20:17];
assign op2_reg = instruction[16:13];
assign immediate = instruction[15:0];
assign alu_Instruct=instruction[27:25];

always @(instruction) begin
    case (instruction[31:30])
        0: begin
            //loading and storing to regs
            load_Flag <= 0;
            store_Flag <= 0;

            //data immediate
            immediate_Flag <= 1;
            
            //setting if flags should be set or not
            if(instruction[28]) flag_Flag<=1;
            else flag_Flag<=0;
        
            case(instruction[29]) 
                1: begin
                    //ALU
                    alu_Flag<=1;
                    case(instruction[27:25])
                        0: begin
                            //MUL
                        end
                        1: begin
                            //ADD
                        end
                        2: begin
                            //SUB
                        end
                        3: begin
                            //AND
                        end
                        4: begin
                            //OR
                        end
                        5: begin
                            //XOR
                        end
                        6: begin
                            //NOT
                        end
                        7: begin
                            //DIV
                        end
                    endcase
                end
                2: begin
                    //Special
                    alu_Flag<=0;
                    case(instruction[27:25])
                        0: begin
                            //mov
                        end
                        1: begin
                            //movt
                        end
                        2: begin
                            //CLR
                        end
                        3: begin
                            //SET
                        end
                        4: begin
                            //LSL
                        end
                        5: begin
                            //LSR
                        end
                        6: begin
                            //movf
                        end
                    endcase
                end
            endcase
        end
        1: begin
            //loading and storing to regs
            load_Flag <=0;
            store_Flag <=0;
            
            //data reg
            immediate_Flag <= 0;

            //setting if flags should be set or not
            if(instruction[28]) flag_Flag<=1;
            else flag_Flag<=0;
            
            
            //ALU
            alu_Flag<=1;
            case(instruction[27:25])
                0: begin
                    //MUL
                end
                1: begin
                    //ADD
                end
                2: begin
                    //SUB
                end
                3: begin
                    //AND
                end
                4: begin
                    //OR
                end
                5: begin
                    //XOR
                end
                6: begin
                    //NOT
                end
                7: begin
                    //DIV
                end
            endcase
        end
        2: begin
            //load store
            case(instruction[25])
                0: begin
                    //load
                    load_Flag <=1;
                    store_Flag <=0;
            
                end
                1: begin
                    //store
                    load_Flag <=0;
                    store_Flag <=1;
                end
            endcase
        end
        3: begin
            //sytem and branch


            //not writeing to a reg
            write_to_reg_Flag<=0;

            if(instruction[28]) begin
                //Halt
            end
            else begin
                if(instruction[27]) begin
                    //NOP
                end
                else begin
                    case(instruction[26:25])
                        0: begin
                            //Branch
                        end
                        1: begin
                            //branch cond
                        end
                        2: begin
                            //branch reg
                        end
                    endcase
                end
            end
        end
    endcase
end

endmodule

