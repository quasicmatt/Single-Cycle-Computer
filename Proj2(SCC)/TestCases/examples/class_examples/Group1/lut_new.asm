    ; NOTE: sin values are multipled by 100 in lut.mem

    ; Writing to Memory
    ORG #0x00000540
    FCB #0x00000000
    FCB #0x00000002
    FCB #0x00000003
    FCB #0x00000005
    FCB #0x00000007
    FCB #0x00000009
    FCB #0x0000000A
    FCB #0x0000000C
    FCB #0x0000000E
    FCB #0x00000010
    FCB #0x00000011
    FCB #0x00000013
    FCB #0x00000015
    FCB #0x00000016
    FCB #0x00000018
    FCB #0x0000001A
    FCB #0x0000001C
    FCB #0x0000001D
    FCB #0x0000001F
    FCB #0x00000021
    FCB #0x00000022
    FCB #0x00000024
    FCB #0x00000025
    FCB #0x00000027
    FCB #0x00000029
    FCB #0x0000002A
    FCB #0x0000002C
    FCB #0x0000002D
    FCB #0x0000002F
    FCB #0x00000030
    FCB #0x00000032
    FCB #0x00000034
    FCB #0x00000035
    FCB #0x00000036
    FCB #0x00000038
    FCB #0x00000039
    FCB #0x0000003B
    FCB #0x0000003C
    FCB #0x0000003E
    FCB #0x0000003F
    FCB #0x00000040
    FCB #0x00000042
    FCB #0x00000043
    FCB #0x00000044
    FCB #0x00000045
    FCB #0x00000047
    FCB #0x00000048
    FCB #0x00000049
    FCB #0x0000004A
    FCB #0x0000004B
    FCB #0x0000004D
    FCB #0x0000004E
    FCB #0x0000004F
    FCB #0x00000050
    FCB #0x00000051
    FCB #0x00000052
    FCB #0x00000053
    FCB #0x00000054
    FCB #0x00000055
    FCB #0x00000056
    FCB #0x00000057
    FCB #0x00000057
    FCB #0x00000058
    FCB #0x00000059
    FCB #0x0000005A
    FCB #0x0000005B
    FCB #0x0000005B
    FCB #0x0000005C
    FCB #0x0000005D
    FCB #0x0000005D
    FCB #0x0000005E
    FCB #0x0000005F
    FCB #0x0000005F
    FCB #0x00000060
    FCB #0x00000060
    FCB #0x00000061
    FCB #0x00000061
    FCB #0x00000061
    FCB #0x00000062
    FCB #0x00000062
    FCB #0x00000062
    FCB #0x00000063
    FCB #0x00000063
    FCB #0x00000063
    FCB #0x00000063
    FCB #0x00000064
    FCB #0x00000064
    FCB #0x00000064
    FCB #0x00000064
    FCB #0x00000064
    FCB #0x00000064
    ORG #0x00000000

    
    MOV R0, #0x540            ; base address of sine table

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
