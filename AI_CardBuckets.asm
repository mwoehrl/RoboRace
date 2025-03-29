AI_3MovesHitlist EQU $4400             ;TODO: Consolidate Buffers! Size = 1+31*4 (Score, Card1,Card2,Card3)
AI_Best5Moves EQU $7000              ;TODO Consolidate buffers!

;IX=Player
AI_SortPlayerStackIntoBuckets:
    LD E, (IX+17)
    LD D, (IX+18)   ;DE points to player's stack
    LD B, 15                ;Reset bucket
    LD HL, AI_CardBuckets-1
    XOR A
 reset_buckets_loop:   
    LD (HL), A
    INC HL
    DJNZ reset_buckets_loop
    LD B, (IX+14)               ;Only sort non-Locked cards into buckets
 player_stack_bucket_loop:
    LD A, (DE)      
    LD C, A     ;C=Card Nr.
    LD HL, AI_CardBuckets
 sort_Card_into_Buckets_loop:
    LD A, (HL)              ;A=BucketCard
    CP C
    JR Z, found_bucket            ;Bucket found
    AND A
    JR Z, new_bucket            ;Bucket with cardNr=0, create new bucket
    INC HL                      ;Try next bucket
    INC HL
    JR sort_Card_into_Buckets_loop
new_bucket:
    LD (HL), C                  ;Define new bucket by setting card Nr.
    PUSH HL
    LD HL, AI_CardBuckets_Count
    INC (HL)                    ;Increase bucket Count
    POP HL
found_bucket:
    INC HL          ;point to bucket size counter
    INC (HL)        ;matching bucket card count is incremented
    INC DE
    INC DE
    DJNZ player_stack_bucket_loop
    RET

;Consolidates buckets after removing one card.
AI_Consolidate_Buckets:
    LD HL, AI_CardBuckets_Count     ;look at counts
    LD B, (HL)          ;Only iterate over existing buckets!
    XOR A
    CP B
    RET Z               ;If Bucketlist size is 0, return!
 consolidate_buckets_loop:
    INC HL
    INC HL              ;HL points to count of first bucket
    LD A, (HL)
    AND A
    JR Z, empty_bucket_found
    DJNZ consolidate_buckets_loop
    RET
empty_bucket_found:
    LD D, H
    LD E, L
    INC HL      ;Bucket above
    DEC DE      ;Empty bucket Card byte
    LD A, B
    ADD A, A
    LD C, A       ;BC = Remaining count*2
    LD B, 0
    LDIR        ;Copy everything above 2 bytes down
    LD HL, AI_CardBuckets_Count
    DEC (HL)
    RET

;DE=Backup destination
AI_Backup_Buckets:
    LD HL, AI_CardBuckets-1         ;includes counter
    LD BC, 17
    LDIR
    RET

;HL=Backup to restore
AI_Restore_Buckets:
    LD DE, AI_CardBuckets-1         ;includes counter
    LD BC, 17
    LDIR
    RET

AI_Flag_Found:
    LD HL, MapDistanceBuffer-WorldMapBuffer
    ADD HL, DE      ;HL=Tile offset
    EX DE, HL
    RET

;IX=Player
AI_Find_Best_5Cards:
    CALL Wait_for_Silence
    LD (IX+6), 15      ;Ready color
    LD A, (IX+21)
    AND A
    JR Z, AI_not_shutdown
    LD (IX+6), 1      ;Shutdown color
    LD (IX+14), 9     ;Full Hitpoints
    CALL ScrollPlayerIntoCenter
    JR AI_shutdown_decision
AI_not_shutdown:
    CALL PaintSidebarProgrammPhase
    CALL ScrollPlayerIntoCenter
    LD A, (IX+14)
    AND A
    JR Z, AI_shutdown_decision           ;If 0 hitpoints, no cards need to be selected
    LD (IX+6), 14       ;Gray Color
    CALL PutRobot
    LD A, (IX+22)       ;current Flag
    LD IYL, A
    CALL AI_FindFlag_DistanceBuffer
    CALL AI_Start_Distance_Calculation
    LD (IX+6), 13       ;Magenta Color
    CALL PutRobot

    XOR A
    LD (AI_3MovesHitlist), A        ;Reset hitlist
    DEC A
    LD (AI_Best5Moves), A           ;255 is worst score, so any score is better
    LD DE, AI_Simulate_OnConveyor
    CALL AI_Reconfigure_Conveyor_Actions
    CALL AI_Fill_Best3MoveBuffer
    LD (IX+6), 14       ;Gray Color
    CALL PutRobot
    CALL AI_Continue_Hitlist_Moves
    LD HL, AI_Best5Moves+1
    LD E, (IX+15)       ;Player card register
    LD D, (IX+16)
    LD BC, 5*256+5      ;B=5, C=5 both used as loop counter by LDI and DJNZ
 AI_register_cards_loop:
    LD A, (HL)          ;Get Card
    LDI
    CALL GetPrioOfCard
    LD (DE), A
    INC DE
    DJNZ AI_register_cards_loop

    LD (IX+6), 15       ;White Color
    CALL PutRobot
AI_shutdown_decision:
    LD A, (IX+14)   ;Hit points
    CP 5            ;If Hit points < 5...
    LD A, 0
    RLA
    LD (IX+21), A       ;...announce Shutdown

    ;Restore Factory actions
    LD DE, HandleConveyorSideways
    CALL AI_Reconfigure_Conveyor_Actions
    RET

;IX=Player
AI_Fill_Best3MoveBuffer:
    CALL AI_SortPlayerStackIntoBuckets

    LD DE, AI_CardBuckets_Backup1
    CALL AI_Backup_Buckets
    XOR A
    LD (AI_Card1_Iterator), A
    
 choose_card1_loop:
    LD BC, AI_Card1_Iterator
    PUSH BC
    CALL take_current_card_from_bucket

    LD DE, AI_CardBuckets_Backup2
    CALL AI_Backup_Buckets
    XOR A
    LD (AI_Card2_Iterator), A       ;Counter = 0
     choose_card2_loop:
        LD BC, AI_Card2_Iterator
        PUSH BC
        CALL take_current_card_from_bucket

        LD DE, AI_CardBuckets_Backup3
        CALL AI_Backup_Buckets
        XOR A
        LD (AI_Card3_Iterator), A       ;Counter = 0
         choose_card3_loop:
            LD BC, AI_Card3_Iterator
            PUSH BC
            CALL take_current_card_from_bucket

            CALL AI_Simulate_3Moves         ;IY points to shadowed player with simulated position and state of bot while IX still points to original player
            CALL AI_ScorePosition           ;A=Score
            CALL AI_InsertPositionInHitlist

            LD HL, AI_CardBuckets_Backup3
            CALL AI_Restore_Buckets
            POP HL
            INC (HL)
            LD A, (AI_CardBuckets_Count)
            AND A
            JR Z, choose_card3_done
            CP (HL)
            JR NZ, choose_card3_loop
     choose_card3_done:
        LD HL, AI_CardBuckets_Backup2
        CALL AI_Restore_Buckets
        POP HL
        INC (HL)
        LD A, (AI_CardBuckets_Count)
        AND A
        JR Z, choose_card2_done
        CP (HL)
        JR NZ, choose_card2_loop
 choose_card2_done:
    LD HL, AI_CardBuckets_Backup1
    CALL AI_Restore_Buckets
    POP HL
    INC (HL)
    LD A, (AI_CardBuckets_Count)
    AND A
    JR Z, choose_card1_done
    CP (HL)
    JR NZ, choose_card1_loop
choose_card1_done:
    RET

;BC points to iterator (AI_Card1_Iterator...AI_Card5_Iterator)
take_current_card_from_bucket:
    LD HL, AI_CardBuckets_Count
    LD A, (HL)
    AND A       ;if Bucketlist is emplty, take locked card instead!
    JR Z, take_locked_card
    INC HL
    LD A, (BC)
    ADD A, A
    LD E, A
    LD D, 0
    ADD HL, DE      ;Pointing to current bucket
    LD A, (HL)
    INC BC          ;Pointing to chosen card memory
    LD (BC), A
    INC HL
    DEC (HL)
    JP AI_Consolidate_Buckets

take_locked_card:
    LD HL, -AI_Card1_Iterator
    ADD HL, BC
    EX DE, HL       ;DE=Offset in CardRegister
    LD L, (IX+15)
    LD H, (IX+16)   
    ADD HL, DE       ;HL points to locked card
    LD A, (HL)
    INC BC          ;Pointing to chosen card memory
    LD (BC), A      ;Copy locked card from corresponding position
    RET

;A=Score
AI_InsertPositionInHitlist:
    LD C, A     ;C=Score to insert
    LD HL, AI_3MovesHitlist
    LD A, (HL)
    LD B, A     ;B=List size
    INC HL
    AND A
    JR Z, AI_Inscribe_to_Hitlist
    ;List is not full yet, find inset position
 AI_find_insert_position_loop:   
    LD A, (HL)      ;Score of existing Element
    CP C            ;Existing-Candidate
    JR NC, AI_insert_position_found
    INC HL
    INC HL
    INC HL
    INC HL
    DJNZ AI_find_insert_position_loop
    ;HL has progressed by count * 4 and now points to insert position
    JR AI_Inscribe_to_Hitlist
AI_insert_position_found:
    ;HL points to score thats bigger, so shift everything after this by 4 bytes
    LD A, B
    RLA
    RLA
    LD B, C         ;store
    LD C, A
    LD A, B         ;A=Score
    LD B, 0         ;BC=Count*4=Nr of Bytes to shift
    EX DE, HL
    LD HL, 3
    ADD HL, DE
    ADD HL, BC      
    EX DE, HL       ;DE=HL+4
    ADD HL, BC      
    DEC HL
    LDDR            ;Copies everything above 4 bytes up to make space
    INC HL
    LD C, A         ;Score to C
AI_Inscribe_to_Hitlist:
    LD (HL), C      ;Write Score
    LD DE, AI_ChosenCard1
    LD B, 3
 AI_inscribe_cards_loop:
    LD A, (DE)
    INC HL
    LD (HL), A
    INC DE
    INC DE      ;Pointing to next card
    DJNZ AI_inscribe_cards_loop
    LD HL, AI_3MovesHitlist
    LD A, (HL)
    CP 30
    RET Z       ;If we already have 30 elements don't count any further
    INC A
    LD (HL), A
    RET

;IX=Player
AI_Continue_Hitlist_Moves:
    LD HL, AI_3MovesHitlist
    LD B, (HL)      ;B=Count
    INC HL          ;Skip Count byte
 ai_Continue_Hitlist_Moves_loop:
    PUSH BC
    LD DE, AI_ChosenCard1
    LD C, 3     ;To prevent counting down B with LDI
    INC HL      ;Skip score byte
    LDI         ;Load Card1
    INC DE
    LDI         ;Load Card2
    INC DE      
    LDI         ;Load Card3
    PUSH HL

    CALL AI_SortPlayerStackIntoBuckets
    LD HL, AI_ChosenCard1
    CALL AI_Remove_ChosenCard_FromBucket
    LD HL, AI_ChosenCard2
    CALL AI_Remove_ChosenCard_FromBucket
    LD HL, AI_ChosenCard3
    CALL AI_Remove_ChosenCard_FromBucket

    CALL AI_Simulate_3Moves         ;IY now points to shadowed player
    LD HL, ShadowPlayerBuffer
    LD DE, ShadowPlayerBuffer + 64
    LD BC, Player2State-Player1State
    LDIR                            ;Make Copy of simulated player for quick repeatability
    LD DE, AI_CardBuckets_Backup1
    CALL AI_Backup_Buckets

    XOR A
    LD (AI_Card4_Iterator), A       ;Counter = 0
     choose_card4_loop:
        LD BC, AI_Card4_Iterator
        PUSH BC
        CALL take_current_card_from_bucket
        LD DE, AI_CardBuckets_Backup2
        CALL AI_Backup_Buckets
        XOR A
        LD (AI_Card5_Iterator), A       ;Counter = 0
         choose_card5_loop:
            LD BC, AI_Card5_Iterator
            PUSH BC
            CALL take_current_card_from_bucket
            CALL AI_Simulate_2Moves         ;IY points to shadowed player with simulated position and state of bot while IX still points to original player
            CALL AI_ScorePosition           ;A=Score
            CALL AI_StorePosition_If_Best
            LD HL, AI_CardBuckets_Backup2
            CALL AI_Restore_Buckets
            POP HL      ;HL=AI_Card5_Iterator
            INC (HL)
            LD A, (AI_CardBuckets_Count)
            AND A
            JR Z, choose_card5_done
            CP (HL)
            JR NZ, choose_card5_loop
     choose_card5_done:
        LD HL, AI_CardBuckets_Backup1
        CALL AI_Restore_Buckets
        POP HL
        INC (HL)
        LD A, (AI_CardBuckets_Count)
        AND A
        JR Z, choose_card4_done
        CP (HL)
        JR NZ, choose_card4_loop
choose_card4_done:
    POP HL
    POP BC
    DEC B
    JP NZ, ai_Continue_Hitlist_Moves_loop
    RET

;HL points to chosenCard
AI_Remove_ChosenCard_FromBucket:
    LD DE, AI_CardBuckets-1
    LD A, (DE)
    AND A
    RET Z               ;If Bucketlist size=0, return!
    DEC DE
chosenCard_FromBucket_loop:
    INC DE
    INC DE      ;DE points to Current card in bucketlist
    LD A, (DE)  ;Card Char Nr
    CP (HL)
    JR NZ, chosenCard_FromBucket_loop
    INC DE      ;DE points to card count
    EX DE, HL
    DEC (HL)
    JP AI_Consolidate_Buckets

;A=Score
AI_StorePosition_If_Best;
    LD HL, AI_Best5Moves
    CP (HL)
    RET NC          ;Score > Best, no improvement
    LD (HL), A      ;Store Score

    INC HL
    LD DE, AI_ChosenCard1
    EX DE, HL
    LD BC, 5*256 + 5
 store_best5_loop:
    LDI         ;Store card
    INC HL
    DJNZ store_best5_loop
    RET
