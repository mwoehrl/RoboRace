;Init Graphics Mode 2
INIT_GRAPHIC_MODE_2:
        LD BC, 00200h   ;Reg0 Value 00h
        CALL VDPWRT
        LD BC, 0A201h   ;Reg1 Value E2h  (16k,Display Diabled during init, EI, 16x16 Sprites, no magnifying)
        CALL VDPWRT
        LD BC, 00E02h   ;Reg2 Value 0Eh  (Name Table starts at 3800h)
        CALL VDPWRT
        LD BC, 0FF03h   ;Reg3 Value FFh  (Color Table starts at 2000h)
        CALL VDPWRT
        LD BC, 00304h   ;Reg4 Value 03h  (Pattern Table starts at 0kB)
        CALL VDPWRT
        LD BC, 07805h   ;Reg5 Value 6Eh  (Sprite Attributes start at 3B00h)
        CALL VDPWRT
        LD BC, 00306h   ;Reg6 Value 07h  (Sprite Patterns start at 1800h)
        CALL VDPWRT
        LD BC, 00107h   ;Reg7 Value 00h  (Background Color 1=Black)
;Writes Value B into VDP Register C
;B=Value
;C=Register Number
VDPWRT:
        LD A, B
        OUT (VDP_PORT_ADDRESS), A
        LD A, C
        OR $80
        OUT (VDP_PORT_ADDRESS), A
        RET

;Sets VDP Address Pointer to DE
VDPADDR:
        LD A, E
        OUT (VDP_PORT_ADDRESS), A
        LD A, D
        OR $40
        OUT (VDP_PORT_ADDRESS), A    ;VRAM address is now pointing to DE
        RET

;Sets VDP Address Pointer to DE for reading
VDPADDR_IN:
        LD A, E
        OUT (VDP_PORT_ADDRESS), A
        LD A, D
        OUT (VDP_PORT_ADDRESS), A    ;VRAM address is now pointing to DE
        RET

;copies RAM to Video RAM
;HL=RAM addr
;DE=VRAM addr
;BC=length
COPY_RAM_TO_VRAM:
        CALL VDPADDR    ;VRAM address is now pointing to DE
        XOR A
        CP C
        JR NZ, RAM2L1
        DEC B          ;IF C=0 decrement B
RAM2L1:
        LD A, (HL)
        OUT (VDP_PORT_WRITE), A
        INC HL
        DEC C
        JP NZ, RAM2L1
        LD A, B
        CP C    ;C is 0
        RET Z   ;Return if B=0 and C=0
        DEC B
        JR RAM2L1

;copies L to Video RAM
;L=Constant to copy
;DE=VRAM addr
;BC=length
COPY_L_TO_VRAM:
        CALL VDPADDR    ;VRAM address is now pointing to DE
        XOR A
        CP C
        JR NZ, L2L1
        DEC B          ;IF C=0 decrement B
L2L1:
        LD A, L
        OUT (VDP_PORT_WRITE), A
        DEC C
        JP NZ, L2L1
        LD A, B
        CP C    ;C is 0
        RET Z   ;Return if B=0 and C=0
        DEC B
        JR L2L1

;copies RAM to Video RAM
;HL=RAM addr
;DE=VRAM addr
;BC=target length
COPY_RAM_TO_VRAM_compressed:
        CALL VDPADDR    ;VRAM address is now pointing to DE
RAM2L1_c:
        LD A, (HL)
        AND %11110000
        LD A, (HL)
        JR Z, copy_compressed
        OUT (VDP_PORT_WRITE), A
        DEC BC
        JR copy_color_done
copy_compressed:
        ADD A, 2
        LD D, A         ;Count of following byte
        INC HL
        LD A, (HL)
 copy_compressed_loop:
        OUT (VDP_PORT_WRITE), A
        DEC BC
        DEC D
        JR NZ, copy_compressed_loop
copy_color_done:
        INC HL
        LD A, B
        OR C    ;C is 0
        RET Z   ;Return if B=0 and C=0
        JR RAM2L1_c

;copies RAM to Video RAM
;HL=RAM addr
;DE=VRAM addr
;B=length
COPY_RAM_TO_VRAM_fast:
        CALL VDPADDR    ;VRAM address is now pointing to DE
RAM2L1f:
        LD A, (HL)
        OUT (VDP_PORT_WRITE), A
        INC HL
        DJNZ RAM2L1f
        RET

;Unrolled loop for superfast copy
;HL=RAM addr
;DE=VRAM addr
;B=Count/8
COPY_RAM_TO_VRAM_unrolled:
        CALL VDPADDR    ;VRAM address is now pointing to DE
Copy_ram_unrolled_NO_VAddr:
        LD C, VDP_PORT_WRITE
 copy_ram_unrolled_loop:
        LD A, (HL)
        INC HL
        OUT (C), A
        LD A, (HL)
        INC HL
        OUT (C), A
        LD A, (HL)
        INC HL
        OUT (C), A
        LD A, (HL)
        INC HL
        OUT (C), A

        LD A, (HL)
        INC HL
        OUT (C), A
        LD A, (HL)
        INC HL
        OUT (C), A
        LD A, (HL)
        INC HL
        OUT (C), A
        LD A, (HL)
        INC HL
        OUT (C), A

        DJNZ copy_ram_unrolled_loop
        RET

;Unrolled loop for superfast copy
;HL=RAM addr
;DE=VRAM addr
;B=Count/8
COPY_VRAM_TO_RAM_unrolled:
        CALL VDPADDR_IN    ;VRAM address is now pointing to DE
        LD C, VDP_PORT_READ
 copy_vram_unrolled_loop:
        IN A, (C)
        LD (HL), A
        INC HL
        IN A, (C)
        LD (HL), A
        INC HL
        IN A, (C)
        LD (HL), A
        INC HL
        IN A, (C)
        LD (HL), A
        INC HL
        IN A, (C)
        LD (HL), A
        INC HL
        IN A, (C)
        LD (HL), A
        INC HL
        IN A, (C)
        LD (HL), A
        INC HL
        IN A, (C)
        LD (HL), A
        INC HL
        DJNZ copy_vram_unrolled_loop
        RET

;copies Byte in L to Video RAM
;L=input byte
;DE=VRAM addr
;B=length
COPY_L_TO_VRAM_fast:
        CALL VDPADDR    ;VRAM address is now pointing to DE
L2L1f:
        LD A, L         ;Time waster
        OUT (VDP_PORT_WRITE), A
        DJNZ L2L1f
        RET

;copies Byte in L to Video RAM and increments
;L=input byte start
;DE=VRAM addr
;B=length
COPY_L_TO_VRAM_Inc:
    CALL VDPADDR
    LD A, L
 L2_Inc_loop:
    OUT(VDP_PORT_WRITE), A
    INC A
    DJNZ L2_Inc_loop
    RET

;DE=VRAM addr
;HL points to String
WRITE_String:
    CALL VDPADDR
wrt_string_loop:
    LD A, (HL)
    AND A
    RET Z
    SUB 33
    OUT(VDP_PORT_WRITE), A
    INC HL
    JR wrt_string_loop

;D=Sprite Layer (0...31)
;E=Pattern
;BC=X,Y
;L=Color
PUT_SPRITE:
        LD A, D
        LD H, E 
        LD DE ,$3C00           ;E=0 for later use
        SLA A
        SLA A
        OUT (VDP_PORT_ADDRESS),A     ;LSB of address
        LD A,D
        OR 040h
        OUT (VDP_PORT_ADDRESS),A    ;VRAM address is now pointing to DE + A
        LD A,C
        LD C,VDP_PORT_WRITE
        DEC A             ;Align Y
        OUT (C), A        ;Y
        LD A, B
        CP 240
        JR C, non_negative_X
        ADD A, 32
        LD E, %10000000
 non_negative_X:        
        OUT (C), A      ;X
        SLA H           ;H is now multiplied by 4 (because we use 16x16pix Sprites)
        SLA H
        OUT (C), H      ;Pattern
        LD A, E         ;Set Early clock bit
        OR L
        NOP
        OUT (C), A      ;Clock + Color
        RET

Hide_ALL_Sprites:
        LD DE, $3C00    ;All sprites below bottom
        LD L, 200
        LD B, 128
        JP COPY_L_TO_VRAM_fast
