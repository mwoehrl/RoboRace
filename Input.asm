IF MSX_MODE

    Debug_Keyboard:
        LD BC, 0E201h   ;Screen ON
        CALL VDPWRT
        LD DE, $3900
        EI
    Debug_Keyboard_loop:
        IN A, (PPI_PORT_C)
        AND $F0
        OR 8        ;Key matrix row 8
        OUT (PPI_PORT_C), A
        IN A, (PPI_PORT_B)

        LD L, A
        LD B, 1
        CALL COPY_L_TO_VRAM_fast

        HALT
        JR Debug_Keyboard_loop

    ; Routine to read the joystick 1 status by direct access to PSG
    ;
    ; Entry: B: 0=Keyboard, 1=Stick 1, 2=Stick 2
    ; Output: A = Joystick 1 status (bits 0-5), ZF = 1 if joystick 1 not used (bits 0-5 are all set)
    ; Note: Interrupts should be disabled between selection and access to the register
    GET_JOYSTICK_TRIGGER:
        LD A, B
        AND A
        JR Z, msx_read_keyboard_TRIGGER
        LD C, $10
        JR msx_read_joystick
    GET_JOYSTICK_INPUT:
        LD A, B
        AND A
        JR Z, msx_read_keyboard_INPUT
        LD C, $0F
     msx_read_joystick:
        PUSH DE
        DEC B
        LD DE, $0F8F    ;Select stick 1
        JR Z, msx_joystick_selected
        LD DE, $4FCF    ;Select stick 2
     msx_joystick_selected:
        ld	a,15
        out	(PSG_PORT_SELECT),a	; Set register 15 as accessible
        in	a,(PSG_PORT_READ)	; Read register #15
        or	D		; 0X0XX1111b (Set bits 0-3, keep current bits 4-7)
        and	E		; %X0001111 (Keep current bits 7, reset bits 4-6)
        out	(PSG_PORT_WRITE),a	; Write to register #15 Setect joystick 1/2 to read

        ld	a,14
        out	(PSG_PORT_SELECT),a	; Set register 14 as accessible
        in	a,(PSG_PORT_READ)	; Read register #14
        and	C		; Mask 4Way or trigger
        POP DE
        ret 

msx_read_keyboard_TRIGGER:
        IN A, (PPI_PORT_C)
        AND $F0
        OR 8        ;Key matrix row 8
        OUT (PPI_PORT_C), A
        IN A, (PPI_PORT_B)
        AND 1
        RET

msx_read_keyboard_INPUT:
        IN A, (PPI_PORT_C)
        AND $F0
        OR 8        ;Key matrix row 8
        OUT (PPI_PORT_C), A
        IN A, (PPI_PORT_B)
        LD C, B        ;B is always 0 when we want Keyboard
        RLA     ;Carry is Right arrow
        RL B    ;Carry rotated into b
        RLA     ;Carry is Down
        RL C    ;Save Down in C bit1
        RLA     ;Carry is UP
        RL C    ;Save UP in C bit0, C is now 000000DU       
        RLA     ;Carry is Left
        RL B    ;B is now 000000RL
        LD A, B
        RLA
        RLA     ;A is now 0000RL00
        OR C    ;A is now 0000RLDU
        RET

ELSE

    ;B=0 for keyboard; 1 for stick1, 2 for stick2
    ;Returns 4 least significant bites in A (Right Left Down Up)
    GET_JOYSTICK_INPUT:
        LD A, B
        AND A
        JR Z, GET_JOYSTICK_INPUT_keyboard
        CP 1
        JR Z, GET_JOYSTICK_INPUT_stick
        LD B, 5     ;stick2
    GET_JOYSTICK_INPUT_stick:
        LD A, 14       ;PSG Register 14 contains Joystick Positions
        OUT (PSG_PORT_SELECT), A
        IN A,(PSG_PORT_READ)
        DEC B   ;to test B for 0
        RET Z
    joy_shift_loop:     ;stick2 has upper 4 bits, so shift them 4 times
        RRA
        DJNZ joy_shift_loop
        RET
    GET_JOYSTICK_INPUT_keyboard:
        LD D, 15     ;result
        LD A, $15
        OUT (PPI_PORT_C), A
        IN A, (PPI_PORT_B)
        AND 128
        JR Z, KEY_UP_Pressed 
        LD A, $17
        OUT (PPI_PORT_C), A
        IN A, (PPI_PORT_B)
        AND 128
        JR Z, KEY_DOWN_Pressed 
CHECK_KEY_SIDEWAYS:
        LD A, $16
        OUT (PPI_PORT_C), A
        IN A, (PPI_PORT_B)
        AND 128
        JR Z, KEY_LEFT_Pressed 
        LD A, $18
        OUT (PPI_PORT_C), A
        IN A, (PPI_PORT_B)
        AND 128
        JR Z, KEY_RIGHT_Pressed 
CHECK_KEY_DONE:
        LD A, D
        RET

KEY_UP_Pressed:
        LD A, 1
        JR $+4
KEY_DOWN_Pressed:
        LD A, 2
        XOR D
        LD D, A
        JR CHECK_KEY_SIDEWAYS

KEY_LEFT_Pressed:
        LD A, 4
        JR $+4
KEY_RIGHT_Pressed:
        LD A, 8
        XOR D
        LD D, A
        JR CHECK_KEY_DONE

    ;B=0 for keyboard, 1 for stick1, 2 for stick2
    ;Z flag is set when Button is pressed
    GET_JOYSTICK_TRIGGER:
        LD A, B
        AND A
        JR Z, GET_JOYSTICK_TRIGGER_keyboard
GET_JOYSTICK_TRIGGER_stick:
        IN A, (PPI_PORT_A)    ;PPI Port A. Bit4 contains Trigger of Joystick 1
        DEC B   ;to test B for 0
        LD C, 010h   ;Mask for trigger 1
        JR Z, joy_1_trigger
        LD C, 020h   ;Mask for trigger 2
    joy_1_trigger:
        AND C          ;Mask with trigger
        RET
GET_JOYSTICK_TRIGGER_keyboard:
        LD A, $18
        OUT (PPI_PORT_C), A
        IN A, (PPI_PORT_B)
        AND 1
        RET
ENDIF 


GET_JOYSTICK_INPUT_ANY:
    LD B, 0
    CALL GET_JOYSTICK_INPUT
    PUSH AF
    LD B, 1
    CALL GET_JOYSTICK_INPUT
    POP BC
    AND B            ;Combine Directional Values of keyboard and Stick1
    PUSH AF
    LD B, 2
    CALL GET_JOYSTICK_INPUT
    POP BC
    AND B            ;Combine Directional Values of all 3 inputs
    RET

GET_JOYSTICK_TRIGGER_ANY:
    LD B, 0
    CALL GET_JOYSTICK_TRIGGER
    RET Z
    LD B, 1
    CALL GET_JOYSTICK_TRIGGER
    RET Z
    LD B, 2
    JP GET_JOYSTICK_TRIGGER
