; Input Stored @ 0x0800, 0xF0F0F0F0 by default
;
; Intended Outputs:
;   0x0880 = # of ones in input
;   0x0884 = # of zeros in input
;   0x0888 = (zeros << 16) | ones
;   0x088C = input inverted
;   0x0890 = (# of ones) ^ 2
;   0x0894 = (# of zeros) ^ 2

; --- Seed input word (0xF0F0F0F0) at 0x0800 ---
    MOV   R0, #0x0800
    MOV32 R1, #0xF0F0F0F0
    STOR  R1, R0, #0

    ; --- Init counters and load value ---
    CLR   R2                  ; ones = 0
    CLR   R3                  ; zeros = 0
    LOAD  R4, R0, #0          ; R4 = value (will be shifted)
    MOV   R5, #32             ; remaining bits

; --- Bit loop ---
BIT_LOOP:
    CMP   R5, #0
    B.EQ  DONE

    ANDS   R6, R4, #1      ; current LSB in R6 (0 or 1)
    LSR   R4, R4, #1      ; consume bit
    CMP   R6, #0
    B.EQ  INC_ZERO

INC_ONE:
    ADD   R2, R2, #1      ; ones++
    B     CONTINUE

INC_ZERO:
    ADD   R3, R3, #1      ; zeros++

CONTINUE:
    SUBS  R5, R5, #1
    MOV   R13, #0x0020
    BR    R13

; --- Store results and extras ---
DONE:
    ; ones @ 0x0880
    MOV   R7, #0x0880
    STOR  R2, R7, #0

    ; zeros @ 0x0884
    ADD   R7, R7, #4
    STOR  R3, R7, #0

    ; (zeros << 16) | ones @ 0x0888
    LSL   R8, R3, #16
    OR    R8, R8, R2
    ADD   R7, R7, #4
    STOR  R8, R7, #0

    ; ~input via SET + XOR @ 0x088C
    LOAD  R4, R0, #0
    SET   R9                ; R9 = 0xFFFFFFFF
    XOR   R10, R4, R9       ; R10 = ~input
    ADD   R7, R7, #4
    STOR  R10, R7, #0

    ; R11 = (# of ones)^2
    ; R12 = (# of zeros)^2
    ADD R7, R7, #4
    MUL R11, R2, R2
    MUL R12, R3, R3

    STOR  R11, R7, #0
    STOR  R12, R7, #4

    HALT
