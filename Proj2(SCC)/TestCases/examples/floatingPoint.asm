mov r0
mov r1
mov32 r8,0x7FFFFFFF; //for checking if either value is zero

FirstSign:
	ors r2,r0,#1
	mov r2,#0
	b.pl FirstEXP
	mov r2,#1
FirstEXP:
	lsl r3,r0,#1
	lsr r3,r3,#1
	xor r9,r3,r8; 
	xors r14,r3,r9; //checking if num is zero using some ops no one had used yet
	b.eq FirstNumZero;
	lsr r3,r3,#23
	xors r14,r3,#0xFF
	b.eq FirstExpInf
FirstMan	
	mov32 r4,0x7FFFFF
	and r4,r4,r0
SecondSign;
	r5
	r6
	r7




FirstNumZero:			//math for first num being zero
FirstExpInf:			
	mov32 r4,#0x7FFFFF; //math for first exp being infinite
	ands r4,r4,r0
	mov r10,#1
	b.eq SecondSign;
	mov32 r13,#0x7FC00000; //in was nan out is nan
	halt;