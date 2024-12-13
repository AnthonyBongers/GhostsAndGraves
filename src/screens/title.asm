.segment "ZEROPAGE"

TitleSpritePtr: .res 2                 ; OAM sprite destination address.
TitleSpriteX: .res 1                   ; Track the x pixel coord to place the next sprite in the title text.
TitleSpriteY: .res 1                   ; Samesies ^, but for the y pixel coord.
TitleSpriteCellIndex: .res 1           ; Track the next sprite sheet index to draw.
TitleSpriteCellStride: .res 1          ; Track how many sprites have been drawn in this row.

.segment "CODE"

;; Draw padding to the PPU until we get to the x position to render the title background.
.proc DrawBuffer
  ldx #$08
  LoopBuffer:
    dex
    lda #$00
    sta PPU_DATA
    cpx #$00
    bne LoopBuffer

  rts
.endproc

;; A bit of a different PPU drawing routine than others.
;; There's no encoding here, we just draw the background tiles as-is to the PPU.
;; Since the background tile sheet is smaller than the nametable, we need to add padding in each axis.
.proc DrawSplash
  lda #$20
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR

  ;; Add padding to the top before rendering the title background, to center it.
  ldx #$80
  LoopTopRows:
    dex
    lda #$00
    sta PPU_DATA                       ; Just render blank tiles until we get to the correct y position.

    cpx #0
    bne LoopTopRows

  ldy #0
  LoopTitleImage:
    jsr DrawBuffer                     ; Add an x buffer to center before drawing the background.

    lda #0
    LoopCell:
      sty PPU_DATA
      iny

      clc
      adc #1
      cmp #$10
      bne LoopCell

    jsr DrawBuffer                     ; Add the x buffer afterwards too.

    cpy #$00
    bne LoopTitleImage

  rts
.endproc

;; Starting position to render the title text (x and y pixel coords).
TitleStartX = 96
TitleStartY = 160

;; Draw the sprites for the game title text.
.proc DrawTitleText
  lda #$00
  sta TitleSpritePtr+0
  lda #$02
  sta TitleSpritePtr+1

  lda #TitleStartX
  sta TitleSpriteX
  lda #TitleStartY
  sta TitleSpriteY

  lda #0
  sta TitleSpriteCellIndex
  sta TitleSpriteCellStride

  ldy #0
  LoopTitleSprites:
    ;; Sprite Y coord.
    lda TitleSpriteY
    sta (TitleSpritePtr),y
    iny

    ;; Tile sheet index for the sprite.
    lda TitleSpriteCellIndex
    sta (TitleSpritePtr),y
    iny

    ;; Attributes (none, nothin fancy goin on here).
    lda #%00000000
    sta (TitleSpritePtr),y
    iny

    ;; Sprite x coord.
    lda TitleSpriteX
    sta (TitleSpritePtr),y
    iny

    ;; Each sprite added will be 8 units over (since the tiles are 8x8).
    lda TitleSpriteX
    clc
    adc #$08
    sta TitleSpriteX
    
    inc TitleSpriteCellIndex
    
    ; The title text is 8 tiles across. If we hit that, we can move to the next row of sprites.
    inc TitleSpriteCellStride
    lda TitleSpriteCellStride
    cmp #$08
    bne :+
      lda #0
      sta TitleSpriteCellStride        ; The x position goes back to 0 since we're on a new row.

      lda #TitleStartX
      sta TitleSpriteX

      lda TitleSpriteY                 ; Y coord increases by 8 pixels (since the tiles are 8x8).
      clc
      adc #$08
      sta TitleSpriteY

      lda TitleSpriteCellIndex         ; Update the sprite tile index we're pointing to in the new row.
      clc
      adc #$08
      sta TitleSpriteCellIndex
    :

    ;; Once we've added all the sprite data, we can exit.
    cpy #160
    bne LoopTitleSprites
    
  rts
.endproc

.proc TitleInit
  ;; Disable VBlank.
  lda #0
  sta PPU_CTRL
  sta PPU_MASK

  SET_CHR_MAPPER CHR_MAP::TITLE

  ldx #<TitleBackgroundPalette
  ldy #>TitleBackgroundPalette
  jsr LoadPalette

  jsr DrawSplash
  jsr DrawTitleText

  ;; Enable VBlank.
  lda #(PPU_CTRL_FLAGS::ENABLE_VBLANK_NMI | PPU_CTRL_FLAGS::SPRITE_ADDR)
  sta PPU_CTRL

  jsr PlayTitleMusic                   ; This is the title screen, so jam out to some tunes.

  rts
.endproc

.proc TitleUpdate
  lda PressedButtons                   ; Pressing any button moves the player from the screen.
  beq :+
    lda PlayerProgressTutorialCompleted
    cmp #0
    bne TutorialCompleted              ; If this is the first time playing, move the player to the tutorial screen.
      lda #SCREEN_TYPE::TUTORIAL
      sta CurrScreen
      rts
    TutorialCompleted:

    lda #SCREEN_TYPE::LEVEL_SELECT
    sta CurrScreen                    ; Otherwise, switch to the level select screen.
  :

  rts
.endproc

.proc TitleCleanup
  ;; Clean up all the sprite data from the OAM so we don't show them on the next screen.
  lda #$00
  sta TitleSpritePtr+0
  lda #$02
  sta TitleSpritePtr+1

  ldy #0
  LoopClearSpriteData:
    lda #$ff
    sta (TitleSpritePtr),y

    iny
    cpy #$ff
    bne LoopClearSpriteData

  jsr StopMusic                        ; Stop the title music.

  rts
.endproc

TitleBackgroundPalette:
.byte $30,$3d,$28,$01, $30,$3d,$28,$01, $30,$3d,$28,$01, $30,$3d,$28,$01
.byte $30,$0d,$28,$01, $30,$3d,$28,$01, $30,$3d,$28,$01, $30,$3d,$28,$01

