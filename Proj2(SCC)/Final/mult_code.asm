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
	B.EQ DONE;
NEGATIVEOUT:
	NOT R2, R2; //2's complement
	ADD R2, R2, #1;
DONE:
	SAVF R4; //Set OG flags
	ADD R2, R2, #0;
	HALT;
