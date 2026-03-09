; ===============================================================
; LOGIC_CHECKSUM.ASM — Simple bit-logic checksum
; Combines each word using XOR + shifts for variety
; ===============================================================

        ORG     #0x00000D500
Data_Block:
        FCB     #0xDEADBEEF ; d500
        FCB     #0x12345678 ; d504
        FCB     #0x90ABCDEF ; d508
        FCB     #0x00000000 ; d50c
        FCB     #0x87654321 ; d510
        FCB     #0x0F0F0F0F ; d514
        ORG     #0x00000000 ; d518

; -------- 1) SETUP --------
Start:  
        MOV32   R3, #0x00000D500     ; pointer to data
        MOV     R0,  #6              ; word count
        SET R1                        ; Initial check sum value. R1 will also contain the running checksum
        MOV     R7,  #0               ; zero constant
        MOV     R8, #0x1c             ; R8 = &Loop
        BR R8                         ; Abs branch to loop, just to test. 

; -------- 2) MAIN LOOP --------
Loop:
        LOAD    R2, R3, #0x0          ; read 32-bit word into R2
        XOR    R1, R1, R2            ; mix current word (XOR)
        LSR     R4, R2, #3            ; right-shift copy
        LSL     R5, R2, #5            ; left-shift copy
        AND    R6, R4, R5            ; AND of shifted versions
        XOR    R1, R1, R6            ; fold it in
        ADD     R3, R3, #4            ; advance pointer
        SUB     R0, R0, #1            ; decrement counter
        CMP     R0, R7

; -------- 3) This just tests MOVF and SAVF but should always just branch to Loop unless the CRC is finally done. --------
FlagTestAndBranchToLoop:
        MOVF    R8                    ; save current flags from CMP
        MOV R9, #1                    ; R9 = #1
        SUBS  R9, R9, #1              ; force the flags to change to Z=1 thru SUBS
        SAVF R8                       ; if this does not succeed, the flag would still be Z=1 and first 5 BNEs would not trigger, failing CRC 
        B.NE    Loop

; -------- 4) STORE Final Checksum --------
        MOV32   R5, #0x0000D51c      ; final check sum location
        STOR   R1, R5, #0x0000

; -------- 5) Undo checksum: restore R1 to initial 0xFFFFFFFF where final checksum is stored at 0xd51c
UndoStart:
        ; R1 <- final checksum
        MOV32   R5, #0x0000D51C
        LOAD    R1, R5, #0x0

        ; ptr -> last word in Data_Block (0xD514), count = 6
        MOV32   R10, #0x00000D514
        MOV     R0,  #6
        MOV     R7,  #0              ; zero for CMP

UndoLoop:
        LOAD    R2, R10, #0x0        ; R2 = word[i]
        LSR     R4, R2, #3
        LSL     R5, R2, #5
        AND     R6, R4, R5
        XOR     R1, R1, R6           ; undo (B)
        XOR     R1, R1, R2           ; undo (A)
        SUB     R0, R0, #1
        CMP     R0, R7
        SUB     R10, R10, #4         ; move to previous word
        B.NE    UndoLoop

; R1 now == 0xFFFFFFFF (initial value). 
; -------- 6) STORE Final Checksum --------
        MOV32  R5, #0x0000D520
        STOR   R1, R5, #0x0
        HALT
