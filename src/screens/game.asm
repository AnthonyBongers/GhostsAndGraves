.include "../gametimer.asm"

MaximumLevelWidth = 10                           ; Level size limit for width. A bit smaller to account for game details on the left of the screen.
MaximumLevelHeight = 11                          ; Level size limit for height.

.segment "ZEROPAGE"

LevelPtr: .res 2                                 ; Point to the current level being played.

LevelType: .res 1                                ; Which type of level is being played.

HiddenLanesHorizontal: .res 1                    ; Shy Ghost: Horizontal lanes to hide (hi and lo nybble to contain two rows).
HiddenLanesVertical: .res 1                      ; Shy Ghost: Vertical lanes to hide (hi and lo nybble to contain two columns).

Timer: .res 2                                    ; Time Attack: How many seconds the player is given.

LevelHeight: .res 1                              ; How many cells high is the level.
LevelWidth: .res 1                               ; How many cells wide is the level.
LevelCellCount: .res 1                           ; How many cells are in the level.
LevelCellIndex: .res 1                           ; Used as an index offset into the board.
LevelCellIndexX: .res 1                          ; Index into the rows of the board.
LevelCellIndexY: .res 1                          ; Index into the columns of the board.

GhostColumnCounters: .res MaximumLevelWidth      ; How many ghosts are in each vertical column (starting at the top).
GhostRowCounters: .res MaximumLevelHeight        ; How many ghosts are in each horizontal row (starting from the left).

.segment "WRAM" 

LevelBoard: .res (MaximumLevelWidth * MaximumLevelHeight)  ; Array of the loaded level (source of truth on level completion).
PlayerBoard: .res (MaximumLevelWidth * MaximumLevelHeight) ; Array of the state of the player-modifiable board.

.segment "CODE"

.enum LevelTypes
  Standard = 1
  NoShovel
  ShyGhosts
  TimeAttack
.endenum

.enum CellTypes
  Empty = 0
  Ghost
  Grave
  GraveUp
  GraveRight
  GraveDown
  GraveLeft
  Ground
.endenum

;; Parse the level bytes and store the results in RAM values for usage throughout the game logic.
.proc ReadLevel
  ldy #0

  ;; Load and store the level type.
  lda (LevelPtr),y
  iny
  sta LevelType

  ;; Load data for Shy Ghost level types.
  lda LevelType
  cmp #LevelTypes::ShyGhosts
  bne :+
    lda (LevelPtr),y
    iny
    sta HiddenLanesHorizontal          ; Horizontal lanes to hide

    lda (LevelPtr),y
    iny
    sta HiddenLanesVertical            ; Vertical lanes to hide
  :

  ;; Load data for Time Attack level types.
  lda LevelType
  cmp #LevelTypes::TimeAttack
  bne :+
    lda (LevelPtr),y
    iny
    sta Timer+0                        ; Hi-byte of timer.

    lda (LevelPtr),y
    iny
    sta Timer+1                        ; Lo-byte of timer.
  :

  lda (LevelPtr),y
  lsr
  lsr
  lsr
  lsr
  sta LevelWidth                       ; The hi-nybble has the width.

  lda (LevelPtr),y
  and #%00001111
  sta LevelHeight                      ; The lo-nybble has the height.
  iny

  ;; Count the cells in the level.
  lda #0                               ; Use accumulator as the counter.
  ldx LevelHeight                      ; For each row in the level...
  TotalCellLoop:
    clc
    adc LevelWidth                     ; Add the level width to the counter.
    dex
    bne TotalCellLoop                  ; When we reach no rows left, end the loop.
    sta LevelCellCount

  ;; Load the cells into the board arrays.
  ;; Each byte contains four cells (%00112233).
  ldx #0
  CellReader:
    lda (LevelPtr),y                   ; Load the current byte from the serialized level.
    and #%11000000                     ; Mask the bits for the first cell.
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    sta PlayerBoard,x
    sta LevelBoard,x
    inx

    cpx LevelCellCount
    beq CellReaderComplete

    lda (LevelPtr),y                   ; Load the current byte from the serialized level.
    and #%00110000                     ; Mask the bits for the second cell.
    lsr
    lsr
    lsr
    lsr
    sta PlayerBoard,x
    sta LevelBoard,x
    inx

    cpx LevelCellCount
    beq CellReaderComplete

    lda (LevelPtr),y                   ; Load the current byte from the serialized level.
    and #%00001100                     ; Mask the bits for the third cell.
    lsr
    lsr
    sta PlayerBoard,x
    sta LevelBoard,x
    inx

    cpx LevelCellCount
    beq CellReaderComplete

    lda (LevelPtr),y                   ; Load the current byte from the serialized level.
    and #%00000011                     ; Mask the bits for the fourth cell.
    sta PlayerBoard,x
    sta LevelBoard,x
    inx

    iny                                ; Move to the next serialized level byte.

    cpx LevelCellCount
    bne CellReader
  CellReaderComplete:

  ;; Sanitize the player board by removing ghost cells
  ldx #0
  LoopPlayerBoard:
    lda PlayerBoard,x
    cmp #CellTypes::Ghost              ; If a ghost was found...
    bne :+
      lda #CellTypes::Empty
      sta PlayerBoard,x
    :

    inx
    cpx LevelCellCount                 ; If there are still cells to check in the level, continue the loop.
    bcc LoopPlayerBoard

  ;; Clear out any potentially stale data from earlier levels.
  ldx #0
  LoopClearGhostRowCounters:
    lda #0
    sta GhostRowCounters,x

    inx
    cpx LevelHeight
    bne LoopClearGhostRowCounters

  ldx #0
  LoopClearGhostColumnCounters:
    lda #0
    sta GhostColumnCounters,x

    inx
    cpx LevelWidth
    bne LoopClearGhostColumnCounters

  ;; Count how many ghosts are in each row / column.
  ldx #0
  ldy #0
  LoopGhostCounters:
    ldx LevelCellIndex
    lda LevelBoard,x
    ldx LevelCellIndexX

    cmp #CellTypes::Ghost              ; If we find a ghost...
    bne :+
      ldx LevelCellIndexY
      inc GhostRowCounters,x           ; Increment the row counter.
      ldx LevelCellIndexX
      inc GhostColumnCounters,x        ; Increment the column counter.
    :

    inc LevelCellIndex
    inc LevelCellIndexX
    inx
    cpx LevelWidth                     ; If there are still cells to check in the row, continue the loop.
    bne LoopGhostCounters

    ldx #0                             ; New row, so move x back to 0.
    stx LevelCellIndexX
    inc LevelCellIndexY
    iny
    cpy LevelHeight                    ; If there are still cells to check in the column, continue the loop.
    bne LoopGhostCounters

  lda LevelType
  cmp #LevelTypes::ShyGhosts
  bne :+
    lda HiddenLanesHorizontal
    and #$0f
    cmp #$0f                           ; Check if a hidden lane is available.
    beq SkipFirstHiddenRow
      tax
      lda #7                           ; If so, set the lane to empty (in this case an impossible ghost count).
      sta GhostRowCounters,x
    SkipFirstHiddenRow:

    lda HiddenLanesHorizontal
    and #$f0
    clc
    ror                                ; Shift the nybble down.
    ror
    ror
    ror
    cmp #$0f                           ; Check if a hidden lane is available.
    beq SkipSecondHiddenRow
      tax
      lda #7
      sta GhostRowCounters,x
    SkipSecondHiddenRow:

    lda HiddenLanesVertical
    and #$0f
    cmp #$0f                           ; Check if a hidden lane is available.
    beq SkipFirstHiddenColumn
      tax
      lda #7
      sta GhostColumnCounters,x
    SkipFirstHiddenColumn:

    lda HiddenLanesVertical
    and #$f0
    clc
    ror                                ; Shift the nybble down.
    ror
    ror
    ror
    cmp #$0f                           ; Check if a hidden lane is available.
    beq SkipSecondHiddenColumn
      tax
      lda #7
      sta GhostColumnCounters,x
    SkipSecondHiddenColumn:
  :

  rts
.endproc

.segment "ZEROPAGE"

RenderOriginAddr = $21d4               ; Origin center for board rendering.
RenderOriginX = 10                     ; The nametable index x offset for rendering.
RenderOriginY = 7                      ; The nametable index y offset for rendering.

RenderAttributeAddr = $23C0            ; PPU address for modifying the palette of a cell.

RenderStartAddr: .res 2                ; The address in the PPU to render the puzzle board.
RenderAddr: .res 2                     ; Working memory, modifies the RenderStartAddr locally, accounting for the x and y of the cell.

RenderTileX: .res 1                    ; The X position of the currently working cell.
RenderTileY: .res 1                    ; The Y position of the currently working cell.
RenderTileIndex: .res 1                ; Which index in the level the current cell is.
RenderTileCHR: .res 1                  ; The CHR index to draw for the current cell.
RenderTileAttributes: .res 1           ; The attributes of the current cell.
RenderTileAttributesMask: .res 1       ; The attributes mask of the current cell.

PaletteY: .res 1                       ; Working byte for calculating the byte offset for attribute setting.
PaletteX: .res 1                       ; Working byte for calculating the byte offset for attribute setting.

.segment "CODE"

;; ((Y / 2) * 8) + (X / 2) = attribute byte offset
;; X mod 2 and Y mod 2 give you the 4 quadrants of that location (i.e. which bits to select)
.proc SetPaletteForTile
  ldx #RenderOriginY                   ; Start at the Y origin of the board.

  lda LevelHeight                      ; Remove half the board height to get the starting Y render of the board.
  clc
  lsr
  LoopHeight:
    sec
    sbc #1
    dex
    cmp #0
    bne LoopHeight

  txa

  clc
  adc RenderTileY                      ; Add the cell Y position to apply the attribute to. This will be the final Y position.
  tax
  and #%00000001                       ; If Y mod 2 has a remainder, then we will offset the bits to apply the attributes to.
  beq :+
    lda RenderTileAttributes           ; Attributes being applied to higher Y vals are in the upper 4 bits of the byte.
    rol
    rol
    rol
    rol
    sta RenderTileAttributes
  :
  txa
  clc
  ror                                  ; Divide Y by 2.
  clc
  rol                                  ; Then multiply Y by 8.
  clc
  rol
  clc
  rol
  sta PaletteY

  ldx #RenderOriginX                   ; Start at the X origin of the board.

  lda LevelWidth                       ; Remove half the board width to get the starting X render of the board.
  clc
  lsr
  LoopWidth:
    sec
    sbc #1
    dex
    cmp #0
    bne LoopWidth

  txa

  clc
  adc RenderTileX                      ; Add the cell X position to apply the attribute to. This will be the final X position.
  tax
  and #%00000001                       ; If X mod 2 has a remainder, then we will offset the bits to apply the attributes to.
  beq :+
    lda RenderTileAttributes           ; Attributes being applied to higher X vals are shifted by 2 bits into the byte.
    rol
    rol
    sta RenderTileAttributes
  :
  txa
  clc
  lsr                                  ; Divide X by 2.
  clc
  adc PaletteY                         ; Add Y position offset.
  clc
  adc #<RenderAttributeAddr            ; Add base address, this is the final lo-byte to apply.
  sta PaletteX

  ;; Set the hi and lo byte addr to apply the attribute to.
  lda #>RenderAttributeAddr
  sta PPU_ADDR
  lda PaletteX
  sta PPU_ADDR
  
  lda PPU_DATA                         ; Read twice due to a delay in the PPU bus to get the correct value.
  lda PPU_DATA

  ;; Reset the hi and lo byte addr since the stride will now be offset due to the reads.
  ldx #>RenderAttributeAddr
  stx PPU_ADDR
  ldx PaletteX
  stx PPU_ADDR

  ora RenderTileAttributes             ; Bitwise OR the attributes into the existing attribute byte for this 2x2 tile.
  sta PPU_DATA

  rts
.endproc

.proc RenderTile
  ;; Transfer the starting address to our working address to modify.
  lda RenderStartAddr+0
  sta RenderAddr+0
  lda RenderStartAddr+1
  sta RenderAddr+1

  ;; Update the address to correspond to the cell Y position.
  ldy RenderTileY
  LoopY:
    cpy #0
    beq DoneLoopY                      ; Exit once we reach 0.

    lda RenderAddr+0
    clc
    adc #$40                           ; Add $40 to the lo-byte.
    sta RenderAddr+0
    lda RenderAddr+1
    adc #0                             ; Carry over the remainder to the hi-byte.
    sta RenderAddr+1

    dey
    jmp LoopY
  DoneLoopY:

  ;; Update the address to correspond to the cell X position.
  ldx RenderTileX
  LoopX:
    cpx #0
    beq DoneLoopX                      ; Exit once we reach 0.

    lda RenderAddr+0
    clc
    adc #$02                           ; Add $02 (since it's a 2x2 tile) to the lo-byte. No carry since increasing the address here won't cross the byte boundary.
    sta RenderAddr+0

    dex
    jmp LoopX
  DoneLoopX:

  ;; Store the new cell address into the PPU.
  lda RenderAddr+1
  sta PPU_ADDR
  lda RenderAddr+0
  sta PPU_ADDR

  ;; Set the PPU to use the given CHR index.
  ldx RenderTileCHR
  stx PPU_DATA

  ;; Add 1 and set the next byte (since it's a 2x2).
  inx
  stx PPU_DATA

  ;; Increase the address by a row, to render the bottom two tiles of the 2x2.
  lda RenderAddr+0
  clc
  adc #$20
  sta RenderAddr+0
  lda RenderAddr+1
  adc #0
  sta RenderAddr+1

  ;; Store the address for the bottom row of the 2x2 into the PPU.
  lda RenderAddr+1
  sta PPU_ADDR
  lda RenderAddr+0
  sta PPU_ADDR

  ;; Set the PPU to use the given CHR index. 
  lda RenderTileCHR
  clc
  adc #$10                             ; We increase by $10 to render the bottom two tiles in the CHR table.
  tax
  stx PPU_DATA

  ;; Add 1 and set the next byte for the last CHR index.
  inx
  stx PPU_DATA

  jsr SetPaletteForTile

  rts
.endproc

;; Render the border and numbers of the level board to the PPU.
.proc RenderLevelDecorations
  ;; Transfer the starting address to our working address to modify.
  lda RenderStartAddr+0
  sta RenderAddr+0
  lda RenderStartAddr+1
  sta RenderAddr+1

  lda RenderAddr+0
  sec
  sbc #$02
  sta RenderAddr+0

  ldx #0
  LoopRowDecorations:
    ;; Store the decoration address into the PPU.
    lda RenderAddr+1
    sta PPU_ADDR
    lda RenderAddr+0
    sta PPU_ADDR

    lda #$06
    sta PPU_DATA

    lda GhostRowCounters,x
    clc
    adc #$e0
    sta PPU_DATA

    lda RenderAddr+0
    clc
    adc #$20
    sta RenderAddr+0
    lda RenderAddr+1
    adc #$00
    sta RenderAddr+1

    ;; Store the decoration address into the PPU.
    lda RenderAddr+1
    sta PPU_ADDR
    lda RenderAddr+0
    sta PPU_ADDR

    lda #$06
    sta PPU_DATA

    lda GhostRowCounters,x
    clc
    adc #$f0
    sta PPU_DATA

    lda RenderAddr+0
    clc
    adc #$20
    sta RenderAddr+0
    lda RenderAddr+1
    adc #$00
    sta RenderAddr+1

    inx
    cpx LevelHeight
    bne LoopRowDecorations             ; Exit once we reach the level height

  ;; Transfer the starting address to our working address to modify.
  lda RenderStartAddr+0
  sta RenderAddr+0
  lda RenderStartAddr+1
  sta RenderAddr+1

  lda RenderAddr+0
  sec
  sbc #$40
  sta RenderAddr+0
  lda RenderAddr+1
  sbc #$00
  sta RenderAddr+1

  ldx #0
  LoopColumnDecorations:
    ;; Store the decoration address into the PPU.
    lda RenderAddr+1
    sta PPU_ADDR
    lda RenderAddr+0
    sta PPU_ADDR

    lda GhostColumnCounters,x
    clc
    rol
    clc
    adc #$60
    sta PPU_DATA
    adc #$01
    sta PPU_DATA

    lda RenderAddr+0
    clc
    adc #$20
    sta RenderAddr+0
    lda RenderAddr+1
    adc #$00
    sta RenderAddr+1

    ;; Store the decoration address into the PPU.
    lda RenderAddr+1
    sta PPU_ADDR
    lda RenderAddr+0
    sta PPU_ADDR

    lda GhostColumnCounters,x
    clc
    rol
    clc
    adc #$70
    sta PPU_DATA
    adc #$01
    sta PPU_DATA

    lda RenderAddr+0
    sec
    sbc #$1e
    sta RenderAddr+0
    lda RenderAddr+1
    sbc #$00
    sta RenderAddr+1

    inx
    cpx LevelWidth
    bne LoopColumnDecorations             ; Exit once we reach the level width

  RenderTopLeftCorner:
    ;; Transfer the starting address to our working address to modify.
    lda RenderStartAddr+0
    sta RenderAddr+0
    lda RenderStartAddr+1
    sta RenderAddr+1

    lda RenderAddr+0
    sec
    sbc #$42
    sta RenderAddr+0
    lda RenderAddr+1
    sbc #$00
    sta RenderAddr+1

    ;; Store the decoration address into the PPU.
    lda RenderAddr+1
    sta PPU_ADDR
    lda RenderAddr+0
    sta PPU_ADDR

    lda #$03
    sta PPU_DATA
    lda #$04
    sta PPU_DATA

    lda RenderAddr+0
    clc
    adc #$20
    sta RenderAddr+0
    lda RenderAddr+1
    adc #$00
    sta RenderAddr+1

    ;; Store the decoration address into the PPU.
    lda RenderAddr+1
    sta PPU_ADDR
    lda RenderAddr+0
    sta PPU_ADDR

    lda #$06
    sta PPU_DATA
    lda #$00
    sta PPU_DATA

  RenderBotom:
    ;; Transfer the starting address to our working address to modify.
    lda RenderStartAddr+0
    sta RenderAddr+0
    lda RenderStartAddr+1
    sta RenderAddr+1

    ldy #0
    LoopLevelHeight:
      lda RenderAddr+0
      clc
      adc #$40
      sta RenderAddr+0
      lda RenderAddr+1
      adc #$00
      sta RenderAddr+1

      iny
      cpy LevelHeight
      bne LoopLevelHeight

    lda RenderAddr+0
    sec
    sbc #$02
    sta RenderAddr+0

    ;; Store the decoration address into the PPU.
    lda RenderAddr+1
    sta PPU_ADDR
    lda RenderAddr+0
    sta PPU_ADDR

    lda #$08
    sta PPU_DATA
    lda #$09
    sta PPU_DATA

    ldy #0
    LoopLevelWidth:
      lda #$09
      sta PPU_DATA
      lda #$09
      sta PPU_DATA

      iny
      cpy LevelWidth
      bne LoopLevelWidth

  RenderRight:
    ;; Transfer the starting address to our working address to modify.
    lda RenderStartAddr+0
    sta RenderAddr+0
    lda RenderStartAddr+1
    sta RenderAddr+1

    lda RenderAddr+0
    sec
    sbc #$40
    sta RenderAddr+0
    lda RenderAddr+1
    sbc #$00
    sta RenderAddr+1

    ldy #0
    LoopToRightEdge:
      lda RenderAddr+0
      clc
      adc #$02
      sta RenderAddr+0

      iny
      cpy LevelWidth
      bne LoopToRightEdge

    ;; Store the decoration address into the PPU.
    lda RenderAddr+1
    sta PPU_ADDR
    lda RenderAddr+0
    sta PPU_ADDR

    lda #PPU_CTRL_FLAGS::VERTICAL_DATA_INCR
    sta PPU_CTRL

    lda #$05
    sta PPU_DATA
    lda #$07
    sta PPU_DATA

    ldy #0
    LoopRightEdgeRender:
      lda #$07
      sta PPU_DATA
      lda #$07
      sta PPU_DATA

      iny
      cpy LevelHeight
      bne LoopRightEdgeRender

    lda #$0a
    sta PPU_DATA

    lda #0
    sta PPU_CTRL

  rts
.endproc

;; Based off the parsed level size data, determine where in the PPU we should render the board.
.proc CalculateRenderLevelPosition
  ;; Set the starting board location on the tilemap.
  lda #<RenderOriginAddr
  sta RenderStartAddr+0
  lda #>RenderOriginAddr
  sta RenderStartAddr+1

  ;; Offset the Y position of the board location, based off the board height.
  lda LevelHeight
  clc
  lsr                                  ; Divide the board height by two since we only want to go up half the board height.
  tax
  LoopBoardOffsetY:
    lda RenderStartAddr+0
    sec
    sbc #$40                           ; For every cell in the board height, go up two tilemap untits (since a cell is 2x2).
    tay
    lda RenderStartAddr+1
    sbc #0
    sta RenderStartAddr+1
    sty RenderStartAddr+0

    dex
    cpx #0
    bne LoopBoardOffsetY

  ;; Offset the X position of the board location, based off the board width.
  lda LevelWidth
  clc
  lsr                                  ; Divide the board width by two since we only want to go left by half the board width.
  tax
  LoopBoardOffsetX:
    lda RenderStartAddr+0
    sec
    sbc #$02                           ; For every cell in the board width, go left two tilemap units (since a cell is 2x2).
    sta RenderStartAddr+0

    dex
    cpx #0
    bne LoopBoardOffsetX

  rts
.endproc

;; Render the level to the PPU.
.proc RenderLevel
  jsr CalculateRenderLevelPosition     ; First, determine where to render the level.
  jsr RenderLevelDecorations           ; Then render the level border and ghost counters.

  ;; Starting at 0x and 0y, and index 0 in the level.
  lda #0
  sta RenderTileX
  sta RenderTileY
  sta RenderTileIndex

  LoopLevelCells:
    ldx RenderTileIndex                ; Load the level index of the cell for our addr offset.
    lda PlayerBoard,x                  ; Which type of cell are we going to render.

    cmp #CellTypes::Empty              ; Empty tile rendering.
    bne :+
      ldy #$00
      ldx #%00000000
    :

    cmp #CellTypes::Ghost              ; Ghost tile rendering.
    bne :+
      ldy #$a2
      ldx #%00000011
    :

    cmp #CellTypes::Grave              ; Grave tile rendering.
    bne :+
      ldy #$40
      ldx #%00000010
    :

    ;; Store the data of the tile to render.
    sty RenderTileCHR
    stx RenderTileAttributes

    jsr RenderTile
    
    inc RenderTileIndex                ; Move to the next tile index.

    inc RenderTileX                    ; Move to the next X position.
    lda RenderTileX
    cmp LevelWidth
    bne LoopLevelCells                 ; If we haven't hit the new row yet, loop back to the beginning.

    lda #0
    sta RenderTileX                    ; If we've moved on to the next row, reset the X index.

    inc RenderTileY                    ; Move to the next Y position.
    lda RenderTileY
    cmp LevelHeight
    bne LoopLevelCells                 ; If we haven't hit the end of the level, loop back to the beginning.
  
  rts
.endproc

.segment "ZEROPAGE"

LevelSuccess: .res 1                   ; Boolean flag to set if the level is successfully completed.

.segment "CODE"

;; Iterate through the level data, and compare it to the player data.
;; If there's a match, then the level is complete!
.proc CheckLevelComplete
  lda #0
  sta LevelSuccess                     ; Default condition, set the success to initially false.

  ldx #0
  LoopBoard:
    ;; If a level ghost doesn't match to a player ghost, the level isn't completed.
    lda LevelBoard,x
    cmp #CellTypes::Ghost
    bne :+
      lda PlayerBoard,x
      cmp #CellTypes::Ghost
      beq :+
        rts
    :

    ;; If a player ghost doesn't match a level ghost, they put a ghost in the wrong spot.
    lda PlayerBoard,x
    cmp #CellTypes::Ghost
    bne :+
      lda LevelBoard,x
      cmp #CellTypes::Ghost
      beq :+
        rts
    :

    inx
    cpx LevelCellCount
    bne LoopBoard

  lda #1                               ; If we got here, the level is complete!
  sta LevelSuccess

  rts
.endproc

.segment "ZEROPAGE"

SpritePtrAddr = $0200                  ; OAM address to store cursor sprite data.
SpritePtr: .res 2                      ; The working OAM pointer.

CursorX: .res 1                        ; The X grid position of the cursor.
CursorY: .res 1                        ; The Y grid position of the cursor.

RerenderX: .res 1                      ; Parameter for setting which cell X grid index to rerender.
RerenderY: .res 1                      ; Parameter for setting which cell Y grid index to rerender.
RerenderAttribute: .res 1              ; Parameter for setting attributes for a rerender.

CursorPixelsX: .res 1                  ; The pixel X coordinate for the cursor sprite.
CursorPixelsY: .res 1                  ; The pixel Y coordinate for the cursor sprite.

CursorCounter: .res 1                  ; Animation tick to determine when to switch to the next animation frame.
CursorIndex: .res 1                    ; Animation frame index for the cursor animation.

DebounceTimeout = 10                   ; Frame counter debounce to block spamming input.
CursorDebounceTimer: .res 1            ; Debounce ticker to track frames until the debounce limit.
CanMoveCursor: .res 1                  ; Toggle byte to determine if the cursor can move.
DidMoveCursor: .res 1                  ; Toggle byte to determine if the cursor did move.

.segment "CODE"

;; Draw the game cursor on the board.
;; Translates the grid x and y coordinates to pixel space to draw on the screen.
.proc DrawCursorSprite
  lda #<SpritePtrAddr                  ; Set sprite OAM destination.
  sta SpritePtr+0
  lda #>SpritePtrAddr
  sta SpritePtr+1

  inc CursorCounter
  lda CursorCounter
  cmp #8
  bne :+                               ; Move to the next animation frame if we hit the counter.
    lda #0
    sta CursorCounter

    inc CursorIndex
    lda CursorIndex
    cmp #7
    bne CursorMax                      ; Loop the animation from the beginning.
      lda #0
      sta CursorIndex
    CursorMax:
  :

  ldx #RenderOriginY                   ; Start at the Y origin of the board.

  lda LevelHeight                      ; Remove half the board height to get the starting Y render of the board.
  clc
  lsr
  LoopHeight:
    sec
    sbc #1
    dex
    cmp #0
    bne LoopHeight

  txa
  clc
  rol
  rol
  rol
  rol
  sta CursorPixelsY                    ; Mult the position by 8, since there are 8 pixels per nametable tile.
  
  lda CursorY                          ; Add the cursor position to the result.
  clc
  rol
  rol
  rol
  rol                                  ; Once again multiplying by 8 for tile to pixel conversions.
  adc CursorPixelsY
  sec
  sbc #1
  sta CursorPixelsY

  ldx #RenderOriginX                   ; Start at the Y origin of the board.

  lda LevelWidth                       ; Remove half the board width to get the starting X render of the board.
  clc
  lsr
  LoopWidth:
    sec
    sbc #1
    dex
    cmp #0
    bne LoopWidth

  txa
  clc
  rol
  rol
  rol
  rol
  sta CursorPixelsX                    ; Mult the position by 8, since there are 8 pixels per nametable tile.
  
  lda CursorX                          ; Add the cursor position to the result.
  clc
  rol
  rol
  rol
  rol
  adc CursorPixelsX                    ; Once again multiplying by 8 for the tile to pixel conversions.
  sta CursorPixelsX

  ;; Start adding the sprite data to the OAM address.

  ldy #0

  ;; Top left cursor sprite.
  lda CursorPixelsY
  sta (SpritePtr),y
  iny

  lda CursorIndex
  sta (SpritePtr),y
  iny

  lda #%00000000
  sta (SpritePtr),y
  iny

  lda CursorPixelsX
  sta (SpritePtr),y
  iny

  ;; Bottom left cursor sprite.
  lda CursorPixelsY
  clc
  adc #8
  sta (SpritePtr),y
  iny

  lda CursorIndex
  clc
  adc #$10
  sta (SpritePtr),y
  iny

  lda #%11000000
  sta (SpritePtr),y
  iny

  lda CursorPixelsX
  sta (SpritePtr),y
  iny

  ;; Top right cursor sprite.
  lda CursorPixelsY
  sta (SpritePtr),y
  iny

  lda CursorIndex
  clc
  adc #$10
  sta (SpritePtr),y
  iny

  lda #%00000000
  sta (SpritePtr),y
  iny

  lda CursorPixelsX
  clc
  adc #8
  sta (SpritePtr),y
  iny

  ;; Bottom right cursor sprite.
  lda CursorPixelsY
  clc
  adc #8
  sta (SpritePtr),y
  iny

  lda CursorIndex
  sta (SpritePtr),y
  iny

  lda #%11000000
  sta (SpritePtr),y
  iny

  lda CursorPixelsX
  clc
  adc #8
  sta (SpritePtr),y
  iny

  rts
.endproc

;; Logic for handling user input to move the cursor around the board.
;; This will debounce the user input, so holding down a direction won't move the cursor once every frame you hold the button.
.proc CursorMove
  inc CursorDebounceTimer
  lda CursorDebounceTimer
  cmp #DebounceTimeout
  bne :+                               ; Have we passed the debounce threshold?
    lda #1
    sta CanMoveCursor                  ; If so, set the flag to allow cursor movement.
    lda #0
    sta CursorDebounceTimer            ; And reset the debounce timer.
  :

  lda CanMoveCursor                    ; Early return if we're in a debounced state.
  bne :+
    rts
  :

  lda #0
  sta DidMoveCursor                    ; Initial flag state. Will be set if the cursor ends up moving from user input.

  lda Buttons
  and #BUTTON_DOWN                     ; Handle the user moving the cursor DOWN.
  beq :+
    lda CursorY
    dec LevelHeight
    cmp LevelHeight
    beq @NotInBoundsDown               ; If the user presses down, but they're already at the bottom of the board, skip the move.
      inc CursorY
      lda #0
      sta CanMoveCursor
      lda #0
      sta CursorDebounceTimer

      jsr PlaySoundClick

      lda #1
      sta DidMoveCursor
    @NotInBoundsDown:
    inc LevelHeight
  :

  lda Buttons
  and #BUTTON_UP                       ; Handle the user moving the cursor UP.
  beq :+
    lda CursorY
    cmp #0
    beq @NotInBoundsUp                 ; If the user presses up, but they're already at the top of the board, skip the move.
      dec CursorY
      lda #0
      sta CanMoveCursor
      lda #0
      sta CursorDebounceTimer

      jsr PlaySoundClick

      lda #1
      sta DidMoveCursor
    @NotInBoundsUp:
  :

  lda Buttons
  and #BUTTON_RIGHT                    ; Handle the user moving the cursor RIGHT.
  beq :+
    lda CursorX
    dec LevelWidth
    cmp LevelWidth
    beq @NotInBoundsRight              ; If the user presses right, but they're already at the rightmost cell of the board, skip the move.
      inc CursorX
      lda #0
      sta CanMoveCursor
      lda #0
      sta CursorDebounceTimer

      jsr PlaySoundClick

      lda #1
      sta DidMoveCursor
    @NotInBoundsRight:
    inc LevelWidth
  :

  lda Buttons
  and #BUTTON_LEFT                     ; Handle the user moving the cursor LEFT.
  beq :+
    lda CursorX
    cmp #0
    beq @NotInBoundsLeft               ; If the user presses left, but they're already at the leftmost cell of the board, skip the move.
      dec CursorX
      lda #0
      sta CanMoveCursor
      lda #0
      sta CursorDebounceTimer

      jsr PlaySoundClick

      lda #1
      sta DidMoveCursor
    @NotInBoundsLeft:
  :

  lda Buttons
  and #BUTTON_A
  beq NotHoldingAction                 ; Pro gaming tip: holding the A button WHILE moving will auto-dig that cell. Tell your friends!
    lda DidMoveCursor
    cmp #1
    bne NotHoldingAction               ; Skip if the cursor didn't move in this sequence.

    lda CursorX
    
    ldy CursorY
    LoopYIndex:                        ; Determine the cell index the cell movement landed on.
      cpy #0
      beq DoneLoopYIndex

      clc
      adc LevelWidth

      dey
      jmp LoopYIndex
    DoneLoopYIndex:

    tax
    lda PlayerBoard,x                  ; What type of cell did the movement just land on?

    cmp #CellTypes::Empty              ; If the cell type was "Empty", then it can be auto-dug.
    bne :+
      jsr ChangeCellType
    :
  NotHoldingAction:

  rts
.endproc

;; Update the cell type of a given x and y coordinate on the game board.
.proc ChangeCellType
  lda CursorX
  
  ldy CursorY                          ; Determine the index of the cell from the given x and y coord.
  LoopYIndex:
    cpy #0
    beq DoneLoopYIndex                 ; Stop once we reach 0.

    clc
    adc LevelWidth

    dey
    jmp LoopYIndex
  DoneLoopYIndex:

  tax
  lda PlayerBoard,x                    ; Load the current cell type...

  cmp #CellTypes::Grave                ; If the current cell type is a Grave, then update it to a directional UP grave.
  bne :+
    lda #$48
    sta RenderTileIndex

    lda #%00000010
    sta RenderTileAttributes

    lda #CellTypes::GraveUp
    sta PlayerBoard,x
    lda #$ff
  :
  cmp #CellTypes::GraveUp              ; If the current cell type is a directional UP grave, then update it to a directional RIGHT grave.
  bne :+
    lda #$42
    sta RenderTileIndex

    lda #%00000010
    sta RenderTileAttributes

    lda #CellTypes::GraveRight
    sta PlayerBoard,x
    lda #$ff
  :
  cmp #CellTypes::GraveRight           ; If the current cell type is a directional RIGHT grave, then update it to a directional DOWN grave.
  bne :+
    lda #$46
    sta RenderTileIndex

    lda #%00000010
    sta RenderTileAttributes

    lda #CellTypes::GraveDown
    sta PlayerBoard,x
    lda #$ff
  :
  cmp #CellTypes::GraveDown            ; If the current cell type is a directional DOWN grave, then update it to a directional LEFT grave.
  bne :+
    lda #$44
    sta RenderTileIndex

    lda #%00000010
    sta RenderTileAttributes

    lda #CellTypes::GraveLeft
    sta PlayerBoard,x
    lda #$ff
  :
  cmp #CellTypes::GraveLeft            ; If the current cell type is a directional LEFT grave, then update it to a non-directional grave.
  bne :+
    lda #$40
    sta RenderTileIndex

    lda #%00000010
    sta RenderTileAttributes

    lda #CellTypes::Grave
    sta PlayerBoard,x
    lda #$ff
  :

  ldy LevelType
  cpy #LevelTypes::NoShovel
  bne EndNoShovel                      ; If we're in no shovel mode, we want to skip the dug state and immediately show a ghost. Spooky!
    cmp #CellTypes::Empty
    bne :+
      lda #$a2
      sta RenderTileIndex

      lda #%00000011
      sta RenderTileAttributes

      lda #CellTypes::Ghost
      sta PlayerBoard,x
      lda #$ff
    :
  EndNoShovel:

  ldy LevelType
  cpy #LevelTypes::NoShovel
  beq EndShovel                        ; We're not in no shovel mode, so digging an empty cell will result in a ground tile.
    cmp #CellTypes::Empty
    bne :+
      lda #$26
      sta RenderTileIndex

      lda #%00000001
      sta RenderTileAttributes

      lda #CellTypes::Ground
      sta PlayerBoard,x
      lda #$ff
    :
  EndShovel:

  cmp #CellTypes::Ground               ; If the current cell is a ground tile, change it to a ghost. Still as spooky as it was a couple dozen lines above this!
  bne :+
    lda #$a2
    sta RenderTileIndex

    lda #%00000011
    sta RenderTileAttributes

    lda #CellTypes::Ghost
    sta PlayerBoard,x
    lda #$ff
  :

  cmp #CellTypes::Ghost                ; If the current cell is a ghost tile (not spooky anymore tbh), then change the tile to an empty one.
  bne :+
    lda #$00
    sta RenderTileIndex

    lda #%00000000
    sta RenderTileAttributes

    lda #CellTypes::Empty
    sta PlayerBoard,x
    lda #$ff
  :

  lda CursorX
  sta RerenderX
  lda CursorY
  sta RerenderY

  lda #1
  sta RerenderAttribute                ; Update the attribute of the cell that just changed.

  jsr RerenderLevelCell                ; Request to rerender the tile.

  jsr CheckLevelComplete               ; Since the game board just changed, check the level completion state.

  jsr PlaySoundDig                     ; Play a sound effect from the user input

  rts
.endproc

;; Update the PPU representation of a tile that just changed from user input.
.proc RerenderLevelCell
  ;; Transfer the starting address to our working address to modify.
  lda RenderStartAddr+0
  sta RenderAddr+0
  lda RenderStartAddr+1
  sta RenderAddr+1

  ;; Update the address to correspond to the cell Y position.
  ldy RerenderY
  LoopY:
    cpy #0
    beq DoneLoopY                      ; Exit once we reach 0.

    lda RenderAddr+0
    clc
    adc #$40                           ; Add $40 to the lo-byte.
    sta RenderAddr+0
    lda RenderAddr+1
    adc #0                             ; Carry over the remainder to the hi-byte.
    sta RenderAddr+1

    dey
    jmp LoopY
  DoneLoopY:

  ;; Update the address to correspond to the cell X position.
  ldx RerenderX
  LoopX:
    cpx #0
    beq DoneLoopX                      ; Exit once we reach 0.

    lda RenderAddr+0
    clc
    adc #$02                           ; Add $02 (since it's a 2x2 tile) to the lo-byte. No carry since increasing the address here won't cross the byte boundary.
    sta RenderAddr+0

    dex
    jmp LoopX
  DoneLoopX:

  ldy BgCopyOffset

  ;; Set render data for the top of the cell.
  lda RenderAddr+1
  sta (BgCopyPtr),y
  iny

  lda RenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda RenderTileIndex
  sta (BgCopyPtr),y
  iny

  lda RenderAddr+0
  clc
  adc #$20
  sta RenderAddr+0

  ;; Set render data for the bottom of the cell.
  lda RenderAddr+1
  adc #0
  sta (BgCopyPtr),y
  iny

  lda RenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda RenderTileIndex
  clc
  adc #$10
  sta (BgCopyPtr),y
  iny

  lda #0
  sta (BgCopyPtr),y

  sty BgCopyOffset

  lda RerenderAttribute                ; Check the flag to see if we want to update the attribute data for the tile that just changed.
  cmp #0
  bne :+
    rts
  :

  ldx #RenderOriginY                   ; Start at the Y origin of the board.

  lda #%11111100
  sta RenderTileAttributesMask         ; Initialize the mask for the given attribute.

  lda LevelHeight                      ; Remove half the board height to get the starting Y render of the board.
  clc
  lsr
  LoopHeight:
    sec
    sbc #1
    dex
    cmp #0
    bne LoopHeight

  txa

  clc
  adc RerenderY                        ; Add the cell Y position to apply the attribute to. This will be the final Y position.
  tax
  and #%00000001                       ; If Y mod 2 has a remainder, then we will offset the bits to apply the attributes to.
  beq :+
    lda RenderTileAttributes           ; Attributes being applied to higher Y vals are in the upper 4 bits of the byte.
    rol
    rol
    rol
    rol
    sta RenderTileAttributes

    lda RenderTileAttributesMask       ; Move the masked bits to remove the old attribute in the PPU.
    sec
    rol
    rol
    rol
    rol
    sta RenderTileAttributesMask
  :
  txa
  clc
  ror                                  ; Divide Y by 2.
  clc
  rol                                  ; Then multiply Y by 8.
  clc
  rol
  clc
  rol
  sta PaletteY

  ldx #RenderOriginX                   ; Start at the X origin of the board.

  lda LevelWidth                       ; Remove half the board width to get the starting X render of the board.
  clc
  lsr
  LoopWidth:
    sec
    sbc #1
    dex
    cmp #0
    bne LoopWidth

  txa

  clc
  adc RerenderX                        ; Add the cell X position to apply the attribute to. This will be the final X position.
  tax
  and #%00000001                       ; If X mod 2 has a remainder, then we will offset the bits to apply the attributes to.
  beq :+
    lda RenderTileAttributes           ; Attributes being applied to higher X vals are shifted by 2 bits into the byte.
    rol
    rol
    sta RenderTileAttributes

    lda RenderTileAttributesMask       ; Move the masked bits to remove the old attribute in the PPU.
    sec
    rol
    rol
    sta RenderTileAttributesMask
  :
  txa
  clc
  lsr                                  ; Divide X by 2.
  clc
  adc PaletteY                         ; Add Y position offset.
  clc
  adc #<RenderAttributeAddr            ; Add base address, this is the final lo-byte to apply.
  sta PaletteX

  ldy AttributeCopyOffset

  ;; Set the data to be copied to the PPU on the next NMI.
  lda #>RenderAttributeAddr
  sta (AttributeCopyPtr),y
  iny

  lda PaletteX
  sta (AttributeCopyPtr),y
  iny

  lda RenderTileAttributesMask
  sta (AttributeCopyPtr),y
  iny

  lda RenderTileAttributes
  sta (AttributeCopyPtr),y
  iny

  lda #0
  sta (AttributeCopyPtr),y

  sty AttributeCopyOffset

  rts
.endproc

;; Handle any button actions from the user.
.proc ProcessActions
  lda PressedButtons
  and #BUTTON_A                        ; If the A button was just pressed, update the tile under the cursor.
  beq :+
    jsr ChangeCellType
  :

  lda PressedButtons
  and #BUTTON_SELECT                   ; If the SELECT button was pressed, leave the level and return to the level select screen.
  beq :+
    lda #SCREEN_TYPE::LEVEL_SELECT
    sta CurrScreen
  :

  rts
.endproc

.segment "ZEROPAGE"

AnimateGhostTarget = 16                ; Animation tick target, for moving to the next animation frame.

AnimateGhostRow: .res 1                ; Which row of the board is animating this frame.
AnimateGhostCounter: .res 1            ; Animation tick counter.
AnimateGhostIndex: .res 1              ; Which index of the animation are we on.
AnimatingGhosts: .res 1                ; Flag to dictate whether the animation is in progress.

.segment "CODE"

;; Animate the ghosts on the level board.
;; Since the NMI vblank only gives you so much time, we split the work up.
;; For each frame, we process the animation for only one row of the board.
.proc AnimateGhosts
  inc AnimateGhostCounter              ; Update the tick of the animation counter.

  lda AnimateGhostCounter
  cmp #AnimateGhostTarget              ; If the animation frame counter is hit, move to the next index of the animation.
  bne SkipAnimationTrigger
    lda #0                             ; When we move to the next animation frame, we also reset the lane to update. Each frame after will animate the next lane, etc.
    sta AnimateGhostCounter
    sta AnimateGhostRow

    inc AnimateGhostIndex
    inc AnimateGhostIndex
    lda AnimateGhostIndex
    cmp #8                             ; Loop the animation when it gets to the end.
    bne :+
      lda #0
      sta AnimateGhostIndex
    :

    lda #1                             ; Set the animation toggle to let us know we can start animating lanes below.
    sta AnimatingGhosts
  SkipAnimationTrigger:

  lda AnimatingGhosts
  cmp #1                               ; Skip this block of code if we aren't animating right now.
  bne SkipAnimation
    lda #0
    ldy #0
    LoopLevelHeight:                   ; Loop the animating row index. For each row, add the level width to the accumulator.
      cpy AnimateGhostRow
      beq LoopLevelHeightDone

      iny
      clc
      adc LevelWidth
      jmp LoopLevelHeight
    LoopLevelHeightDone:
    tax

    ;; The X register should be the starting index of the row now. 
    ;; can start here to animate the ghosts until we hit the level width.
    ldy #0
    LoopLevelWidth:
      cpy LevelWidth
      beq LoopLevelWidthDone

      lda PlayerBoard,x
      cmp #CellTypes::Ghost
      beq :+                           ; If this cell isn't a ghost, then move to the next cell.
        iny
        inx
        jmp LoopLevelWidth
      :

      lda #$a0                         ; The starting ghost tile animation index.
      clc
      adc AnimateGhostIndex            ; Add the animation index offset/
      sta RenderTileIndex

      lda #%00000000
      sta RenderTileAttributes         ; Set param for tile attibutes to update.

      lda AnimateGhostRow
      sta RerenderY                    ; Set param for Y index into the level board.

      sty RerenderX                    ; Set param for X index into the level board.

      lda #0
      sta RerenderAttribute            ; Set param to dictate that we don't want to update the attributes for this cell.

      PUSH_REGS
      jsr RerenderLevelCell            ; Call routine will all the params above to update the ghost animation cell.
      PULL_REGS

      iny
      inx
      jmp LoopLevelWidth
    LoopLevelWidthDone:

    inc AnimateGhostRow                ; Move the animation to the next row on the board for the next frame.
    lda AnimateGhostRow
    cmp LevelHeight                    ; If the animation makes it to the last row of the level, then...
    bne :+
      lda #0
      sta AnimateGhostRow              ; Reset the animation row back to the top...
      sta AnimatingGhosts              ; And turn off the ghost animation flag.
    :
  SkipAnimation:

  rts
.endproc

.proc GameInit
  ;; Disable VBlank.
  lda #0
  sta PPU_CTRL
  sta PPU_MASK

  SET_CHR_MAPPER CHR_MAP::GAME

  ldx #<GameBackgroundPalette
  ldy #>GameBackgroundPalette
  jsr LoadPalette

  ldx #<GameBackgroundData
  ldy #>GameBackgroundData
  jsr LoadBackgroundRLE

  lda CurrentLevelAddress+0            ; Set from the level table, load it into the game level pointer.
  sta LevelPtr+0
  lda CurrentLevelAddress+1
  sta LevelPtr+1

  jsr ReadLevel                        ; Parse the level from ROM.
  jsr RenderLevel                      ; And then render it to the PPU.

  lda #0
  sta LevelSuccess
  sta LevelCellIndex
  sta LevelCellIndexX
  sta LevelCellIndexY
  sta CursorY
  sta CursorX
  sta RerenderX
  sta RerenderY
  sta CursorIndex
  sta CursorCounter
  sta CursorDebounceTimer

  lda #1
  sta CanMoveCursor                    ; Don't debounce the player input until they move around.

  jsr ResetTimer                       ; Get the game timer in a good initial state.

  lda LevelType
  cmp #LevelTypes::TimeAttack
  bne :+
    jsr SetCountdownTimer              ; If we're in Time Attack mode, set the timer into countdown mode.
  :

  ;; Enable VBlank.
  lda #(PPU_CTRL_FLAGS::ENABLE_VBLANK_NMI | PPU_CTRL_FLAGS::SPRITE_ADDR)
  sta PPU_CTRL

  rts
.endproc

.proc GameUpdate
  jsr UpdateTimer                      ; Tick the level timer clock. Can end the game in Time Attack mode.

  jsr CursorMove                       ; Process any button input to move the cursor.
  jsr DrawCursorSprite                 ; Draw the cursor on the board.

  jsr ProcessActions                   ; Handle buttons to dig, show ghosts, move grave pointers.

  jsr AnimateGhosts                    ; Make the ghosts float on the board.

  lda LevelSuccess
  cmp #1                               ; If the board completion flag is set...
  bne :+
    jsr IncrementLevel                 ; Update the player progress.

    lda #SCREEN_TYPE::GAME_OVER
    sta CurrScreen                     ; And then switch back to the level select screen.
  :

  lda LevelType
  cmp #LevelTypes::TimeAttack          ; If we're in Time Attack mode...
  bne NotTimeAttackLevel
    lda TimerCountMode
    cmp #TimerMode::Stopped            ; And the timer is now in the Stopped state (meaning we reached 0)...
    bne :+
      lda #SCREEN_TYPE::GAME_OVER
      sta CurrScreen                   ; Then the player failed, and gets sent back to the level select screen.
    :
  NotTimeAttackLevel:

  rts
.endproc

.proc GameCleanup
  ;; Clear the board data for the next level.
  ldx #0
  LoopClearBoards:
    lda #0
    sta LevelBoard,x
    sta PlayerBoard,x

    cpx #(MaximumLevelWidth * MaximumLevelHeight)
    inx
    bne LoopClearBoards

  ldx #0

  rts
.endproc

GameBackgroundData:
.incbin "nametables/game.rle"

GameBackgroundPalette:
.byte $1B,$0D,$3B,$0A, $1B,$0D,$17,$27, $1B,$0D,$13,$33, $1B,$0D,$16,$36
.byte $1B,$27,$27,$1C, $1B,$31,$27,$1C, $1B,$31,$27,$1C, $1B,$02,$30,$30

