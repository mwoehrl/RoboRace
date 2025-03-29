ORG 0
defb 0
ORG $4000
defb $41,$42
defw ROM_Start


ROM_Start:
    LD HL, $4000 + 58 + $25
    LD DE, $8000 + 58 + $25
    LD BC, $4000 - (58 + $25) 
    LDIR

    LD A, %11010100
    OUT($A8), A         ;Switch next 16kB of Cardridge

    LD HL, $8000
    LD DE, $C000
    LD BC, EndCAS-$8000
    LDIR

    LD A, %11110100
    OUT($A8), A         ;Switch back RAM

    JP $8094            ;Address of INIT symbol

StartCAS:
    incbin "Rally.cas"
EndCAS: