FlickerFreq EQU 8

PaintMiniMap:
   LD A, 1
   LD (MiniMapMode), A
   LD HL, CharPatterns + 208*8    ;Chars 2k to Address $800 in VRAM
   LD BC, CharColors-CharPatterns  -208*8
   LD DE, $0000 + 208*8
   CALL COPY_RAM_TO_VRAM
   LD HL, CharPatterns + 208*8     ;Chars 2k to Address $800 in VRAM
   LD BC, CharColors-CharPatterns -208*8
   LD DE, $0800 + 208*8 
   CALL COPY_RAM_TO_VRAM
   LD HL, CharPatterns + 208*8     ;Chars 2k to Address $1000 in VRAM
   LD BC, CharColors-CharPatterns -208*8
   LD DE, $1000 + 208*8
   CALL COPY_RAM_TO_VRAM
   
   LD HL, CharColors     ;Colors 2k to Address 2800h in VRAM
   LD BC, CharColors-CharPatterns
   LD DE, $2000
   CALL COPY_RAM_TO_VRAM_compressed
   LD HL, CharColors     ;Colors 2k to Address 2800h in VRAM
   LD BC, CharColors-CharPatterns
   LD DE, $2800
   CALL COPY_RAM_TO_VRAM_compressed
   LD HL, CharColors     ;Colors 2k to Address 3000h in VRAM
   LD BC, CharColors-CharPatterns
   LD DE, $3000
   CALL COPY_RAM_TO_VRAM_compressed

   CALL Hide_ALL_Sprites

   LD C, 24   
   LD DE, $3800
clear_miniMap_loop:
   LD B, 24
   LD L, 25
   CALL COPY_L_TO_VRAM_fast
   LD HL, 32
   ADD HL, DE
   EX DE, HL
   DEC C
   JR NZ, clear_miniMap_loop

   LD HL, WorldMapBuffer + 1 + 26
   LD IYL, 24
   LD IYH, 24
   LD DE, $3800

   LD A, (MapScroll_X_max)
   CP 18
   JR Z, miniMap_smallX
   LD A, (MapScroll_Y_max)
   CP 18
   JR NZ, miniMap_sizeDone
miniMap_smallY:      ;Big X, small Y
   LD IYL, 14 
   LD DE, $3800 + 32*5
   LD HL, WorldMapBuffer + 1
   JR miniMap_sizeDone
miniMap_smallX:
   LD IYH, 14
   LD HL, WorldMapBuffer
   LD IYL, 14 
   LD DE, $3800 + 5 + 32*5
miniMap_sizeDone:    
   LD A, IYL
   LD C, A
 paint_map_loop:
   LD A, IYH
   LD B, A
   PUSH DE
   CALL VDPADDR
 paint_map_row_loop
    PUSH HL
    LD D, 0
    LD E, (HL)
    LD HL, MiniTiles
    ADD HL, DE
    LD A, (HL)
    OUT (VDP_PORT_WRITE), A
    POP HL      ;WorldMapPointer restored
    INC HL
    DJNZ paint_map_row_loop
    LD A, IYH
    SUB 26
    NEG  ;A=26-IYH
    LD E, A
    ADD HL, DE        ;ADD HL, 26-IYH
    POP DE
    PUSH HL
    LD HL, 32        ;+32 to next Row in VRAM
    ADD HL, DE
    EX DE, HL
    POP HL
    DEC C
    JR NZ, paint_map_loop
    CALL HALT_Animation
    LD A, FlickerFreq
    LD (FrameCounter), A
    JP PaintRobots

;IX=Player
Put_Minibot:
   LD A, (IX+12)     ;WorldX
   CP 30
   RET Z
   PUSH BC
   ADD A, A
   RLA
   RLA
   ADD A, B       ;A=WorldX*8+Offset
   LD B, A
   LD A, (IX+13)  ;WorldY
   ADD A, A
   RLA
   RLA
   ADD A, C       ;A=WorldY*8+Offset
   LD C, A
   LD D, (IX+5)   ;Use layer of player
   LD E, 8        ;Center Sprite Pattern
   LD L, (IX+3)   ;Players primary color
   LD A, (FrameCounter)
   AND FlickerFreq
   JR NZ, put_minibot_solid
   LD L, A
put_minibot_solid:
   CALL PUT_SPRITE
   POP BC
   RET