.segment "SAV"

PlayerProgressTutorialCompleted: .res 1            ; Save data for the tutorial completion state.

.segment "ZEROPAGE"

.enum TUTORIAL_STEPS
  WELCOME

  GHOST_GRAVE_PLACEMENT
  ROW_AND_COLUMN_NUMBERS
  GHOST_BESIDE_GRAVE
  GHOSTS_CANT_TOUCH
  HOW_TO_DIG
  MARKING_TILES
  GRAVE_ARROWS
  LEAVE_LEVEL
  SPECIAL_LEVELS
  SHY_GHOST
  NO_SHOVEL
  TIME_ATTACK

  FAREWELL
  COMPLETED
.endenum

TutorialAdvanceDebounceTarget = 30     ; Block the user from pressing through the tutorial steps too quickly.

TutorialAdvanceDebounce: .res 1        ; Tick counter for debouncing input.
TutorialStep: .res 1                   ; Index of the tutorial in the TUTORIAL_STEPS enum.

.segment "CODE"

.proc TutorialWelcome
  ldx #<Tutorial1BackgroundData
  ldy #>Tutorial1BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialGhostGravePlacement
  ldx #<Tutorial2BackgroundData
  ldy #>Tutorial2BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialRowAndColumnNumbers
  ldx #<Tutorial3BackgroundData
  ldy #>Tutorial3BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialGhostBesideGrave
  ldx #<Tutorial4BackgroundData
  ldy #>Tutorial4BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialGhostsCantTouch
  ldx #<Tutorial5BackgroundData
  ldy #>Tutorial5BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialHowToDig
  ldx #<Tutorial6BackgroundData
  ldy #>Tutorial6BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialMarkingTiles
  ldx #<Tutorial7BackgroundData
  ldy #>Tutorial7BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialGraveArrows
  ldx #<Tutorial8BackgroundData
  ldy #>Tutorial8BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialLeaveLevel
  ldx #<Tutorial9BackgroundData
  ldy #>Tutorial9BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialSpecialLevels
  ldx #<Tutorial10BackgroundData
  ldy #>Tutorial10BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialShyGhost
  ldx #<Tutorial11BackgroundData
  ldy #>Tutorial11BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialNoShovel
  ldx #<Tutorial12BackgroundData
  ldy #>Tutorial12BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialTimeAttack
  ldx #<Tutorial13BackgroundData
  ldy #>Tutorial13BackgroundData
  jsr LoadBackgroundRLE
  
  rts
.endproc

.proc TutorialFarewell
  ldx #<Tutorial14BackgroundData
  ldy #>Tutorial14BackgroundData
  jsr LoadBackgroundRLE

  rts
.endproc

.proc TutorialCompleted
  lda #1
  sta PlayerProgressTutorialCompleted  ; Mark the tutorial as completed so this screen isn't shown again.
  
  lda #SCREEN_TYPE::LEVEL_SELECT       ; Then move to the level select screen.
  sta CurrScreen

  rts
.endproc

;; Indexes into the tutorial steps, and jumps to the correct tutorial code.
.proc AdvanceTutorialStep
  lda TutorialAdvanceDebounce
  cmp #0
  beq :+                               ; Early return on debounced input.
    rts
  :

  lda #TutorialAdvanceDebounceTarget
  sta TutorialAdvanceDebounce

  ;; Disable VBlank.
  lda #0
  sta PPU_CTRL
  sta PPU_MASK

  inc TutorialStep
  lda TutorialStep

  cmp #TUTORIAL_STEPS::WELCOME
  bne :+
    jsr TutorialWelcome
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::GHOST_GRAVE_PLACEMENT
  bne :+
    jsr TutorialGhostGravePlacement
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::ROW_AND_COLUMN_NUMBERS
  bne :+
    jsr TutorialRowAndColumnNumbers
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::GHOST_BESIDE_GRAVE
  bne :+
    jsr TutorialGhostBesideGrave
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::GHOSTS_CANT_TOUCH
  bne :+
    jsr TutorialGhostsCantTouch
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::HOW_TO_DIG
  bne :+
    jsr TutorialHowToDig
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::MARKING_TILES
  bne :+
    jsr TutorialMarkingTiles
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::GRAVE_ARROWS
  bne :+
    jsr TutorialGraveArrows
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::LEAVE_LEVEL
  bne :+
    jsr TutorialLeaveLevel
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::SPECIAL_LEVELS
  bne :+
    jsr TutorialSpecialLevels
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::SHY_GHOST
  bne :+
    jsr TutorialShyGhost
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::NO_SHOVEL
  bne :+
    jsr TutorialNoShovel
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::TIME_ATTACK
  bne :+
    jsr TutorialTimeAttack
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::FAREWELL
  bne :+
    jsr TutorialFarewell
    jmp DoneTutorialStep
  :

  cmp #TUTORIAL_STEPS::COMPLETED
  bne :+
    jsr TutorialCompleted
    jmp DoneTutorialStep
  :

  DoneTutorialStep:

  ;; Enable VBlank.
  lda #(PPU_CTRL_FLAGS::ENABLE_VBLANK_NMI)
  sta PPU_CTRL

  rts
.endproc

.proc TutorialInit
  ;; Disable VBlank.
  lda #0
  sta PPU_CTRL
  sta PPU_MASK

  SET_CHR_MAPPER CHR_MAP::TUTORIAL

  ldx #<GameBackgroundPalette
  ldy #>GameBackgroundPalette
  jsr LoadPalette

  lda #0
  sta TutorialAdvanceDebounce

  lda #255
  sta TutorialStep                     ; Since moving to the next tutorial step increases this, it will wrap around to step 0 (welcome step).

  jsr AdvanceTutorialStep

  rts
.endproc

.proc TutorialUpdate
  lda TutorialAdvanceDebounce
  cmp #0
  beq :+
    dec TutorialAdvanceDebounce        ; Update the debounced input.
  :

  lda PressedButtons
  cmp #0
  beq :+
    jsr AdvanceTutorialStep            ; Update the tutorial step on any input.
  :
  rts
.endproc

.proc TutorialCleanup
  rts
.endproc

Tutorial1BackgroundData:
.incbin "nametables/tutorial_1.rle"

Tutorial2BackgroundData:
.incbin "nametables/tutorial_2.rle"

Tutorial3BackgroundData:
.incbin "nametables/tutorial_3.rle"

Tutorial4BackgroundData:
.incbin "nametables/tutorial_4.rle"

Tutorial5BackgroundData:
.incbin "nametables/tutorial_5.rle"

Tutorial6BackgroundData:
.incbin "nametables/tutorial_6.rle"

Tutorial7BackgroundData:
.incbin "nametables/tutorial_7.rle"

Tutorial8BackgroundData:
.incbin "nametables/tutorial_8.rle"

Tutorial9BackgroundData:
.incbin "nametables/tutorial_9.rle"

Tutorial10BackgroundData:
.incbin "nametables/tutorial_10.rle"

Tutorial11BackgroundData:
.incbin "nametables/tutorial_11.rle"

Tutorial12BackgroundData:
.incbin "nametables/tutorial_12.rle"

Tutorial13BackgroundData:
.incbin "nametables/tutorial_13.rle"

Tutorial14BackgroundData:
.incbin "nametables/tutorial_14.rle"

