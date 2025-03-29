WorldMapBuffer EQU $0800        ;TODO: Buffer Consolidation!
PlayfieldBuffer EQU $1000       ;TODO: Buffer Consolidation!

InitTitleMap:
    CALL ClearMap
    LD DE, WorldMapBuffer + 1 + 26*6  ;Start +1 XY
    LD HL, MapPiece_Title
    CALL Put_MapPiece
    LD A, 5
    LD (MapScroll_X), A
    LD A, 3
    LD (MapScroll_Y), A

    LD BC, $0706                ;Player Positions
    LD (Player1State+19), BC
    LD BC, $0702
    LD (Player2State+19), BC
    LD BC, $060B
    LD (Player3State+19), BC

    LD BC, Player1CardRegister  ;Init Card Stacks (might have been switched due to sorting of Winner)
    LD (Player1State+15), BC
    LD BC, Player1CardStack
    LD (Player1State+17), BC
    LD BC, Player2CardRegister
    LD (Player2State+15), BC
    LD BC, Player2CardStack
    LD (Player2State+17), BC
    LD BC, Player3CardRegister
    LD (Player3State+15), BC
    LD BC, Player3CardStack
    LD (Player3State+17), BC
    LD A, 255
    LD (Player1State+25), A
    LD (Player2State+25), A
    LD (Player3State+25), A
    JP InitMapBuffer

InitWinnerMap:
    LD DE, WorldMapBuffer  
    LD HL, MapPiece_Winner
    CALL Put_MapPiece
    JP InitMapBuffer

ClearMap:
    LD IX, Player1State
    CALL InitPlayer
    LD IX, Player2State
    CALL InitPlayer
    LD IX, Player3State
    CALL InitPlayer

    LD HL, WorldMapBuffer
    LD DE, 61*256+61
    LD C, 30
    CALL initMap_clear_row
    LD A, WorldMapBufferHeight
init_rows_loop:
    LD DE, 39*256+31
    LD C, 0
    CALL initMap_clear_row
    DEC A
    JR NZ, init_rows_loop
    LD DE, 61*256+61
    LD C, 38
    JP initMap_clear_row

;DE=Destination Addr.
WritePieceFromMapDef:
    PUSH DE
    LD E, (HL)
    INC HL
    LD D, (HL)
    INC HL
    EX (SP), HL     ;HL is saved to stack, Destination is in HL
    EX DE, HL       ;DE=Destination, HL points to map Piece
    CALL Put_MapPiece
    POP HL          ;HL=next map piece entry in MapDef
    RET

PlayField_ExtendX:
    LD A, 46
    LD (MapScroll_X_max), A
    RET

PlayField_ExtendY:
    LD A, 54
    LD (MapScroll_Y_max), A
    RET

Playfield_RightBorder:
    PUSH HL
    LD HL, WorldMapBuffer + 13
    LD A, 61
    LD (HL), A
    LD DE, 26
    LD A, 31
    LD B, 12
 playfield_RightBorder_loop:
    ADD HL, DE
    LD (HL), A
    DJNZ playfield_RightBorder_loop
    POP HL
    RET

Playfield_BottomBorder:
    PUSH HL
    LD HL, WorldMapBuffer + 13*26
    LD DE, 61*256+61
    LD C, 38
    CALL initMap_clear_row
    LD A, (MapScroll_X_max)
    CP 46
    JR z, skip_blank_tile
    LD A, 61
    LD HL, WorldMapBuffer + 13 + 13*26
    LD (HL), A
 skip_blank_tile:   
    POP HL
    RET

InitPlayerStartPosition:
;HL now points to Start positions
    LD C, (HL)  ;C=XPos
    LD (IX+19), C
    INC HL
    LD B, (HL)  ;B=YPos
    LD (IX+20), B
    INC HL
;Set Bot Start Positions
    LD A, (HL)
    INC HL
    LD (IX+2), A    ;Rotation
    PUSH HL

    LD HL, PlayfieldBuffer + 79
    LD A, C
    ADD A, A
    ADD A, C
    LD E, A
    LD D, 0     ;DE=C*3
    ADD HL, DE
    PUSH HL

    LD A, B
    ;C*3 + A*234 + 27
    LD DE, 234
    CALL mult_a_de      ;HL=A*DE
    POP DE
    ADD HL, DE
    EX DE, HL
    POP HL
    RET

InitMap:
    CALL ClearMap
    LD A, 10
    LD HL, MapScroll_X_max
    LD (HL), A
    INC HL
    LD A, 18
    LD (HL), A

    LD HL, (SelectedMap)
    LD BC, 11       ;Skip map title
    ADD HL, BC      ;HL points to first map piece entry

    LD DE, WorldMapBuffer + 1 + 26
    CALL WritePieceFromMapDef
    LD DE, WorldMapBuffer + 13 + 26
    CALL WritePieceFromMapDef
    CALL Z, Playfield_RightBorder
    CALL NZ, PlayField_ExtendX
    LD DE, WorldMapBuffer + 1 + 26*13
    CALL WritePieceFromMapDef
    CALL NZ, PlayField_ExtendY
    CALL Z, Playfield_BottomBorder
    LD DE, WorldMapBuffer + 13 + 26*13
    CALL WritePieceFromMapDef
;HL now points to Flag positions
;Set Flag tiles
    LD A, (FlagCount)
    ADD A, 42
    LD IYH, A       ;IYH is highest FlagNr+1
    LD A, 42
    LD B, 4
put_flag_loop:
    LD E, (HL)
    INC HL
    LD D, (HL)
    INC HL
    CP IYH
    JR NC, dont_put_flag
    LD (DE), A
dont_put_flag:
    INC A
    DJNZ put_flag_loop
    PUSH HL
    CALL InitMapBuffer
    POP HL
    LD IX, Player1State
    CALL InitPlayerStartPosition
    LD A, 10
    LD (DE), A
    LD IX, Player2State
    CALL InitPlayerStartPosition
    LD A, 12
    LD (DE), A
    LD IX, Player3State
    CALL InitPlayerStartPosition
    LD A, 254
    LD (DE), A
    RET

InitMapBuffer:
    LD HL, WorldMapBuffer
    LD DE, PlayfieldBuffer
    LD IYH, 26
copy_tiles_loop:
    LD BC, 26*9     ;Byte count for 26 tiles
copy_tile_row_loop:
    LD A, (HL)          ;A= Tile Index
    PUSH HL
    PUSH DE
    LD D, 0
    LD H, D
    LD L, A
    SLA A       ;A=126 max
    RLA         ;A=252 max
    RLA
    RL D
    LD E, A     ;DE=A*8
    ADD HL, DE  ;HL = A*9
    LD DE, TileLibrary
    ADD HL, DE  ;HL Points to Tile
    POP DE      ;DE points to current destination in scroll buffer
    LDI         ;3 Bytes from Tile
    LDI
    LDI
    PUSH HL
    LD HL, 26 * 3 - 3
    ADD HL, DE
    EX DE, HL   ;Destination pointer +1 row
    POP HL
    LDI         ;3 Bytes from Tile
    LDI
    LDI
    PUSH HL
    LD HL, 26 * 3 - 3
    ADD HL, DE
    EX DE, HL   ;Destination pointer +1 row
    POP HL
    LDI         ;3 Bytes from Tile
    LDI
    LDI
    LD HL, -(2 * 26 * 3)
    ADD HL, DE
    EX DE, HL   ;Destination pointer -2 rows
    POP HL      ;Points into World Map
    INC HL      ;Next tile in world map
    LD A, B
    OR C
    JR NZ, copy_tile_row_loop
    PUSH HL
    LD HL, 2*26*3
    ADD HL, DE
    EX DE, HL
    POP HL
    DEC IYH
    JR NZ, copy_tiles_loop
    RET

;D=first tile
;C=middle tile
;E=last tile
initMap_clear_row:
    LD (HL), D
    INC HL
    LD B, 24
 initMap_clear_loop:
    LD (HL), C
    INC HL
    DJNZ initMap_clear_loop
    LD (HL), E
    INC HL
    RET

Reset_PseudoChars:
    XOR A                   ;Reset memorized pseudochar to prevent restoring
    LD (Player1State+8), A
    LD (Player2State+8), A
    LD (Player3State+8), A
    RET

PaintMap_from_buffer:
    CALL Reset_PseudoChars
    
    LD A, (TitleMode)
    AND A
    JP NZ, PaintTitleMap

    ;First, check if scroll position is within bounds
    LD HL, MapScroll_X
    XOR A
    CP (HL)
    JP P, scroll_x_too_small
    JR C, scroll_x_not_too_small
scroll_x_too_small:
    LD (HL), A
 scroll_x_not_too_small:
    LD A, (MapScroll_X_max)
    CP (HL)
    JR NC, scroll_x_not_too_big
    LD (HL), A
 scroll_x_not_too_big:
    INC HL
    XOR A
    CP (HL)
    JP P, scroll_y_too_small
    JR C, scroll_y_not_too_small
 scroll_y_too_small:
    LD (HL), A
 scroll_y_not_too_small:
    LD A, (MapScroll_Y_max)
    CP (HL)
    JR NC, scroll_y_not_too_big
    LD (HL), A
 scroll_y_not_too_big:
    ;HL still points to ScrollY
    LD A, (HL)
    LD DE, 26*3
    CALL mult_a_de      ;HL=y*26*3

    LD A, (MapScroll_X)
    LD E, A
    LD D, 0
    ADD HL, DE          ;HL=x+y*26*3
    LD DE, PlayfieldBuffer
    ADD HL, DE          ;HL points to top left corner in buffer

    LD DE, $3800
    LD B, 24            ;Nr. of Rows
 copy_buffer_loop:
    PUSH BC
 playfield_reprogram1:   
    LD B, 3         ;Reprogrammable (3 for 24 cols, 4 fullscreen)
    CALL COPY_RAM_TO_VRAM_unrolled
    PUSH DE
 playfield_reprogram2:   
    LD DE, 26*3 - 24        ;Reprogrammable (24 vs 32)
    ADD HL, DE
    POP DE
    PUSH HL
    LD HL, 32
    ADD HL, DE
    EX DE, HL
    POP HL
    POP BC
    DJNZ copy_buffer_loop
    CALL World_to_Screen_Coordinates_ALL
    JP Put_All_Robots

;DE = Destination on World Map
;HL = Points to MapPiece
Put_MapPiece:
    XOR A
    OR H
    RET Z       ;If HL is 0 then don't put piece
    LD B, 12
 put_map_piece_loop:
    PUSH BC
    LD BC, 12
    LDIR
    PUSH HL
    LD HL, 26-12
    ADD HL, DE
    EX DE, HL
    POP HL
    POP BC
    DJNZ put_map_piece_loop
    RET

Animate_ExpressConveyor_Left:
    LD HL, CharPatterns + 8 * 131
    LD DE, 8 * 131
    JR animate_shift_left
Animate_Conveyor_Left:
    LD HL, CharPatterns + 8 * 128
    LD DE, 8 * 128
animate_shift_left:   
    PUSH DE
    LD B, 8
animate_shift_left_loop:
    LD C, (HL) 
    LD DE, 8
    ADD HL, DE  ;Inc HL by 8
    LD D, (HL)
    PUSH DE
    LD DE, 8
    ADD HL, DE
    POP DE
    LD A, (HL)
    RLA
    RL D
    RL C
    JR NC, no_carry_left
    LD E, %00000001
    OR E
    JR shift_left_complete
no_carry_left:
    LD E, %11111110
    AND E
shift_left_complete:
    CALL shiftSideways_copy_back
    DJNZ animate_shift_left_loop
    JP shiftSideways_copy_to_VRAM

Animate_ExpressConveyor_Right:
    LD HL, CharPatterns + 8 * 137
    LD DE, 8 * 137
    JR animate_shift_right
Animate_Conveyor_Right:
    LD HL, CharPatterns + 8 * 134
    LD DE, 8 * 134
animate_shift_right:   
    PUSH DE
    LD B, 8
animate_shift_right_loop:
    LD A, (HL) 
    LD DE, 8
    ADD HL, DE  ;Inc HL by 8
    LD D, (HL)
    PUSH DE
    LD DE, 8
    ADD HL, DE
    POP DE
    LD C, (HL)
    RRA
    RR D
    RR C
    JR NC, no_carry_right
    LD E, %10000000
    OR E
    JR shift_right_complete
no_carry_right:
    LD E, %01111111
    AND E
shift_right_complete:
    LD E, A
    LD A, C
    LD C, E
    CALL shiftSideways_copy_back
    DJNZ animate_shift_right_loop
shiftSideways_copy_to_VRAM:
    ADD HL, DE
shiftAny_copy_to_VRAM:
    POP DE
    PUSH HL
    LD A, (TitleMode)
    AND A
    JR NZ, third_section_only
    LD B, 3
    CALL COPY_RAM_TO_VRAM_unrolled
    POP HL
    PUSH HL
    LD D, $C
    LD B, 3
    CALL COPY_RAM_TO_VRAM_unrolled
third_section_only:    
    POP HL
    LD D, $14
    LD B, 3
    JP COPY_RAM_TO_VRAM_unrolled
shiftSideways_copy_back:
    LD (HL), A
    PUSH DE
    LD DE, -8
    ADD HL, DE
    POP DE
    LD (HL), D
    LD DE, -8
    ADD HL, DE
    LD (HL), C
    INC HL
    RET

Animate_ExpressConveyor_Down:
    LD HL, CharPatterns + 8 * 149 + 22
    LD DE, 8 * 149
    JR animate_shift_down
Animate_Conveyor_Down:
    LD HL, CharPatterns + 8 * 146 + 22
    LD DE, 8 * 146
animate_shift_down:   
    PUSH DE
    LD D, H
    LD E, L
    INC DE
    LD A, (DE)
    LD BC, 23
    LDDR
    INC HL
    LD (HL), A
    JP shiftAny_copy_to_VRAM

Animate_ExpressConveyor_Up:
    LD HL, CharPatterns + 8 * 143
    LD DE, 8 * 143
    JR animate_shift_Up
Animate_Conveyor_Up:
    LD HL, CharPatterns + 8 * 140
    LD DE, 8 * 140
animate_shift_Up:   
    PUSH DE
    LD D, H
    LD E, L
    INC HL
    LD A, (DE)
    LD BC, 23
    LDIR
    LD (DE), A
    LD DE, -24
    ADD HL, DE
    JP shiftAny_copy_to_VRAM

AnimateConveyors:
    CALL Animate_Conveyor_Right
    CALL Animate_ExpressConveyor_Right
    CALL Animate_Conveyor_Left
    CALL Animate_ExpressConveyor_Left
    CALL Animate_Conveyor_Down
    CALL Animate_ExpressConveyor_Down
    CALL Animate_Conveyor_Up
    JP Animate_ExpressConveyor_Up

AnimateExpressConveyors:
    CALL Animate_ExpressConveyor_Right
    CALL Animate_ExpressConveyor_Left
    CALL Animate_ExpressConveyor_Down
    JP Animate_ExpressConveyor_Up

World_to_Screen_Coordinates_ALL:
    LD IX, Player1State
    CALL World_to_Screen_Coordinates
    LD IX, Player2State
    CALL World_to_Screen_Coordinates
    LD IX, Player3State
;IX=Player
World_to_Screen_Coordinates:
    LD A, (MapScroll_X)
    LD B, A
    LD A, (IX+12)   ;World Pos X
    CALL a_minusScroll_mult_24
    LD (IX+0), A
    CP 240
    JR NZ, screen_Coordinate_y
    LD (IX+1), 240
    RET
 screen_Coordinate_y:
    LD A, (MapScroll_Y)
    LD B, A
    LD A, (IX+13)   ;World Pos Y
    CALL a_minusScroll_mult_24
    LD (IX+1), A
    RET    

;A=Robot Pos
;B=Scroll
 a_minusScroll_mult_24
    LD C, A
    ADD A, A
    ADD A, C        ;A is multiplied by 3 (World Coordinates is in Tiles, Scroll in Chars)
    SUB B        ;A=WorldPosX-ScrollX
    CP 29       
    JR C, validScreenCoordinate
    CP 254
    JR NC, validScreenCoordinate
    LD A, 240           ;Marks invalid value
    RET
 validScreenCoordinate:   ;A=[-2...28]
    SCF
    RLA         ;A * 2 + 1 from carry makes result +4
    SLA A
    SLA A           
    RET
