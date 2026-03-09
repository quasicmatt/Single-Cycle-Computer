START:
    MOV R0, #8;
    MOV R1, #1;
    MUL R2, R1, R0;

    CLR R0;
    CLR R1;
    CLR R2;

    MOV32 R0, #0xFFFFFFFF;
    MOV R1, #0;
    MULS R2, R1, R0;

    CLR R0;
    CLR R1;
    CLR R2;

    MOV R0, #8;
    MUL R2, R0, #2;

    CLR R0;
    CLR R1;
    CLR R2;

    MOV32 R0, #0xFFFFFFFF;
    MULS R2, R0, #0;
    HALT;
