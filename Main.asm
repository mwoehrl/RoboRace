
KiloBytes  EQU 29	  ;Max 28 for CAS mode, Max 63 for Tapeloader Mode
FileStart  EQU $8025 + 58
LastByte   EQU FileStart + 29199 -1-$25 - 58   ;1024*KiloBytes-1-$25 - 58

InitialSP EQU $FFFE

;--------------------- Tape header
ORG FileStart - 58
defb 'UUUUUUUUUUUUUUUU', 7Fh
defb 0D0h, 0D0h, 0D0h, 0D0h, 0D0h, 0D0h, 0D0h, 0D0h, 0D0h, 0D0h
defb 'RoRace'
defb 0,0
defb 'UUUUUUUUUUUUUUUU', 7Fh
defw FileStart
defw LastByte
defw INIT
;---------------------------------- 58 bytes

ORG FileStart   ;All bytes between FileStart and CodeStart are only used for initialization and can later be overwritten
;----------------------- VDP Interrupt routine to be copied to $0038 ---
IF MSX_MODE
    include "Ports_msx.asm"
ELSE 
    include "Ports_svi.asm"
ENDIF

INT_0038:
    EX AF, AF'
    EXX
    IN A, (VDP_PORT_INTACK)    ;Acknowledge IRQ
    AND A
    JP P, spriteSave_zero - INT_0038 + $38
    AND %01000000
    LD HL, SpriteSaveMode
    JR Z, no_overlapping_sprites   ;Skip if not VDP Interrupt
    ;Sprite overlap detected
    LD A, 100
    LD (HL), A
no_overlapping_sprites
    LD A, (HL)
    AND A       ;Check if zero
    JR Z, spriteSave_zero
    DEC (HL)
spriteSave_zero:
    EXX
    EX AF, AF'
    EI
    RET
INT_END:
;----------------------------------
INIT:
    DI
    LD SP, InitialSP
    IM 1

    ;Memory bank switch
    CALL SwitchMemoryBank
    ;copy code for Interrupt routine
    LD HL, INT_0038
    LD DE, $0038    ;Interrupt jump address
    LD BC, INT_END-INT_0038
    LDIR

    CALL INIT_GRAPHIC_MODE_2

    LD DE, $1900        ;Pattern $100 = #8
    LD HL, RoboCenterSprite
    LD B, 32
    CALL COPY_RAM_TO_VRAM_fast

    LD DE, $1920        ;Pattern #9
    LD L, %00011000
    LD B, 16
    CALL COPY_L_TO_VRAM_fast
    LD DE, $1930        ;Pattern #9
    LD L, %00000000
    LD B, 16
    CALL COPY_L_TO_VRAM_fast

    LD DE, $1940        ;Pattern #10
    LD L, %00011000
    LD B, 8
    CALL COPY_L_TO_VRAM_fast
    LD DE, $1948        ;Pattern #10
    LD L, %00000000
    LD B, 24
    CALL COPY_L_TO_VRAM_fast

    CALL InitSpriteCaches
    JP TitleStart

CodeStart:
SpriteSaveMode:
    defb 0

include "TitleScreen.asm"
include "WinnerScreen.asm"
include "Game.asm"
include "Math.asm"
include "Video.asm"
include "Input.asm"
include "PlayField.asm"
include "MiniMap.asm"
include "FactoryActions.asm"
include "RobotActions.asm"
include "Sidebar.asm"
include "Camera.asm"
include "AI_DistanceBuffer.asm"
include "AI_CardBuckets.asm"
include "AI_MoveSimulator.asm"
include "Cards.asm"
include "RoboSprites.asm"
include "Tileset.asm"
include "Frames.asm"
include "MapPieces.asm"
include "MenuChars.asm"
include "Music.asm"
include "EndCredits.asm"
include "Music_Intro.asm"
TitleBitmap:
include "TitleChars.asm"
include "Buffers.asm"
include "SoundFX.asm"
LastUsedByte:
ORG LastByte

AA_Bytes_Unused EQU LastByte-LastUsedByte
DEFB $FF
