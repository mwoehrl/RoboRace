EndCreditsText:
defb "       ROBO RACE", 0
defb "    Copyright 2]2\\", 0
defb "Contribution to MSXdev2\\", 0
defb 0		   
defb "      Programming", 0
defb "        Graphics", 0
defb "     and SoundFX by", 0
defb "    Maximilian W[hrl", 0
defb 0		   
defb "   Music composed by", 0
defb "   Francois Couperin", 0
defb " Johann Sebastian Bach", 0
defb "     Darius Milhaud", 0
defb 0		   
defb "     Playtesting by", 0
defb "    the Kellerparty", 0
defb 0		   
defb 0		   
defb "Vielleicht spielt Sophie", 0
defb " das irgendwann einmal", 0
defb 0		   

CreditLinesCount EQU 21

CreditsCharColors:
	defb 0E1h, 051h, 051h, 051h, 041h, 041h, 041h, 041h
	defb 0E1h, 051h, 051h, 051h, 041h, 041h, 041h, 041h
	defb 0E1h, 051h, 051h, 051h, 041h, 041h, 041h, 041h


;BLUE:
;	defb 051h, 051h, 051h, 051h, 041h, 041h, 041h, 041h
;GOLD:
;	defb 0F1h, 0B1h, 0B1h, 0B1h, 0A1h, 0A1h, 0A1h, 0E1h


EndCreditsBuffer EQU PlayfieldBuffer

FillEndCreditsBuffer:
    LD HL, EndCreditsBuffer
    LD BC, 32*(CreditLinesCount+1)*8      ;number of bytes
clearEndCreditsBuffer_loop:
    LD (HL), 0
    INC HL
    DEC BC
    LD A, B
    OR C
    JR NZ, clearEndCreditsBuffer_loop
    LD HL, EndCreditsText
    LD DE, EndCreditsBuffer + 256
    LD IYH, CreditLinesCount      ;Number of lines
CreditsLine_loop:
    LD A, (HL)
    AND A
    JR Z, Newline_Credits
    PUSH HL
    SUB 33      ;Map ASCII char to MenuChar
    CALL C, space_char
    LD B, 0
    RLA
    RLA
    RL B
    RLA
    RL B
    LD C, A     ;BC=MenuChar*8
    LD HL, MenuCharPatterns
    ADD HL, BC  ;HL points to char pattern of current letter
    LD BC, 8
    LDIR        ;Copy pattern to buffer
    POP HL
    INC HL
    JR CreditsLine_loop
space_char:
    XOR A
    RET

Newline_Credits:
    LD E, 0
    INC D
    INC HL      ;Skip 0
    DEC IYH
    RET Z
    JR CreditsLine_loop

PaintEndCreditsFromBuffer_prep:
    CALL PaintCreditColors
    LD L, 0       ;Empty pattern
    LD DE, $0800    ;Pattern Table 1&2 addr. in VRAM
    LD BC, $1000
    CALL COPY_L_TO_VRAM
    LD DE, $3900
    LD B, 0
    LD L, B
    CALL COPY_L_TO_VRAM_Inc
    JP L2_Inc_loop

;DE = Top position in VRAM
PaintEndCreditsFromBuffer_Start
    LD A, %00000111
    AND E           ;A = 0...7  
    LD B, A         ;B contains byte count of lower char part
    NEG
    ADD A, 8        ;A = 8...1    
    LD C, A         ;C contains Nr. of bytes to copy for upper char part
                    ;BC contains partition (B=0...7,  C=8...1, B+C=8)
PaintEndCreditsFromBuffer_loop:    
    PUSH BC
    PUSH DE
    LD A, B
    AND A
    JR Z, credit_char_straight

    LD A, %11111000
    AND E
    LD E, A           ;DE Points to first row of char in VRAM

    DEC H
    LD A, C
    ADD A, L
    LD L, A

    LD IYL, 24
    CALL VDPADDR
 credit_char_loop:
    PUSH BC
    CALL RAM2L1f    ;Fill upper part
    LD DE, 256-8
    ADD HL, DE
    LD B, C         ;Now lower part
    CALL RAM2L1f
    LD DE, 8-256
    ADD HL, DE
    POP BC
    DEC IYL
    JR NZ, credit_char_loop    
credit_line_done:
    LD A, %11111000
    AND L
    LD L, A

    LD BC, 64 + 256
    ADD HL, BC
    POP DE
    POP BC
    INC D           ;1 Char row down in VRAM
    LD A, $18
    CP D
    RET Z
    DEC IYH
    JR NZ, PaintEndCreditsFromBuffer_loop
    RET

credit_char_straight:
    LD B, 24
    CALL COPY_RAM_TO_VRAM_unrolled
    DEC H
    JR credit_line_done

ShowEndCredits:
    LD BC, 0A201h   ;Screen OFF
    CALL VDPWRT

    CALL silence_music
    LD HL, HALT_Animation_ret
    LD (HALT_Callback+1), HL
    CALL Hide_ALL_Sprites

    CALL FillEndCreditsBuffer
    CALL PaintEndCreditsFromBuffer_prep
    CALL ShowTitleBanner

    LD BC, 0E201h   ;Screen ON
    CALL VDPWRT

    LD DE, $1707 + 32
    LD IYH, CreditLinesCount
    LD HL, EndCreditsBuffer + 256
ShowEndCredits_loop:
    LD A, D
    CP 9
    JR NC, go_for_scrolling
    INC D
    INC H
    DEC IYH
    JP Z, TitleStart
 go_for_scrolling:   
    PUSH IY
    PUSH HL
    PUSH DE
    CALL HALT_Animation
    CALL PaintEndCreditsFromBuffer_Start
    CALL HALT_Animation
    POP DE
    PUSH DE
    CALL PaintCreditColors
    CALL HALT_Animation
    CALL GET_JOYSTICK_TRIGGER_ANY
    JP Z, TitleStart
    POP DE
    LD A, %00000111
    AND E
    JR Z, DE_one_row_up
    DEC DE
ShowEndCredits_loop_end:    
    POP HL
    POP IY
    JR ShowEndCredits_loop

infinite_loop:
    CALL HALT_Animation
    JR infinite_loop

DE_one_row_up:
    LD HL, 7-256
    ADD HL, DE
    EX DE, HL
    JR ShowEndCredits_loop_end

;DE=VRAM addr
PaintCreditColors:
    LD A, E
    AND %00000111
    NEG
    ADD A, 8
    LD C, A
    LD B, 0
    LD HL, CreditsCharColors
    ADD HL, BC

    LD DE, $2800
    CALL VDPADDR
 color_loop:   
    LD B, 2
    PUSH HL
    CALL Copy_ram_unrolled_NO_VAddr
    POP HL
    DEC E
    JR NZ, color_loop
    RET
