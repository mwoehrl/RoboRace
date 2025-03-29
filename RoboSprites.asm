SpriteTransformBuffer EQU FileStart
Cache_45_Mirror EQU $6000				;TODO: Buffer Consolidation!

InitSpriteCaches:
	LD HL, RoboSpritePatterns
	LD DE, Cache_45_Mirror
	CALL InitSpriteCache
	LD HL, RoboSpritePatterns + 9*32
	LD DE, Cache_45_Mirror + 32*64
InitSpriteCache:
	XOR A
InitSpriteCaches_loop:	
	PUSH AF
	PUSH HL
	PUSH DE
	CALL PerpareRotatedSpritePattern
	POP DE
	LD BC, 32
	LD HL, SpriteTransformBuffer
	LDIR		;DE increased by 32
	POP HL
	POP AF
	INC A
	CP 64
	JR NZ, InitSpriteCaches_loop
	RET

Put_All_Robots:
	LD IX, Player1State
	CALL PutRobot
	LD IX, Player2State
	CALL PutRobot
	LD IX, Player3State
	JP PutRobot

CALL_BC_PUT_Sprite:
    LD B, (IX+0)
    LD C, (IX+1)    ;BC=X,Y
    LD A, -13
	CP B
    JR C, call_BC_PUT_done
    LD A, (SpriteLimit1)
	CP B
    JR NC, call_BC_PUT_done
    LD C, 240
 call_BC_PUT_done:
    JP PUT_SPRITE

Put_Sprites_Rich_Mode:
    LD D, (IX+5)
    LD E, D
    LD L, (IX+3)         ;L=Color
    CALL CALL_BC_PUT_Sprite

    LD A, (IX+5)
    LD E, A
    INC E                ;E=Pattern (+1 for secondary)
    ADD A, 22
    LD D, A              ;D=Sprite Layer (+22 for secondary)
    LD L, (IX+4)         ;L=Color
    JP CALL_BC_PUT_Sprite

Put_Sprites_Save_Mode:
    LD D, (IX+5)
    LD E, D
    INC E
    LD L, (IX+3)         ;L=Color
    CALL CALL_BC_PUT_Sprite

    LD A, (IX+5)
    LD E, A
    ADD A, 22
    LD D, A              ;D=Sprite Layer (+22 for secondary)
    LD L, (IX+4)         ;L=Color
    LD C, 240           ;Below screen
    LD B, C
	JP PUT_SPRITE

;IX = PlayerInfo
PutRobot:
    CALL PerpareRotatedSpritePatterns
    LD A, (SpriteSaveMode)
    AND A
    JR NZ, SpriteModeSelection_save
    CALL Put_Sprites_Rich_Mode
    JR SpriteModeSelection_done
SpriteModeSelection_save:
    CALL Put_Sprites_Save_Mode
;Now... set Pseudo-Sprite Char
SpriteModeSelection_done:
    LD A, (IX+0)         ;X-Position
    AND %00000111
    CP 4
    JR NZ, show_centerSprite    ;X-Position is off, so 3rd sprite is needed
    LD A, (IX+1)         ;Y-Position
    AND %00000111
    CP 4
    JR Z, no_centerSprite
show_centerSprite:
    LD B, (IX+0)
    LD C, (IX+1)
    LD A, (SpriteLimit1)			
    CP B
    JR C, no_centerSprite
    LD E, 8              ;Pattern Nr. (fixed for Center)
    LD L, (IX+6)         ;Color=Psuedosprite Char
    JR centerSprite_done
no_centerSprite:
    LD C, 240           ;y-Position
    LD L, 12            ;error color
    LD E, 8              ;Pattern Nr. (fixed for Center)
centerSprite_done:
    LD A, (IX+5)
    ADD A, 27
    LD D, A              ;D=Sprite Layer (+27 for Center)
    CALL PUT_SPRITE
;Replace Background Char as a backup in case Center Sprite cant be shown
    LD A, (IX+3)
	AND A
	JR Z, CheckRemoveChar   	;Don't proceed; Bot is invisible
	
	LD A, (IX+0)         ;X-Position
    ADD A, 8
    AND %11111000        ;Mask 3LSB
    RRA
    RRA
    RRA
    CP 31
    JR Z, CheckRemoveChar                ;Sprite is bleeding off the right border, no char needed
    LD HL, SpriteLimit2
	CP (HL)
    JR NC, CheckRemoveChar                ;Sprite is bleeding off the right border, no char needed

	LD C, A             ;Store LSB
    LD A, (IX+1)        ;Y-Position
    ADD A, 8            
    AND %11111000       ;Reset carry
    RLA
	LD B, 0
    RL B                
    RLA
    RL B
    JR NC, pseudosprite_skip_carry
    INC B
pseudosprite_skip_carry:
    OR C                ;Combine X and Y
    LD C, A             ;BC now contains Offset for Pseudochar
    LD HL, $3800
    ADD HL, BC          
    EX DE, HL			;DE now contains VRAM addr. of char

	LD A, E
	CP (IX+7)	;Compare with LSB of previous value
	JR NZ, pseudosprite_necessary		
	LD A, %10000000		;Require previous char to be set!
	OR D
	CP (IX+8)
	JR Z, pseudosprite_overwrite		;M/LSBs are equal to previous char, don't remove old one, only overwrite in case color changed!
	;DE=VRAM Char addr
pseudosprite_necessary:
	PUSH DE
    CALL CheckRemoveChar
	POP DE
    CALL VDPADDR_IN
    NOP		;For stable read
	IN A, (VDP_PORT_READ)   ;Read existing Char for restore later
    LD (IX+9), A
pseudosprite_overwrite:
    LD (IX+7), E        ;Store where the char is put for restore
    LD A, %10000000     ;Bitmask for restore=true
    OR D                ;MSB of char location
    LD (IX+8), A        ;Store MSB of char pos and control bits
    LD B, 1
	LD L, (IX+6)        ;L Contains the char# to set
    JP COPY_L_TO_VRAM_fast
CheckRemoveChar:
    ;Lastly, restore background chars if necessary
    LD A, (IX+8)    ;High byte of last pseudosprite char position
    RLA
    RET NC
    LD E, (IX+7)
    LD D, (IX+8)
    LD A, %01111111
    AND D
    LD D, A
    LD L, (IX+9)
    LD B, 1
    LD (IX+8), B        ;B=1, no restore char stored
    JP COPY_L_TO_VRAM_fast


FlipSpriteHorizontally:
	LD HL, SpriteTransformBuffer
FlipSpriteHorizontally_noHL:
	LD D, H
	LD E, L
	LD BC, 16
	ADD HL, BC
	LD C, 16
 mirrorBytesLoop:
	LD B, 8
 mirrorByteLoop:
	AND A		;Kill Carry
	RL (HL)
	EX DE, HL
	RR (HL)
	EX DE, HL
	JR NC, skip_carry_rotate_in
	INC (HL)
 skip_carry_rotate_in:
	DJNZ mirrorByteLoop
	INC HL
	INC DE
	DEC C
	JR NZ, mirrorBytesLoop
	RET

;Flips Sprinte Pattern in SpriteTransformBuffer
FlipSpriteVertically:
	LD HL, SpriteTransformBuffer
	LD DE, 15
	EX DE, HL		;DE = Byte0
	ADD HL, DE		;HL points to Byte15
	PUSH HL
	CALL mirrorVByteExchange		
	POP HL
	INC HL			;HL points to Byte16
	LD DE, 15
	EX DE, HL		;DE = Byte16
	ADD HL, DE		;HL points to Byte31
 mirrorVByteExchange:
	LD B, 8
 mirrorVByteExchangeLoop:
	LD C, (HL)
	LD A, (DE)
	LD (HL), A
	LD A, C
	LD (DE), A
	DEC HL
	INC DE
	DJNZ mirrorVByteExchangeLoop
	RET

;HL=Source Pattern
FlipSprite45Degrees:
	EX DE, HL
	LD HL, SpriteTransformBuffer
	LD BC, 24
	ADD HL, BC
	CALL flip8x8Tile
	LD BC, -16
	ADD HL, BC
	CALL flip8x8Tile
	LD BC, 8
	ADD HL, BC
	CALL flip8x8Tile
	LD BC, -16
	ADD HL, BC
flip8x8Tile:
	LD C, 8
 flip45outerloop:		
	LD A, (DE)
	LD B, 8
	PUSH HL
 flip45innerloop:		
	RRA
	RR(HL)
	INC HL
	DJNZ flip45innerloop
	POP HL
	INC DE
	DEC C
	JR NZ, flip45outerloop
	RET

mul_Rotation_32_add_HL:

	RET

;IX = PlayerInfo
PerpareRotatedSpritePatterns:
    LD A, (TitleMode)
    AND A
    JR NZ, sprite_no_clip
	LD A, (IX+0)	;ScreenX Position
	CP 180
	JR C, sprite_no_clip
	CP 192
	JR NC, sprite_no_clip
	SUB 176			;A now is 4...15
	AND %00001100	;A now is 4 | 8 | 12
	RLA
	RLA
	RLA
	RLA				
	JR sprite_clip_known
sprite_no_clip:
	XOR A
sprite_clip_known:		;A=(0...3)<<6
	LD B, A
    LD A, (IX+2)	;Get Rotation
	AND 63
	OR B			;A=Clipping + Rotation
	CP (IX+11)      ;Copare with cached Direction
	RET Z
	LD (IX+11), A	;write cached Direction
	LD HL, Cache_45_Mirror
	LD B, 0
	CALL Copy_SpritePattern
	LD HL, Cache_45_Mirror + 32*64
	LD B, 1
Copy_SpritePattern:
    LD A, (IX+2)	;Get Rotation
    AND 63
    LD D, 0
    RLA
    RLA
    RLA
    RL D
	RLA
    RL D
    RLA
    RL D
	LD E, A			;DE = A*32
	ADD HL, DE		;HL is set to source
	LD A, (IX+5)
    ADD A, B
    RLA
    RLA
    RLA
    RLA
    RLA
    LD D, $18
    LD E, A			;DE is set to Destination
	LD A, (IX+11)
	AND %11000000
	JR Z, Copy_SpritePattern_0
	CP  %01000000
	JR Z, Copy_SpritePattern_1
	CP  %10000000
	JR Z, Copy_SpritePattern_2

Copy_SpritePattern_3:
	CALL VDPADDR
	CALL copy_SpritePattern_1_loop_prep
	JR copy_SpritePattern_2_loop_prep

Copy_SpritePattern_0:
    LD B, 4
    JP COPY_RAM_TO_VRAM_unrolled

Copy_SpritePattern_1:
    LD B, 2		;Only 16 bytes (first column of sprite)
    CALL COPY_RAM_TO_VRAM_unrolled
 copy_SpritePattern_1_loop_prep:
	LD B, 16
 copy_SpritePattern_1_loop:
	LD A, %11110000
	AND (HL)
	OUT (VDP_PORT_WRITE), A
	INC HL
	DJNZ copy_SpritePattern_1_loop
	RET

Copy_SpritePattern_2:
    LD B, 2		;Only 16 bytes (first column of sprite)
    CALL COPY_RAM_TO_VRAM_unrolled
 copy_SpritePattern_2_loop_prep:
	LD B, 16
	XOR A
 copy_SpritePattern_2_loop:		;Write empty 2nd Column of Sprite
	OUT (VDP_PORT_WRITE), A
	INC HL
	DJNZ copy_SpritePattern_2_loop
	RET

;A=Sprite Rotation 0...63
PerpareRotatedSpritePattern:
	CP 9
	JR C, RotationSector_1
	CP 17
	JR C, RotationSector_2
	CP 24
	JR C, RotationSector_3
	CP 33
	JR C, RotationSector_4
	CP 41
	JR C, RotationSector_5
	CP 49
	JR C, RotationSector_6
	CP 56
	JR C, RotationSector_7
RotationSector_8:	;56...63
	NEG
	ADD A, 64
	CALL Point_HL_toBaseParttern
	CALL DryCopyPatternToBuffer
	JP FlipSpriteHorizontally
RotationSector_1:	;0...8
	CALL Point_HL_toBaseParttern
	JP DryCopyPatternToBuffer
RotationSector_2:
	NEG
	ADD A, 16
	CALL Point_HL_toBaseParttern
	JP FlipSprite45Degrees
RotationSector_3:
	ADD A, -16
	CALL Point_HL_toBaseParttern
	CALL FlipSprite45Degrees
	JP FlipSpriteVertically
RotationSector_4:
	NEG
	ADD A, 32
	CALL Point_HL_toBaseParttern
	CALL DryCopyPatternToBuffer
	JP FlipSpriteVertically
RotationSector_5:
	ADD A, -32
	CALL Point_HL_toBaseParttern
	CALL DryCopyPatternToBuffer
	PUSH HL
	CALL FlipSpriteVertically
	POP HL
	JP FlipSpriteHorizontally
RotationSector_6:
	NEG
	ADD A, 48
	CALL Point_HL_toBaseParttern
	CALL FlipSprite45Degrees
	PUSH HL
	CALL FlipSpriteVertically
	POP HL
	JP FlipSpriteHorizontally
RotationSector_7:
	ADD A, -48
	CALL Point_HL_toBaseParttern
	CALL FlipSprite45Degrees
	JP FlipSpriteHorizontally

;A = 0...8
;HL=Pattern base
Point_HL_toBaseParttern:
    AND A		;Neutralize Carry
	LD B, 5     ;Shift 5 bits
 copySpritePatternShiftloop:   
    RLA
    DJNZ copySpritePatternShiftloop
    LD E, A
    LD A, B     ;B is 0
    RLA         ;leaving bit from lower byte
	LD D, A     ;DE=Pattern*32
    ADD HL, DE  ;HL points to pattern
	RET

BonusSpriteToBuffer:
	LD HL, (CurrentBonusSpritePattern)
;HL=SourcePattern
DryCopyPatternToBuffer:
	LD DE, SpriteTransformBuffer
	LD BC, 64
	LDIR
	LD HL, SpriteTransformBuffer
	RET

CurrentBonusSpritePattern:
	defw 0
;IX=Player
;HL=SpritePattern
;IYL=Color
AnimateBonusSprite:
    LD (CurrentBonusSpritePattern), HL
	CALL ScrollPlayerIntoCenter
	LD HL, FX_Bonus
	CALL PlaySoundFX
	LD A, (IX+1)		;PlayerY
	SUB 16				;Start Above Player
	LD B, (IX+0)
	LD C, A
	LD E, 60
 bonusSprite_loop:
	PUSH DE
	LD A, C
	RRA
	RRA
	AND %00000111
	CP 0
	JR Z, paintBonusSprite
	CP 1
	JR Z, paintBonusSprite_Squeezed
	CP 3
	JR Z, paintBonusSprite_Squeezed_H
	CP 4
	JR Z, paintBonusSprite_H
	CP 5
	JR Z, paintBonusSprite_Squeezed_H
	CP 7
	JR Z, paintBonusSprite_Squeezed
	JR paintEdgeOnSprite
bonusSprite_loop_done:
	POP DE
	DEC E
	JR Z, cleanup_bonusSprite
	DEC C
	LD A, -18
	CP C
	JR NZ, bonusSprite_loop
	RET
cleanup_bonusSprite:
	LD BC, 240*256+240
	LD D, 1
	PUSH BC
	CALL PUT_SPRITE
	POP BC
	LD D, 31
	JP PUT_SPRITE

;BC=XY
;IYL=Color
paintBonusSprite:
	LD HL, (CurrentBonusSpritePattern)
paintBonusSprite_common:
    PUSH BC
	LD DE, $1960        ;Pattern #11
	LD B, 8
	CALL COPY_RAM_TO_VRAM_unrolled		;Copy Sprite Pattern #11
	LD DE, 31 * $100 + 11			;layer , Pattern
	LD A, IYL				;color
	LD L, A
	POP BC
	PUSH BC
	CALL PUT_SPRITE
	LD BC, 32
	ADD HL, BC		;Pattern2
	POP BC

    PUSH BC
	LD DE, 1 * $100 + 12			;layer , Pattern
	LD L, 1							;black
	POP BC
	PUSH BC
	CALL PUT_SPRITE
	POP BC


	CALL HALT_Animation
	JR bonusSprite_loop_done

paintBonusSprite_H:
	PUSH BC
	CALL BonusSpriteToBuffer
	CALL FlipSpriteHorizontally 
	CALL FlipSpriteHorizontally_noHL 
	LD HL, SpriteTransformBuffer
	POP BC
	JR paintBonusSprite_common
paintEdgeOnSprite:
	LD HL, RotationSprite
	JR paintBonusSprite_common

paintBonusSprite_Squeezed:
	PUSH BC
	CALL BonusSpriteToBuffer
	CALL SqueezeSpriteHorizontally 
	CALL SqueezeSpriteHorizontally_noHL
	LD HL, SpriteTransformBuffer
	POP BC
	JR paintBonusSprite_common

paintBonusSprite_Squeezed_H:
	PUSH BC
	CALL BonusSpriteToBuffer
	CALL SqueezeSpriteHorizontally 
	CALL SqueezeSpriteHorizontally_noHL 
	CALL FlipSpriteHorizontally 
	CALL FlipSpriteHorizontally_noHL 
	LD HL, SpriteTransformBuffer
	POP BC
	JR paintBonusSprite_common

;Sprite is already in Trnasformbuffer
SqueezeSpriteHorizontally:
	LD HL, SpriteTransformBuffer
SqueezeSpriteHorizontally_noHL:
	LD D, 16
 squeeze_Loop_outer_L:	
	LD C, 0
	LD B, 4
	LD A, (HL)
 squeeze_loop_L:
	RLA
	RL C
	RLA
	DJNZ squeeze_loop_L
	DEC D
	LD (HL), C
	INC HL
	JR NZ, squeeze_Loop_outer_L
	LD D, 16
 squeeze_Loop_outer_R:
	LD C, 0
	LD B, 4
	LD A, (HL)
 squeeze_loop_R:
	RRA
	RR C
	RRA
	DJNZ squeeze_loop_R
	DEC D
	LD (HL), C
	INC HL
	JR NZ, squeeze_Loop_outer_R
	RET

RoboCenterSprite:
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000011
	defb %00000111
	defb %00001111
	defb %00001111
	defb %00001111
	defb %00001111
	defb %00000111
	defb %00000011
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %11000000
	defb %11100000
	defb %11110000
	defb %11110000
	defb %11110000
	defb %11110000
	defb %11100000
	defb %11000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
RoboSpritePatterns:	
	defb 3, 15, 31, 62, 124, 120, -16, -8, -4, -4, 124, 124, 63, 31, 15, 3, -64, -16, -8, 124, 62, 30, 15, 31, 63, 63, 62, 62, -4, -8, -16, -64
	defb 1, 15, 31, 63, 62, 120, -16, -4, -4, 124, -4, 124, 63, 31, 7, 3, -64, -32, -8, 124, 62, 31, 30, 15, 63, 63, 62, 126, -4, -8, -16, -96
	defb 3, 15, 31, 63, 124, 120, -8, -4, -4, -8, 120, 124, 63, 31, 15, 3, -64, -16, -8, 60, 62, 30, 15, 15, 63, 63, 62, 62, -4, -8, -16, -64
	defb 1, 15, 31, 63, 126, 120, -8, -4, -4, -8, 120, 124, 63, 31, 7, 3, -64, -16, -8, 60, 62, 30, 31, 15, 31, 63, 62, 126, -4, -8, -16, -64
	defb 3, 15, 31, 63, 124, 120, -8, -4, -8, -8, 120, 124, 63, 31, 15, 3, -64, -16, -8, -68, 30, 30, 31, 15, 15, 63, 126, 126, -4, -8, -16, -64
	defb 3, 15, 31, 63, 126, 120, -4, -4, -8, -8, 120, 124, 63, 31, 15, 3, -64, -16, -8, -68, 30, 30, 31, 15, 15, 63, 126, 126, -4, -8, -16, -64
	defb 3, 15, 63, 63, 124, 120, -4, -4, -8, -8, 120, 124, 63, 63, 15, 3, -64, -16, -4, -4, 30, 30, 15, 15, 15, 111, 126, -2, -4, -4, -16, -64
	defb 3, 15, 31, 63, 124, 124, -4, -4, -8, -16, 120, 124, 63, 31, 15, 3, -64, -16, -8, -4, 14, 14, 15, 15, 15, 111, 126, -2, -4, -8, -16, -64
	defb 3, 15, 31, 63, 124, 124, -2, -4, -8, -16, 120, 125, 63, 31, 15, 3, -64, -16, -8, -4, 14, 14, 15, 15, 15, 79, -2, -2, -4, -8, -16, -64

	defb 7, 31, 63, 127, 126, -4, -8, -4, -4, -4, -4, 126, 127, 63, 31, 7, -32, -8, -4, -2, 126, 63, 31, 63, 63, 63, 63, 126, -2, -4, -8, -32
	defb 7, 31, 63, 127, 126, -4, -8, -4, -4, -4, -4, 124, 127, 63, 15, 7, -32, -16, -4, 126, 62, 63, 31, 31, 63, 63, 127, 126, -4, -4, -8, -32
	defb 7, 31, 63, 127, 126, -4, -8, -4, -4, -4, -4, 126, 127, 63, 31, 7, -32, -8, -4, -2, 62, 63, 31, 31, 63, 127, 127, 126, -2, -4, -8, -32
	defb 7, 31, 63, 127, 126, -8, -4, -4, -4, -4, -8, 126, 127, 63, 31, 7, -32, -16, -4, -4, 62, 31, 31, 15, 63, 127, 127, 126, -4, -4, -8, -32
	defb 7, 15, 63, 127, 127, -8, -2, -4, -4, -4, -8, 126, 63, 63, 31, 7, -32, -8, -4, -4, 62, 31, 31, 31, 63, 127, 127, -2, -2, -4, -16, -32
	defb 7, 31, 63, 127, 126, -8, -2, -4, -4, -8, -8, 126, 127, 63, 31, 7, -32, -8, -4, -2, 62, 31, 31, 15, 15, 127, 127, -2, -2, -4, -8, -32
	defb 7, 31, 63, 127, 127, -4, -2, -4, -4, -8, -8, 126, 127, 63, 31, 7, -32, -8, -4, -2, 30, 31, 31, 31, 15, 127, -1, -2, -2, -4, -8, -32
	defb 7, 31, 63, 127, 127, -4, -2, -4, -8, -8, -8, 127, 127, 63, 31, 7, -32, -8, -4, -4, -34, 31, 31, 31, 31, 127, -1, -2, -2, -4, -8, -32
	defb 7, 31, 63, 127, 127, -2, -2, -4, -8, -8, -8, 127, 127, 63, 31, 7, -32, -8, -4, -2, -2, 31, 31, 31, 31, 127, -1, -2, -2, -4, -8, -32

FlagSprite:
	defb %00000001
	defb %00000011
	defb %00000011
	defb %00000111
	defb %00000111
	defb %00001111
	defb %00001110
	defb %00011111
	defb %00011110
	defb %00111100
	defb %00111100
	defb %01111000
	defb %01111000
	defb %11110000
	defb %11110000
	defb %01100000

	defb %10000000
	defb %11100000
	defb %10111000
	defb %11111110
	defb %01111111
	defb %11111111
	defb %11111111
	defb %11111110
	defb %01111110
	defb %00011100
	defb %00000100
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000

FlagSprite2:
	defb %00000001
	defb %00000010
	defb %00000010
	defb %00000100
	defb %00000100
	defb %00001001
	defb %00001000
	defb %00010001
	defb %00010010
	defb %00100100
	defb %00100100
	defb %01001000
	defb %01001000
	defb %10010000
	defb %10010000
	defb %01100000

	defb %10000000
	defb %01100000
	defb %01011000
	defb %00000110
	defb %10000001
	defb %00000001
	defb %00000001
	defb %10000010
	defb %01100010
	defb %00010100
	defb %00000100
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000

HeartSprite:
	defb %00000000
	defb %00111000
	defb %01111100
	defb %11111110
	defb %11111111
	defb %11111111
	defb %11111111
	defb %11111111
	defb %01111111
	defb %01111111
	defb %00111111
	defb %00011111
	defb %00001111
	defb %00000111
	defb %00000011
	defb %00000001

	defb %00000000
	defb %00011100
	defb %00111110
	defb %01111111
	defb %11111111
	defb %11111111
	defb %11111111
	defb %11111111
	defb %11111110
	defb %11111110
	defb %11111100
	defb %11111000
	defb %11110000
	defb %11100000
	defb %11000000
	defb %10000000

HeartSprite2:
	defb %00000000
	defb %00111000
	defb %01000100
	defb %10000010
	defb %10011001
	defb %10010000
	defb %10000000
	defb %10000000
	defb %01000000
	defb %01000000
	defb %00100000
	defb %00010000
	defb %00001000
	defb %00000100
	defb %00000010
	defb %00000001

	defb %00000000
	defb %00011100
	defb %00100010
	defb %01000001
	defb %10000001
	defb %00000001
	defb %00000001
	defb %00000001
	defb %00000010
	defb %00000010
	defb %00000100
	defb %00001000
	defb %00010000
	defb %00100000
	defb %01000000
	defb %10000000

TrophySprite:
	defb %00011111
	defb %00011111
	defb %11111111
	defb %01011111
	defb %01001111
	defb %00101111
	defb %00011111
	defb %00000111
	defb %00000011
	defb %00000001
	defb %00000001
	defb %00000111
	defb %00001111
	defb %00001111
	defb %00001111
	defb %00000000

	defb %11111000
	defb %11111000
	defb %11111111
	defb %11111010
	defb %11110010
	defb %11110100
	defb %11111000
	defb %11100000
	defb %11000000
	defb %10000000
	defb %10000000
	defb %11100000
	defb %11110000
	defb %11110000
	defb %11110000
	defb %00000000

TrophySprite2:
	defb %00111111
	defb %11100000
	defb %00000000
	defb %10000000
	defb %10110000
	defb %01010000
	defb %00100000
	defb %00001000
	defb %00000100
	defb %00000010
	defb %00000010
	defb %00001000
	defb %00010000
	defb %00010000
	defb %00010000
	defb %00011111

	defb %11111100
	defb %00000111
	defb %00000000
	defb %00000001
	defb %00001101
	defb %00001010
	defb %00000100
	defb %00010000
	defb %00100000
	defb %01000000
	defb %01000000
	defb %00010000
	defb %00001000
	defb %00001000
	defb %00001000
	defb %11111000

WrenchSprite:
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000001
	defb %00000011
	defb %00000111
	defb %00001111
	defb %00011111
	defb %00111110
	defb %01111100
	defb %11111000
	defb %11110000
	defb %01100000

	defb %00111000
	defb %01110000
	defb %01100000
	defb %01100001
	defb %01110011
	defb %11111111
	defb %11111110
	defb %11100000
	defb %11000000
	defb %10000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000

WrenchSprite2:
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000001
	defb %00000011
	defb %00000111
	defb %00001111
	defb %00011111
	defb %00111110
	defb %01111100
	defb %11111000
	defb %11110000
	defb %01100000

	defb %00111000
	defb %01110000
	defb %01100000
	defb %01100001
	defb %01110011
	defb %11111111
	defb %11111110
	defb %11100000
	defb %11000000
	defb %10000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000

Wrench2Sprite:
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000001
	defb %00000011
	defb %00000111
	defb %01111111
	defb %11111111
	defb %11001110
	defb %10000110
	defb %00000110
	defb %00001110
	defb %00011100

	defb %00111000
	defb %01110000
	defb %01100000
	defb %01100001
	defb %01110011
	defb %11111111
	defb %11111110
	defb %11100000
	defb %11000000
	defb %10000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000

Wrench2Sprite2:
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000001
	defb %00000011
	defb %00000111
	defb %01111111
	defb %11111111
	defb %11001110
	defb %10000110
	defb %00000110
	defb %00001110
	defb %00011100

	defb %00111000
	defb %01110000
	defb %01100000
	defb %01100001
	defb %01110011
	defb %11111111
	defb %11111110
	defb %11100000
	defb %11000000
	defb %10000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000
	defb %00000000

RotationSprite:
	defb %00000001
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000011
	defb %00000001

	defb %10000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %11000000
	defb %10000000
RotationSprite2:
	defb %00000001
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000010
	defb %00000001

	defb %10000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %01000000
	defb %10000000	