.include "levels/world_1.asm"
.include "levels/world_2.asm"
.include "levels/world_3.asm"
.include "levels/world_4.asm"
.include "levels/world_5.asm"
.include "levels/world_6.asm"
.include "levels/world_7.asm"
.include "levels/world_8.asm"
.include "levels/world_9.asm"
.include "levels/world_10.asm"
.include "levels/world_11.asm"
.include "levels/world_12.asm"
.include "levels/world_13.asm"
.include "levels/world_14.asm"
.include "levels/world_15.asm"
.include "levels/world_16.asm"
.include "levels/world_17.asm"
.include "levels/world_18.asm"
.include "levels/world_19.asm"
.include "levels/world_20.asm"
.include "levels/world_21.asm"
.include "levels/world_22.asm"
.include "levels/world_23.asm"
.include "levels/world_24.asm"
.include "levels/world_25.asm"

.segment "SAV"

PlayerProgressWorld: .res 1            ; Save data for the current level index.
PlayerProgressLevel: .res 1            ; Save data for the current world index.

.segment "ZEROPAGE"

CurrentLevelAddress: .res 2            ; Resulting RAM to calculate the resulting pointer to the current player level.
WorkingLevelWidth: .res 1              ; Working RAM to store how many cells are left in the level width calculation.
IteratedLevelWidth: .res 1             ; Storage for holding the current level width.
IteratedLevelHeight: .res 1            ; Working RAM to store how many cells are left in the level height calculation.
CellByteIndex: .res 1                  ; Counts the number of level cells in a byte. Every four counts of a cell per byte, the level pointer increments.
LevelStride: .res 1                    ; Working RAM to store how many bytes the a level contained, to move to the next level in ROM.
DidCompleteGame: .res 1                ; Flag for if the player completed all the worlds.

.segment "CODE"

LevelTableHi:
  .byte >world_1
  .byte >world_2
  .byte >world_3
  .byte >world_4
  .byte >world_5
  .byte >world_6
  .byte >world_7
  .byte >world_8
  .byte >world_9
  .byte >world_10
  .byte >world_11
  .byte >world_12
  .byte >world_13
  .byte >world_14
  .byte >world_15
  .byte >world_16
  .byte >world_17
  .byte >world_18
  .byte >world_19
  .byte >world_20
  .byte >world_21
  .byte >world_22
  .byte >world_23
  .byte >world_24
  .byte >world_25

LevelTableLo:
  .byte <world_1
  .byte <world_2
  .byte <world_3
  .byte <world_4
  .byte <world_5
  .byte <world_6
  .byte <world_7
  .byte <world_8
  .byte <world_9
  .byte <world_10
  .byte <world_11
  .byte <world_12
  .byte <world_13
  .byte <world_14
  .byte <world_15
  .byte <world_16
  .byte <world_17
  .byte <world_18
  .byte <world_19
  .byte <world_20
  .byte <world_21
  .byte <world_22
  .byte <world_23
  .byte <world_24
  .byte <world_25

.proc IncrementLevel
  inc PlayerProgressLevel              ; Move to the next level index.

  lda PlayerProgressLevel
  cmp #28                              ; If we hit the total number of levels in a world...
  bne :+
    lda #0
    sta PlayerProgressLevel            ; Reset the level index back to 0.

    inc PlayerProgressWorld            ; And move to the next world.
  :

  lda PlayerProgressWorld
  cmp #25                              ; There are only 25 worlds, so wrap back to the first world if we overflow.
  bne :+
    lda #0
    sta PlayerProgressWorld

    lda #1
    sta DidCompleteGame                ; Set game completion flag to show the user a thank you screen.
  :

  rts
.endproc

;; Using the SAV data for the level and world, calculate the ROM pointer to load into the game screen.
.proc GetLevelAddress
  ldx PlayerProgressWorld              ; Use the current world progress to index into the level table.
  lda LevelTableHi,x
  sta CurrentLevelAddress+1
  lda LevelTableLo,x
  sta CurrentLevelAddress+0

  ldx PlayerProgressLevel              ; Loop into the table entry x times, where x is the level within the world to load.
  LoopLevelAddress:
    cpx #0
    beq LoopLevelAddressEnd            ; If we reach 0 here, we're at the correct address in the table.
    dex

    ;; Load in the level type.
    ldy #0
    lda (CurrentLevelAddress),y
    iny

    cmp #3                             ; ShyGhost mode has 2 extra bytes to load (hidden lanes).
    bne :+
      iny
      iny
    :

    cmp #4                             ; TimeAttack mode has 2 extra bytes to load (minutes and seconds).
    bne :+
      iny
      iny
    :

    ;; Load in the level height and store it. Level height is the masked lower half of the byte.
    lda (CurrentLevelAddress),y
    and #%00001111
    sta IteratedLevelHeight

    ;; Load in the level width and store it. Level width is the masked upper half of the byte.
    lda (CurrentLevelAddress),y
    ror
    ror
    ror
    ror
    and #%00001111                     ; The byte must be shifted before masking to get the desired value.
    sta IteratedLevelWidth
    iny

    ;; Count the cells in the level. Dictated by (width * height) / 4, because there are four cells stored per byte.
    lda #0
    sta CellByteIndex
    LoopLevelHeight:
      lda IteratedLevelWidth
      sta WorkingLevelWidth

      LoopLevelWidth:
        inc CellByteIndex
        lda CellByteIndex
        cmp #4                         ; If we hit 4 cells in the byte, then we can increment the level stride.
        bne :+
          lda #0
          sta CellByteIndex
          iny
        :

        dec WorkingLevelWidth
        lda WorkingLevelWidth
        cmp #0
        bne LoopLevelWidth

      dec IteratedLevelHeight
      lda IteratedLevelHeight
      cmp #0
      bne LoopLevelHeight

    lda CellByteIndex                  ; If there are remaining cells that were counted, but haven't affect the stride yet, count them now.
    cmp #0
    beq :+
      iny
    :
    
    ;; Add the level stride to the resulting address.
    sty LevelStride
    lda CurrentLevelAddress+0
    clc
    adc LevelStride
    sta CurrentLevelAddress+0
    lda CurrentLevelAddress+1
    adc #0
    sta CurrentLevelAddress+1

    jmp LoopLevelAddress
  LoopLevelAddressEnd:

  ;; No levels left to count. The CurrentLevelAddress value will point to the level to load.
  rts
.endproc
