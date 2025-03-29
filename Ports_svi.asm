VDP_PORT_WRITE   EQU $80
VDP_PORT_READ    EQU $84
VDP_PORT_ADDRESS EQU $81
VDP_PORT_INTACK  EQU $85

PSG_PORT_WRITE   EQU $8C
PSG_PORT_READ    EQU $90
PSG_PORT_SELECT  EQU $88

PPI_PORT_A       EQU $98
PPI_PORT_B       EQU $99
PPI_PORT_C       EQU $96

SwitchMemoryBank:
    LD	A, 15
    OUT	(PSG_PORT_SELECT), A	; select PSG register 15 (Port B)
    LD A, 11011101b	; clear bit for bank 21. also disable capslock led
    OUT	(PSG_PORT_WRITE), A	; switch bank
    RET