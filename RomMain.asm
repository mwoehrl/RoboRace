InitialSP EQU $FFFE

ORG 0   ;start at first address in ROM
    DI  ;DI and LD SP, NN  instructions must be first 2 bytes of ROM Cartridge!
    LD SP, InitialSP

    LD HL, StartCAS
    LD DE, $8000+$25
    LD BC, EndCAS - StartCAS
    LDIR
    JP $8083

StartCAS:
    incbin "Rally.cas"
EndCAS:

