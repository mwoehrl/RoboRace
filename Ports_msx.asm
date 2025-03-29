VDP_PORT_WRITE   EQU $98
VDP_PORT_READ    EQU $98
VDP_PORT_ADDRESS EQU $99
VDP_PORT_INTACK  EQU $99

PSG_PORT_WRITE   EQU $A1
PSG_PORT_READ    EQU $A2
PSG_PORT_SELECT  EQU $A0

PPI_PORT_A       EQU $A8
PPI_PORT_B       EQU $A9
PPI_PORT_C       EQU $AA

SwitchMemoryBank:
    IN	A, (PPI_PORT_A)	; read current Slot config
    CALL CopyMemoryUpperToLower
    OUT	(PPI_PORT_A), A	; switch bank
    LD HL, $FFFF
    LD A, (HL)
    CALL CopyMemoryUpperToLower
    CPL
    LD (HL), A
    RET

CopyMemoryUpperToLower:
    AND	11110000b	; clear bits for pages 0 and 1
    LD B, A         ; save bits for pages 2 and 3 (RAM slot)
    RRA             ; Shift RAM slot config from pages 2&3 down to 0&1
    RRA             ; (Carry is reset by previous AND operation, so no Problem)
    RRA
    RRA
    OR B            ; Set RAM config of Pages 2&3
    RET