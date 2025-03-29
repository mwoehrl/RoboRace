;Memory Variables
FadeAwayPattern:
    defb %11101111
    defb %11011101
    defb %11010110
    defb %10101010
    defb %10010010
    defb %10001000
    defb %00001000
    defb %00000001
PlayerColors:
    defb 6,8,4,5,12,3
PlayerSignatureSounds:
    defw FX_Signature2,FX_Signature1,FX_Signature3
FlagColors:
    defb 2,8,7,15
PlayerArray:
    defw Player1State
    defw Player2State
    defw Player3State
PlayerSortingArray:
    defw Player1State
    defw Player2State
    defw Player3State

ShadowPlayerBuffer EQU FileStart

ShadowPlayerArray:
    defw ShadowPlayerBuffer
    defw ShadowPlayerBuffer + (Player2State-Player1State)
    defw ShadowPlayerBuffer + 2 * (Player2State-Player1State)

Player1State:
    defb 132        ; +0 Bot XPos
    defb 131        ; +1 Bot YPos
    defb 32         ; +2 Bot Direction
    defb 4          ; +3 Bot Primary Color
    defb 5          ; +4 Bot Secondary Color
    defb 0          ; +5 Sprite Plane1
    defb 15         ; +6 Pseudosprite Char
    defw 0          ; +7 restore Background Position
    defb 0          ; +9 RestoreChar 1
    defb 0          ; +10 Mark Blocked for Conveyor movement
    defb 127        ; +11 Cached Direction
    defb 6         ; +12 World Position X
    defb 7         ; +13 World Position Y
    defb 7          ;+14 Hit Points
    defw Player1CardRegister     ;+15,16 Pointer to Card Register
    defw Player1CardStack        ;+17,18 Pointer to Card Stack
    defb 6          ;+19 respawn positionX 
    defb 7          ;+20 respawn positionY
    defb 0          ;+21 Shutdown announced
    defb 0          ;+22 Current Flag
    defb 4          ;+23 Portrait Char
    defb 0          ;+24 Joystick 1
    defb 1          ;+25 Lives
Player2State:
    defb 36          ;Bot XPos
    defb 131+24        ;Bot YPos
    defb 0         ;Bot Direction
    defb 6         ;Bot Primary Color
    defb 8         ;Bot Secondary Color
    defb 2          ;Sprite Plane1
    defb 15          ;Pseudosprite Char
    defw 0         ; +7 restore Background Position
    defb 0          ; +9 RestoreChar 1
    defb 0          ; +10 Mark Blocked for Conveyor movement
    defb 127          ; +11 Cached Direction
    defb 2          ; +12 World Position X
    defb 7          ; +13 World Position Y
    defb 9          ;+14 Hit Points
    defw Player2CardRegister     ;+15,16 Pointer to Card Register
    defw Player2CardStack        ;+17,18 Pointer to Card Stack
    defb 2          ;+19 respawn positionX 
    defb 7          ;+20 respawn positionY
    defb 0          ;+21 Shutdown announced
    defb 0          ;+22 Current Flag
    defb 2         ;+23 Portrait Char
    defb 255          ;+24 Keyboard
    defb 3          ;+25 Lives
Player3State:
    defb 60         ;Bot XPos
    defb 155        ;Bot YPos
    defb 16         ;Bot Direction
    defb 12         ;Bot Primary Color
    defb 3         ;Bot Secondary Color
    defb 4         ;Sprite Plane1
    defb 15       ;Pseudosprite Char
    defw 0         ; +7 restore Background Position
    defb 0         ; +9 RestoreChar 1
    defb 0         ; +10 Mark Blocked for Conveyor movement
    defb 127       ; +11 Cached Direction
    defb 11          ; +12 World Position X
    defb 6          ; +13 World Position Y
    defb 5          ;+14 Hit Points
    defw Player3CardRegister     ;+15,16 Pointer to Card Register
    defw Player3CardStack        ;+17,18 Pointer to Card Stack
    defb 11          ;+19 respawn positionX 
    defb 6          ;+20 respawn positionY
    defb 0          ;+21 Shutdown announced
    defb 0          ;+22 Current Flag
    defb 6          ;+23 Portrait Char
    defb 255          ;+24 255=Computer AI
    defb 3          ;+25 Lives
PlayerInfo_END:

defw 0
HALT_Animation_off:
    PUSH BC
    LD BC, 00107h   ;Reg7 Value 00h  (Background Color 1=Black)
    CALL VDPWRT
    EI
    HALT
    DI
    LD BC, 00D07h   ;Reg7 Value 00h  (Background Color D=Magenta)
    LD A, (SpriteSaveMode)
    AND A
    JR Z, spritesavemodeColor
    LD B, 5    
spritesavemodeColor:
    CALL VDPWRT
    POP BC
    RET

HALT_Animation:
    PUSH BC
    PUSH DE
    PUSH HL
    PUSH IX
    CALL HandleMusic
    POP IX
    POP HL
    POP DE
    POP BC
    IN A, (VDP_PORT_INTACK)    ;Check if Interrupt is already triggered
    AND A
    JP M, HALT_Callback

    EI
    HALT
    DI
HALT_Callback:
    JP HALT_Animation_ret
HALT_Animation_ret:    
    RET

Start_The_Game:
    LD SP, InitialSP
    LD BC, 0A201h   ;Blackout for transistion
    CALL VDPWRT

    LD A, R
    LD (RandomSeed), A
    LD A, R
    LD (RandomSeed+1), A

    CALL Hide_ALL_Sprites
    CALL HALT_Animation
    
    LD HL, CharPatterns     ;Chars 2k to Address $800 in VRAM
    LD BC, CharColors-CharPatterns
    LD DE, $0000
    CALL COPY_RAM_TO_VRAM
    CALL HALT_Animation
    LD HL, CharColors     ;Colors 2k to Address 2800h in VRAM
    LD BC, CharColors-CharPatterns
    LD DE, $2000
    CALL COPY_RAM_TO_VRAM_compressed
    CALL HALT_Animation
    LD HL, CharPatterns     ;Chars 2k to Address $800 in VRAM
    LD BC, CharColors-CharPatterns
    LD DE, $0800
    CALL COPY_RAM_TO_VRAM
    CALL HALT_Animation
    LD HL, CharColors     ;Colors 2k to Address 2800h in VRAM
    LD BC, CharColors-CharPatterns
    LD DE, $2800
    CALL COPY_RAM_TO_VRAM_compressed
    CALL HALT_Animation

;Reconfigure Game Mode and limits:
    XOR A
    LD (TitleMode), A
    LD A, 190
    LD (SpriteLimit1), A
    LD A, 24
    LD (SpriteLimit2), A

    LD A, 4         ;Reprogram Playfield drawing to fullscreen
    LD (playfield_reprogram1+1), A
    LD A, 26*3 - 32
    LD (playfield_reprogram2+1), A

    CALL InitMap

    CALL HALT_Animation
    LD BC, 0E201h   ;Screen ON
    CALL VDPWRT

    LD IYL, 0
 scroll_to_flags_loop:   
    PUSH IY
    CALL ScrollToFlag
    POP IY
    INC IYL
    LD A, (FlagCount)
    CP IYL
    JR NZ, scroll_to_flags_loop

GameStart:
    LD A, 3         ;Reprogram Playfield drawing to 24 Cols
    LD (playfield_reprogram1+1), A
    LD A, 26*3 - 24
    LD (playfield_reprogram2+1), A
    LD A, (MapScroll_X_max)
    ADD A, 8
    LD (MapScroll_X_max), A
    CALL PaintBlankSidebar

    CALL RespawnDeadBots
    LD A, 9                 ;Start with 9HP (no respawn malus on first Bot)
    LD (Player1State+14), A
    LD (Player2State+14), A
    LD (Player3State+14), A

    LD A, 255
    LD (MapScrolled), A
GameLoop:
    CALL ProgrammingPhase
    CALL PaintSidebarExecutePhase
    LD B, 5
 register_phase_loop:
    PUSH BC
    CALL NextPhase
    POP BC
    DJNZ register_phase_loop
    
    LD IX, Player1State     ;Check if at least 2 players are in the game
    XOR A
    CP (IX+25)
    ADC A, A
    LD B, A
    XOR A
    CP (IX+(25+Player2State-Player1State))
    ADC A, B
    LD B, A
    XOR A
    CP (IX+(25+Player3State-Player1State))
    ADC A, B
    CP 2
    CALL C, Init_Winner_Screen
    JR GameLoop

FreeScroolLoop:
    LD A, (MapScrolled)
    AND A
    JR Z, no_map_refresh
    CALL PaintMap_from_buffer
    XOR A
    LD (MapScrolled), A
    JR gameloop_refresh_done
no_map_refresh:
    CALL Put_All_Robots
gameloop_refresh_done:
    CALL HALT_Animation
    CALL GET_JOYSTICK_TRIGGER_ANY
    RET Z
    CALL GET_JOYSTICK_INPUT_ANY     ;A=0000RLDU
    RRA
    PUSH AF
    JR NC, Scroll_up
    RRA
    JR NC, Scroll_down
 gameloop_sideways:   
    POP AF
    RRA
    RRA
    JR NC, Scroll_left
    RRA
    JR NC, Scroll_right
    JR FreeScroolLoop
Scroll_up:
    LD HL, MapScroll_Y
    DEC (HL)
    INC HL
    LD (HL), 255
    JR gameloop_sideways
Scroll_down:
    LD HL, MapScroll_Y
    INC (HL)
    INC HL
    LD (HL), 255
    JR gameloop_sideways
Scroll_left:
    LD HL, MapScroll_X
    DEC (HL)
    JR Scroll_done
Scroll_right:
    LD HL, MapScroll_X
    INC (HL)
Scroll_done:
    LD A, 255
    LD (MapScrolled), A
    JR FreeScroolLoop

ProgrammingPhase:
    XOR A
    LD (RegisterPhaseNr), A
    CALL RespawnDeadBots
    CALL DealCards
    
    LD IX, Player1State
    CALL Switch_AI_or_Manual
    LD IX, Player2State
    CALL Switch_AI_or_Manual
    LD IX, Player3State
Switch_AI_or_Manual:
    LD A, (IX+25)
    AND A
    RET Z   ;If 0 lives, directly Return
    LD A, (IX+24)
    CP 255
    JP Z, AI_Find_Best_5Cards
    JP ProgrammingLoop

NextPhase:
    CALL RegisterPhase
    CALL FactoryPhase
    LD HL, RegisterPhaseNr
    INC (HL)
    CALL PaintSidebarExecutePhase
    RET

RegisterPhase:
    ;Sorting players: Compare 1vx2, 1vs3, 2vs3
    LD IX, (PlayerSortingArray + 0)
    LD IY, (PlayerSortingArray + 2)
    CALL CompareCardPrio
    LD HL, PlayerSortingArray + 0
    LD DE, 2
    CALL NC, SwitchPlayers_Prio

    LD IX, (PlayerSortingArray + 0)
    LD IY, (PlayerSortingArray + 4)
    CALL CompareCardPrio
    LD HL, PlayerSortingArray + 0
    LD DE, 4
    CALL NC, SwitchPlayers_Prio

    LD IX, (PlayerSortingArray + 2)
    LD IY, (PlayerSortingArray + 4)
    CALL CompareCardPrio
    LD HL, PlayerSortingArray + 2
    LD DE, 2
    CALL NC, SwitchPlayers_Prio

    LD IX, (PlayerSortingArray + 0)
    CALL ExecutePlayerCard 
    LD IX, (PlayerSortingArray + 2)
    CALL ExecutePlayerCard 
    LD IX, (PlayerSortingArray + 4)
    JP ExecutePlayerCard

;IX=PlayerA
;IY=PlayerB
CompareCardPrio:
    PUSH IX         ;PlayerA onto stack
    CALL Load_Players_CurrentCard_to_A
    INC HL
    LD B, (HL)          ;B=PlayerA Prio
    PUSH IY
    POP IX
    CALL Load_Players_CurrentCard_to_A
    INC HL
    LD A, (HL)      ;A=PlayerB Prio
    POP IX          ;IX=PlayerA
    CP B            ;Sets Carry which is comparison result
    RET

;HL=PlayerA
;DE=Offset
SwitchPlayers_Prio:
    PUSH HL
    LD C, (HL)
    INC HL
    LD B, (HL)      ;BC contains A
    DEC HL
    ADD HL, DE
    LD E, (HL)
    INC HL
    LD D, (HL)      ;DE contains B
    LD (HL), B
    DEC HL
    LD (HL), C
    POP HL
    LD (HL), E
    INC HL
    LD (HL), D
    RET

FactoryPhase:
    CALL BoardPhase_ExpressConveyors
    CALL AfterEachFactoryPhase
    CALL BoardPhase_Conveyors
    CALL AfterEachFactoryPhase
    CALL BoardPhase_Turntables
    CALL AfterEachFactoryPhase
    CALL BoardPhase_Lasers
    CALL AfterEachFactoryPhase
    CALL BoardPhase_Bot_Lasers
    CALL AfterEachFactoryPhase
    CALL BoardPhase_Repairs
    JP AfterEachFactoryPhase

AfterEachFactoryPhase:
    CALL PaintSidebarExecutePhase
    CALL CheckDeath_ALL
Short_Delay:
    LD A, (ShortDelayDuration)
    LD B, A
 factoryPhase_delayloop:
    PUSH BC
    CALL Put_All_Robots
    POP BC
    CALL HALT_Animation
    DJNZ factoryPhase_delayloop
    RET

BoardPhase_Repairs:
    LD IX, Player1State
    CALL CheckPlayerRepair
    LD IX, Player2State
    CALL CheckPlayerRepair
    LD IX, Player3State
CheckPlayerRepair:
    CALL calculate_World_Position_DE
    LD A, (DE)      ;A=tile index
    ADD A, A
    LD D, 0
    LD E, A
    LD HL, TileFlags+1
    ADD HL, DE
    LD A, (HL)
    AND 16          ;Repair Trigger
    RET Z
    LD DE, TileActions- (TileFlags+1)
    ADD HL, DE      ;HL points to Tile Action
    LD E, (HL)
    INC HL
    LD D, (HL)
    EX DE, HL
    JP (HL)

CheckDeath_ALL:
    PUSH IX
    LD IX, Player1State
    CALL CheckDeath
    LD IX, Player2State
    CALL CheckDeath
    LD IX, Player3State
    CALL CheckDeath
    POP IX
    RET

;IX=Player
CheckDeath:
    LD A, (IX+12)    ;XPos, if 30 means dead already
    CP 30
    RET Z           ;Do nothing, Bot is already dead
    LD A, (IX+14)   ;Bot hit points
    AND A
    JP M, KillRobot ;If hitpoints are negative, kill!
    CALL calculate_World_Position_DE
    LD A, (DE)      ;A=tile index
    ADD A, A
    LD D, 0
    LD E, A
    LD HL, TileFlags
    ADD HL, DE
    LD A, (HL)
    AND 32          ;Flag flag
    JR NZ, CheckFlag
    LD A, (HL)
    AND 16          ;Pit Flag
    RET Z           ;Pit flag not set, Return
;IX=Player
KillRobot:
    CALL ScrollPlayerIntoCenter
    DEC (IX+25)     ;-1 Life
    LD HL, FX_Death
    CALL PlaySoundFX
    LD (IX+6), 1   ;Shutdown
    LD D, (IX+3)
    LD E, (IX+4)
    LD HL, FadeAwayPattern
    LD C, 8
 kill_animation_loop2:
    LD B, 8
    LD A, (HL)
    PUSH HL
 kill_animation_loop:
    PUSH BC
    INC (IX+2)        ;Rotate
    LD (IX+3), D
    LD (IX+4), E
    RLA
    JR C, killed_solid
    LD (IX+3), 0
    LD (IX+4), 0
 killed_solid:
    PUSH AF
    PUSH DE
    CALL PutRobot
    CALL HALT_Animation
    POP DE
    POP AF
    POP BC
    DJNZ kill_animation_loop
    POP HL
    INC HL
    DEC C
    JR NZ, kill_animation_loop2
    LD (IX+12), 30      ;X-Position=30 means dead!
    LD (IX+1), 240
    CALL PutRobot
    CALL PaintSidebarExecutePhase
    RET

;HL Points to tile Flags
CheckFlag:
    XOR A
    LD B, (HL)
    RL B
    RLA
    RL B
    RLA         ;A contains flag nr.
    CP (IX+22)  ;Equals current target flag?
    RET NZ      ;Wrong flag
    LD A, (IX+6)    ;Check if Shutdown
    CP 1
    RET Z           ;Shutdown Robot gets no flag
    ;Aquire Flag
    LD E, (IX+22)
    LD D, 0
    LD HL, FlagColors
    ADD HL, DE
    LD A, (HL)
    LD IYL, A
    INC (IX+22)     ;New Target Flag
    LD A, (IX+12)
    LD (IX+19), A
    LD A, (IX+13)
    LD (IX+20), A   ;New respawn point is saved at Flag pos
    LD HL, FlagSprite
    CALL AnimateBonusSprite
    LD A, (FlagCount)
    CP (IX+22)
    CALL Z, Init_Winner_Screen
    JP PaintSidebarExecutePhase

RespawnDeadBots:
    LD IX, Player1State
    CALL RespawnDeadBot
    LD IX, Player2State
    CALL RespawnDeadBot
    LD IX, Player3State
RespawnDeadBot:
    LD A, (IX+12)
    CP 30
    RET NZ  ;Not dead, dont respawn
    LD A, (IX+25)
    AND A
    RET Z           ;0 Lives, don't respawn
    LD (IX+14), 7   ;Respawned Bot gets 7 Hit points
    LD (IX+6),15    ;Respawed bot has white Pseudosprite
    LD (IX+21),0   ;Respawed bot has no shutdown announced
    LD B, (IX+19)
    LD C, (IX+20)
    CALL FindRespawnField
    LD (IX+12), B
    LD (IX+13), C
    CALL World_to_Screen_Coordinates

    LD D, (IX+3)
    LD E, (IX+4)
    LD (IX+3), 0    ;Make invisible before scroll
    LD (IX+4), 0
    PUSH DE
    CALL ScrollPlayerIntoCenter
    LD HL, FX_Spawn
    CALL PlaySoundFX    
    POP DE
    LD HL, FadeAwayPattern+7
    LD C, 8
 spawn_animation_loop2:
    LD B, 8
    LD A, (HL)
    PUSH HL
 spawn_animation_loop:
    PUSH BC
    LD (IX+3), D
    LD (IX+4), E
    RLA
    JR C, spawn_solid
    LD (IX+3), 0
    LD (IX+4), 0
 spawn_solid:
    PUSH AF
    PUSH DE
    CALL PutRobot
    CALL HALT_Animation
    POP DE
    POP AF
    POP BC
    DJNZ spawn_animation_loop
    POP HL
    DEC HL
    DEC C
    JR NZ, spawn_animation_loop2
    RET

;IX=Player
InitPlayer:
    XOR A
    LD (IX+12), 30          ;Initially Dead
    LD (IX+6), 1            ;Initially Shutdown
    LD (IX+14), 9           ;Hitpoints
    LD (IX+8), A            ;Pseudochar
    LD (IX+10), A           ;Blocker
    LD (IX+21), A
    LD (IX+22), A    
    LD A, 3
    LD (IX+25), A           ;Lives
    JP SetPlayerColorByPortrait

;BC=Field Candidate XY
FindRespawnField:
    LD IY, Player1State
    CALL CheckFieldOccupiedByPlayer
    JR Z, respanFieldOccupied
    LD IY, Player2State
    CALL CheckFieldOccupiedByPlayer
    JR Z, respanFieldOccupied
    LD IY, Player3State
    CALL CheckFieldOccupiedByPlayer
    JR Z, respanFieldOccupied
    ;Field is free of other players. Check if no pit or conveyor
    LD (IX+12), B
    LD (IX+13), C
    PUSH BC
    CALL calculate_World_Position_DE
    CALL CheckTileFlag          ;C=Flag byte of tile
    LD A, %00010000             ;No Pits!
    AND C
    POP BC
    RET Z  ;If none of the forbidden flags is set, Return!
 respanFieldOccupied:
    INC B  ;Try one to the right
    JR FindRespawnField

    




