IntroSong:
    defb 4
    defw CouperinRondeau, CouperinCouplet1      ;KeyFrame,ShortSilence

OutroSong:
    defb 14
    defw scaIntro, scaTheme, scaThemeE1, scaPiano, scaTheme, scaThemeE2, ShortSilence

HandleMusic:
    LD A, (MusicMode)
    CP 255
    RET Z       ;If silence mode, do nothing
    LD HL, CurrentFrameRemaining
    DEC (HL)
    RET NZ      ;Do nothing if there is still time
    LD HL, CurrentMusicFrame
    LD E, (HL)
    INC HL
    LD D, (HL)
    EX DE, HL       ;HL now points to current Frame
    LD A, (HL)
    CPL             ;Invert A
    AND A           ;Test for EOF
    JR Z, init_music    ;Load Keyframe
    CPL
    LD E, A             ;Load deltaframe
    INC HL
    LD D, (HL)  ;DE Contains Frame Mask
    INC HL
    LD A, (HL)  ;A Contains Frame Duration
copy_Psg_Registers:
    INC HL
    LD (CurrentFrameRemaining), A       ;New frame, store duration
    LD C, 0
    LD B, 14
loop_psg_Register:
    RL E
    RL D
    JR NC, skip_psg_Register
    LD A, C
    OUT (PSG_PORT_SELECT), A	; select PSG register
    LD A, (HL)
    INC HL
    OUT	(PSG_PORT_WRITE), A	;Write Value
skip_psg_Register:
    INC C
    DJNZ loop_psg_Register
    LD (CurrentMusicFrame), HL
    RET

MusicMode:
    defb 0      ;0=Music; 1=SoundFX, -1=Silence

init_music:
    LD HL, MusicMode
    LD A, (HL)
    AND A
    JR NZ, silence_music    ;If not 0=Music, no new piece to play
init_music_continue:
    LD HL, (CurrentMusicSong)
    LD A, (CurrentSongPart)
    INC A
    INC A
    CP (HL)   ;Compare with number of parts
    JR NZ, song_no_Wrap
    XOR A     ;Restart with first part
song_no_Wrap:
    LD (CurrentSongPart), A ;Store back to memory
    LD D, 0
    LD E, A
    INC HL
    ADD HL, DE      ;HL now points to Piece in Song parts array
    
    LD E, (HL)
    INC HL
    LD D, (HL)

    EX DE, HL   ;HL now points to keyframe of current piece
PlaySoundFX_cont:
    LD A, (HL)
    LD DE, $FFFF
    JR copy_Psg_Registers

;(HL)=Sound Keyframe
PlaySoundFX:
    LD DE, MusicMode
    LD A, (DE)
    CP 255
    RET NZ       ;Only play soundFX if in silent mode!
    LD A, 1      ;A=1=SoundFX Mode
    LD (DE), A
    JR PlaySoundFX_cont

silence_music:
    LD A, -1
    LD (MusicMode), A
    LD A, 7
    OUT (PSG_PORT_SELECT), A	; select PSG register
    LD A, %10111111
    OUT	(PSG_PORT_WRITE), A	    ;Write Value
    LD A, 8
    OUT (PSG_PORT_SELECT), A	; select PSG register
    XOR A
    OUT	(PSG_PORT_WRITE), A	    ;Write Value
    LD A, 9
    OUT (PSG_PORT_SELECT), A	; select PSG register
    XOR A
    OUT	(PSG_PORT_WRITE), A	    ;Write Value
    XOR 10
    OUT (PSG_PORT_SELECT), A	; select PSG register
    XOR A
    OUT	(PSG_PORT_WRITE), A	    ;Write Value
    RET

;HL points to music definition array
Switch_music:
    XOR A
    LD (MusicMode), A
    LD (CurrentMusicSong), HL
    LD HL, Music_init
    LD (CurrentMusicFrame), HL
    LD A, 2
    LD (CurrentFrameRemaining), A
    NEG
    LD (CurrentSongPart), A
    RET

Wait_for_Silence:
    LD A, (MusicMode)
    CP -1
    RET Z
    CALL HALT_Animation
    JR Wait_for_Silence
