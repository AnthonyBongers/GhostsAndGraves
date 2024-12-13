.segment "ZEROPAGE"
BgCopyPtr: .res 2                      ; Pointer to start of background change data.
BgCopyOffset: .res 1                   ; Pointer to end of background change data.

AttributeCopyPtr: .res 2               ; Pointer to start of attribute change data.
AttributeCopyOffset: .res 1            ; Pointer to end of attribute change data.

.segment "CODE"

;; WRAM address to store background changes.
BgCopyAddress = $0700
AttributeCopyAddress = $07c0

;; Initialize the start and end pointers, and set the first byte to terminate.
.proc BgCopyReset
  ;; Reset background copy pointer.
  lda #>BgCopyAddress
  sta BgCopyPtr+1
  lda #<BgCopyAddress
  sta BgCopyPtr+0

  ;; Reset attribute copy pointer.
  lda #>AttributeCopyAddress
  sta AttributeCopyPtr+1
  lda #<AttributeCopyAddress
  sta AttributeCopyPtr+0

  ;; Reset offsets.
  lda #0
  ldy #0
  sta (BgCopyPtr), y
  sta BgCopyOffset
  sta (AttributeCopyPtr), y
  sta AttributeCopyOffset

  rts
.endproc

;; Copies two bytes to the PPU.
;; Format: PPU hi-byte / PPU lo-byte / byte to copy.
;; The byte to copy is incremented and set to the sequential PPU address.
;; Exits when the hi-byte of the PPU destination is 0.
.proc BgCopy
  ldy #0
  BufferLoop:
    lda (BgCopyPtr),y                  ; PPU address hi-byte to write to.
    beq EndBackgroundCopy              ; Break on terminator byte (address hi-byte of 0).

    sta PPU_ADDR
    iny
    lda (BgCopyPtr),y                  ; PPU address lo-byte to write to.
    sta PPU_ADDR
    iny

    lda (BgCopyPtr),y                  ; The byte to write to the PPU.
    tax
    stx PPU_DATA
    inx                                ; Increment the byte and write to the next PPU_ADDR.
    stx PPU_DATA
    iny

    jmp BufferLoop
  EndBackgroundCopy:

  ;; Now that the copy is done, we can reset the offsets.
  ;; Copies that are made are only applied for one frame.
  lda #0
  ldy #0
  sta (BgCopyPtr), y
  sta BgCopyOffset

  rts
.endproc

;; Copies an attribute change to the PPU.
;; Format: PPU hi-byte / PPU lo-byte / attribute mask /attribute byte to copy.
;; Exits when the hi-byte of the PPU destination is 0.
.proc AttributeCopy
  ldy #0
  BufferLoop:
    lda (AttributeCopyPtr),y           ; PPU address hi-byte to write to.
    beq EndAttributeCopy               ; Break on terminator byte (hi-byte of 0).

    sta PPU_ADDR
    iny
    lda (AttributeCopyPtr),y           ; PPU address lo-byte to write to.
    sta PPU_ADDR

    lda PPU_DATA                       ; Load in the current attribute byte at the destination.
    lda PPU_DATA
    tax                                ; Store the current attribute to the x register.

    dey

    lda (AttributeCopyPtr),y           ; PPU address hi-byte to write to.
    sta PPU_ADDR
    iny
    lda (AttributeCopyPtr),y           ; PPU address lo-byte to write to.
    sta PPU_ADDR
    iny

    txa
    and (AttributeCopyPtr),y           ; Bitwise AND the attribute mask, to remove the attribute bits for the current tile.
    iny
    ora (AttributeCopyPtr),y           ; Bitwise OR the current attribute byte with the new attribute byte.
    sta PPU_DATA                       ; Store the result in the PPU attribute byte.
    iny

    jmp BufferLoop
  EndAttributeCopy:

  ;; Now that the copy is done, we can reset the offsets.
  ;; Copies that are made are only applied for one frame.
  lda #0
  ldy #0
  sta (AttributeCopyPtr), y
  sta AttributeCopyOffset

  rts
.endproc

