START:
	ADD R0, R14, r0; //OpeRand 1
	ADD R1, R14, #0; //OpeRand 2
	MOVF R4; //ORiginal Flag
OPER1:
	SUBS R0, R0, #0; //Check Neg
	B.EQ OUTPUT;
	B.MI OPER1NEG;
OPER2:
	SUBS R1, R1, #0; //Check Neg
	B.EQ OUTPUT;
	B.MI OPER2NEG;
OPERATION:
	ANDS R3, R1, #1; //LSB of multiplier
	B.EQ OPERATIONNEXT;
	ADD R2, R2, R0;
OPERATIONNEXT:
	LSL R0, R0, #1;
	LSR R1, R1, #1;
	SUBS R1, R1, #0x0; //See if multiplier is 0
	B.EQ OUTPUT;
	B OPERATION;
OPER1NEG:
	NOT R0, R0; //2's complement
	ADD R0, R0, #1;
	ADD R5, R5, #1; //Add to Neg counter
	B OPER2;
OPER2NEG:
	NOT R1, R1; //2's complement
	ADD R1, R1, #1;
	ADD R5, R5, #1; //Add to Neg counter
	B OPERATION;
OUTPUT:
	ANDS R7, R5, #1;
	B.EQ FLAGSHELL;
NEGATIVEOUT:
	NOT R2, R2; //2's complement
	ADD R2, R2, #1;
FLAGSHELL:
	ANDS R6,R4,#8; //Masking for the N flag and checking if it's on
	B.EQ NEG;
POS:
	ANDS R6,R4,#4; //Masking for the Z flag
	B.NE ZERO;
	ANDS R6,R4,#2;	//Masking for the C flag
	B.NE CARRY;
	ANDS R6,R4,#1; //Masking for the V flag
	B.NE OVER;
	MOV32 R0,#1;
	MOV32 R1,#0;
	ADDS R6,R0,R1; //Setting no flag
	B FINALDONE;
OVER:
	MOV32 R0,#0xFFFFFFFF;
	MOV32 R1,#0x80000000;
	SUBS R6,R0,R1; //Setting V flag
	B FINALDONE;
CARRY:
	ANDS R6,R4,#1; //Masking for CV flag
	B.NE CARRYV;
	MOV32 R0,#1;
	MOV32 R1,#0;
	SUBS R6,R0,R1; //Setting C flag
CARRYV:
	MOV32 R0,#0xFFFFFFFF;
	MOV32 R1,#0x80000000;
	ADDS R6,R0,R1; //Setting CV flags
ZERO:
	ANDS R6,R4,#2; //Masking for ZC flags
	B.NE ZEROC;
	MOV32 R0,#0;
	MOV32 R1,#0;
	ADDS R6,R0,R1; //Setting Z flag
	B FINALDONE;
ZEROC:
	ANDS R6,R4,#1; //Masking for ZCV flags
	B.NE ZEROCV;
	MOV32 R0,#1;
	MOV32 R1,#0xFFFFFFFF;
	ADDS R6,R0,R1; //Setting ZC flags
	B FINALDONE;
ZEROCV:
	MOV32 R0,#0x80000000;
	MOV32 R1,#0x80000000;
	ADDS R6,R0,R1; //Setting ACV flags
	B FINALDONE;
NEG: 
	ANDS R6,R4,#2;//Masking for NC flags
	B.NE NEGC;
	ANDS R6,R4,#1; //Masking for NV flags
	B.NE NEGV;
	MOV32 R0,#0xFFFFFFFE;
	MOV32 R1,#1;
	ADDS R6,R0,R1; //Setting N flag
	B FINALDONE;
NEGV:
	MOV32 R0,#1;
	MOV32 R1,#0x7FFFFFFF;
	ADDS R6,R0,R1; //Setting NV flags
	B FINALDONE;
NEGC:
	MOV32 R0,#0xFFFFFFFF;
	MOV32 R1,#1;
	ADDS R6,R0,R1; //Setting NC flags
	B FINALDONE;
FINALDONE:
	ADD R2, R2, #0;
	HALT;
