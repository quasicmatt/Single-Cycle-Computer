START:
    MOV R0, #8;
    MOV R1, #1;
    MUL R2, R1, R0;

    CLR;

    MOV R0, #-1;
    MOV R1, #0;
    MULS R2, R1, R0;

    CLR;

    MOV R0, #8;
    MULI R2, R0, #2;

    CLR;

    MOV R0, #0;
    MULS R2, R0, #-1;
