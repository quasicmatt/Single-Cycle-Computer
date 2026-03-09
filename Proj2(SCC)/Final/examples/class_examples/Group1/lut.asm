    ; NOTE: sin values are multipled by 100 in lut.mem
    
    MOV R0, #0x0            ; base address of sine table

    ; Degree options for each quadrant
    ;MOV R1, #0x2D           ; 45, Q1
    MOV R1, #0x96           ;150, Q2
    ;MOV R1, #0xB5           ; 181, Q3
    ;MOV R1, #0x10F          ; 271, Q4

    MOV R9, #0x190          ; Address we store to

    SUBS R14, R1, #0x5A           ; Compare angle against 90 degrees
    B.HS check_q2           ; if angle is greater than 90, we start to check next qudrant

    ; Quadrant 1
    LSL R2, R1, #0x2        ; Offset = angle * 4 (byte offset)
    ADD R3, R0, R2          ; Temp = Address of Sine table + offset
    LOAD R4, R3             ; Grabbing result from memory
    B stop

; Quadrant 2
check_q2: ; 
    SUBS R14, R1, #0xB4
    B.HS check_q3           ; If angle is greater than 180, check next quadrant
    MOV R3, #0xB4       
    SUB R3, R3, R1          ; Temp = 180 - angle
    LSL R2, R3, #0x2        ; Offset = angle * 4 (byte offset)
    ADD R3, R0, R2  
    LOAD R4, R3
    B stop

; Quardrant 3
check_q3:
    SUBS R14, R1, #0x10E
    B.HS check_q4           ; If angle is greater than 270, check last quadrant
    MOV R3, #0xB4
    SUB R3, R1, R3          ; Temp = angle - 180
    LSL R2, R3, #0x2        ; Offset = angle * 4 (byte offset)
    ADD R3, R0, R2
    LOAD R4, R3
    MUL R4, R4, #0xFFFF ; Negative quadrant
    B stop

; Quadrant 4
check_q4:
    MOV R3, #0x168
    SUB R3, R3, R1          ; Temp = 360 - angle
    LSL R2, R3, #0x2
    ADD R3, R0, R2 
    LOAD R4, R3
    MUL R4, R4, #0xFFFF ; Negative quadrant
    

stop:
    STOR R4, R9
    HALT