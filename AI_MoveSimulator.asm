;DE=Target Method Mem Addr
AI_Reconfigure_Conveyor_Actions:
    LD HL, OnConveyorNorth
    LD B, 12
    LD A, $C3       ;JP Opcode
 reconfigure_Conveyor_Actions_loop:
    LD C, 255
    CPIR
    LD (HL), E
    INC HL
    LD (HL), D
    DJNZ reconfigure_Conveyor_Actions_loop
    RET

;B=sideways direction (+/-1)
;C=Rotation (-1,0,1)
;IX points to Player
;IY points to Player (offset +1 for vertical direction)
AI_Simulate_OnConveyor:
    LD A, (IY+12)
    ADD A, B
    LD (IY+12), A       ;Position is updated
    LD A, C
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, A            ;Rotation * 16
    LD B, (IX+2)
    ADD A, B
    LD (IX+2), A
    RET

;IX=Player
;Choice of 2 cards are in (AI_ChosenCard4)...5
AI_Simulate_2Moves:
    LD DE, ShadowPlayerBuffer
    LD HL, ShadowPlayerBuffer + 64
    LD BC, Player2State-Player1State
    LDIR         ;Restore player position after 3 Moves
    LD A, (IX+12)
    CP 30
    RET Z       ;Don't move if bot is dead
    LD HL, AI_ChosenCard4
    LD B, 2
    JR simulate_3moves_loop

;IX=Player
;Choice of 3 cards are in (AI_ChosenCard1)...3
AI_Simulate_3Moves:
    PUSH IX
    POP HL
    LD IY, ShadowPlayerBuffer
    PUSH IY
    POP DE
    LD BC, Player2State-Player1State
    LDIR        ;Copy Player to ShadowPayerBuffer
    LD HL, AI_ChosenCard1
    LD B, 3
 simulate_3moves_loop:   
    PUSH BC
    PUSH HL
    LD A, (HL)          ;A=Card Char
    CP 35
    JR Z, AI_Simulate_Move1
    CP 36
    JR Z, AI_Simulate_Move2
    CP 37
    JR Z, AI_Simulate_Move3
    CP 38
    JR Z, AI_Simulate_Turn_Left
    CP 39
    JR Z, AI_Simulate_Turn_Right
    CP 40
    JR Z, AI_Simulate_Turn_UTurn
    CP 41
    JR Z, AI_Simulate_MoveBack
AI_Card_done:
    LD A, (IY+12)   
    CP 30
    JR Z, AI_cancel_3Moves           ;If player is dead, dont proceed
    ;Factory actions (Conveyors, Turntables, (Lasers))
    CALL AI_FactoryActions
    POP HL
    POP BC
    INC HL      ;Next card
    INC HL
    DJNZ simulate_3moves_loop
    RET
AI_cancel_3Moves:
    POP HL
    POP BC
    RET

AI_Simulate_Move1:
    LD A, (IY+2)        ;Check Direction
    CALL AI_PrepareMove
    CALL AI_Move_one
    JR AI_Card_done

AI_Simulate_Move2:
    LD A, (IY+2)        ;Check Direction
    CALL AI_PrepareMove
    PUSH BC
    PUSH DE
    CALL AI_Move_one
    POP DE
    POP BC
    CALL Z, AI_Move_one
    JR AI_Card_done
    
AI_Simulate_Move3:
    LD A, (IY+2)        ;Check Direction
    CALL AI_PrepareMove
    PUSH BC
    PUSH DE
    CALL AI_Move_one
    POP DE
    POP BC
    PUSH BC
    PUSH DE
    CALL Z, AI_Move_one
    POP DE
    POP BC
    CALL Z, AI_Move_one
    JR AI_Card_done

AI_Simulate_MoveBack:
    LD A, (IY+2)
    XOR 32      ;Turn by 32
    CALL AI_PrepareMove
    CALL AI_Move_one
    JR AI_Card_done

AI_Simulate_Turn_Left:
    LD A, (IY+2)
    ADD A, -16
    AND 63
    LD (IY+2), A
    JR AI_Card_done
AI_Simulate_Turn_Right:
    LD A, (IY+2)
    ADD A, 16
    AND 63
    LD (IY+2), A
    JR AI_Card_done
AI_Simulate_Turn_UTurn:
    LD A, (IY+2)
    XOR 32
    LD (IY+2), A
    JR AI_Card_done

;Sets BC=Offset and DE=Wall Flags for movement according to Direction in a
AI_PrepareMove:
    AND 63
    AND A
    JR Z, AI_Move_North
    CP 16
    JR Z, AI_Move_East
    CP 48
    JR Z, AI_Move_West
    LD BC, 26                ;MoveSouth
    LD DE, 4*256 + 1        ;Wall flags
    RET
AI_Move_North:
    LD BC, -26
    LD DE, 1*256 + 4        ;Wall flags
    RET
AI_Move_East:
    LD BC, 1
    LD DE, 2*256 + 8        ;Wall flags
    RET
AI_Move_West:
    LD BC, -1
    LD DE, 8*256 + 2        ;Wall flags
    RET

AI_calculate_IY_WorldPosition_HL:
    LD A, (IY+13)
    LD DE, 26
    CALL mult_a_de      ;HL=A*DE
    LD E, (IY+12)
    LD D, 0
    ADD HL, DE          ;HL=Y*26+X
    LD DE, WorldMapBuffer
    ADD HL, DE          ;HL=WorldMapPosition
    RET

;BC=MoveOffset
;D=Start Field Wall Flag
;E=Target Field Wall Flag
;IY=Shadowed Player
;Returns Z flag set if movement successful
AI_Move_one:
    PUSH BC
    PUSH DE
    CALL AI_calculate_IY_WorldPosition_HL
    CALL AI_get_TileFlags
    POP DE
    POP BC
    AND D            ;Check wall if we can exit current field
    RET NZ           ;Dont move at all
    PUSH DE
    ADD HL, BC       ;Move player position
    CALL AI_get_TileFlags
    POP DE
    LD D, A
    AND E            ;Check wall if we can enter new field
    RET NZ           ;cant move
    LD A, D
    AND 16           ;Test if new field is a pit
    JR Z, AI_move_successful
    LD (IY+12), 30  ;X=30 means dead
    RET             ;Also NZ
AI_move_successful:
    LD A, D
    AND 32           ;Test if new field is a Flag
    JR Z, AI_not_a_flag
    LD A, %11000000
    AND D
    LD B, 0
    RLA
    RL B
    RLA
    RL B                ;B contains Flag nr. of Tile
    LD A, (IY+22)       ;Current Flag of Player
    CP B                ;Is this the flag we need?
    JR NZ, AI_not_a_flag
    INC (IY+22)         ;Flag found, next target flag
 AI_not_a_flag:
    ;HL=target Worldpos
    LD BC, -WorldMapBuffer
    ADD HL, BC
    LD C, 26
    CALL div_hl_c    ;The following routine divides hl by c and places the quotient in hl and the remainder in a
    LD (IY+13), L
    LD (IY+12), A
    CP A            ;Set Z flag
    RET

;HL=WorldMapPosition
AI_get_TileFlags:
    PUSH HL
    LD A, (HL)      ;A=Tile Index
    ADD A, A
    LD D, 0
    LD E, A
    LD HL, TileFlags
    ADD HL, DE  ;HL points to tile Flag byte
    LD A, (HL)  ;Tile Flags
    INC HL
    LD B, (HL)  ;Tile Action Triggers
    POP HL
    RET

;IX = Shadowed Player
AI_execute_TileAction:
    LD A, (IX+13)
    LD DE, 26
    CALL mult_a_de      ;HL=Y*26
    LD D, 0
    LD E, (IX+12)
    ADD HL, DE          ;HL=x+y*26
    LD DE, WorldMapBuffer
    ADD HL, DE
    LD A, (HL)          ;A=Tile index
    ADD A, A
    LD D, 0
    LD E, A
    LD HL, TileActions
    ADD HL, DE      ;HL points to tile Action
    LD E, (HL)
    INC HL
    LD D, (HL)
    EX DE, HL       ;HL contains jump address
    JP (HL)

AI_FactoryActions:
    PUSH IX         ;Save current Player original
    PUSH IY
    POP IX          ;IX now points to simulated player
    CALL AI_calculate_IY_WorldPosition_HL
    CALL AI_get_TileFlags   ;B=action flag byte
    LD A, 2         ;onExpressConveyorFlag
    AND B           ;Check action flag of players tile
    JR Z, AI_express_conveyors_done
    CALL AI_execute_TileAction
    PUSH IX
    POP IY          ;Restore IY because it might have been shifted +1
    CALL AI_Check_Death_after_conveyor
AI_express_conveyors_done:   
    CALL AI_calculate_IY_WorldPosition_HL
    CALL AI_get_TileFlags   ;B=action flag byte
    LD A, 1         ;onConveyorFlag
    AND B           ;Check action flag of players tile
    JR Z, AI_conveyors_done
    CALL AI_execute_TileAction
    PUSH IX
    POP IY          ;Restore IY because it might have been shifted +1
    CALL AI_Check_Death_after_conveyor
AI_conveyors_done:   
    CALL AI_calculate_IY_WorldPosition_HL
    LD C, (HL)      ;Store tile index for later
    CALL AI_get_TileFlags   ;B=action flag byte
    LD A, 4         ;onTurntable
    AND B           ;Check action flag of players tile
    JR Z, AI_Turntables_done
    LD A, 1
    CP C
    JR Z, AI_turntable_counterwise
    LD B, 16
    JR AI_Turntables_turn
AI_turntable_counterwise:
    LD B, -16
AI_Turntables_turn:
    LD A, (IX+2)
    ADD A, B
    AND 63
    LD (IX+2), A
AI_Turntables_done:   
    POP IX          ;Restore current player original
    RET

AI_Check_Death_after_conveyor:
    CALL AI_calculate_IY_WorldPosition_HL
    CALL AI_get_TileFlags
    AND 16
    RET Z           ;Not a pit, don't die!
    LD (IY+12), 30  ;X=30 means dead
    RET

;IX=Player
;IY=ShadowPlayer
;Returns A=Score considering Position, Death and flag
AI_ScorePosition:
    LD A, (IY+12)
    CP 30
    JR Z, score_player_dead
    LD A, (IY+13)
    LD DE, 26
    CALL mult_a_de      ;HL=y*26
    LD B, 0
    LD C, (IY+12)
    ADD HL, BC          ;HL=x+y*26
    LD DE, MapDistanceBuffer
    ADD HL, DE
    LD A, (HL)      ;A=distance score
    ADD A, 128
  score_by_position_done:   
    LD C, A
    LD A, (IX+22)
    LD B, (IY+22)
    CP B        ;Found Flag?
    LD A, C
    JR Z, AI_no_flag_scored
    ADD A, -128     ;Huge bonus if flag is hit
AI_no_flag_scored:
    RET
score_player_dead:
    LD A, 254
    JR score_by_position_done