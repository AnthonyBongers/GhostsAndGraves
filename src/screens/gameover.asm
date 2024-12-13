.segment "ZEROPAGE"

GameOverTimeoutTarget = 60                ; Stay on this screen for 1 second.
GameOverTimeout: .res 1                   ; Timer before you can leave the screen.

;; Starting position to render the title text (x and y pixel coords).
GameOverTextStartX = 128
GameOverTextStartY = 96

GameOverSpritePtr: .res 2                 ; OAM sprite destination address.
GameOverSpriteX: .res 1                   ; Track the x pixel coord to place the next sprite in the game over text.
GameOverSpriteY: .res 1                   ; Samesies ^, but for the y pixel coord.
GameOverSpriteCellIndex: .res 1           ; Track the next sprite sheet index to draw.
GameOverSpriteCellStride: .res 1          ; Track how many sprites have been drawn in this row.

.segment "CODE"

.proc RenderGameOverText
  lda #$00
  sta GameOverSpritePtr+0
  lda #$02
  sta GameOverSpritePtr+1

  lda #GameOverTextStartX
  sta GameOverSpriteX
  lda #GameOverTextStartY
  sta GameOverSpriteY

  lda #0
  sta GameOverSpriteCellStride

  lda #$60
  sta GameOverSpriteCellIndex

  lda LevelSuccess
  cmp #0
  beq :+
    lda #$20
    sta GameOverSpriteCellIndex
  :

  ldy #0
  LoopGameOverSprites:
    ;; Sprite Y coord.
    lda GameOverSpriteY
    sta (GameOverSpritePtr),y
    iny

    ;; Tile sheet index for the sprite.
    lda GameOverSpriteCellIndex
    sta (GameOverSpritePtr),y
    iny

    ;; Attributes (use the fourth sprite colour index).
    lda #%00000011
    sta (GameOverSpritePtr),y
    iny

    ;; Sprite x coord.
    lda GameOverSpriteX
    sta (GameOverSpritePtr),y
    iny

    ;; Each sprite added will be 8 units over (since the tiles are 8x8).
    lda GameOverSpriteX
    clc
    adc #$08
    sta GameOverSpriteX
    
    inc GameOverSpriteCellIndex
    
    ; The game over text is 8 tiles across. If we hit that, we can move to the next row of sprites.
    inc GameOverSpriteCellStride
    lda GameOverSpriteCellStride
    cmp #$08
    bne :+
      lda #0
      sta GameOverSpriteCellStride     ; The x position goes back to 0 since we're on a new row.

      lda #GameOverTextStartX
      sta GameOverSpriteX

      lda GameOverSpriteY              ; Y coord increases by 8 pixels (since the tiles are 8x8).
      clc
      adc #$08
      sta GameOverSpriteY

      lda GameOverSpriteCellIndex      ; Update the sprite tile index we're pointing to in the new row.
      clc
      adc #$08
      sta GameOverSpriteCellIndex
    :

    ;; Once we've added all the sprite data, we can exit.
    cpy #128
    bne LoopGameOverSprites
    
  rts
.endproc

.proc GameOverInit

  jsr RenderGameOverText

  rts
.endproc

.proc GameOverUpdate
  lda GameOverTimeout
  cmp #GameOverTimeoutTarget
  beq :+
    inc GameOverTimeout
    rts
  :

  lda PressedButtons
  beq :+
    lda DidCompleteGame
    cmp #1                             ; If that was the last level, go to the game complete screen.
    bne GameNotCompleted
      lda #SCREEN_TYPE::GAME_COMPLETE
      sta CurrScreen
      rts
    GameNotCompleted:

    lda #SCREEN_TYPE::LEVEL_SELECT     ; Otherwise, go back to the level select screen.
    sta CurrScreen
  :

  rts
.endproc

.proc GameOverCleanup
  ;; Clean up all the sprite data from the OAM so we don't show them on the next screen.
  lda #$00
  sta GameOverSpritePtr+0
  lda #$02
  sta GameOverSpritePtr+1

  ldy #0
  LoopClearSpriteData:
    lda #$ff
    sta (GameOverSpritePtr),y

    iny
    cpy #$ff
    bne LoopClearSpriteData

  rts
.endproc

