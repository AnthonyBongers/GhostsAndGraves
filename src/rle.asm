.segment "ZEROPAGE"

BackgroundRLEPtr: .res 2

.segment "CODE"

;; Run Length Decode data into the PPU.
; Params:
; X register - lo-byte of the data to read.
; Y register - hi-byte of the data to read.
.proc LoadBackgroundRLE
  stx BackgroundRLEPtr+0
  sty BackgroundRLEPtr+1

  PPU_SETADDR $2000

  ldy #0                               ; Use Y register as offset into memory.

  @Loop:
    lda (BackgroundRLEPtr),y           ; The tile count to repeat.
    beq @Completed                     ; If we hit a 0 here, we hit the end of the dataset.

    iny
    bne :+
      inc BackgroundRLEPtr+1           ; Increment hi-byte if we overflow the lo-byte.
    :
    tax

    lda (BackgroundRLEPtr),y           ; The tile id to repeat.
    iny
    bne :+
      inc BackgroundRLEPtr+1           ; Increment hi-byte if we overflow the lo-byte.
    :
    
    : sta PPU_DATA                     ; Store the tile id (A register) into the PPU n times (X register).
      dex
      bne :-

    jmp @Loop

  @Completed:
    rts
.endproc
