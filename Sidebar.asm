SidebarRowPlain:
   defb 26,0,0,0,0,0,0,0

SidebarRowCards1:
   defb 26,0,32,34,33,32,34,33
SidebarRowCards2:
   defb 26,0,48,50,49,48,50,49

SidebarRowCards3:
   defb 26,0,0,0,0,32,34,33
SidebarRowCards4:
   defb 26,0,0,0,0,48,50,49

SidebarRowBots:
   defb 26,0,250,0,249,0,251,0
SidebarRowRegisters1:
   defb 26,32,34,42,34,42,34,33
SidebarRowRegisters2:
   defb 26,48,50,58,50,58,50,49

SidebarRowStatus1:
   defb 26,95,1,1,1,1,1,1
SidebarRowStatus2:
   defb 26,78,79,79,79,79,79,79

ButtonRow1_Map:
   defb 5,74,76,75
ButtonRow2_Map:
   defb 90,92,91
ButtonRow1_Play:
   defb 6,74,64,75
ButtonRow2_Play:
   defb 90,80,91
ButtonRow1_Shutdown:
   defb 7,74,65,75
ButtonRow2_Shutdown:
   defb 90,81,91

skip_dead_portrait:
   INC DE
   INC DE
   JR portraits_loop_nextPlayer

PaintSidebarExecutePhase:
   LD A, (TitleMode)
   AND A
   RET NZ

   CALL PaintHeaderField
   LD DE, $3800 + 0*32 + 24+2
   LD IX, Player1State
   LD B, 3
 execute_portraits_loop:
   PUSH BC
   LD A, (IX+25)
   AND A
   JR Z, skip_dead_portrait
   PUSH HL
   CALL PaintPlayerPortrait
   LD A, 32
   ADD A, E
   LD E, A
   CALL PaintTargetFlag
   LD HL, -63
   ADD HL, DE
   EX DE, HL
   POP HL
portraits_loop_nextPlayer:   
   LD BC, Player2State-Player1State
   ADD IX, BC
   POP BC
   DJNZ execute_portraits_loop

execute_portraits_done:
   LD DE, $3800 + 24 + 4 * 32
   LD B, 5
   LD C, 0
 paintSidebarExecutePhase_loop:
   PUSH BC
   PUSH DE
   CALL WritePlayerCardsToRow
   POP DE
   LD HL, SidebarRowPlain
   CALL PaintSidebarRow
   LD HL, SidebarRowRegisters1
   CALL PaintSidebarRow
   LD HL, SidebarRowRegisters2
   CALL PaintSidebarRow
   POP BC
   INC C
   DJNZ paintSidebarExecutePhase_loop

   LD B, 5
 paintSidebarExecutePhase_loop2:
   PUSH BC
   LD HL, SidebarRowPlain
   CALL PaintSidebarRow
   POP BC
   DJNZ paintSidebarExecutePhase_loop2
   RET

;C=0...4
WritePlayerCardsToRow:
   LD IYH, C
   LD A, (RegisterPhaseNr)
   CP C
   LD B, 32    ;Default char
   JR NZ, $+4 
   LD B, 43     ;Arrow Char
   LD A, C
   ADD A, A
   LD E, A
   LD D, 0
   LD HL, Player1CardRegister
   ADD HL, DE
   LD A, B
   LD DE, SidebarRowRegisters1+1
   LD BC, SidebarRowRegisters2+1
   LD (DE), A
   ADD A, 16
   LD (BC), A
   INC DE
   INC BC
   LD IX, Player1State
   CALL writeCard
   LD IX, Player2State
   CALL writeCard
   LD IX, Player3State
writeCard:
   LD A, (IX+12)
   CP 30    ;Dead?
   JR NZ, check_shutdown
   LD A, 66    ;X-Card
   JR write_card_set
 check_shutdown:
   LD A, (IX+6)
   CP 1    ;Shutdown?
   JR NZ, read_card
   LD A, 34    ;blank Card
   JR $+3
 read_card:
   LD A, (HL)
   LD IYL, A
   LD A, IYH
   CP  (IX+14)  ;Players hit points
   LD A, IYL
   JR C, $+4
   ADD A, 32
 write_card_set:
   LD (DE), A
   ADD A, 16
   LD (BC), A
   PUSH BC
   LD BC, 10
   ADD HL, BC
   POP BC
   INC BC
   INC BC
   INC DE
   INC DE
   RET

PaintHeaderField:
   LD DE, $3800 + 24 + 0  * 32
   LD B, 3 
 status_paint_loop:
   PUSH BC
   LD HL, SidebarRowStatus1
   CALL PaintSidebarRow
   POP BC
   DJNZ  status_paint_loop
   LD HL, SidebarRowStatus2
   JP PaintSidebarRow

;DE=VRamp addr.
PaintTargetFlag:
   LD L, 27
   LD B, 1
   CALL COPY_L_TO_VRAM_fast
   LD A, (IX+22)  ;Current Target Flag
   ADD A, 60      ;First Flag Char
   LD L, A
   INC DE
   LD B, 1
   JP COPY_L_TO_VRAM_fast

PaintSidebarProgrammPhase:
   CALL PaintHeaderField

   LD DE, $3800 + 24 + 4 * 32
   LD B, 5
 paintSidebarProgrammPhase_loop1:
   PUSH BC
   LD HL, SidebarRowCards1
   CALL PaintSidebarRow
   LD HL, SidebarRowCards2
   CALL PaintSidebarRow
   POP BC
   DJNZ paintSidebarProgrammPhase_loop1
   LD B, 4
 paintSidebarProgrammPhase_loop2:
   PUSH BC
   LD HL, SidebarRowCards3
   CALL PaintSidebarRow
   LD HL, SidebarRowCards4
   CALL PaintSidebarRow
   POP BC
   DJNZ paintSidebarProgrammPhase_loop2

   LD A, (ProgrammingCursorX)
   AND A
   LD A, (ProgrammingCursorY)
   JR NZ, cont_focus_frame     ;to prevent ugly frame behind button showing up
   CP 5
   JR Z, skip_focus_frame
cont_focus_frame:   
   LD DE, 64      ;2 rows
   CALL mult_a_de ;HL=Y*64
   LD A, (ProgrammingCursorX)
   LD B, A
   ADD A, B
   ADD A, B
   LD D, 0
   LD E, A     ;X*3
   ADD HL, DE 
   LD DE, $3800 + 24 + 2 + 4 * 32
   LD A, 30
   CALL PaintSingleChar
   LD HL, 2
   LD A, 31
   CALL PaintSingleChar
   LD HL, 30
   LD A, 46
   CALL PaintSingleChar
   LD HL, 2
   LD A, 47
   CALL PaintSingleChar
 skip_focus_frame:
   LD DE, $3800 + 15 * 32 + 24 + 2
   LD HL, ButtonRow1_Map
   CALL PaintButton
   LD DE, $3800 + 17 * 32 + 24 + 2
   CALL PaintButton
   LD DE, $3800 + 19 * 32 + 24 + 2
   CALL PaintButton

   LD DE, $3800 + 1 * 32 + 24 + 3
   CALL PaintPlayerPortrait
   LD DE, $3800 + 2 * 32 + 24 + 5
   CALL PaintTargetFlag
   LD DE, $3800 + 0 * 32 + 24 + 2
   LD B, (IX+25)     ;Player's lives
   DEC B
   JR Z, skip_paint_lives
   LD L, 8
   CALL COPY_L_TO_VRAM_fast
skip_paint_lives:     
   LD DE, $3800 + 0 * 32 + 24 + 5
   LD A, (IX+22)     ;Player's flags
   AND A
   JR Z, skip_paint_flags
   LD L, 60
   LD B, A
   CALL COPY_L_TO_VRAM_Inc

skip_paint_flags:
   LD A, (IX+6)
   LD B, 1
   CP B
   JR NZ, skipShutdownMarker
   LD DE, $3800 + 1 * 32 + 24 + 2
   LD L, 29
   CALL COPY_L_TO_VRAM_fast
   CALL paint_lower_card
skipShutdownMarker:
   LD DE, $3800 + 22 * 32 + 24
   LD HL, SidebarRowPlain
   CALL PaintSidebarRow
   LD HL, SidebarRowPlain
   CALL PaintSidebarRow

   LD A, (IX+21)
   AND A
   RET NZ   ;Shutdown announced, don't paint the cards!
;Paint dealt cards
   LD DE, paintDealtCards_locked
   LD (damage_branch+1), DE
   LD DE, $3800 + 4 * 32 + 24 + 3
   LD L, (IX+15)
   LD H, (IX+16)  ;HL points to players CardRegister
   LD C, 5
   CALL paintDealtCards_loop1
   LD DE, paintDealtCards_X
   LD (damage_branch+1), DE
   LD DE, $3800 + 4 * 32 + 24 + 6
   LD L, (IX+17)
   LD H, (IX+18)  ;HL points to players CardRegister
   LD C, 9
 paintDealtCards_loop1:
   LD A, C
   LD (paintDealtCards_loop+3), A
 paintDealtCards_loop
   LD B, 1
   LD A, 9        ;Reprogrammed operator
   SUB C
   CP (IX+14)     ;Compare with Hit points
   PUSH HL
 damage_branch:  
   JP NC, paintDealtCards_locked
   CALL COPY_RAM_TO_VRAM_fast
 paintDealtCards_lower:  
   CALL paint_lower_card
   LD HL, 32
   ADD HL, DE
   EX DE, HL
   POP HL
   INC HL
   INC HL
   DEC C
   JR NZ, paintDealtCards_loop
   RET
paintDealtCards_X:
   LD A, 66
   JR $+5
paintDealtCards_locked:
   LD A, (HL)
   ADD A, 32
   LD L, A
   CALL COPY_L_TO_VRAM_fast
   JR paintDealtCards_lower

paint_lower_card:
   ADD A, 16      ;Last char for top of card + 16 is lower part of card
   LD L, A
   LD A, 32
   ADD A, E
   LD E, A
   LD B, 1
   JP COPY_L_TO_VRAM_fast


;HL points to row to paint
;DE points to VRAM Target addr.
PaintButton:
   LD B, (HL)
   INC HL
   LD A, (ProgrammingCursorY)
   CP B
   LD C, 74    ;normal button
   JR NZ, button_unfocussed
   LD A, (ProgrammingCursorX)
   AND A
   JR NZ, button_unfocussed
   LD C, 28    ;focussed button
button_unfocussed:
   LD (HL), C
   LD A, 16
   ADD A, C
   LD C, A
   LD B, 3
   CALL COPY_RAM_TO_VRAM_fast
   PUSH HL
   LD HL, 32
   ADD HL, DE
   EX DE, HL
   POP HL
   LD (HL), C
   LD B, 3
   JP COPY_RAM_TO_VRAM_fast

;HL=Step to add
;A=Char
PaintSingleChar:
   ADD HL, DE
   EX DE, HL
   LD L, A
   LD B, 1
   JP COPY_L_TO_VRAM_fast

;HL points to 8Bytes of memory top paint
PaintSidebarRow:
   LD B, 1
   CALL COPY_RAM_TO_VRAM_unrolled
   LD HL, 32
   ADD HL, DE
   EX DE, HL
   RET

ScrollToPlayerAndSignature:
   CALL ScrollPlayerIntoCenter
   LD E, (IX+23)     ;Players Portrait char
   LD HL, PlayerSignatureSounds-2
   LD D, 0
   ADD HL, DE    ;HL now points to Array position
   LD E, (HL)
   INC HL
   LD D, (HL)
   EX DE, HL
   JP PlaySoundFX

;IX=Player
ProgrammingLoop:
   XOR A
   LD (ProgrammingCursorY), A
   LD (MiniMapMode), A
   INC A
   LD (ProgrammingCursorX), A
   LD (IX+6), 15      ;Ready color

   LD A, (IX+21)
   AND A
   JR Z, not_shutdown
   LD (IX+6), 1      ;Shutdown color
   LD (IX+14), 9     ;Full Hitpoints
   XOR A
   LD (ProgrammingCursorX), A
   LD A, 5
   LD (ProgrammingCursorY), A
   CALL ScrollToPlayerAndSignature
   JP programmingLoop_loop_left
 not_shutdown:   
   CALL ScrollToPlayerAndSignature
 programmingLoop_loop_right:   
   CALL HALT_Animation
   CALL PaintSidebarProgrammPhase
   CALL PaintRobots
   CALL WaitDPadReleaseLoop
   LD B, (IX+24)
   CALL GET_JOYSTICK_TRIGGER
   CALL Z, PickCardFromPlayerStack
   LD B, (IX+24)
   CALL GET_JOYSTICK_INPUT     ;A=0000RLDU
   LD HL, ProgrammingCursorY
   RRA
   JR NC, programming_up_R
   RRA
   JR NC, programming_down_R
   RRA
   JR NC, programming_left_R
   JR programmingLoop_loop_right
 programming_up_R:
   LD A, (HL)
   DEC A
   JP M, programmingLoop_loop_right
   JR up_down_done_R
 programming_down_R:
   LD A, (HL)
   INC A
   CP 9     ;Max CursorY
   JR NC, programmingLoop_loop_right
 up_down_done_R
   LD (HL), A
   LD A, (CursorBlockerDuration)     ;Marker for WaitDPadRelease
   INC HL
   LD (HL), A
   JR programmingLoop_loop_right
 programming_left_R:
   LD A, (ProgrammingCursorY)
   CP 8
   JR NZ, $+6
   DEC A       ;YCursor = 7
   LD (ProgrammingCursorY), A
   XOR A
   LD (ProgrammingCursorX), A
   JP programmingLoop_loop_left

Shutdown_Pressed:
   LD C, 1  ;Shutdown announced!
   JR $+4
Play_Pressed:
   LD C, 0   ;No shutdown
   LD A, (IX+6)
   CP 1
   JR Z, program_check_done
   LD L, (IX+15)
   LD H, (IX+16)     ;HL Points to player's Register
   LD B, 5
 check_program_loop:
   LD A, (HL)
   CP 77             ;?-Card
   JR Z, findFreeStackSlot_error   ;Cancel, Programming not done!
   INC HL
   INC HL
   DJNZ check_program_loop
 program_check_done:  
   LD (IX+21), C  ;Write Shutdown only if sucessful check
   LD HL, FX_Select
   CALL PlaySoundFX
   CALL WaitButtonReleaseLoop   ;Returns from programming loop
   RET NZ      ;Return from programming loop for player.
   JR programmingLoop_loop_left

call_Freescroll:
   LD HL, FX_Select
   CALL PlaySoundFX
   CALL WaitButtonReleaseLoop
   JR Z, programmingLoop_loop_left
   PUSH IX
   CALL PaintMap_from_buffer
   XOR A
   LD (MiniMapMode), A
   CALL FreeScroolLoop
   POP IX
   CALL WaitButtonReleaseLoop
   JR programmingLoop_loop_left

RemoveCardFromRegister:
   LD A, (ProgrammingCursorY)
   CP 5  ;Map scroll
   JR Z, call_Freescroll
   CP 6
   JR Z, Play_Pressed                      ;Returns from Programming phase
   CP 7                 
   JR Z, Shutdown_Pressed
   
   LD B, 9
   LD L, (IX+17)
   LD H, (IX+18)
 findFreeStackSlot_loop:  
   LD A, (HL)
   CP 34    ;Blank Card
   JR Z, freeStackSlot_found
   INC HL
   INC HL
   DJNZ findFreeStackSlot_loop
   JR findFreeStackSlot_error ;No free slot
 freeStackSlot_found:
   LD B, H
   LD C, L     ;Copy found Slot pointer to BC
   LD A, (ProgrammingCursorY)
   CP (IX+14)
   JR NC, findFreeStackSlot_error
   ADD A, A
   LD D, 0
   LD E, A
   LD L, (IX+15)
   LD H, (IX+16)
   ADD HL, DE     ;HL points to Card on Player's Register
   LD A, (HL)
   CP 35
   JR C, findFreeStackSlot_error ;If Card < 35
   CP 42          
   JR NC, findFreeStackSlot_error ;If Card >= 42
   LD (BC), A     ;Write card to first free Register
   LD (HL), 77    ;Write ? card to Register
   LD HL, FX_Select
   JR findFreeStackSlot_done
findFreeStackSlot_error:
   LD HL, FX_Error
findFreeStackSlot_done:
   CALL PlaySoundFX
   CALL WaitButtonReleaseLoop

programmingLoop_loop_left:   
   CALL HALT_Animation
   CALL PaintSidebarProgrammPhase
   CALL PaintRobots
   CALL WaitDPadReleaseLoop
   LD B, (IX+24)
   CALL GET_JOYSTICK_TRIGGER
   JR Z, RemoveCardFromRegister
   LD B, (IX+24)
   CALL GET_JOYSTICK_INPUT     ;A=0000RLDU
   LD HL, ProgrammingCursorY
   RRA
   JR NC, programming_up
   RRA
   JR NC, programming_down
   RRA
   RRA
   JR NC, programming_right
   JR programmingLoop_loop_left
programming_up:
   LD A, (HL)
   DEC A
   JP M, programmingLoop_loop_left
   JR up_down_done
programming_down:
   LD A, (HL)
   INC A
   CP 8
   JR NC, programmingLoop_loop_left
 up_down_done:
   LD (HL), A
   LD A, (CursorBlockerDuration)     ;Marker for WaitDPadRelease
   INC HL
   LD (HL), A
   JR programmingLoop_loop_left
programming_right:
   LD A, 1
   LD (ProgrammingCursorX), A
   JP programmingLoop_loop_right

WaitDPadReleaseLoop:
   LD HL, CursorBlocker
waitDPadReleaseLoop_loop:
   LD A, (HL)
   AND A
   RET Z    ;If Marker not set do nothing
   DEC (HL)
   INC HL
   LD (HL), 5    ;We shall block, so next blocking is shorter
   DEC HL
   CALL HALT_Animation
   LD B, (IX+24)
   CALL GET_JOYSTICK_INPUT
   LD B, %00001111
   AND B
   CP B
   JR NZ, waitDPadReleaseLoop_loop
   XOR A
   LD (HL), A  ;Reset blocker
   INC HL
   LD A, 20          ;Released, next blocking is longer
   LD (HL), A
   RET

WaitButtonReleaseLoop:
   LD A, 50
   LD (CursorBlocker), A
WaitButtonReleaseLoop_loop:
   LD HL, CursorBlocker
   DEC (HL)
   JP Z, Show_MiniMap
   CALL HALT_Animation
   CALL PaintSidebarProgrammPhase
   LD B, (IX+24)
   CALL GET_JOYSTICK_TRIGGER
   RET NZ
   JR WaitButtonReleaseLoop_loop

PickCardFromPlayerStack:
   LD B, 5
   LD L, (IX+15)
   LD H, (IX+16)
 findFreeCardSlot_loop:  
   LD A, (HL)
   CP 77    ;?-Card
   JR Z, freeCardSlot_found
   INC HL
   INC HL
   DJNZ findFreeCardSlot_loop
   JR pickCard_error   ;No free slot
 freeCardSlot_found:
   LD B, H        
   LD C, L         ;Copy found Slot pointer to BC
   LD A, (ProgrammingCursorY)
   CP (IX+14)     ;Player's hit points
   JR NC, pickCard_error
   ADD A, A
   LD D, 0
   LD E, A
   LD L, (IX+17)  ;Card Stack of player
   LD H, (IX+18)
   ADD HL, DE     ;HL points to Card on Player's stack
   LD A, (HL)
   CP 35
   JR C, pickCard_error          ;If Card < 35
   CP 42          
   JR NC, pickCard_error         ;If Card >= 42
   LD (BC), A     ;Write card to first free Register
   LD (HL), 34    ;Write blank card to stack
   INC BC
   INC HL
   LD A, (HL)     ;Read Card Prio
   LD (BC), A     ;Write Card Prio
   LD HL, FX_Select
   JR pickCard_playsound
pickCard_error:
   LD HL, FX_Error
pickCard_playsound:
   CALL PlaySoundFX
   JP WaitButtonReleaseLoop

PaintBlankSidebar:
   LD DE, $3800 + 24
   LD B, 24
 paintBlankSidebar_loop: 
   PUSH BC
   LD HL, SidebarRowPlain
   CALL PaintSidebarRow
   POP BC
   DJNZ paintBlankSidebar_loop
   RET

Show_MiniMap:
   LD HL, MiniMapMode
   LD A, (HL)
   AND A
   JR NZ, Show_Normal_Map
   CALL PaintMiniMap
   LD HL, FX_Select
   CALL PlaySoundFX
   JR wait_release_loop
Show_Normal_Map:
   LD (HL), 0
   PUSH IX
   CALL PaintMap_from_buffer
   POP IX
   LD HL, FX_Select
   CALL PlaySoundFX
wait_release_loop:
   CALL HALT_Animation
   LD B, (IX+24)
   CALL GET_JOYSTICK_TRIGGER
   JR NZ, Show_miniMap_done
   JR wait_release_loop
Show_miniMap_done:
   SUB A    ;Set Zero Flag to prevent leaving programming phase after returning from minimap if it was triggered on OK button
   RET

PaintRobots:
   PUSH IX
   LD A, (MiniMapMode)
   AND A
   JR Z, PaintBigRobots

   LD HL, FrameCounter
   INC (HL)

   LD HL, MapScroll_Y_max
   CALL MiniRobots_XY_Offset   
   LD C, B
   DEC HL
   CALL MiniRobots_XY_Offset   

   LD IX, Player1State
   CALL Put_Minibot
   LD IX, Player2State
   CALL Put_Minibot
   LD IX, Player3State
   CALL Put_Minibot
   JR PaintRobots_done
PaintBigRobots:
   CALL Put_All_Robots
PaintRobots_done:
   POP IX
   RET

MiniRobots_XY_Offset:
   LD A, (HL)
   CP 18
   LD B, 36
   RET Z
   LD B, -12
   RET

