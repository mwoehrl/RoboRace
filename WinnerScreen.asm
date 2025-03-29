Init_Winner_Screen:
    LD A, (TitleMode)
    AND A
    RET NZ
    CALL Reset_PseudoChars
    LD HL, HALT_Animation_ret
    LD A, 1
    LD (TitleMode), A
    LD (HALT_Callback+1), HL
    LD HL, OutroSong
    CALL Switch_music
    CALL SortPlayersByScore
    CALL ShowBlankBanner
    CALL InitWinnerMap
    CALL PaintWinnerMap
    LD HL, Player1State
    LD (HL), 132
    INC HL
    LD (HL), 192
    INC HL
    LD (HL), 0
    LD A, 15
    LD (Player1State+6), A
    LD HL, Player2State
    LD (HL), 132 + 48
    INC HL
    LD (HL), 192 + 24
    INC HL
    LD (HL), 0
    LD (Player2State+6), A
    LD HL, Player3State
    LD (HL), 132 - 72
    INC HL
    LD (HL), 192 + 48
    INC HL
    LD (HL), 0
    LD (Player3State+6), A

    LD B, 92
Init_Winner_Screen_loop1:
    PUSH BC
    LD HL, Player1State + 1
    DEC (HL)
    LD BC, Player2State-Player1State
    ADD HL, BC
    DEC (HL)
    ADD HL, BC
    DEC (HL)
    CALL Put_All_Robots
    CALL HALT_Animation
    POP BC
    DJNZ Init_Winner_Screen_loop1

    LD HL, TrophySprite             ;Copy trophy pattern for static display
    LD DE, $1800 + 32 * 13
    LD B, 8
    CALL COPY_RAM_TO_VRAM_unrolled

    LD DE, $3800 + 7 + 0*32
    LD IX, Player1State
    LD IYL, 11
    CALL PaintPlayerScore
    LD IX, Player2State
    LD IYL, 15
    CALL PaintPlayerScore    
    LD IX, Player3State
    LD IYL, 9
    CALL PaintPlayerScore    

    LD BC, 1024
Init_Winner_Screen_loop2:
    PUSH BC
    CALL HALT_Animation
    CALL GET_JOYSTICK_TRIGGER_ANY
    POP BC
    JR Z, Winner_Screen_END
    DEC BC
    LD A, B
    OR C
    JR NZ, Init_Winner_Screen_loop2
    JP ShowEndCredits

Winner_Screen_END:
    CALL Reset_PseudoChars
    JP TitleStart

;IX=Player
PaintPlayerScore
    PUSH DE
    LD HL, TrophySprite
    CALL AnimateBonusSprite
    POP DE
    PUSH DE

    LD HL, -$3800
    ADD HL, DE
    LD A, %00011111
    AND E           ;A=Xpos of portrait in chars
    RLA
    RLA
    RLA             ;A=XPos in pixels
    SUB 26
    LD B, A         ;B= XPos of sprite
    LD A, E
    AND %11100000
    RRA
    RRA
    ADD A, 2            
    LD C, A         ;A=YPos in pixels
    PUSH BC
    LD A, (IX+5)
    ADD A, 16
    LD D, A
    LD E, 13
    LD A, IYL
    LD L, A
    PUSH DE
    CALL PUT_SPRITE
    POP DE
    LD HL, $101
    ADD HL, DE
    EX DE, HL
    POP BC
    LD L, 1
    CALL PUT_SPRITE
    POP DE
    CALL PaintPlayerPortrait
    CALL HALT_Animation
    INC DE
    INC DE
    INC DE
    LD A, (IX+22)       ;Flags
    AND A
    JR Z, Skip_Score_Flags
    LD B, A
    LD L, 60
    CALL VDPADDR
    LD A, L
 L2_Inc_loop_slow:
    OUT(VDP_PORT_WRITE), A
    INC A
    PUSH AF
    CALL HALT_Animation
    POP AF
    DJNZ L2_Inc_loop_slow
Skip_Score_Flags:
    CALL HALT_Animation
    LD A, %11100000
    AND E
    OR 14
    LD E, A         ;DE Now points to next Tab Column

    LD A, (IX+25)       ;Lives
    AND A
    JR Z, Skip_Score_Lives
    LD B, A
    LD L, 8
    CALL COPY_L_TO_VRAM_slow
Skip_Score_Lives:
    CALL HALT_Animation
    LD A, %11100000
    AND E
    OR 18
    LD E, A         ;DE Now points to next Tab Column
    LD A, 9
    SUB (IX+14)       ;Hitpoints
    JR Z, Skip_Score_Hitpoints
    LD B, A
    LD L, 253
    CALL COPY_L_TO_VRAM_slow
Skip_Score_Hitpoints:
    CALL HALT_Animation

    LD A, %11100000
    AND E
    OR 7
    LD E, A         ;DE Now points to first Tab Column

    LD HL, 32
    ADD HL, DE      ;2 Rows down for next Player
    EX DE, HL
    RET

PaintWinnerMap:
    LD HL, PlayfieldBuffer + 10*78 + 25
    LD (HL), 12
    LD HL, PlayfieldBuffer + 13*78 + 10
    LD (HL), 254
    LD HL, PlayfieldBuffer + 2 + 2*78
    LD DE, $3800 + 32*8
    LD B, 16
 paint_WinnerMap_loop:   
    PUSH BC
    LD B, 4
    PUSH HL
    CALL COPY_RAM_TO_VRAM_unrolled
    LD HL, 32
    ADD HL, DE
    EX DE, HL
    POP HL
    LD BC, 78
    ADD HL, BC
    POP BC
    DJNZ paint_WinnerMap_loop
    RET
    
SortPlayersByScore:
    LD IX, Player1State
    LD IY, Player2State
    CALL ComparePlayers
    CALL C, SwitchPlayers
    LD IY, Player3State
    CALL ComparePlayers
    CALL C, SwitchPlayers
    LD IX, Player2State
    CALL ComparePlayers
    CALL C, SwitchPlayers
    RET

;IX=PlayerA
;IY=PlayerB
SwitchPlayers:
    LD HL, ShadowPlayerBuffer
    LD D, IXH
    LD E, IXL
    EX DE, HL
    LD BC, Player2State-Player1State
    LDIR    ;Copy PlayerA to buffer
    LD D, IYH
    LD E, IYL
    EX DE, HL
    LD D, IXH
    LD E, IXL
    LD BC, Player2State-Player1State
    LDIR    ;Copy PlayerB to PlayerA
    LD HL, ShadowPlayerBuffer
    LD D, IYH
    LD E, IYL
    LD BC, Player2State-Player1State
    LDIR    ;Copy Buffer to PlayerB
    RET

;IX=PlayerA
;IY=PlayerB
;IF Carry Returned, means A < B, so we must switch
ComparePlayers:
    LD B, 0
    LD C, B
    LD A, (IX+25)
    CP 1
    RL B        ;B=0 Alive, B=1 Dead
    LD A, (IY+25)
    CP 1
    RL C
    LD A, C
    CP B
    RET NZ      ;If A != B we have Carry!
    LD A, (IX+22)       ;Player A Flags 
    CP (IY+22)
    RET NZ
    LD A, (IX+25)   ;Lives
    CP (IY+25)
    RET NZ
    LD A, (IX+14)
    CP (IY+14)
    RET

ShowBlankBanner:
    LD B, 6
    LD DE, $3800
 showBlankBanner_loop:
    PUSH BC
    LD L, 25
    LD B, 6        
    CALL COPY_L_TO_VRAM_fast
    LD L, 95
    LD B, 1         
    CALL L2L1f
    LD L, 1
    LD B, 19        
    CALL L2L1f
    LD L, 252
    LD B, 1        
    CALL L2L1f
    LD L, 25
    LD B, 5        
    CALL L2L1f
    LD HL, 32
    ADD HL, DE
    EX DE, HL
    POP BC
    DJNZ showBlankBanner_loop
    LD L, 25
    LD B, 6        
    CALL COPY_L_TO_VRAM_fast
    LD L, 249
    LD B, 1         
    CALL L2L1f
    LD L, 250
    LD B, 19         
    CALL L2L1f
    LD L, 251
    LD B, 1         
    CALL L2L1f
    LD L, 25
    LD B, 37
    JP L2L1f

COPY_L_TO_VRAM_slow:
        CALL VDPADDR    ;VRAM address is now pointing to DE
L2L1s:
        LD A, L         ;Time waster
        OUT (VDP_PORT_WRITE), A
        CALL HALT_Animation
        DJNZ L2L1s
        RET
