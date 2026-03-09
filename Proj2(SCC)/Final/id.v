module id(
    input [31:0] instruction,       //instruction from IF
    output reg halt_f,              //set halt
    output [3:0] b_cond,            //says what branch conditional we are doing
    output [3:0] destination_reg,   //destination reg
    output [3:0] op1_reg,           //operand1 reg
    output [3:0] op2_reg,           //operand2 reg
    output [15:0] immediate,        //data immediate
    output reg alu_Flag,            //flag to say if we are doing an ALU instruction
    output reg flag_Flag,           //flag to say if we are setting flags
    output reg shift_Flag,          //flag to say if we are doing a shift instruction
    output reg immediate_Flag,      //flag to say if we are using an immediate
    output reg load_Flag,           //flag for if storing from alu or mem
    output reg store_Flag,          //flag for if writing to reg or mem
    output reg branch_Flag,         //flag for if branching
    output reg write_to_reg_Flag,   //flag for writing to a reg
    output reg [2:0] alu_Instruct,  //flag for what alu instruction
    output reg [1:0] mov_flag,      //flag for what kinda move
    output reg clear_flag,          //flag for clear instruction
    output reg set_flag,            //flag for set instruction
    output reg setCatch,            //flag for starting MUL
    output reg sav_flag,            //flag for saving nzcv flags
    output reg branch_reg,          //flag for branch register instruction
    input preventCatch              //prevent MUL instruction catch
    );

wire b_cond = instruction[24:21];
wire destination_reg = instruction[24:21];
wire op1_reg = instruction[20:17];
wire op2_reg = instruction[16:13];
wire immediate = instruction[15:0];
//assign alu_Instruct=instruction[27:25];

initial begin
    halt_f=0;
    setCatch=0;
end
always @(instruction) begin
    alu_Instruct<=instruction[27:25];
    sav_flag=0;
    set_flag <= 0;
    branch_reg=0;
    case (instruction[31:30])
        0: begin
            //loading and storing to regs
            load_Flag <= 0;
            store_Flag <= 0;
            clear_flag=0;
            branch_Flag=0;
            
            write_to_reg_Flag=1;
            //data immediate
            immediate_Flag <= 1;
            
            //setting if flags should be set or not
            if(instruction[28]) flag_Flag=1;
            else flag_Flag=0;
        
            case(instruction[29]) 
                1: begin
                    //ALU
                    alu_Flag<=1;
                    mov_flag = 0;
                    shift_Flag <= 0;
                    if(instruction[27:25]==0) begin
                        //MUL
                        flag_Flag=0;
                        if(preventCatch==0) //sets catch as long as prevent catch is 0
                            setCatch=1;
                    end
                    
                end
                0: begin
                    //Special
                    alu_Flag<=0;
                    shift_Flag <= 0;
                    mov_flag = 0;
                    
                    case(instruction[27:25])
                        0: begin
                            //mov
                            mov_flag = 1;
                        end
                        1: begin
                            //movt
                            mov_flag = 2;
                        end
                        2: begin
                            //CLR
                            mov_flag = 0;
                            clear_flag=1;
                        end
                        3: begin
                            //SET
                            set_flag <= 1;
                            mov_flag = 0;
                        end
                        4: begin
                            //LSL
                            mov_flag = 0;
                            shift_Flag <= 1;
                        end
                        5: begin
                            //LSR
                            mov_flag = 0;
                            shift_Flag <= 1;
                        end
                        6: begin
                            //movf
                            if(flag_Flag) begin
                                sav_flag=1;
                                write_to_reg_Flag=0;
                            end
                            else
                                mov_flag = 3;
                        end
                    endcase
                end
            endcase
        end
        1: begin
            //loading and storing to regs
            load_Flag <=0;
            branch_Flag=0;
            store_Flag <=0;
            mov_flag = 0;
            shift_Flag <= 0;
            write_to_reg_Flag<=1;
            //data reg
            immediate_Flag <= 0;
            clear_flag=0;
            //setting if flags should be set or not
            if(instruction[28]) flag_Flag=1;
            else flag_Flag=0;
            
            
            //ALU
            alu_Flag<=1;
            if(instruction[27:25]==0) begin
                //MUL
                    flag_Flag=0;
                if(preventCatch==0) //sets catch as long as prevent catch is 0
                    setCatch=1;
            end
        end
        2: begin
            //load store
            branch_Flag=0;
            
            mov_flag = 0;
            shift_Flag <= 0;
            immediate_Flag <= 1;
            flag_Flag=0;
            clear_flag=0;
            case(instruction[25])
                0: begin
                    //load
                    load_Flag <=1;
                    store_Flag <=0;
                    write_to_reg_Flag<=1;
            
                end
                1: begin
                    //store
                    load_Flag <=0;
                    store_Flag <=1;
                    write_to_reg_Flag<=0;
                end
            endcase
        end
        3: begin
            //sytem and branch
            branch_Flag=0;
            
            clear_flag=0;
            //not writeing to a reg
            write_to_reg_Flag<=0;
            mov_flag = 0;
            flag_Flag=0;
            shift_Flag <= 0;
            if(instruction[28]) begin
                //Halt
                if(setCatch) begin 
                    setCatch <= 0;
                    
                end
                else halt_f <= 1;
            end
            else begin
                if(instruction[27]) begin
                    //NOP
                end
                else begin
                    case(instruction[26:25])
                        0: begin
                            //Branch
                            branch_Flag=1;
                        end
                        1: begin
                            //branch cond
                            branch_Flag=1;
                        end
                        2: begin
                            //branch reg
                            branch_Flag=1;
                            branch_reg=1;
                            immediate_Flag <= 1;
                        end
                    endcase
                end
            end
        end
    endcase
end

endmodule

