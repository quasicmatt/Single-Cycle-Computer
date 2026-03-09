    ORG     #0x400;
    FCB     #0x39; Your input to encrypt (4 bytes)


    ORG #0x0
ENCRYPT:
    MOV R0, #0x400; pointer to input
    LOAD R1, R0; Value to encrypt
    MOV R2, #0x19; Hashing key
    MOV R3, #0x0; Result register

    XOR R3, R3, R1; load the value to encrypt
    XORS R3, R3, R2; // XOR the input with the key
    
    OR R4, R4, #0x30; load 30 into R4
    SUBS R5, R3, R4; Check if (input XOR hash) is less than 30
    B.LT ADD_OFFSET; if it is, branch it will add hex 20
    B CHECK_HIGH; otherwise it will check if the XOR result is greater than 


ADD_OFFSET:
    ADDS R3, R3, #0x20; offset result by hex 20
    ORS R7, R7, #1; Mark that we added

CHECK_HIGH:
    SET R4; AND identity property
    AND R4, R4, #0x7E; move Defined max hash output
    SUBS R5, R3, R4; compare the (input XOR Hash) or the (input XOR HASH) + 0x30 is greater than 0x7E
    B.GT SUB_OFFSET; Branch to subtract 0x1F if result is greater than 0x7E
    B SAVE_RESULT; Otherwise save the result to memory

SUB_OFFSET:
    SUB R3, R3, #0x1F; subtract offset
    MOV R7, #2; Note that we subtracted

SAVE_RESULT:
    STOR R3, R0, #0x4; Store result



DECRYPT:
    MOV R8, #0x1
    SUBS R5, R7, R8; case if prior encrypt added

    B.EQ UNDO_ADD

    MOV R8, #2; case if prior encrypt subtracted
    SUBS R5, R7, R8
    B.EQ UNDO_SUB
    B UNDO_XOR; case if encrypt didn't add or subtract

UNDO_ADD:
    SUBS R3, R3, #0x20
    B UNDO_XOR
    
UNDO_SUB:
    ADD R3, R3, #0x1F

UNDO_XOR:
    XOR R3, R3, R2;

FINAL_STORE:
    STOR R3, R0, #0x8 ; R3 should be the original value

    HALT