.segment "ZEROPAGE"

PalettePtr: .res 2

.segment "CODE"

;; Loads 32 bytes of palette data into the PPU.
; First 16 bytes are for the background.
; Seconds 16 bytes are for the sprites.
;
; Params:
; X register - lo-byte of the data to read.
; Y register - hi-byte of the data to read.
.proc LoadPalette
  stx PalettePtr+0
  sty PalettePtr+1

  PPU_SETADDR $3F00
  ldy #0
: lda (PalettePtr),y
  sta PPU_DATA
  iny
  cpy #32                              ; Loop until all 32 bytes are copied.
  bne :-
  rts
.endproc
