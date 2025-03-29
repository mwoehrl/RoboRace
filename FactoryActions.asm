;B=sideways direction (+/-1)
;C=Rotation (-1,0,1)
;A=AnimationFrame (0...23)
;IX points to Player
;IY points to Player (offset +1 for vertical direction)
HandleConveyorSideways:
    CP 23
    LD E, A         ;Store A for later
    JR NZ, skip_sideways_position_check
    CALL AddHotspot_Player
    LD A, (IX+10)   ;Blocked marker
    AND A           
    RET NZ          ;Cancel world Coordinate update if blocked
    LD A, B         ;movement direction
    ADD A, (IY+12)
    LD (IY+12), A   ;World Coordinate updated
    CALL AddHotspot_Player
    LD A, E         ;Restore A (=Animation Frame)
 skip_sideways_position_check:
    CP 12           ;first or second half of animation?
    JR C, skip_sideways_position_check_ok
    LD A, (IX+10)   ;Blocked marker
    AND A
    JR Z, sideways_no_block_check_frame
    ;Blocked movement, invert direction for 2nd half of animation
    LD A, C
    NEG
    LD C, A         ;Invert rotation
    LD A, B
    NEG             ;Invert direction
    JR sideways_inverted
skip_sideways_position_check_ok:
    LD A, B
sideways_inverted:
    LD B, A
    LD A, 240
    CP (IX+1)           ;If Player Y-Screen position is 240, he's offscreen, don't move!
    JP Z, sideways_skip_offscreen
    LD A, B
    ADD A, (IY+0)      ;Player x-screen position, Move back
    LD (IY+0), A
sideways_skip_offscreen:    
    LD A, C
    ADD A, (IX+2)      ;Direction of player 
    LD (IX+2), A
RETURN:
    RET
sideways_no_block_check_frame:
    LD A, E
    CP 16
    JR C, skip_sideways_position_check_ok
    LD C, 0
    JR skip_sideways_position_check_ok


;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorNorth:
    PUSH IX
    POP IY      ;IY = IX
    INC IY      ;offset to point to player's Y-Coordinates
    LD B, -1    ;Decrement Y values for north
    LD C, 0     ;No rotation
    JP HandleConveyorSideways                       ;Reprogrammed!

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorSouth:
    PUSH IX
    POP IY      ;IY = IX
    INC IY      ;offset to point to player's Y-Coordinates
    LD B, 1     ;Increment Y values for South
    LD C, 0     ;No rotation
    JP HandleConveyorSideways

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorWest:
    PUSH IX
    POP IY      ;IY = IX
    LD B, -1   ;Decrement X values for West
    LD C, 0     ;No rotation
    JP HandleConveyorSideways

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorEast:
    PUSH IX
    POP IY      ;IY = IX
    LD B, 1     ;Increment X values for East
    LD C, 0     ;No rotation
    JP HandleConveyorSideways

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorSouth_Clockwise:
    PUSH IX
    POP IY      ;IY = IX
    INC IY      ;offset to point to player's Y-Coordinates
    LD B, 1     ;Increment Y values for South
    LD C, 1     ;Clockwise rotation
    JP HandleConveyorSideways

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorNorth_Clockwise:
    PUSH IX
    POP IY      ;IY = IX
    INC IY      ;offset to point to player's Y-Coordinates
    LD B, -1    ;Decrement Y values for North
    LD C, 1     ;Clockwise rotation
    JP HandleConveyorSideways

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorEast_Clockwise:
    PUSH IX
    POP IY      ;IY = IX
    LD B, 1     ;Increment X values for East
    LD C, 1     ;Clockwise rotation
    JP HandleConveyorSideways

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorWest_Clockwise:
    PUSH IX
    POP IY      ;IY = IX
    LD B, -1    ;Decrement X values for West
    LD C, 1     ;Clockwise rotation
    JP HandleConveyorSideways

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorSouth_Counterwise:
    PUSH IX
    POP IY      ;IY = IX
    INC IY      ;offset to point to player's Y-Coordinates
    LD B, 1     ;Increment Y values for South
    LD C, -1    ;CounterClockwise rotation
    JP HandleConveyorSideways

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorNorth_Counterwise:
    PUSH IX
    POP IY      ;IY = IX
    INC IY      ;offset to point to player's Y-Coordinates
    LD B, -1    ;Decrement Y values for North
    LD C, -1    ;CounterClockwise rotation
    JP HandleConveyorSideways

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorEast_Counterwise:
    PUSH IX
    POP IY      ;IY = IX
    LD B, 1     ;Increment X values for East
    LD C, -1    ;CounterClockwise rotation
    JP HandleConveyorSideways

;A=AnimationFrame (0...23)
;IX points to Player
OnConveyorWest_Counterwise:
    PUSH IX
    POP IY      ;IY = IX
    LD B, -1    ;Decrement X values for West
    LD C, -1    ;CounterClockwise rotation
    JP HandleConveyorSideways

OnPlusExtraLife:        ;We have 9 hitpoints, check if we have < 4 lives and phase 5
    LD A, (RegisterPhaseNr)
    CP 4
    RET NZ              ;Return if not phase 5
    LD A, (IX+25)       ;Players lives
    CP 4
    RET NC              ;Return if player already has max lives
    INC (IX+25)         ;+1 Live
    LD IYL, 8
    LD HL, HeartSprite
    JP AnimateBonusSprite

OnDoubleRepair:
    LD A, (IX+14)   ;Hitpoints
    CP 9
    JR Z, OnPlusExtraLife
    CP 8
    JR Z, OnRepair
    RET NC
    INC (IX+14)     ;If HP<8 repair +2
    LD HL, Wrench2Sprite
    JR repair_Common
OnRepair:
    LD A, (IX+14)   ;Hitpoints
    CP 9
    RET NC
    LD HL, WrenchSprite
repair_Common:
    LD A, (IX+12)
    LD (IX+19), A
    LD A, (IX+13)
    LD (IX+20), A      ;Respawn Position updated
    INC (IX+14)     ;If HP<9 repair +1
    LD IYL, 1
    JP AnimateBonusSprite

BoardPhase_ExpressConveyors:
    LD HL, Check_Player_Express
    CALL PreCheckConveyorCollisions
    CALL HALT_Animation         ;New frame
    LD A, (HotspotCount)
    AND A
    RET Z   ;If no robot is moved, skip Animation
    CALL ScrollToHotspots
    LD HL, FX_Conveyor
    CALL PlaySoundFX
    LD B, 24
boardPhase_ExpressConveyors_loop:
    PUSH BC
    CALL AnimateExpressConveyors
    POP BC
    PUSH BC
    LD HL, Check_Player_Express
    CALL Check_All_Players_Any
    CALL Put_All_Robots
    POP BC
    CALL HALT_Animation
    DEC B
    LD A, 8
    AND B
    JR NZ, boardPhase_ExpressConveyors_loop_done
    CALL HALT_Animation    ;Additional Halt for slower start and end
boardPhase_ExpressConveyors_loop_done:
    INC B
    DJNZ boardPhase_ExpressConveyors_loop
    CALL ResetAllBlockMarkers
    CALL World_to_Screen_Coordinates_ALL
    JP Put_All_Robots    

BoardPhase_Conveyors:
    LD HL, Check_Player_Conveyor
    CALL PreCheckConveyorCollisions
    CALL HALT_Animation         ;New frame
    LD A, (HotspotCount)
    AND A
    RET Z   ;If no robot is moved, skip Animation
    CALL ScrollToHotspots
    LD HL, FX_Conveyor
    CALL PlaySoundFX
    LD B, 24
boardPhase_Conveyors_loop:
    PUSH BC
    CALL AnimateConveyors
    POP BC
    PUSH BC
    LD HL, Check_Player_Conveyor
    CALL Check_All_Players_Any
    CALL Put_All_Robots
    POP BC
    CALL HALT_Animation
    DEC B
    LD A, 8
    AND B
    JR NZ, boardPhase_Conveyors_loop_done
    CALL HALT_Animation     ;Additional Halt for slower start and end
boardPhase_Conveyors_loop_done:
    INC B
    DJNZ boardPhase_Conveyors_loop
    CALL ResetAllBlockMarkers
    CALL World_to_Screen_Coordinates_ALL
    JP Put_All_Robots    

;B=Loop Counter (24...1)
Check_All_Players_Any:
    LD (call_check_addr+1), HL  ;Re-Program CALL address
    LD A, 24
    SUB B
    LD C, A     ;C stores amimation phase (0...23)
    LD A, (PlayerCount)
    LD B, A
    LD DE, PlayerArray              ;Re-Programmed to ShadowArray
 checkallplayers_loop:    
    LD A, (DE)
    LD IXL, A
    INC DE
    LD A, (DE)
    LD IXH, A
    INC DE      ;IX points to current player
    PUSH DE
    PUSH BC
 call_check_addr:   
    CALL Check_Player_Express       ;Re-programmed between Check_Player_Express and Check_Player_Conveyor
    POP BC
    POP DE
    DJNZ checkallplayers_loop
    RET

;C=(0...23)
;IX points to Player
Check_Player_Conveyor:
    LD A, 1
    LD (conveyor_flag+1), A     ;Reprogramm flag
    JR Check_Player_Any
Check_Player_Express:
    LD A, 2
    LD (conveyor_flag+1), A     ;Reprogramm flag
Check_Player_Any:
    LD A, (IX+12)
    CP 30
    RET Z       ;if PlayerPosx=30 means Player is dead!
    CALL Point_DE_to_Player_tile_offset
    LD HL, TileFlags + 1
    ADD HL, DE
    LD A, (HL)      ;A contains Tile Action Flags
 conveyor_flag:   
    AND 2           ;Test for Express Flag, is reprogrammed
    RET Z           ;Return of flag not set
    ;Express flag set
    CALL Point_DE_to_Player_tile_offset
    LD HL, TileActions
    ADD HL, DE
    LD E, (HL)
    INC HL
    LD D, (HL)
    EX DE, HL
    LD A, C
    JP (HL)     ;Jump to configured Action

Point_DE_to_Player_tile_offset
    LD A, (IX+13)       ;Player World Y-Coordinate
    LD DE, 26
    PUSH BC
    CALL mult_a_de  ;HL = Y*26
    POP BC
    LD E, (IX+12)
    LD D, 0
    ADD HL, DE      ;HL = x + y*26
    LD DE, WorldMapBuffer
    ADD HL, DE      ;HL points to players Tile
    LD A, (HL)      ;A=Tile Index
    ADD A, A
    LD D, 0
    LD E, A
    RET

;HL = Check_Player_Express / Check_Player_Conveyor
PreCheckConveyorCollisions:
    CALL ResetHotspots
    LD DE, ShadowPlayerArray
    LD (checkallplayers_loop-2), DE     ;Re-Program to look at shadow-Array
    PUSH HL
    CALL ShadowPlayersAndCheckCollisions
    POP HL
    CALL ShadowPlayersAndCheckCollisions    ;Second time to account for Auffahrunfall
    ;Now all Players are marked if Collision would occur directly or indirectly
    LD HL, PlayerArray
    LD (checkallplayers_loop-2), HL     ;Restore to normal
    RET

ShadowPlayersAndCheckCollisions:
    PUSH HL
    LD HL, Player1State
    LD DE, ShadowPlayerBuffer
    LD BC, 3 * (Player2State - Player1State)
    LDIR        ;Copy player states into shadow states
    POP HL      ;HL=Check_Player_Express / Check_Player_Conveyor
    LD B, 1     ;Set final frame where World Coordinates are set
    CALL Check_All_Players_Any  ;Moves Shadow players
    ;Now check for collisions: 1vs2, 1vs3, 2vs3
    LD IX, ShadowPlayerBuffer
    LD IY, ShadowPlayerBuffer + (Player2State - Player1State)
    CALL CheckCollision_IX_IY   ;Check 1vs2
    LD IX, ShadowPlayerBuffer
    LD IY, ShadowPlayerBuffer + 2 * (Player2State - Player1State)
    CALL CheckCollision_IX_IY  ;Check 1vs3
    LD IX, ShadowPlayerBuffer + (Player2State - Player1State)
    LD IY, ShadowPlayerBuffer + 2 * (Player2State - Player1State)
    JP CheckCollision_IX_IY   ;Check 2vs3

;IX and IY point to shadow players
CheckCollision_IX_IY:
    LD A, (IX+12)   ;WorldX
    CP 30
    RET Z           ;Player1 is dead, dont compare!
    CP (IY+12)      ;If only player2 were dead compare also returns NZ
    RET NZ
    ;X-Coordinates are same
    LD A, (IX+13)   ;WorldY
    CP (IY+13)
    RET NZ
    ;X an Y are Same, Collision detected. Block both players!
    LD D, IXH
    LD E, IXL
    LD HL, Player1State - ShadowPlayerBuffer + 10
    ADD HL, DE  ;HL points to player corresponding to IX+10
    LD (HL), 255    ;Blocked marker
    LD D, IYH
    LD E, IYL
    LD HL, Player1State - ShadowPlayerBuffer + 10
    ADD HL, DE  ;HL points to player corresponding to IY+10
    LD (HL), 255    ;Blocked marker
    RET

ResetAllBlockMarkers:
    PUSH IX
    XOR A               ;Reset all blockers 
    LD IX, Player1State
    LD (IX+10), A
    LD IX, Player2State
    LD (IX+10), A
    LD IX, Player3State
    LD (IX+10), A
    POP IX
    RET

BoardPhase_Bot_Lasers:
    LD A, (UseLasers)
    AND A
    RET Z   ;IF Lasers turned off, skip
    LD IX, Player1State
    CALL BoardPhase_Bot_Laser
    LD IX, Player2State
    CALL BoardPhase_Bot_Laser
    LD IX, Player3State

;IX=Player
BoardPhase_Bot_Laser:
    XOR A
    LD (BoardPhase_Lasers_Repeatmarker), A
    LD A, (IX+12)    ;WorldX Position
    CP 30
    RET Z       ;If player is Dead don't fire!
    LD A, (IX+6)    ;Pseudosprite color
    CP 1
    RET Z       ;If player is shut down don't fire!
    LD (IX+6), 9
    PUSH IX
    CALL Fire_BotLaser
    POP IX
    LD A, (HotspotCount)
    AND A
    JR Z, skip_bot_to_bot_hit
    CALL AddHotspot_Player      ;We hit some other Bot, add shooter!
    PUSH IX
    CALL ScrollToHotspots
    POP IX
    PUSH IX
    LD A, 255
    LD (BoardPhase_Lasers_Repeatmarker), A
    CALL Fire_BotLaser      ;Redo after scrolling
    POP IX
    PUSH IX
    CALL AnimatePreparedLaserChars
    CALL PaintMap_from_buffer   ;Restore map
    POP IX
skip_bot_to_bot_hit:    
    LD (IX+6), 15
    JP hide_all_lasersprites

BoardPhase_Lasers:
    XOR A
    LD (BoardPhase_Lasers_Repeatmarker), A
BoardPhase_Lasers_Repeat:    
    CALL ResetHotspots
    LD A, 208
    LD (CurrentLaserChar), A
    LD A, 4
    LD (LaserSprite_Z), A
    XOR A
    LD (LaserSprite_8), A
    LD HL, WorldMapBuffer
    LD BC, 26 * (WorldMapBufferHeight+2)
 boardPhase_Lasers_loop:
    LD A, (HL)      ;A=Tile Index
    ADD A, A
    LD E, A
    LD D, 0
    PUSH HL
    LD HL, TileFlags+1
    ADD HL, DE
    LD A, (HL)  ;A=file action flags
    AND 8       ;8 is Flag for Laser
    POP HL      ;HL is world position + WorldMapBuffer
    PUSH HL 
    PUSH BC
    CALL NZ, FireBoardLaser
    POP BC
    POP HL
    INC HL      ;Next tile in World
    DEC BC      ;Counter
    LD A, B
    OR C
    JR NZ, boardPhase_Lasers_loop
;Laser chars prepared, animate firing
    LD A, (HotspotCount)
    AND A
    JR Z, skip_board_laser_scrolling
    LD A, (BoardPhase_Lasers_Repeatmarker)
    AND A
    JR NZ, skip_board_laser_scrolling_fire
    CALL ScrollToHotspots
    LD A, 255
    LD (BoardPhase_Lasers_Repeatmarker), A
    JR BoardPhase_Lasers_Repeat
skip_board_laser_scrolling_fire:
    CALL AnimatePreparedLaserChars
    CALL PaintMap_from_buffer   ;Restore map
skip_board_laser_scrolling:
;Animate Damage
hide_all_lasersprites:
    LD IX, Player1State
    CALL SubtractDamage
    LD IX, Player2State
    CALL SubtractDamage
    LD IX, Player3State
    CALL SubtractDamage
    CALL ResetAllBlockMarkers
hide_all_lasersprites_do:
    LD DE, $3C00 +20    ;All sprites below bottom
    LD L, 192
    LD B, 17*4
    JP COPY_L_TO_VRAM_fast    ;Hide all potential Laser Sprites

SubtractDamage:
    LD A, (IX+14)   ;Player Hitpoints
    LD B, (IX+10)
    SRA B     ;Divide by 2, becaue every hit is counted twice!
    SUB B     ;Player Damage taken
    LD (IX+14), A   ;Store Hitpoints
    RET

;HL = World position + WorldMapBuffer
;DE = TileIndex*2
FireBoardLaser:
    PUSH HL     ;World Position
    LD HL, TileActions
    ADD HL, DE
    LD E, (HL)
    INC HL
    LD D, (HL)
    EX DE, HL
    POP DE      ;DE=WorldPos
    JP (HL)     ;HL points to configured Laser Method

;IX=Player
Fire_BotLaser:
    CALL ResetHotspots
    CALL hide_all_lasersprites_do
    LD A, 208
    LD (CurrentLaserChar), A
    LD A, 4
    LD (LaserSprite_Z), A
    XOR A
    LD (LaserSprite_8), A
    CALL calculate_World_Position_DE

    PUSH DE
    CALL calculate_Tile_XY
    CALL calculate_playfieldbuffer_position     ;HL points to position in Playfield
    LD DE, PlayfieldBuffer + 2 + 1*78
    ADD HL, DE
    POP DE

    LD A, (IX+2)        ;Direction
    AND 63              ;Mask in case Direction got bigger than 63
    CP 0
    JP Z, Fire_BotLaser_North
    CP 16
    JP Z, Fire_BotLaser_East
    CP 32
    JP Z, Fire_BotLaser_South

;IX=Player
;DE=WorldPos
;HL=PlayfieldbufferPos
Fire_BotLaser_West:
    CALL ReconfigureLaserWest
    DEC HL
    DEC HL
    JR jump_in_BotLaser_east
Fire_BotLaser_East:
    CALL ReconfigureLaserEast
    JR jump_in_BotLaser_east

;IX=Player
Fire_BotLaser_South:
    CALL ReconfigureLaserSouth
    JR $+5
Fire_BotLaser_North:
    CALL ReconfigureLaserNorth
    LD A, (CurrentTileX)
    LD B, A
    ADD A, B
    ADD A, B
    INC A
    LD (LaserSprite_X), A   

    LD A, (CurrentTileY)
    LD B, A
    ADD A, B
    ADD A, B
    INC A
 laser_north_start_offset:
    DEC A           ;Reprogram for south
    LD (LaserSprite_Y), A   

    PUSH DE                 ;WorldPos
    JP jump_in_BotLaser_north

;B=X
;L=Y
calculate_playfieldbuffer_position:
    LD A, B
    ADD A, B
    ADD A, B            ;A=X*3
    LD E, A
    LD D, 0
    PUSH DE             ;X*3
    LD A, L             ;Y
    LD DE, 234          ;=26*3*3
    CALL mult_a_de      ;HL=Y*243
    POP DE              ;X*3
    ADD HL, DE          ;HL=Y*234 + X*3
    RET

;DE=WorldPos
OnDoubleLaserEast:
    CALL ReconfigureLaserEast
    LD HL, PlayfieldBuffer + 1 + 0*78
    LD (laser_offset_addr+1), HL
    PUSH DE
    CALL OnLaserANY
    POP DE
    LD HL, PlayfieldBuffer + 1 + 2*78
    LD (laser_offset_addr+1), HL
    JR OnLaserANY
OnLaserEast:
    CALL ReconfigureLaserEast
    LD HL, PlayfieldBuffer + 1 + 1*78
    LD (laser_offset_addr+1), HL
OnLaserANY:
    PUSH DE             ;WorldPos
    CALL calculate_Tile_XY
    CALL calculate_playfieldbuffer_position
laser_offset_addr:    
    LD DE, PlayfieldBuffer + 1 + 78     ;Offset from Tile upper left corner. Can be reprogrammed for multi-Laser!
    ADD HL, DE          ;HL=First Laser Char position in PlayfieldBuffer
    POP DE              ;WorldPos
laser_east_loop:
    LD IX, Player1State
    CALL Check_Laser_vs_Player
    LD IX, Player2State
    CALL NZ, Check_Laser_vs_Player
    LD IX, Player3State
    CALL NZ, Check_Laser_vs_Player
    RET Z              ;Done: Laser hits player
    
    CALL PrepareLaserChar
 jump_in_BotLaser_east:
    CALL PrepareLaserChar
 east_wall_flag:   
    LD B, 2             ;!For West direction replace 2/8!
    CALL CheckTileFlag
    RET NZ              ;Current Tile has East wall: Done

    PUSH HL
    LD HL, CurrentTileX
 next_eastern_tile:
    INC (HL)            ;TileX + 1      !For West direction replace INC/DEC!
    POP HL
    INC DE              ;Next Tile      !For West direction replace INC/DEC!

 west_wall_flag:   
    LD B, 8     ;!For West direction replace 8/2!
    CALL CheckTileFlag
    RET NZ              ;Current Tile has West wall: Done

    ;Current Tile is free to enter, add 1 laser chars
    CALL PrepareLaserChar
    JR laser_east_loop

calculate_Tile_XY:
    LD HL, -WorldMapBuffer
    ADD HL, DE      ;HL=Tile offset
    LD C, 26
    CALL div_hl_c      ;L=TilePos/26=YPos, A=Remainder=xPos
    LD (CurrentTileX), A 
    LD B, A
    LD A, L
    LD (CurrentTileY), A 
    RET

;IX=Player
;Returns Player Tile in (DE)
calculate_World_Position_DE:
    LD A, (IX+13)       ;World Y
    LD DE, 26
    CALL mult_a_de      ;HL=Y*26
    LD D, 0
    LD E, (IX+12)       ;DE=X
    ADD HL, DE
    LD DE, WorldMapBuffer
    ADD HL, DE
    EX DE, HL       ;DE=WorldPos
    RET

;DE points to current Tile in World
;B=Flags to check
CheckTileFlag:
    PUSH HL             ;HL=Laser Char position in PlayfieldBuffer
    PUSH DE             ;WorldPos
    LD A, (DE)
    ADD A, A            
    LD E, A
    LD D, 0
    LD HL, TileFlags
    ADD HL, DE
    LD A, (HL)          ;A=tile flags
    LD C, A             ;Store whole flag byte for later
    AND B               ;2=East Flag, 8=West Flag
    POP DE
    POP HL
    RET

;IX=Player
;Returns Zero Flag=false if player is hit
Check_Laser_vs_Player:
    LD A, (CurrentTileX)
    CP (IX+12)  ;Player world PosX
    RET NZ
    LD A, (CurrentTileY)
    CP (IX+13)  ;Player world PosY
    RET NZ
    ;Player is hit by laser
    INC (IX+10) ;Damage counter
    CALL AddHotspot_Player
    SUB A       ;Set Zero Flag (A-A is always 0)
    RET

;HL=Laser Char position in PlayfieldBuffer
PrepareLaserChar:
    LD A, (BoardPhase_Lasers_Repeatmarker)
    AND A
    RET Z
    PUSH HL
    PUSH DE
    ;Calculate VRAM Position corresponding to 
    LD DE, -PlayfieldBuffer
    ADD HL, DE              ;HL is offset in PlayfieldBuffer

    LD C, 78
    CALL div_hl_c           ;L is Y, A is X
    LD C, A                 ;C=X
    LD A, (MapScroll_Y)
    NEG
    ADD A, L                
    JP M, laser_char_offscreen      ;Y is a negative number
    LD B, A                 ;B=Y-ScrollY

    LD A, (MapScroll_X)
    NEG
    ADD A, C                ;A=X-Scrollx
    LD C, A
    JP M, laser_char_offscreen      ;X is a negative number
    ;Check if 0 <= X < 24

    LD A, C
    LD HL, SpriteLimit2
    CP (HL)
    JP NC, laser_char_offscreen
    LD A, 23
    CP B
    JP C, laser_char_offscreen
    ;Onscreen
    LD H, 0
    LD A, B
    RLA
    RLA
    RLA
    RLA
    RL H
    RLA
    RL H
    OR C        ;ADD X
    LD L, A     ;HL = Y*32+X

    LD DE, $3800
    ADD HL, DE
    EX DE, HL

    CALL VDPADDR_IN
    NOP     ;Waste time for more stable read
    IN A, (VDP_PORT_READ)
    LD (SpriteTransformBuffer), A   ;Which char is currently shown?

    LD B, 1
    LD A, (CurrentLaserChar)
    LD L, A
    CALL COPY_L_TO_VRAM_fast        ;Copy replacement char to position on screen

    LD HL, SpriteTransformBuffer
    CALL pHL_mul8_to_DE
    LD HL, 4096
    ADD HL, DE
    EX DE, HL       ;Use 3rd pattern area

    LD HL, SpriteTransformBuffer
    LD B, 1
    CALL COPY_VRAM_TO_RAM_unrolled      ;Copy pattern of char
    LD HL, 8192
    ADD HL, DE                          ;Address of colors
    EX DE, HL
    LD HL, SpriteTransformBuffer + 8
    LD B, 1
    CALL COPY_VRAM_TO_RAM_unrolled      ;Copy colors of char

    LD HL, CurrentLaserChar
    CALL pHL_mul8_to_DE         ;DE points to LaserChar pattern
    LD HL, SpriteTransformBuffer
    LD B, 1
    LD A, (TitleMode)
    AND A
    JR NZ, skip_first_Pattern_section
    PUSH HL
    CALL COPY_RAM_TO_VRAM_unrolled
    POP HL
skip_first_Pattern_section:
    PUSH HL
    CALL copy_additionalPatternBlock
    LD HL, SpriteTransformBuffer+8
    EX (SP), HL         ;Saves one POP/PUSH
    CALL copy_additionalPatternBlock

    LD HL, 2048
    ADD HL, DE
    EX DE, HL       ;DE is pointing to Color Section
    POP HL

    LD A, (TitleMode)
    AND A
    JR NZ, skip_first_Color_section

    PUSH HL
    CALL copy_additionalPatternBlock
    POP HL
    JR first_Color_section_done
skip_first_Color_section:
    LD A, D
    ADD A, 8
    LD D, A
first_Color_section_done:
    PUSH HL
    CALL copy_additionalPatternBlock
    POP HL
    CALL copy_additionalPatternBlock
    LD HL, CurrentLaserChar
    INC (HL)  ;CurrentLaser char inc
 laser_char_offscreen:
    POP DE
    POP HL
    INC HL              ;Next Char in buffer !For West direction replace INC/DEC!
    RET

;HL = Source in Memeory
copy_additionalPatternBlock:
    LD A, D
    ADD A, 8
    LD D, A     ;DE increased by 2048 (=256*8)
    LD B, 1
    JP COPY_RAM_TO_VRAM_unrolled

pHL_mul8_to_DE:
    XOR A                   ;Reset Carry
    LD D, A
    LD A, (HL)              ;Which Char?
    RLA
    RL D
    RLA
    RL D
    RLA
    RL D
    LD E, A                ;DE=Char*8
    RET

AnimatePreparedLaserChars:
    LD HL, FX_PewPew
    CALL PlaySoundFX
    LD B, 13    ;Long firing animation, because we hit something
flickerPreparedLaserChars_loop:
    PUSH BC
    LD IYL, 6 + $10 * 8
    CALL animatePreparedLaserChars_Color
    CALL HALT_Animation
    CALL HALT_Animation
    LD IYL, 11 + $10 * 10
    CALL animatePreparedLaserChars_Color
    CALL HALT_Animation
    POP BC
    DJNZ flickerPreparedLaserChars_loop
    RET

;IYL = Color
animatePreparedLaserChars_Color
    LD IX, Player1State
    CALL AnimatePlayerIfHitByLaser
    LD IX, Player2State
    CALL AnimatePlayerIfHitByLaser
    LD IX, Player3State
    CALL AnimatePlayerIfHitByLaser

    LD C, 12
    LD DE, $3C00 + 5*4 + 3
    LD A, IYL
    AND %00001111
    LD L, A
 animatePreparedLaserSprites_loop:
    LD B, 1
    CALL COPY_L_TO_VRAM_fast
    INC DE
    INC DE
    INC DE
    INC DE
    DEC C
    JR NZ, animatePreparedLaserSprites_loop

    LD A, (CurrentLaserChar)                      ;A=Highest char nr.
    LD HL, SpriteTransformBuffer
    LD (HL), A   ;
animatePreparedLaserChars_loop:
    CALL pHL_mul8_to_DE
    LD HL, 8192 + 3
    ADD HL, DE
    EX DE, HL
    LD A, (TitleMode)
    AND A
    JR NZ, laser_char_3rd_only
    CALL write_laser_color
    CALL write_laser_color
    JR laser_char_3rd_done
laser_char_3rd_only:
    LD A, D
    ADD A, 16
    LD D, A
laser_char_3rd_done:
    CALL write_laser_color
    LD HL, SpriteTransformBuffer
    LD A, (HL)
    DEC A
    CP 207
    RET Z
    LD (HL), A
    JR animatePreparedLaserChars_loop

;IX=Player
AnimatePlayerIfHitByLaser:
    LD A, (IX+10)       ;Hit counter
    AND A
    RET Z               ;Do nothing if no hits counted
    LD B, (IX+0)
    LD C, (IX+1)
    LD E, (IX+5)
    LD D, E
    LD A, IYL
    AND %00001111
    LD L, A
    RRA
    JR C, animatePlayerIfHitByLaser_done
    LD L, (IX+3)
 animatePlayerIfHitByLaser_done:
    JP PUT_SPRITE

write_laser_color:
    LD B, 2
    LD A, IYL     ;color
    LD L, A
    CALL COPY_L_TO_VRAM_fast
    LD A, D
    ADD A, 8
    LD D, A         ;DE increased by 2048
    RET

;DE=WorldPos
OnLaserNorth:
    CALL ReconfigureLaserNorth
    XOR A
    LD (LaserSprite_8), A       ;Set 0 because new sprite line

    PUSH DE                 ;WorldPos
    CALL calculate_Tile_XY  ;(CurrentTileX/Y are set)
    LD A, (CurrentTileX)
    LD B, A
    ADD A, B
    ADD A, B
    INC A
    LD (LaserSprite_X), A   

    LD A, (CurrentTileY)
    LD B, A
    ADD A, B
    ADD A, B
    INC A
    LD (LaserSprite_Y), A   
onLaserNorth_loop:
    POP DE                  ;WorldPos

    LD IX, Player1State
    CALL Check_Laser_vs_Player
    LD IX, Player2State
    CALL NZ, Check_Laser_vs_Player
    LD IX, Player3State
    CALL NZ, Check_Laser_vs_Player
    RET Z              ;Done: Laser hits player

    PUSH DE
    CALL PrepareLaserSprite         ;Center of tile
 jump_in_BotLaser_north:
    CALL PrepareLaserSprite         ;Outside edge
    POP DE
north_wall_flag:
    LD B, 1     ;North Wall Flag !For South direction Reprogram 1/4!
    PUSH DE
    CALL CheckTileFlag
    POP DE
    RET NZ      ;Wall hit: Return    

    LD HL, CurrentTileY
 laser_north_progress_tile:
    DEC (HL)    ;Reprogram INC/DEC for South
    LD HL, -26  ;Reprogram with +26 for South
    ADD HL, DE
    EX DE, HL   ;Tile is one field further North

    PUSH DE
south_wall_flag:
    LD B, 4     ;South WallFlag !For North direction Reprogram 4/1!
    CALL CheckTileFlag
    POP DE
    RET NZ      ;Wall hit: Return    
    PUSH DE
    CALL PrepareLaserSprite         ;Outside edge
    JR onLaserNorth_loop

;LaserSprite_X/Y/Z/8
PrepareLaserSprite:
    LD A, (MapScroll_Y)
    LD B, A
    LD A, (LaserSprite_Y)
    SUB B       ;A = LaserSprite_X - MapScroll_X
    JP M, laser_sprite_offscreen    ;If result < 0
    CP 24
    JR NC, laser_sprite_offscreen
    ADD A, A
    ADD A, A
    ADD A, A
    LD C, A             ;C = Screen Position y

    LD A, (MapScroll_X)
    LD B, A
    LD A, (LaserSprite_X)
    SUB B       ;A = LaserSprite_X - MapScroll_X
    JP M, laser_sprite_offscreen    ;If result < 0
    EX AF, AF'
    LD A, (SpriteLimit2)
    LD B, A
    EX AF, AF'
    CP B
    JR NC, laser_sprite_offscreen
    ADD A, A
    ADD A, A
    ADD A, A
    LD B, A             ;BC = Screen Position xy

    LD A, (LaserSprite_Z)
    LD D, A             ;Sprite Layer
    LD L, 0             ;Color transparent for prep phase

    LD A, (LaserSprite_8)
    AND A
    JR Z, laserSprite_new
 laser_sprite_south_offset:   
    LD A, 0                     ;Reprogram to -8 for south
    ADD A, C
    LD C, A                     ;C decreased by 8 if we go south with 16rows Sprite
    XOR A
    LD (LaserSprite_8), A       ;Set 0, because we are re-using the 8-Row sprite and extend to 16 rows
    LD E, 9                     ;Pattern with 16 rows of laser
    JR laserSprite_done
 laserSprite_new:
    LD E, 10                    ;Pattern with 8 rows
    INC D                       ;New sprite
    LD A, D
    LD (LaserSprite_Z), A       ;New Sprite layer
    LD (LaserSprite_8), A       ;Set not 0, because we are re-using the 8-Row sprite and extend to 16 rows
 laserSprite_done:
    CALL PUT_SPRITE
 laser_sprite_offscreen:
    LD HL, LaserSprite_Y
 laser_sprite_north_next:   
    DEC (HL)                    ;Reprogram DEC/INC
    RET

ReconfigureLaserSouth:
    LD A, -8
    LD (laser_sprite_south_offset+1), A
    LD A, $34       ;Opcode for INC(HL)
    LD (laser_sprite_north_next), A
    LD (laser_north_progress_tile), A
    LD BC, 26
    LD (laser_north_progress_tile+2), BC
    LD A, 4
    LD (north_wall_flag+1), A
    LD A, 1
    LD (south_wall_flag+1), A
    LD A, $3C   ;INC A
    LD (laser_north_start_offset), A
    RET
ReconfigureLaserNorth:
    LD A, 0
    LD (laser_sprite_south_offset+1), A
    LD A, $35       ;Opcode for DEC(HL)
    LD (laser_sprite_north_next), A
    LD (laser_north_progress_tile), A
    LD BC, -26
    LD (laser_north_progress_tile+2), BC
    LD A, 1
    LD (north_wall_flag+1), A
    LD A, 4
    LD (south_wall_flag+1), A
    LD A, $3D   ;DEC A
    LD (laser_north_start_offset), A
    RET

ReconfigureLaserEast:
    LD A, 2
    LD (east_wall_flag+1), A
    LD A, 8
    LD (west_wall_flag+1), A
    LD A, $34       ;Opcode for INC(HL)
    LD (next_eastern_tile), A
    LD A, $13       ;Opcode for INC DE
    LD (next_eastern_tile+2), A
    LD A, $23       ;Opcode for INC HL
    LD (laser_char_offscreen+2), A
    RET
ReconfigureLaserWest:
    LD A, 8
    LD (east_wall_flag+1), A
    LD A, 2
    LD (west_wall_flag+1), A
    LD A, $35       ;Opcode for DEC(HL)
    LD (next_eastern_tile), A
    LD A, $1B       ;Opcode for DEC DE
    LD (next_eastern_tile+2), A
    LD A, $2B       ;Opcode for DEC HL
    LD (laser_char_offscreen+2), A
    RET