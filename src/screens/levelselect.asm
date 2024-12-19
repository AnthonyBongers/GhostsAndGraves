.include "leveltable.asm"

.segment "ZEROPAGE"

LevelLaneDrawPtr: .res 2               ; Parameter to select where to draw the level lane.

WorldDigits: .res 2                    ; The number to draw, representing the player world progress.

LevelSelectSpritePtrAddr = $0200
LevelSelectSpritePtr: .res 2           ; OAM sprite address to draw the level selection cursor.
LevelSelectCursorCounter: .res 1       ; Frame tracker to progress to the next cursor animation sprite.
LevelSelectCursorIndex: .res 1         ; The sprite sheet index to draw for the cursor.

LevelSelectCursorXOrigin = 24
LevelSelectCursorYOrigin = 63
LevelSelectCursorX: .res 1             ; The cursor x pixel coord.
LevelSelectCursorY: .res 1             ; The cursor y pixel coord.

.segment "CODE"

WorldDigitsPPUAddr = $2052             ; PPU address destination for the world number text.

;; Draw the player world progression number on the screen at the top.
;; Converts the progress into decimal mode, then renders.
.proc DrawWorldDigits
  lda #0                               ; Reset the data from 0.
  sta WorldDigits+0
  sta WorldDigits+1

  ldx PlayerProgressWorld              ; Loop the hex progression to convert to two decimal bytes.
  inx
  LoopWorld:
    cpx #0
    beq EndLoopWorld

    inc WorldDigits+1
    lda WorldDigits+1
    cmp #10                            ; If we hit decimal 10, increment the hi byte and reset the lo byte to 0.
    bne :+
      lda #0
      sta WorldDigits+1

      inc WorldDigits+0
    :

    dex
    jmp LoopWorld
  EndLoopWorld:

  ;; Set the PPU address destination.
  lda #>WorldDigitsPPUAddr
  sta PPU_ADDR
  lda #<WorldDigitsPPUAddr
  sta PPU_ADDR

  ;; Draw the upper portion of the decimal hi byte.
  lda WorldDigits+0
  clc
  adc #$60
  sta PPU_DATA

  ;; Draw the lower portion of the decimal hi byte.
  lda WorldDigits+1
  clc
  adc #$60
  sta PPU_DATA

  ;; Shift over in the PPU for the decimal lo byte.
  lda #>WorldDigitsPPUAddr
  sta PPU_ADDR
  lda #<WorldDigitsPPUAddr
  clc
  adc #$20
  sta PPU_ADDR

  ;; Draw the upper portion of the decimal lo byte.
  lda WorldDigits+0
  clc
  adc #$70
  sta PPU_DATA

  ;; Draw the lower portion of the decimal lo byte.
  lda WorldDigits+1
  clc
  adc #$70
  sta PPU_DATA

  rts
.endproc

;; Draw several levels on the x axis to the PPU.
;; Takes the LevelLaneDrawPtr as an argument to determine the starting position to render.
.proc DrawLevelLane
  lda LevelLaneDrawPtr+1
  sta PPU_ADDR
  lda LevelLaneDrawPtr+0
  sta PPU_ADDR

  ;; Draw the top of the level graves.
  ldx #$40
  ldy #0
  LoopLevelTopMarkers:
    stx PPU_DATA
    inx
    stx PPU_DATA
    inx

    lda #$00                           ; Draw a gap of two tiles between each level grave.
    sta PPU_DATA
    sta PPU_DATA

    iny
    cpy #7                             ; Each lane has 7 levels. Keep drawing until we reach that.
    bne LoopLevelTopMarkers

  ;; Draw the bottom of the level graves.
  ;; This is one PPU row down, so add the difference to the PPU address.
  lda LevelLaneDrawPtr+0
  clc
  adc #$20
  sta LevelLaneDrawPtr+0
  lda LevelLaneDrawPtr+1
  adc #$00
  sta PPU_ADDR
  lda LevelLaneDrawPtr+0
  sta PPU_ADDR

  ldx #$50
  ldy #0
  LoopLevelBottomMarkers:
    stx PPU_DATA
    inx
    stx PPU_DATA
    inx

    lda #$00                           ; Just like the top, add a space between each level marker.
    sta PPU_DATA
    sta PPU_DATA

    iny
    cpy #7                             ; Loop until we hit seven level markers.
    bne LoopLevelBottomMarkers

  rts
.endproc

;; The lower row of levels are special levels.
;; The first 3 are Shy Ghost levels, so draw a ghost indicator sprite on the level to signify that.
;; The next 3 are no shovel levels, so draw a shovel indicator sprite on the level to signify that.
;; The last level is a time attack level, so draw a timea timer sprite on the level to signify that.
.proc DrawLevelDecorations
  lda #<LevelSelectSpritePtrAddr
  sta LevelSelectSpritePtr+0
  lda #>LevelSelectSpritePtrAddr
  sta LevelSelectSpritePtr+1

  ldy #16                              ; Start at OAM offset of 16, to account for the cursor (4 sprites of 4 bytes each = 16).

  ;; Decoration for Level 1
  lda #182
  sta (LevelSelectSpritePtr),y
  iny

  lda #$21
  sta (LevelSelectSpritePtr),y
  iny

  lda #%00000000
  sta (LevelSelectSpritePtr),y
  iny

  lda #32
  sta (LevelSelectSpritePtr),y
  iny

  ;; Decoration for Level 2
  lda #182
  sta (LevelSelectSpritePtr),y
  iny

  lda #$21
  sta (LevelSelectSpritePtr),y
  iny

  lda #%00000000
  sta (LevelSelectSpritePtr),y
  iny

  lda #64
  sta (LevelSelectSpritePtr),y
  iny

  ;; Decoration for Level 3
  lda #182
  sta (LevelSelectSpritePtr),y
  iny

  lda #$21
  sta (LevelSelectSpritePtr),y
  iny

  lda #%00000000
  sta (LevelSelectSpritePtr),y
  iny

  lda #96
  sta (LevelSelectSpritePtr),y
  iny

  ;; Decoration for Level 4
  lda #182
  sta (LevelSelectSpritePtr),y
  iny

  lda #$22
  sta (LevelSelectSpritePtr),y
  iny

  lda #%00000000
  sta (LevelSelectSpritePtr),y
  iny

  lda #128
  sta (LevelSelectSpritePtr),y
  iny

  ;; Decoration for Level 5
  lda #182
  sta (LevelSelectSpritePtr),y
  iny

  lda #$22
  sta (LevelSelectSpritePtr),y
  iny

  lda #%00000000
  sta (LevelSelectSpritePtr),y
  iny

  lda #160
  sta (LevelSelectSpritePtr),y
  iny

  ;; Decoration for Level 6
  lda #182
  sta (LevelSelectSpritePtr),y
  iny

  lda #$22
  sta (LevelSelectSpritePtr),y
  iny

  lda #%00000000
  sta (LevelSelectSpritePtr),y
  iny

  lda #192
  sta (LevelSelectSpritePtr),y
  iny

  ;; Decoration for Level 7
  lda #182
  sta (LevelSelectSpritePtr),y
  iny

  lda #$20
  sta (LevelSelectSpritePtr),y
  iny

  lda #%00000000
  sta (LevelSelectSpritePtr),y
  iny

  lda #224
  sta (LevelSelectSpritePtr),y
  iny

  rts
.endproc

;; Draw the cursor sprite for the currently selected level.
;; This code is grosser than I initially intended, and realistically should be refactored to be shared with the game cursor.
.proc DrawCursor
  lda #<LevelSelectSpritePtrAddr       ; Set the OAM address destination for drawing sprites.
  sta LevelSelectSpritePtr+0
  lda #>LevelSelectSpritePtrAddr
  sta LevelSelectSpritePtr+1

  ;; Animate the cursor.
  inc LevelSelectCursorCounter
  lda LevelSelectCursorCounter
  cmp #8                               ; Every 8 frames, change the sprite animation index.
  bne :+
    lda #0
    sta LevelSelectCursorCounter

    inc LevelSelectCursorIndex
    lda LevelSelectCursorIndex
    cmp #7                             ; When we reach the last animation index, loop back to the start.
    bne CursorMax
      lda #0
      sta LevelSelectCursorIndex
    CursorMax:
  :

  ;; Determine the cursor position. We start at a predetermined x and y pixel coord.
  lda #LevelSelectCursorXOrigin
  sta LevelSelectCursorX
  lda #LevelSelectCursorYOrigin
  sta LevelSelectCursorY

  ldx #0
  ldy #0
  LoopCursorPosition:
    cpx PlayerProgressLevel
    beq LoopCursorPositionComplete     ; When we reach the player level progress, we're done calculating the x and y position.

    inx
    iny

    lda LevelSelectCursorX             ; For each level increment, move the x pixel coord over by 32 (the grave is 16 pixels wide, with a 16 pixel gap).
    clc
    adc #32
    sta LevelSelectCursorX

    cpy #7
    bne LoopCursorPosition             ; If we haven't hit the end of row boundary of 7 levels yet, just loop back to the top.

    ldy #0                             ; Reset the level counter back to 0 since we're at the beginning of the next row.

    lda LevelSelectCursorY             ; For each row increment, move the y pixel coord down by 32 (the grave is 16 pixels hight, with a 16 pixel gap).
    clc
    adc #32
    sta LevelSelectCursorY

    cpx #21                            ; Special case: when we hit the special levels, there's a 1-row gap, so move an extra 32 pixels down.
    bne :+
      lda LevelSelectCursorY
      clc
      adc #32
      sta LevelSelectCursorY
    :

    lda #LevelSelectCursorXOrigin      ; We're still in the "you hit the next row" logic, so we want to set the x back to the origin position.
    sta LevelSelectCursorX

    jmp LoopCursorPosition

  LoopCursorPositionComplete:

  ;; Okay now we get to the gross sprite drawing logic.
  ;; The cursor consists of four separate sprites.
  ;; We add the y, tile index, attributes, and x for each of these sprites.

  ldy #0

  ;; Cursor sprite 1 - top left.
  lda LevelSelectCursorY
  sta (LevelSelectSpritePtr),y
  iny

  lda LevelSelectCursorIndex
  sta (LevelSelectSpritePtr),y
  iny

  lda #%00000000
  sta (LevelSelectSpritePtr),y
  iny

  lda LevelSelectCursorX
  sta (LevelSelectSpritePtr),y
  iny

  ;; Cursor sprite 2 - bottom left.
  lda LevelSelectCursorY
  clc
  adc #8
  sta (LevelSelectSpritePtr),y
  iny

  lda LevelSelectCursorIndex
  clc
  adc #$10
  sta (LevelSelectSpritePtr),y
  iny

  lda #%11000000
  sta (LevelSelectSpritePtr),y
  iny

  lda LevelSelectCursorX
  sta (LevelSelectSpritePtr),y
  iny

  ;; Cursor sprite 3 - top right.
  lda LevelSelectCursorY
  sta (LevelSelectSpritePtr),y
  iny

  lda LevelSelectCursorIndex
  clc
  adc #$10
  sta (LevelSelectSpritePtr),y
  iny

  lda #%00000000
  sta (LevelSelectSpritePtr),y
  iny

  lda LevelSelectCursorX
  clc
  adc #8
  sta (LevelSelectSpritePtr),y
  iny

  ;; Cursor sprite 4 - bottom right.
  lda LevelSelectCursorY
  clc
  adc #8
  sta (LevelSelectSpritePtr),y
  iny

  lda LevelSelectCursorIndex
  sta (LevelSelectSpritePtr),y
  iny

  lda #%11000000
  sta (LevelSelectSpritePtr),y
  iny

  lda LevelSelectCursorX
  clc
  adc #8
  sta (LevelSelectSpritePtr),y
  iny

  rts
.endproc

.proc LevelSelectInit
  ;; Disable VBlank.
  lda #0
  sta PPU_CTRL
  sta PPU_MASK

  SET_CHR_MAPPER CHR_MAP::LEVEL_SELECT

  ldx #<LevelSelectBackgroundPalette
  ldy #>LevelSelectBackgroundPalette
  jsr LoadPalette

  ldx #<LevelSelectBackgroundData
  ldy #>LevelSelectBackgroundData
  jsr LoadBackgroundRLE

  ;; Draw the lane for the first 7 levels.
  lda #$21
  sta LevelLaneDrawPtr+1
  lda #$03
  sta LevelLaneDrawPtr+0
  jsr DrawLevelLane

  ;; Draw the second lane for the next 7 levels.
  lda #$21
  sta LevelLaneDrawPtr+1
  lda #$83
  sta LevelLaneDrawPtr+0
  jsr DrawLevelLane

  ;; Draw the third lane for the next 7 levels.
  lda #$22
  sta LevelLaneDrawPtr+1
  lda #$03
  sta LevelLaneDrawPtr+0
  jsr DrawLevelLane

  ;; Draw the special level lane.
  lda #$23
  sta LevelLaneDrawPtr+1
  lda #$03
  sta LevelLaneDrawPtr+0
  jsr DrawLevelLane

  jsr DrawWorldDigits                  ; Draw the player world progress number at the title.

  ;; Enable VBlank.
  lda #(PPU_CTRL_FLAGS::ENABLE_VBLANK_NMI | PPU_CTRL_FLAGS::SPRITE_ADDR)
  sta PPU_CTRL

  jsr DrawLevelDecorations             ; Draw the special level decorations on the last lane.

  rts
.endproc

.proc LevelSelectUpdate
  jsr DrawCursor

  lda PressedButtons
  and #(BUTTON_START | BUTTON_A)       ; On a confirmation button press...
  beq :+
    jsr GetLevelAddress                ; Calculate the level address in ROM...
    
    lda #SCREEN_TYPE::GAME             ; And switch over to the game screen.
    sta CurrScreen
  :

  lda PressedButtons
  and #(BUTTON_SELECT)                 ; On a SELECT press...
  beq :+
    lda #SCREEN_TYPE::TUTORIAL         ; Bring the player to the tutorial if they need a refresher.
    sta CurrScreen
  :

  rts
.endproc

.proc LevelSelectCleanup
  ;; Clean up all the sprite OAM data used on this screen.
  lda #$00
  sta LevelSelectSpritePtr+0
  lda #$02
  sta LevelSelectSpritePtr+1

  ldy #0
  LoopClearSpriteData:
    lda #$ff
    sta (LevelSelectSpritePtr),y

    iny
    cpy #$ff
    bne LoopClearSpriteData

  ldy #0
  lda #0

  rts
.endproc

LevelSelectBackgroundData:
.incbin "nametables/levelselect.rle"

LevelSelectBackgroundPalette:
.byte $1B,$0D,$3B,$0A, $1B,$0D,$17,$27, $1B,$0D,$13,$33, $1B,$0D,$16,$36
.byte $1B,$27,$27,$1C, $1B,$31,$27,$1C, $1B,$31,$27,$1C, $1B,$31,$27,$1C

