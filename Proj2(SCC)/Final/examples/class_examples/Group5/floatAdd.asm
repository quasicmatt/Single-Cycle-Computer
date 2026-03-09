	ORG     #0x400;
	FCB     #0xC1200000;op1 num 1
	FCB     #0xC1200000;op1 num 2
	FCB     #0;         op1 output

	FCB     #0xC1200000;op2 num 1
	FCB     #0x40400000;op2 num 2
	FCB     #0;         op2 output

	FCB     #0x00000000;op3 num 1
	FCB     #0xC1200000;op3 num 2
	FCB     #0;         op3 output

	FCB     #0x7F800000;op4 num 1
	FCB     #0xFF800000;op4 num 2
	FCB     #0;         op4 output

	FCB     #0x7F810000;op5 num 1
	FCB     #0xFF800000;op5 num 2
	FCB     #0;         op5 output

	FCB     #0x40200000;op6 num 1
	FCB     #0x3ff00000;op6 num 2
	FCB     #0;         op6 output
	ORG     #0x0;
START:
	MOV R13,#6;  //counter for how many times to loop
	MOV R11,#0x400; //mem location for data
	;//R0 operand 1
	;//R1 operand 2
	;//R2 Mask
	;//R3 operand 1 exponent
	;//R4 operand 2 exponent
	;//R5 operand 1 mantissa
	;//R6 operand 2 mantissa
	;//R7 Mantissa calc
	;//R8 result sign
	;//R9 Implicit 1 of mantissa
	;//r10 burner flag reg
	;//R12 Result
	;//0x40400000: 3 0x41400000: 12 0xC1200000: -10
LoadNum:
	MOV R2, #0;
	MOV R3, #0;
	MOV R4, #0;
	MOV R5, #0;
	MOV R6, #0;
	MOV R7, #0;
	MOV R8, #0;
	MOV32 R9, #0x00800000;
	MOV R12, #0;	
	LOAD R0, r11; //op1
	LOAD R1, r11,#4; //op2
	ors r5,r5,r5
	b.ne #0xFFFF;
CHKZERO1:
	MOV32 R2, #0x7F800000; //Masking exponents for 0
	ANDS R3, R0, R2; //Masking operand 1
	B.EQ ZEROADD1;
CHKZERO2:
	ANDS R4, R1, R2; //Masking operand 2
	B.EQ ZEROADD2;
CHKINF1:
	CMP R3, R2;
	B.EQ NAN1;
CHKINF2:
	CMP R4, R2;
	B.EQ NAN2;
GRBMAN:
	MOV32 R2, #0x007FFFFF; //Mask for mantissa
	AND R5, R0, R2;
	AND R6, R1, R2;
	OR R5, R5, R9;//Add implicit 1
	OR R6, R6, R9; //Add implicit 1
	LSR R3,R3, #23; //Shift exponents
	LSR R4,R4, #23;
	MOV32 R2, #0x00FFFFFF; //Mask for implicit 1 mantissa
CHKOP1G:
	CMP R3, R4; //Check which exponent is larger
	B.EQ CHKNEG1;
	B.MI OP2G;
OP1G:
	ADD R4, R4, #1; //Add op2 exponent
	LSR R6,R6, #1; //Shift right op2 mantissa
	CMP R3, R4;
	B.NE OP1G;
	mov r10,#4;//nzcv
	SAVF r10; //was a normal branch using this to check cases   checked on 2
	B.LE CHKNEG1;
OP2G:
	ADD R3, R3, #1; //Add op1 exponent
	LSR R5,R5, #1; //Shift right op1 mantissa
	CMP R3, R4;
	B.NE OP2G;
CHKNEG1:
	CMP R0, #0; //Check op1 is neg
	B.MI OP1COMP;
CHKNEG2:
	CMP R1, #0; //CHeck op2 is neg
	B.MI OP2COMP;
	mov r10,#0;//nzcv
	SAVF r10; //was a normal branch using this to check cases   checked on 1
	B.GE OPADD;
OP1COMP:
	NOT R5, R5; //2's complement
	ADD R5,R5, #1;
	mov r10,#4;//nzcv
	SAVF r10; //was a normal branch using this to check cases   checked on 1
	B.LS CHKNEG2;
OP2COMP:
	NOT R6, R6; //2's complement
	ADD R6,R6, #1;
OPADD:
	ADDS R7, R5, R6; //Add the results and check if negative
	B.PL SHIFTRIGHT;
RESCOMPL:
	NOT R7, R7;
	ADD R7,R7, #1;
	MOV32 R8, #0x80000000; //Set signed as neg
SHIFTRIGHT:
	CMP R2, R7;
	B.PL SHIFTLEFT;
	LSR R7,R7, #1; //Shift right by 1
	ADD R3,R3, #1; //Add 1 to exponent
	mov r10,#2;//nzcv
	SAVF r10; //was a normal branch using this to check cases   checked on 1
	B.HI SHIFTRIGHT;
SHIFTLEFT:
	CMP R7, R9; //Compare mantissa to implicit 1 value
	B.PL SETRESULT;
	LSL R7,R7, #1; //Shift left by 1
	SUB R3,R3, #1; //Subtract 1 from exponent
	mov r10,#0;//nzcv
	SAVF r10; //was a normal branch using this to check cases  checked on 2
	B.VC SHIFTLEFT;
ZEROADD1:
	Add R12, R1,#0;
	mov r10,#1;//nzcv
	SAVF r10; //was a normal branch using this to check cases checked on 3
	B.VS DONE;
ZEROADD2:
	Add R12, R0,#0;
	B DONE;
NAN1:
	CMP R4, R2;
	B.EQ NANBoth;
	Add R12, R0,#0;
	B DONE;
NAN2:
	Add R12, R1,#0;
	B DONE;
NANBoth:
	MOV32 R2, #0x007FFFFF;
	ANDS R5, R0, R2;
	b.ne NAN;
	ANDS R6, R1, R2;
	b.ne NAN;
	cmp r0,r1;
	b.eq NAN2;
	mov r12,#0;
	mov r10,#0;//nzcv
	SAVF r10; //was a normal branch using this to check cases   checked on 4
	B.LO DONE;
NAN:
	MOV32 r12, #0x7fc00000;
	b DONE;

SETRESULT:
	MOV32 R2, #0x007FFFFF; //Mask for mantissa
	AND R7, R7, R2;
	LSL R3,R3, #23; //Shift exponent back
	OR R12, R8, R3;
	OR R12, R12, R7;
DONE:
	STOR R12,r11,#8;
	add r11,r11,#12;
	sub r13,r13,#1;
	MULS r14,r13,r13; //using this instead of subs to check an instruct no one had checked 
	b.ne LoadNum
	HALT;
	
	