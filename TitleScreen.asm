MenuText1:
    defb 'Players', 0
MenuText2:
    defb 'Map', 0
MenuText3:
    defb 'Flags', 0
MenuText4:
    defb 'Lasers', 0
MenuWidths:
    defb 9, 12, 7, 6

Input_AI:
    defb 'Computer', 0
Input_Keyboard:
    defb 'Keyboard', 0
Input_Joystick:
    defb 'GamePad1', 0
Input_Joystick2:
    defb 'GamePad2', 0

ShowTitleBanner:
    LD HL, TitleBitmap     ;Chars 2k to Address 0 in VRAM
    LD BC, 2048
    LD DE, 0
    CALL COPY_RAM_TO_VRAM
    LD HL, TitleBitmap + 2048
    LD BC, 2048
    LD DE, $2000
    CALL COPY_RAM_TO_VRAM_compressed
    LD DE, $3800
    XOR A
    LD B, A
    LD L, A
    JP COPY_L_TO_VRAM_Inc

TitleStart:
    LD BC, 0A201h   ;Screen OFF
    CALL VDPWRT

    LD HL, CharPatterns     ;Chars 2k to Address $800 in VRAM
    LD BC, CharColors-CharPatterns
    LD DE, $0800
    CALL COPY_RAM_TO_VRAM
    LD HL, CharColors     ;Colors 2k to Address 2800h in VRAM
    LD BC, CharColors-CharPatterns
    LD DE, $2800
    CALL COPY_RAM_TO_VRAM_compressed
    LD HL, CharPatterns     ;Chars 2k to Address $1000 in VRAM
    LD BC, CharColors-CharPatterns
    LD DE, $1000
    CALL COPY_RAM_TO_VRAM
    LD HL, CharColors     ;Colors 2k to Address 3000h in VRAM
    LD BC, CharColors-CharPatterns
    LD DE, $3000
    CALL COPY_RAM_TO_VRAM_compressed

    CALL Hide_ALL_Sprites
    XOR A
    LD (ProgrammingCursorY), A
    LD (GameStartMarker), A
    INC A
    LD (TitleMode), A
    LD A, 232
    LD (SpriteLimit1), A
    LD A, 31
    LD (SpriteLimit2), A

    LD HL, IntroSong
    CALL Switch_music
    CALL ShowTitleBanner

    LD HL, MenuCharPatterns
    LD DE, $800
    LD BC, 89*8
    CALL COPY_RAM_TO_VRAM
    LD HL, MenuCharColors
    LD DE, $2800
    LD BC, 256
    CALL COPY_RAM_TO_VRAM_compressed

    LD D, 58
WriteMenuColors_loop:
    PUSH HL
    INC B
    CALL Copy_ram_unrolled_NO_VAddr
    POP HL
    DEC D
    JR NZ, WriteMenuColors_loop

    LD DE, $3900
    LD L, 0
    LD B, 0
    CALL COPY_L_TO_VRAM_fast

    LD DE, $3800+ 32*10 + 6
    LD HL, MenuText1                    ;Flags
    CALL WRITE_String

    LD DE, $3800+ 32*11 + 10
    LD HL, MenuText2                    ;Map
    CALL WRITE_String

    LD DE, $3800+ 32*12 + 8
    LD HL, MenuText3                    ;Flags
    CALL WRITE_String

    LD DE, $3800+ 32*13 + 7
    LD HL, MenuText4                     ;Lasers
    CALL WRITE_String

    LD IX, Player1State
    LD DE, $3800+ 32*9 + 16
    CALL PaintPlayerPortrait

    LD IX, Player2State
    LD DE, $3800+ 32*9 + 18
    CALL PaintPlayerPortrait

    LD IX, Player3State
    LD DE, $3800+ 32*9 + 20
    CALL PaintPlayerPortrait

    CALL PaintMapTitle
    CALL PaintFlagCount    
    CALL PaintLasersOnOff

    LD HL, TitleScreen_Callback
    LD (HALT_Callback+1), HL

    CALL InitTitleMap
    CALL PaintTitleMap
    CALL PaintSeparationBar
    CALL World_to_Screen_Coordinates_ALL
    CALL Put_All_Robots

    LD BC, 0E201h   ;Screen ON
    CALL VDPWRT

TitleLoop:
    CALL RespawnDeadBots
    LD B, 5
 title_5_loop:
    PUSH BC
    CALL AllBotsRandomAction
    CALL FactoryPhase
    POP BC
    LD A, (GameStartMarker)
    AND A
    JP NZ, Start_The_Game
    DJNZ title_5_loop
    JR TitleLoop

PaintMapTitle:
    LD DE, $3800+ 32*11 + 16
    LD HL, (SelectedMap)
    JP WRITE_String

PaintFlagCount:
    LD DE, $3800+ 32*12 + 16
    LD L, 8                     ;Flag icons
    LD A, (FlagCount)
    LD B, A
    CALL COPY_L_TO_VRAM_Inc
    XOR A
    OUT (VDP_PORT_WRITE), A     ;blank char after last flag
    RET

String_On:
    defb 'on', 0
String_Off:
    defb 'off', 0

PaintLasersOnOff:
    LD DE, $3800+ 32*13 + 16
    LD A, (UseLasers)
    AND A
    JR Z, no_lasers_used
    LD HL, String_On
    JR no_lasers_done
no_lasers_used:
    LD HL, String_Off
no_lasers_done:
    CALL WRITE_String
    XOR A
    OUT (VDP_PORT_WRITE), A     ;blank char after last flag
    RET


leftright_row0:
    LD A, 4     
    LD (ProgrammingCursorX), A
    LD HL, Scroll_Players_Callback
    LD (HALT_Callback+1), HL
    JR mainmenu_input_done

;---------- Menu Loop -----------------
TitleScreen_Callback:
    CALL ANY_Callback_Start

    LD HL, ArrowsAnimationPhase
    LD B, (HL)
    INC HL
    LD A, (HL)
    ADD A, B
    CALL Z, positiveArrowsAnimation
    CP 15
    CALL Z, negativeArrowsAnimation
    DEC HL
    LD (HL), A
    SRA A
    SRA A
    ADD A, 12        ;Arrow Char
    LD C, A

    LD HL, ProgrammingCursorY
    CALL Calculate_VRam_CursorY
    CALL PaintMenuCursor
    LD A, 16
    ADD A, C
    LD C, A
    EX DE, HL
    CALL MenuWidth_to_A
    CALL PaintMenuCursor

    LD HL, CursorBlocker
    CALL GET_JOYSTICK_INPUT_ANY
    RRA
    JR NC, mainmenu_up
    RRA
    JR NC, mainmenu_down
    RRA
    JR NC, mainmenu_left
    RRA
    JR NC, mainmenu_right
    XOR A   ;if Dpad is released, release blocker
    LD (HL), A
 mainmenu_input_done:
    CALL GET_JOYSTICK_TRIGGER_ANY
    CALL Z, Scroll_Away_Menu1
    JP ANY_Callback_End


mainmenu_left:
    LD C, -1
    JR mainmenu_rightleft
mainmenu_right:
    LD C, 1
mainmenu_rightleft:
    LD A, (HL)
    AND A
    JR NZ, mainmenu_input_done      ;If Cursorblocker is set, do nothing
    DEC HL    ;HL= ProgrammingCursorY
    XOR A
    CP (HL)
    JR Z, leftright_row0
    INC A
    CP (HL)
    JR Z, leftright_row1
    INC A
    CP (HL)
    JR Z, leftright_row2
    JR leftright_row3

leftright_row1:
    LD HL, (SelectedMap)
    LD A, 1
    CP C
    JR Z, map_plus
    LD A, MapDefinition
    CP L
    JR Z, mainmenu_input_done       ;If we are already on 1st Position
    LD BC, -MapDefinitionSize
    JR map_add
map_plus:
    LD BC, MapDefinitionSize
map_add:
    ADD HL, BC
    LD A, (HL)  ;Check if we hit EOF marker
    AND A
    JR Z, mainmenu_input_done
    LD (SelectedMap), HL
    CALL PaintMapTitle
    JR menu_block_DPad

leftright_row2:         ;select flagCount
    LD A, (FlagCount)
    ADD A, C
    AND A
    JR Z, mainmenu_input_done
    CP 5
    JR Z, mainmenu_input_done
    LD (FlagCount), A
    CALL PaintFlagCount
    JR menu_block_DPad

leftright_row3:         ;switch lasers on/off
    LD A, (UseLasers)
    CPL
    LD (UseLasers), A
    CALL PaintLasersOnOff
    JR menu_block_DPad

mainmenu_up:
    LD BC, 255 * 256 + 255        ;ADD +1, CP -1
    JR mainmenu_updown
mainmenu_down:
    LD BC, 1 * 256 + 4        ;ADD -1; CP 4
mainmenu_updown:
    LD A, (HL)
    AND A
    JR NZ, mainmenu_input_done      ;If Cursorblocker is set, do nothing
    DEC HL    ;HL= ProgrammingCursorY
    LD A, (HL)
    ADD A, B
    CP C
    JR Z, mainmenu_input_done
    PUSH AF
    CALL Calculate_VRam_CursorY
    LD C, 0
    CALL PaintMenuCursor
    EX DE, HL
    CALL MenuWidth_to_A
    CALL PaintMenuCursor
    POP AF
    LD HL, ProgrammingCursorY
    LD (HL), A
 menu_block_DPad:   
    LD HL, ProgrammingCursorY
    LD A, (CursorBlockerDuration)     ;Marker for WaitDPadRelease
    INC HL
    LD (HL), A
    JP mainmenu_input_done

Calculate_VRam_CursorY:
    LD A, (HL)
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, A
    LD HL, $3800 + 32*10 + 14
    RET

;HL=VRAM Addr.
;A=add to HL
;C=Cursor char
PaintMenuCursor:
    LD E, A
    LD D, 0
    ADD HL, DE
    EX DE, HL
    LD B, 1
    LD L, C
    JP COPY_L_TO_VRAM_fast


positiveArrowsAnimation:
    LD (HL), 1
    RET
negativeArrowsAnimation:
    LD (HL), -1
    RET

AllBotsRandomAction:
    CALL RandomCard
    LD IX, Player1State
    CALL ExecutePlayerCard
    CALL RandomCard
    LD IX, Player2State
    CALL ExecutePlayerCard
    CALL RandomCard
    LD IX, Player3State
    JP ExecutePlayerCard

PaintTitleMap:
    LD HL, PlayfieldBuffer + 78*3*6+5
    LD DE, $3800 + 32*15

    LD B, 9
 paint_TitleMap_loop:   
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
    DJNZ paint_TitleMap_loop
    JP Put_All_Robots

PaintSeparationBar:
    LD DE, $3800 + 14*32+1
    LD L, 1
    LD B, 30
    JP COPY_L_TO_VRAM_fast

;DE=Top left Corner char pos
PaintPlayerPortrait:
    LD L, (IX+23)
;L=Top Left corner char
PaintPortraint:
    LD B, 2
    CALL COPY_L_TO_VRAM_Inc
    LD A, L
    ADD A, 16
    LD L, A
    LD A, 32
    ADD A, E
    LD E, A
    LD B, 2
    JP COPY_L_TO_VRAM_Inc

MenuWidth_to_A:
    PUSH HL
    LD A, (ProgrammingCursorY)
    LD D, 0
    LD E, A
    LD HL, MenuWidths
    ADD HL, DE
    LD A, (HL)
    POP HL
    RET

Mark_Start_The_Game:
    LD A, 1
    LD (GameStartMarker), A
    LD HL, HALT_Animation_ret
    LD (HALT_Callback+1), HL
    CALL silence_music
    LD HL, StartJingle
    JP PlaySoundFX

Scroll_Away_Menu1:
    LD B, 1
    CALL SMART_Preset_Player1Input   ;... in which case Player1 input method is preset to Joystick
    LD B, 2
    CALL SMART_Preset_Player1Input   ;... in which case Player1 input method is preset to Joystick
    LD A, 27
    LD (ProgrammingCursorY), A
    LD HL, Scroll_Away_Callback
    LD (HALT_Callback+1), HL
    RET

;B= stick 1/2
SMART_Preset_Player1Input:
    PUSH BC
    CALL GET_JOYSTICK_TRIGGER           ;Check if trigger came from Joystick...
    POP BC
    RET NZ
    LD HL, Player1State+24
    LD (HL), B
    RET    

Scroll_Players_Callback:
    CALL ANY_Callback_Start

    CALL GET_JOYSTICK_INPUT_ANY
    AND $0F
    XOR $0F
    JR NZ, ANY_Callback_End

    LD HL,ProgrammingCursorX
    LD A, (HL)
    DEC (HL)
    JR Z, Scroll_Players_Callback_done

    LD A, (HL)
    CP 2
    JR Z, Wrap_Around_Robot

    LD DE, $3800+9*32+15
    LD B, 1 
    LD IYH, 96 + 15
    CALL Scroll_Away_row_loop
    JR ANY_Callback_End

Scroll_Players_Callback_done:
    LD HL, TitleScreen_Callback
    LD (HALT_Callback+1), HL
    JR ANY_Callback_End

Wrap_Around_Robot:
    LD HL, Player1State + 23    ;Players Portrait
    LD E, (HL)
    LD BC, Player2State + 23
    LD A, (BC)
    LD (HL), A      ;Player 1 has shifted portait
    LD HL, Player3State + 23
    LD A, (HL)
    LD (BC), A      ;Player 2
    LD (HL), E

    LD DE, $3800+9*32+21
    LD IX, Player3State
    CALL PaintPlayerPortrait
    JR ANY_Callback_End

;IYH = Emax
;B=Row count
;DE points to start VRAM addr
Scroll_Away_row_loop:
    PUSH BC
    LD HL, SpriteTransformBuffer
    CALL COPY_VRAM_TO_RAM_unrolled
    LD (HL), B      ;B is 0
    LD HL, SpriteTransformBuffer+1
    LD (HL), B
    POP BC
    PUSH BC
    CALL COPY_RAM_TO_VRAM_unrolled
    LD A, 32
    ADD A, E
    CP IYH
    LD E, A
    POP BC
    JR NZ, Scroll_Away_row_loop
    RET

Scroll_Away_Callback:
    CALL ANY_Callback_Start

    LD DE, $3800+8*32
    LD B, 4
    LD IYH, 192
    CALL Scroll_Away_row_loop

    LD HL, ProgrammingCursorY
    DEC (HL)
    JR NZ, ANY_Callback_End
    LD HL, Titlemenu2_Callback
    LD (HALT_Callback+1), HL
    CALL Init_Menupage2

ANY_Callback_End:
    POP DE
    POP BC
    POP IX
    POP HL
    RET

ANY_Callback_Start:
    EX (SP), HL ;Switch return Addr with HL
    PUSH IX
    PUSH BC
    PUSH DE
    PUSH HL     ;Return addr on top
    RET

Titlemenu2_Callback:
    CALL ANY_Callback_Start

    LD HL, ArrowsAnimationPhase
    LD B, (HL)
    INC HL
    LD A, (HL)
    ADD A, B
    CALL Z, positiveArrowsAnimation
    CP 15
    CALL Z, negativeArrowsAnimation
    DEC HL
    LD (HL), A
    SRA A
    SRA A
    ADD A, 12        ;Arrow Char
    LD C, A

    LD HL, ProgrammingCursorY
    CALL Calculate_VRam_CursorY_page2
    CALL PaintMenuCursor
    LD A, 16
    ADD A, C
    LD C, A
    EX DE, HL
    LD A, 11
    CALL PaintMenuCursor

    CALL GET_JOYSTICK_TRIGGER_ANY
    CALL Z, Mark_Start_The_Game

    LD HL, CursorBlocker
    CALL GET_JOYSTICK_INPUT_ANY
    RRA
    JR NC, menu2_up
    RRA
    JR NC, menu2_down
    RRA
    JR NC, menu2_left
    RRA
    JR NC, menu2_right
    XOR A   ;if Dpad is released, release blocker
    LD (HL), A
menu2_input_done:
    JP ANY_Callback_End

menu2_up:
    LD BC, 255 * 256 + 255        ;ADD +1, CP -1
    JR menu2_updown
menu2_down:
    LD BC, 1 * 256 + 3        ;ADD -1; CP 3
menu2_updown:
    LD A, (HL)
    AND A
    JR NZ, menu2_input_done      ;If Cursorblocker is set, do nothing
    DEC HL    ;HL= ProgrammingCursorY
    LD A, (HL)
    ADD A, B
    CP C
    JR Z, menu2_input_done
    PUSH AF
    CALL Calculate_VRam_CursorY_page2
    LD C, 0
    CALL PaintMenuCursor
    EX DE, HL
    LD A, 11
    CALL PaintMenuCursor
    POP AF
    LD HL, ProgrammingCursorY
    LD (HL), A
 menu2_block_DPad:   
    LD HL, ProgrammingCursorY
    LD A, (CursorBlockerDuration)     ;Marker for WaitDPadRelease
    INC HL
    LD (HL), A
    JP menu2_input_done

menu2_left:
    LD C, -1
    JR menu2_rightleft
menu2_right:
    LD C, 1
menu2_rightleft:
    LD A, (HL)
    AND A
    JR NZ, menu2_input_done      ;If Cursorblocker is set, do nothing
    DEC HL    ;HL= ProgrammingCursorY
    LD A, (HL)
    LD DE, Player2State-Player1State     ;Sizeof Playerstate
    PUSH BC
    CALL mult_a_de      ;HL=Y*Sizeof(PlayerState)
    LD DE, Player1State+24
    ADD HL, DE          ;HL points to player's Input method
    POP BC
    LD A, (HL)
    INC A               ;Offset to 0...3
    ADD A, C            ;+/-1 
    JP M, menu2_leftright_too_low
    CP 4
    JR Z, menu2_leftright_too_big
menu2_leftright_done:
    DEC A               ;Revert offset
    LD (HL), A          ;Store Value
    CALL Init_Menupage2
    JR menu2_block_DPad

menu2_leftright_too_low:
    LD A, 3
    JR menu2_leftright_done
menu2_leftright_too_big:
    XOR A
    JR menu2_leftright_done


SetPlayerColorByPortrait:
    LD HL, PlayerColors-2
    LD C, (IX+23)
    LD B, 0
    ADD HL, BC  ;Add Portrait index to base addr
    LD A, (HL)  ;primary color
    LD (IX+3), A
    INC HL
    LD A, (HL)  ;Secondary color
    LD (IX+4), A
    RET

Init_Menupage2:
    LD IX, Player1State
    LD DE, $3800+ 32*8 + 9
    CALL PaintPlayerPage2Row

    LD IX, Player2State
    LD DE, $3800+ 32*10 + 9
    CALL PaintPlayerPage2Row
    
    LD IX, Player3State
    LD DE, $3800+ 32*12 + 9

;DE = Vram
;IX = player
PaintPlayerPage2Row:
    CALL PaintPlayerPortrait
    LD HL, 5
    ADD HL, DE
    EX DE, HL
    LD A, (IX+24)
    CP 255
    JR Z, set_text_AI
    CP 0
    JR Z, set_text_Keyboard
    CP 2
    JR Z, set_text_Stick2
    LD HL, Input_Joystick
    JP WRITE_String

set_text_AI:
    LD HL, Input_AI
    JP WRITE_String
set_text_Keyboard:
    LD HL, Input_Keyboard
    JP WRITE_String
set_text_Stick2:
    LD HL, Input_Joystick2
    JP WRITE_String

Calculate_VRam_CursorY_page2:
    LD A, (HL)
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, A
    LD HL, $3800 + 32*9 + 12
    RET