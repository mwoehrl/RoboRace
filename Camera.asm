ResetHotspots:
    XOR A
    LD (HotspotCount), A
    RET

;IX=Player
AddHotspot_Player:
    PUSH BC
    PUSH DE
    PUSH HL
    LD B, (IX+12)
    LD C, (IX+13)       ;CB=XY
    LD HL, HotspotCount
    LD A, (HL)
    CP 6
    JR Z, hotspotBuffer_full
    ADD A, A
    INC (HL)
    INC HL
    LD D, 0
    LD E, A
    ADD HL, DE
    LD (HL), B
    INC HL
    LD (HL), C
hotspotBuffer_full:
    POP HL
    POP DE
    POP BC
    RET

ScrollToHotspots:
    LD A, (TitleMode)
    AND A
    RET NZ
    
    LD HL, HotspotCount
    LD B, (HL)      ;B=Count
    LD A, B
    AND A
    RET Z           ;No hotspots, RET
    INC HL
    LD DE, $7F7F    ;Max values
 scroll_min_loop:
    LD A, (HL)  ;A=X
    CP D
    JR NC, $+3
    LD D, A     ;D becomes new minX
    INC HL
    LD A, (HL)
    CP E
    JR NC, $+3
    LD E, A     ;E becomes new minY
    INC HL
    DJNZ scroll_min_loop
    PUSH DE     ;Store minXY

    LD HL, HotspotCount
    LD B, (HL)      ;B=Count
    INC HL
    LD DE, $0000    ;min values
 scroll_max_loop:
    LD A, (HL)  ;A=X
    CP D
    JR C, $+3
    LD D, A     ;D becomes new minX
    INC HL
    LD A, (HL)
    CP E
    JR C, $+3
    LD E, A     ;E becomes new minY
    INC HL
    DJNZ scroll_max_loop
    POP BC  ;BC = minXY, DE = maxXY
    LD A, D
    SUB B   ;A=Width of bounding box
    CP 8    ;8 is too big
    JR NC, boundingbox_too_big
    LD A, E
    SUB C   ;A=Height of bounding box
    CP 8    ;8 is too big
    JR NC, boundingbox_too_big
    LD A, D
    SUB B   ;MaxX-MinX always positive: NC
    LD D, A
    ADD A, A
    ADD A, D    ;A=3*Width
    RRA         ;A=3*width/2
    LD D, A
    LD A, B
    ADD A, B
    ADD A, B    ;A=3*MinX
    ADD A, D    ;A=3*(Minx+width/2)
    SUB 10
    CALL M, A_negative_to_Zero
    LD D, A     ;D=TargetX
    LD A, E
    SUB C   ;MaxY-MinY always positive: NC
    LD E, A
    ADD A, A
    ADD A, E    ;A=3*Height
    RRA         ;A=3*Height/2
    LD E, A
    LD A, C
    ADD A, C
    ADD A, C    ;A=3*MinY
    ADD A, E    ;A=3*(MinY+Height/2)
    SUB 10
    CALL M, A_negative_to_Zero
    LD E, A     ;DE=TargetXY
    JR Bresenham_Map_to_Position
 boundingbox_too_big:
    LD HL, HotspotCount
    DEC (HL)
    JR ScrollToHotspots

A_negative_to_Zero:
    XOR A
    RET

;IX=Player
ScrollPlayerIntoCenter:
    LD A, (TitleMode)
    AND A
    RET NZ
    PUSH IX
    LD A, (IX+12)
    LD B, A
    ADD A, A
    ADD A, B        ;A=WorldX*3
    SUB 10
    CALL M, A_negative_to_Zero
    LD D, A
    LD A, (IX+13)
    LD B, A
    ADD A, A
    ADD A, B        ;A=WorldY*3
    SUB 10
    CALL M, A_negative_to_Zero
    LD E, A
    CALL Bresenham_Map_to_Position
    POP IX
    RET

;DE=XY of scroll Destination
Bresenham_Map_to_Position:
    LD HL, MapScroll_X
    LD A, (HL)
    SUB D
    LD D, -1   
    JP P, positive_dx
    LD D, 1   
    NEG         
positive_dx:
    LD B, A     ;B=|dx|
    INC HL
    LD A, (HL)
    SUB E   
    LD E, -1
    JP P, positive_dy
    LD E, 1
    NEG         
positive_dy:    ;A=|dy|
    LD IYH, A
    OR B        ;dx OR dy = 0?
    RET Z
    LD A, IYH
    CP B
    JR C, dx_bigger

    LD H, B     ;H=|dx|
    LD B, A     ;B=|dy|=Counter
    LD (addr_dy_const+1), A
    SRA A       ;dy/2
    LD L, A     ;L=dy/2
    LD A, (MapScroll_X)  ;C=ScrollX
    LD C, A
    LD A, (MapScroll_Y)
    ;A=Y
    ;C=X
    ;D=sX (+/-1)
    ;E=sY (+/-1)
    ;B=Counter (=|dy|)
    ;L=Fehler
    ;H=|dx|
dy_bigger_loop:
    ADD A, E    ;Step in fast direction
    PUSH AF
    LD A, L
    SUB H
    LD L, A     ;L=L-dY
    JR NC, skip_slowStepy
    LD A, C
    ADD A, D
    LD C, A     ;C is one step further
    LD A, L
  addr_dy_const:  
    ADD A, $FF    ;L=L+dx       ;FF will be overwritten
    LD L, A
    LD A, C
    LD (MapScroll_X), A
skip_slowStepy:
    POP AF
    LD (MapScroll_Y), A
    CALL UpdateMap
    DJNZ dy_bigger_loop    
    RET
dx_bigger:    ;B=|dx|=Counter
    LD C, (HL)  ;C=ScrollY
    LD H, A     ;H=|dy|
    LD A, B
    LD (addr_dx_const+1), A
    SRA A       ;dx/2
    LD L, A     ;L=dx/2
    LD A, (MapScroll_X)
    ;A=X
    ;C=Y
    ;D=sX (+/-1)
    ;E=sY (+/-1)
    ;B=Counter (=|dx|)
    ;L=Fehler
    ;H=|dy|
dx_bigger_loop:
    ADD A, D    ;Step in fast direction
    PUSH AF
    LD A, L
    SUB H
    LD L, A     ;L=L-dY
    JR NC, skip_slowStep
    LD A, C
    ADD A, E
    LD C, A     ;C is one step further
    LD A, L
  addr_dx_const:  
    ADD A, $FF    ;L=L+dx       ;FF will be overwritten
    LD L, A
    LD A, C
    LD (MapScroll_Y), A
skip_slowStep:
    POP AF
    LD (MapScroll_X), A
    CALL UpdateMap
    DJNZ dx_bigger_loop    
    RET

UpdateMap:
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    CALL PaintMap_from_buffer
    CALL HALT_Animation
    POP HL
    POP DE
    POP BC
    POP AF
    PUSH AF
    LD A, (addr_dx_const+1)
    SUB B
    CP 8
    CALL C, HALT_Animation
    LD A, B
    CP 8
    CALL C, HALT_Animation
    POP AF
    RET    

;IYL=FlagNr. (0...3)
AI_FindFlag_DistanceBuffer:
    LD HL, AI_Flag_Found
    JR find_flag_start
ScrollToFlag:
    LD HL, Flag_Found
 find_flag_start:
    LD (reconfigure_Flag_found+1), HL
    LD DE, WorldMapBuffer + 26
    LD HL, 26 * WorldMapBufferHeight      ;HL as 16-bit counter
    LD B, $80
    LD A, IYL
    RRA
    RR B
    RRA
    RR B        ;B= Flag flag + FlagNr
 findFlag_loop:
    CALL CheckTileFlag          ;Z flag reset when Flag-flag is set
    LD A, C
    CP B                        ;Compare if flags fit exactly
    JR NZ, findFlag_next 
 reconfigure_Flag_found:   
    JP Flag_Found
 findFlag_next:
    INC DE
    DEC HL
    LD A, H
    OR L
    JR NZ, findFlag_loop
    RET

Flag_Found:
    LD HL, -WorldMapBuffer
    ADD HL, DE      ;HL=Tile offset
    LD C, 26
    CALL div_hl_c      ;L=TilePos/26=YPos, A=Remainder=xPos

    LD IX, Player3State    ;Just somewhere
    LD (IX+12), A
    LD (IX+13), L
    LD D, 0
    LD (IX+3), D
    LD (IX+4), D
    
    LD E, IYL
    LD HL, FlagColors
    ADD HL, DE
    LD A, (HL)
    LD IYL, A
    LD HL, FlagSprite
    CALL AnimateBonusSprite
    LD (IX+12), 30
    LD (IX+1), 240
    JP SetPlayerColorByPortrait
