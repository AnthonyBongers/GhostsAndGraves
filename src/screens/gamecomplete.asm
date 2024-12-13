.segment "ZEROPAGE"

GameCompleteDebounceTarget = 60        ; Block the user from pressing through the screen too quickly.
GameCompleteDebounce: .res 1           ; Tick counter for debouncing input.

.segment "CODE"

.proc GameCompleteInit
  ;; Disable VBlank.
  lda #0
  sta PPU_CTRL
  sta PPU_MASK

  SET_CHR_MAPPER CHR_MAP::TUTORIAL

  ldx #<GameCompleteBackgroundData     ; Nothing fancy here, just show a pre-generated thank you message :) 
  ldy #>GameCompleteBackgroundData
  jsr LoadBackgroundRLE

  ldx #<GameBackgroundPalette
  ldy #>GameBackgroundPalette
  jsr LoadPalette

  ;; Enable VBlank.
  lda #(PPU_CTRL_FLAGS::ENABLE_VBLANK_NMI)
  sta PPU_CTRL

  lda #0
  sta GameCompleteDebounce
  sta DidCompleteGame                  ; Reset the game complete flag, so we don't show this screen again.

  rts
.endproc

.proc GameCompleteUpdate
  lda GameCompleteDebounce
  cmp #0
  beq :+
    dec TutorialAdvanceDebounce        ; Update the debounced input.
    rts
  :

  lda PressedButtons
  cmp #0
  beq :+
    lda #SCREEN_TYPE::LEVEL_SELECT     ; Move to the level select screen.
    sta CurrScreen
  :
  rts
.endproc

.proc GameCompleteCleanup
  rts
.endproc

GameCompleteBackgroundData:
.incbin "nametables/gamecomplete.rle"

