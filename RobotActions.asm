;IX=Player
ConfigureMoveDirection:
    AND 63          ;Mask direction
    CP 0            ;North?
    JP Z, ConfigureMove_NORTH
    CP 16           ;East?
    JP Z, ConfigureMove_EAST
    CP 32           ;South?
    JP Z, ConfigureMove_SOUTH
    JP ConfigureMove_WEST

;IX=Player
;Returns Card Char in A
Load_Players_CurrentCard_to_A:
    LD L, (IX+15)
    LD H, (IX+16)      ;HL points to players card register
    LD A, (RegisterPhaseNr)
    ADD A, A
    LD E, A
    LD D, 0
    ADD HL, DE
    LD A, (HL)      ;A=Card Char
    RET

;IX=Player
ExecutePlayerCard:
    LD A, (IX+12)
    CP 30
    RET Z       ;if PlayerPosx=30 means Player is dead!
    LD A, (IX+6)
    CP 1
    RET Z       ;Shutdown, do nothing!
    LD (IX+6), 11   ;Yellow light for movement
    CALL ResetHotspots
    CALL AddHotspot_Player
    PUSH IX
    CALL ScrollToHotspots
    POP IX
    CALL Load_Players_CurrentCard_to_A
    CP 35
    JR Z, MoveRobot_1
    CP 36
    JR Z, MoveRobot_2
    CP 37
    JR Z, MoveRobot_3
    CP 38
    JR Z, TurnRobot_Left
    CP 39
    JR Z, TurnRobot_Right
    CP 40
    JR Z, TurnRobot_U
    CP 41
    JR Z, MoveRobot_Back
    RET

;IX=Player
MoveRobot_1:
    LD A, (IX+2)    ;Bot direction
    CALL ConfigureMoveDirection
    CALL MoveRobot_ANYWHERE
    LD (IX+6), 15   ;Yellow light for movement
    RET


;IX=Player
MoveRobot_2:
    LD A, (IX+2)    ;Bot direction
    CALL ConfigureMoveDirection
    CALL MoveRobot_ANYWHERE
    CALL MoveRobot_ANYWHERE
    LD (IX+6), 15   ;Yellow light for movement
    RET

;IX=Player
MoveRobot_3:
    LD A, (IX+2)    ;Bot direction
    CALL ConfigureMoveDirection
    CALL MoveRobot_ANYWHERE
    CALL MoveRobot_ANYWHERE
    CALL MoveRobot_ANYWHERE
    LD (IX+6), 15   ;Yellow light for movement
    RET

;IX=Player
MoveRobot_Back:
    LD A, (IX+2)    ;Bot direction
    ADD A, 32       ;reversed dirction
    CALL ConfigureMoveDirection
    CALL MoveRobot_ANYWHERE
    LD (IX+6), 15   ;Yellow light for movement
    RET

;IX=Player
TurnRobot_Left:
    LD HL, FX_Rotate
    CALL PlaySoundFX
    LD B, 16
 turnRobot_Left_loop:
    DEC (IX+2)
    PUSH BC
    CALL PutRobot
    CALL HALT_Animation
    POP BC
    DJNZ turnRobot_Left_loop
    LD (IX+6), 15   ;Yellow light for movement
    RET

;IX=Player
TurnRobot_Right:
    LD HL, FX_Rotate
    CALL PlaySoundFX
    LD B, 16
 turnRobot_Right_loop:
    INC (IX+2)
    PUSH BC
    CALL PutRobot
    CALL HALT_Animation
    POP BC
    DJNZ turnRobot_Right_loop
    LD (IX+6), 15   ;Yellow light for movement
    RET

;IX=Player
TurnRobot_U:
    LD HL, FX_Rotate
    CALL PlaySoundFX
    LD B, 32
 turnRobot_U_loop:
    INC (IX+2)
    PUSH BC
    CALL PutRobot
    CALL HALT_Animation
    POP BC
    DJNZ turnRobot_U_loop
    LD (IX+6), 15   ;Yellow light for movement
    RET


ConfigureMove_NORTH:
    LD A, 1     ;d=+1 (IX+1) Screen posY
    LD (reconfigure_marker_2+2), A
    LD (skip_bot_movement_frame-1), A
    LD (reconfigure_marker_3+2), A
    LD A, $35   ;DEC (IX+d)
    LD (skip_bot_movement_frame-2), A
    LD (reconfigure_marker_1+1), A 
    LD (reconfigure_marker_2+1), A
    LD A, $34   ;INC (IX+d)
    LD (reconfigure_marker_3+1), A
    LD A, 13     ;d=+13 (IX+13) World posY
    LD (reconfigure_marker_1+2), A
    LD A, 1     ;North Wall
    LD (reconfigure_marker_4+1), A
    LD HL, reconfigure_marker_5+1
    LD BC, -26      ;Tile offset North
    LD (HL), C
    INC HL
    LD (HL), B
    LD A, 4     ;South wall
    LD (reconfigure_marker_6+1), A
    LD A, $0D       ;DEC C
    LD (reconfigure_marker_7), A
    RET

    
ConfigureMove_SOUTH:
    LD A, 1     ;d=+1 (IX+1) Screen posY
    LD (reconfigure_marker_2+2), A
    LD (skip_bot_movement_frame-1), A
    LD (reconfigure_marker_3+2), A
    LD A, $34   ;INC (IX+d)
    LD (skip_bot_movement_frame-2), A
    LD (reconfigure_marker_1+1), A 
    LD (reconfigure_marker_2+1), A
    LD A, $35   ;DEC (IX+d)
    LD (reconfigure_marker_3+1), A
    LD A, 13     ;d=+13 (IX+13) World posY
    LD (reconfigure_marker_1+2), A
    LD A, 4     ;South Wall
    LD (reconfigure_marker_4+1), A
    LD HL, reconfigure_marker_5+1
    LD BC, 26      ;Tile offset South
    LD (HL), C
    INC HL
    LD (HL), B
    LD A, 1     ;North wall
    LD (reconfigure_marker_6+1), A
    LD A, $0C       ;INC C
    LD (reconfigure_marker_7), A
    RET

ConfigureMove_WEST:
    LD A, 0     ;d=+1 (IX+1) Screen posX
    LD (reconfigure_marker_2+2), A
    LD (skip_bot_movement_frame-1), A
    LD (reconfigure_marker_3+2), A
    LD A, $35   ;DEC (IX+d)
    LD (skip_bot_movement_frame-2), A
    LD (reconfigure_marker_1+1), A 
    LD (reconfigure_marker_2+1), A
    LD A, $34   ;INC (IX+d)
    LD (reconfigure_marker_3+1), A
    LD A, 12     ;d=+13 (IX+13) World posY
    LD (reconfigure_marker_1+2), A
    LD A, 8     ;WEST Wall
    LD (reconfigure_marker_4+1), A
    LD HL, reconfigure_marker_5+1
    LD BC, -1      ;Tile offset West
    LD (HL), C
    INC HL
    LD (HL), B
    LD A, 2     ;East wall
    LD (reconfigure_marker_6+1), A
    LD A, $05       ;DEC B
    LD (reconfigure_marker_7), A
    RET

ConfigureMove_EAST:
    LD A, 0     ;d=+1 (IX+1) Screen posX
    LD (reconfigure_marker_2+2), A
    LD (skip_bot_movement_frame-1), A
    LD (reconfigure_marker_3+2), A
    LD A, $34   ;INC (IX+d)
    LD (skip_bot_movement_frame-2), A
    LD (reconfigure_marker_1+1), A 
    LD (reconfigure_marker_2+1), A
    LD A, $35   ;DEC (IX+d)
    LD (reconfigure_marker_3+1), A
    LD A, 12     ;d=+13 (IX+13) World posY
    LD (reconfigure_marker_1+2), A
    LD A, 2     ;EAST Wall
    LD (reconfigure_marker_4+1), A
    LD HL, reconfigure_marker_5+1
    LD BC, 1      ;Tile offset EAST
    LD (HL), C
    INC HL
    LD (HL), B
    LD A, 8     ;East wall
    LD (reconfigure_marker_6+1), A
    LD A, $04       ;DEC B
    LD (reconfigure_marker_7), A
    RET

;IX=Player
MoveRobot_ANYWHERE:
    LD HL, FX_Move
    CALL PlaySoundFX
    LD A, (IX+12)
    CP 30
    RET Z       ;if PlayerPosx=30 means Player is dead!
    LD HL, MovingBotsCount
    LD (HL), 1
    INC HL
    LD A, IXL
    LD (HL), A
    INC HL
    LD A, IXH
    LD (HL), A          ;First player pushed to Buffer

    PUSH IX
    CALL PrepareMoveBot_North
    ;MovingBotsBuffer is now filled with all robots involved and blocked markers are set (0 or NZ)

    LD A, (IX+10)   ;Blocker of Player's Bot
    AND A
    JR NZ, animate_blocked_movement

    LD HL, MovingBotsBuffer-1
    LD B, (HL)      ;Count of bots moving
    XOR A
 mul_frames_loop:   
    ADD A, 8
    DJNZ mul_frames_loop
    ADD A, 16
    LD B, A         ;B=Frames count
    LD (exec_movement_bots_loop-1), A
 exec_movement_loop:
    PUSH BC
    LD HL, MovingBotsBuffer-1
    LD B, (HL)      ;Count of bots moving
    INC HL
    LD C, 24        ;Reprogrammed!
 exec_movement_bots_loop:
        LD A, (HL)
        LD IXL, A
        INC HL
        LD A, (HL)
        LD IXH, A       ;HL points to current bot
        INC HL

        EX (SP), HL     ;Get frame loop counter from stack...
        LD A, H     
        EX (SP), HL     ;Exchange back
        DEC A
        CP C            ;Idle-LoopCounter
        JR NC, skip_bot_movement_frame
        ADD A, 24
        CP C
        JR C, skip_bot_movement_frame
        DEC (IX+1)      ;Move bot North                         REPROGRAM
 skip_bot_movement_frame:
        LD A, -8
        ADD A, C
        LD C, A         ;C=Idlepre
        DJNZ exec_movement_bots_loop
    CALL Put_All_Robots
    CALL HALT_Animation
    POP BC
    DJNZ exec_movement_loop

;----Update world position
    LD HL, MovingBotsBuffer-1
    LD C, (HL)      ;Count of bots moving
    INC HL
 exec_movement_bots_loop2:
    LD A, (HL)
    LD IXL, A
    INC HL
    LD A, (HL)
    LD IXH, A       ;HL points to current bot
    INC HL
 reconfigure_marker_1:   
    DEC (IX+13)      ;Move bot North                         REPROGRAM
    DEC C
    JR NZ, exec_movement_bots_loop2
    CALL ResetAllBlockMarkers
    POP IX
    JP CheckDeath_ALL

animate_blocked_movement:
    LD HL, MovingBotsBuffer-1
    LD B, (HL)      ;Count of bots moving
    XOR A
 mul_blocked_frames_loop:   
    ADD A, 8
    DJNZ mul_blocked_frames_loop
    ADD A, -4
    LD B, A         ;B=Frames count
    LD (exec_blocked_bots_loop-1), A
    LD (exec_blocked_bots_loop2-1), A
    INC A
    LD (blocked_reverse_addr+1), A    
 exec_blocked_loop:
    PUSH BC
    LD HL, MovingBotsBuffer-1
    LD B, (HL)      ;Count of bots moving
    INC HL
    LD C, 4        ;Reprogrammed!
 exec_blocked_bots_loop:
        LD A, (HL)
        LD IXL, A
        INC HL
        LD A, (HL)
        LD IXH, A       ;HL points to current bot
        INC HL

        EX (SP), HL     ;Get frame loop counter from stack...
        LD A, H     
        EX (SP), HL     ;Exchange back
        DEC A
        CP C            ;Idle-LoopCounter
        JR NC, skip_bot_blocked_frame
        ADD A, 24
        CP C
        JR C, skip_bot_blocked_frame
reconfigure_marker_2:
        DEC (IX+1)      ;Move bot North                         REPROGRAM
 skip_bot_blocked_frame:
        LD A, -8        ;Idle counter adjust for next bot
        ADD A, C
        LD C, A         ;C=Idlepre
        DJNZ exec_blocked_bots_loop
    CALL Put_All_Robots
    CALL HALT_Animation
    POP BC
    DJNZ exec_blocked_loop

    LD B, 1         ;this time, B counts up
 exec_blocked_loop2:
    PUSH BC
    LD HL, MovingBotsBuffer-1
    LD B, (HL)      ;Count of bots moving
    INC HL
    LD C, 4        ;Reprogrammed!
 exec_blocked_bots_loop2:
        LD A, (HL)
        LD IXL, A
        INC HL
        LD A, (HL)
        LD IXH, A       ;HL points to current bot
        INC HL

        EX (SP), HL     ;Get frame loop counter from stack...
        LD A, H     
        EX (SP), HL     ;Exchange back
        DEC A
        CP C            ;Idle-LoopCounter
        JR NC, skip_bot_blocked_frame2
        ADD A, 24
        CP C
        JR C, skip_bot_blocked_frame2
reconfigure_marker_3:
        INC (IX+1)      ;Move bot North                         REPROGRAM
 skip_bot_blocked_frame2:
        LD A, -8        ;Idle counter adjust for next bot
        ADD A, C
        LD C, A         ;C=Idlepre
        DJNZ exec_blocked_bots_loop2
    CALL Put_All_Robots
    CALL HALT_Animation
    POP BC
    INC B
  blocked_reverse_addr:
    LD A, 4         ;Reprogrammed
    CP B
    JR NZ, exec_blocked_loop2
    CALL ResetAllBlockMarkers
    POP IX
    RET

;IX=Player
PrepareMoveBot_North:
    ;Bot World Coordinates to playfield tile
    CALL calculate_World_Position_DE
    ;Playfield tile: Check North Wall?
    LD A, (DE)      ;A=Tile Index
    LD B, D         ;Store WorldMap Position in BC
    LD C, E
    ADD A, A
    LD E, A
    LD D, 0
    LD HL, TileFlags
    ADD HL, DE
    LD A, (HL)      ;A=Tile Flags
reconfigure_marker_4:
    AND 1           ;North Flag set?                        REPROGRAM
    JR NZ, Movement_blocked
reconfigure_marker_5:
    LD HL, -26      ;Offset to northern Tile                REPROGRAM
    ADD HL, BC      ;HL points to northern Tile
    LD A, (HL)      ;A=Tile Flags
    ADD A, A
    LD E, A
    LD D, 0
    LD HL, TileFlags
    ADD HL, DE
    LD A, (HL)      ;A=Tile Flags
reconfigure_marker_6:
    AND 4           ;South Flag set?                        REPROGRAM
    JR NZ, Movement_blocked
    LD B, (IX+12)
    LD C, (IX+13)
reconfigure_marker_7:
    DEC C               ;YPos-1 is Norther Tile position Y  REPROGRAM
    LD IY, Player1State
    CALL CheckFieldOccupiedByPlayer
    JR Z, Field_occupied
    LD IY, Player2State
    CALL CheckFieldOccupiedByPlayer
    JR Z, Field_occupied
    LD IY, Player3State
    CALL CheckFieldOccupiedByPlayer
    JR Z, Field_occupied
    RET     ;all Ok: No walls and field clear
 Field_occupied:             ;IY=Player that occupies target field
    PUSH IX                 ;Push Current player
    PUSH IY
    POP IX                  ;Colliding player is now being checked for movement
    LD HL, MovingBotsCount
    LD A, (HL)
    INC (HL)                ;Count++
    INC HL
    ADD A, A
    LD E, A
    LD D, 0
    ADD HL, DE              ;HL points to insert position in buffer
    LD A, IXL
    LD (HL), A
    INC HL
    LD A, IXH
    LD (HL), A              ;IX Player is inscribed in buffer
    CALL PrepareMoveBot_North
    LD A, (IX+10)           ;Is that payer's movement blocked..?
    POP IX
Movement_blocked:
    LD (IX+10), A     ;Set Blocked marker A is either NZ or inherits from colliding bot
    RET

;BC=XY world Pos
;IY=Player to check
;Returns Z Flag set if position of Player IY matches BC
CheckFieldOccupiedByPlayer:
    LD A, B
    CP (IY+12)
    RET NZ      ;Player is somwhere else
    LD A, C
    CP (IY+13)  
    RET


