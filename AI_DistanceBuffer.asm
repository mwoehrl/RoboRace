MapDistanceBuffer_Pos EQU $4000
MapDistanceBuffer EQU MapDistanceBuffer_Pos + 2             ;TODO: Consolidate Buffers!


MaxDistance_Step EQU 35

;DE=WorldPos in DistanceBuffer
AI_Start_Distance_Calculation:
    LD HL, MapDistanceBuffer_Pos
    LD A, (HL)
    CP E
    JR NZ, AI_Start_Distance_Calculation_start
    INC HL
    LD A, (HL)
    CP D
    RET Z       ;DistanceBuffer is already chached
AI_Start_Distance_Calculation_start:
    LD (MapDistanceBuffer_Pos), DE
    PUSH DE
    LD E, MaxDistance_Step
    LD HL, MapDistanceBuffer + 26
    LD BC, (WorldMapBufferHeight) * 26
 init_distancebuffer_loop:
    LD (HL), E
    INC HL
    DEC BC
    LD A, B
    OR C
    JR NZ, init_distancebuffer_loop
    POP DE
    LD A, 1
;DE=WorldPos in DistanceBuffer
;A=Start Distance
AI_Do_Distance_Calculation:
    LD (DE), A          ;Set initial distance
    LD C, A             ;C=current Distance
    INC C
    CALL proceed_right_if_possible
    CALL proceed_left_if_possible
    CALL proceed_down_if_possible
    JP proceed_up_if_possible

proceed_right_if_possible:
    CALL AI_check_Right
    PUSH DE
    PUSH BC
    CALL Z, AI_proceed_Right
    POP BC
    POP DE
    RET

proceed_left_if_possible:
    CALL AI_check_Left
    PUSH DE
    PUSH BC
    CALL Z, AI_proceed_Left
    POP BC
    POP DE
    RET

proceed_up_if_possible:
    CALL AI_check_UP
    PUSH DE
    PUSH BC
    CALL Z, AI_proceed_Up
    POP BC
    POP DE
    RET

proceed_down_if_possible:
    CALL AI_check_DOWN
    PUSH DE
    PUSH BC
    CALL Z, AI_proceed_Down
    POP BC
    POP DE
    RET

;C=dist
;DE=WorldPos
AI_proceed_Left:
    LD HL, proceed_left_if_possible
    LD (reconfigure_proceed_sideways+1), HL
    DEC DE
    JR AI_proceed_sideways
AI_proceed_Right:
    LD HL, proceed_right_if_possible
    LD (reconfigure_proceed_sideways+1), HL
    INC DE
AI_proceed_sideways:
    LD A, (DE)  ;current distance value
    DEC A
    CP C
    RET C       ;If A<=C don't proceed
    LD A, C
    LD (DE), A  ;Store distance value

    INC C       ;dist+1
 reconfigure_proceed_sideways:   
    CALL proceed_right_if_possible
    INC C
    CALL proceed_down_if_possible
    CALL proceed_up_if_possible
    RET

;C=dist
;DE=WorldPos
AI_proceed_Up:
    LD HL, proceed_up_if_possible
    LD (reconfigure_proceed_updown+1), HL
    LD HL, -26
    JR AI_proceed_updown
AI_proceed_Down:
    LD HL, proceed_down_if_possible
    LD (reconfigure_proceed_updown+1), HL
    LD HL, 26
AI_proceed_updown:
    ADD HL, DE
    EX DE, HL   
    LD A, (DE)  ;current distance value
    DEC A
    CP C
    RET C       ;If A<=C don't proceed
    LD A, C
    LD (DE), A  ;Store distance value

    INC C       ;dist+1
 reconfigure_proceed_updown:   
    CALL proceed_down_if_possible
    INC C
    CALL proceed_right_if_possible
    CALL proceed_left_if_possible
    RET

;DE=WorldPos
;if check ist ok, Z flag is set
AI_check_Right:
    PUSH DE
    CALL load_tileFlag_from_DE_in_DistanceMap
    AND 2       ;East Wall              :Reprogram!
    JR NZ, AI_check_Right_done
    POP DE
    PUSH DE
    INC DE
    CALL load_tileFlag_from_DE_in_DistanceMap
    AND 8+16       ;West Wall or pit             :Reprogram!
AI_check_Right_done:
    POP DE
    RET

;DE=WorldPos
;if check ist ok, Z flag is set
AI_check_Left:
    PUSH DE
    CALL load_tileFlag_from_DE_in_DistanceMap
    AND 8       ;West Wall              :Reprogram!
    JR NZ, AI_check_Left_done
    POP DE
    PUSH DE
    DEC DE
    CALL load_tileFlag_from_DE_in_DistanceMap
    AND 2 +16      ;East Wall    or pit          :Reprogram!
AI_check_Left_done:
    POP DE
    RET

;DE=WorldPos
;if check ist ok, Z flag is set
AI_check_UP:
    PUSH DE
    CALL load_tileFlag_from_DE_in_DistanceMap
    AND 1       ;North Wall              :Reprogram!
    JR NZ, AI_check_Up_done
    POP DE
    PUSH DE
    LD HL, -26
    ADD HL, DE
    EX DE, HL
    CALL load_tileFlag_from_DE_in_DistanceMap
    AND 4 +16      ;South Wall      or pit        :Reprogram!
AI_check_Up_done:
    POP DE
    RET

;DE=WorldPos
;if check ist ok, Z flag is set
AI_check_DOWN:
    PUSH DE
    CALL load_tileFlag_from_DE_in_DistanceMap
    AND 4       ;South Wall              :Reprogram!
    JR NZ, AI_check_Down_done
    POP DE
    PUSH DE
    LD HL, 26
    ADD HL, DE
    EX DE, HL
    CALL load_tileFlag_from_DE_in_DistanceMap
    AND 1  +16     ;North Wall  or pit            :Reprogram!
AI_check_Down_done:
    POP DE
    RET

;DE=WorldPos in distanceMap
;Returns Flags of tile in A
load_tileFlag_from_DE_in_DistanceMap
    LD HL, WorldMapBuffer-MapDistanceBuffer
    ADD HL, DE      ;HL points to corresponding Tile in WorldMapBuffer
    LD A, (HL)      ;A=Tile Index
    ADD A, A
    LD D, 0
    LD E, A
    LD HL, TileFlags
    ADD HL, DE  ;HL points to tile Flag byte
    LD A, (HL)
    RET