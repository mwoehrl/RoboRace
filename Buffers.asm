WorldMapBufferHeight EQU 24

FlagCount:          
    defb 4
PlayerCount:
    defb 3
UseLasers:
    defb 255
SelectedMap:
    defw MapDefinition

MapScroll_X:
    defb 0          
MapScroll_Y:
    defb 0
MapScrolled:
    defb 0

MapScroll_X_max:    
    defb 0
MapScroll_Y_max:
    defb 0

AI_CardBuckets_Count:
    defb 0
AI_CardBuckets:                 
    defw 0,0,0,0,0,0,0,0        ;7 buckets +1 for good luck

AI_CardBuckets_Backup1:          
    defb 0
    defw 0,0,0,0,0,0,0,0        ;7 buckets +1 for good luck
AI_CardBuckets_Backup2:          
    defb 0
    defw 0,0,0,0,0,0,0,0        ;7 buckets +1 for good luck
AI_CardBuckets_Backup3:          
    defb 0
    defw 0,0,0,0,0,0,0,0        ;7 buckets +1 for good luck

RandomSeed:
   defw 432542

CurrentMusicSong:
    defw IntroSong
CurrentMusicFrame:
    defw Music_init
CurrentFrameRemaining:
    defb 2      ;Wait for 2 Frames initially
CurrentSongPart:
    defb -2

;---------------------- 0 initialized variables:
HotspotCount:
    defb 0
HotspotBuffer:
    defw 0          ;Every 16-bit value is XY coordinate of hotspot
    defw 0
    defw 0
    defw 0
    defw 0
    defw 0

GameStartMarker:
AI_Card1_Iterator:
    defb 0
AI_ChosenCard1:
    defb 0
AI_Card2_Iterator:
    defb 0
AI_ChosenCard2:
    defb 0
AI_Card3_Iterator:
    defb 0
AI_ChosenCard3:
    defb 0
AI_Card4_Iterator:
    defb 0
AI_ChosenCard4:
    defb 0
AI_Card5_Iterator:
    defb 0
AI_ChosenCard5:
    defb 0

LaserSprite_X:
    defb 0
LaserSprite_Y:
    defb 0
LaserSprite_Z:
    defb 0
LaserSprite_8:
    defb 0
CurrentTileX:
    defb 0
CurrentTileY:
    defb 0
CurrentLaserChar:
    defb 0
BoardPhase_Lasers_Repeatmarker:
    defb 0

MovingBotsCount:
    defb 0
MovingBotsBuffer:
    defw 0
    defw 0
    defw 0

RegisterPhaseNr:
    defb 0

ProgrammingCursorX:
   defb 0
ProgrammingCursorY:
   defb 0
CursorBlocker:
   defb 0
END_Zero_init:
;END------------------ 0 initialized variables:

CursorBlockerDuration:
   defb 20

ShortDelayDuration:
    defb 1

MiniMapMode:
    defb 0
FrameCounter:
    defb 0
ArrowsAnimationPhase:
    defb 0
ArrowsAnimationStep:
    defb 1
TitleMode:
    defb 0
SpriteLimit1:       ;190 for game mode, 232 for Title mode
    defb 190
SpriteLimit2:    ;Variable limit! (24 vs 31)
    defb 24
