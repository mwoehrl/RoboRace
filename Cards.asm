PlayerCardBuffer EQU $7010                  ;TODO Consolidate buffers Size: 84
Player1CardStack EQU PlayerCardBuffer
Player2CardStack EQU Player1CardStack + 18
Player3CardStack EQU Player2CardStack + 18

Player1CardRegister EQU Player3CardStack + 18
Player2CardRegister EQU Player1CardRegister + 10
Player3CardRegister EQU Player2CardRegister + 10

CardStack:
    defb 35, 10
    defb 35, 12
    defb 35, 14
    defb 35, 16
    defb 35, 18
    defb 35, 20
    defb 35, 22
    defb 35, 24
    defb 35, 26
    defb 35, 28
    defb 35, 30
    defb 35, 32
    defb 35, 34
    defb 35, 36
    defb 35, 38
    defb 35, 40
    defb 35, 42
    defb 35, 44
    defb 35, 46
    defb 35, 48
    defb 35, 50
    defb 35, 54
    defb 35, 56
    defb 35, 58
    defb 36, 41
    defb 36, 43
    defb 36, 45
    defb 36, 47
    defb 36, 49
    defb 36, 51
    defb 36, 53
    defb 36, 55
    defb 36, 55
    defb 36, 57
    defb 36, 59
    defb 36, 61
    defb 37, 52
    defb 37, 53
    defb 37, 60
    defb 37, 73
    defb 37, 75
    defb 37, 79
    defb 38, 1
    defb 38, 2
    defb 38, 3
    defb 38, 4
    defb 38, 7
    defb 38, 8
    defb 38, 10
    defb 38, 11
    defb 38, 12
    defb 38, 13
    defb 38, 14
    defb 38, 15
    defb 39, 1
    defb 39, 2
    defb 39, 3
    defb 39, 4
    defb 39, 7
    defb 39, 8
    defb 39, 10
    defb 39, 11
    defb 39, 12
    defb 39, 13
    defb 39, 14
    defb 39, 15
    defb 40, 10
    defb 40, 13
    defb 40, 17
    defb 40, 20
    defb 40, 15
    defb 40, 31
    defb 41, 20
    defb 41, 23
    defb 41, 26
    defb 41, 29
    defb 41, 31
    defb 41, 34
    defb 41, 37
    defb 41, 40
    defb 41, 42
    defb 41, 44
    defb 41, 48
    defb 41, 50

;A=CardType
;Returns Prio in A
GetPrioOfCard:
    PUSH HL             ;Preserve HL
    LD HL, CardStack
 getPrioOfCard_loop:
    CP (HL)
    INC HL
    JR Z, getPrioOfCard_found
    INC HL
    JR getPrioOfCard_loop
 getPrioOfCard_found:
    LD A, (HL)      ;Load Prio of found Card
    POP HL
    RET

ShuffleCardStack:
    LD HL, CardStack
    LD B, 83
 shuffleCardStack_loop:
    PUSH BC
    PUSH HL
    CALL Random16Bit        ;HL is 0...65535
    EX DE,HL
    LD A, B
    CALL mult_a_de           ;A contains 0...83
    INC A
    ADD A, A
    LD L, A
    LD H, 0
    POP DE
    PUSH DE
    ADD HL, DE      ;HL and DE point to 2 different cards, switch them!
    LD C, (HL)
    INC HL
    LD B, (HL)
    DEC HL
    LD A, (DE)
    LD (HL), A
    INC HL
    INC DE
    LD A, (DE)
    LD (HL), A
    EX DE, HL
    LD (HL), B
    DEC HL
    LD (HL), C
    POP HL
    POP BC
    INC HL
    INC HL
    DJNZ shuffleCardStack_loop        
    RET

DealCards:
    CALL ShuffleCardStack
    LD HL, CardStack
    LD DE, Player1CardStack
    LD BC, 3 * 9 * 2
    LDIR    ;Copy first 27 Cards from shuffled Stack to players stacks
    LD IX, Player1State
    CALL ClearPlayerCardRegister
    LD IX, Player2State
    CALL ClearPlayerCardRegister
    LD IX, Player3State
;IX=Player
ClearPlayerCardRegister:
    LD A, (IX+21)       ;Shutdown Announced?
    AND A
    RET NZ              ;Don't clear any cards
    LD L, (IX+15)
    LD H, (IX+16)       ;HL points to players register pos 0
    LD B, (IX+14)       ;B=Players Hitpoints
    XOR A
 clearPlayerCardRegister_loop:
    CP B
    RET Z               ;Done when maximum number of cards is cleared
    CP 5
    RET Z               ;Done when 5 cards are cleared
    LD (HL), 77         ;Set ? card
    INC HL
    LD (HL), 0
    INC HL
    INC A
    JR clearPlayerCardRegister_loop

RandomCard:
    CALL DealCards
    LD HL, CardStack
    LD DE, Player1CardRegister
    LD BC, 30
    LDIR
    RET