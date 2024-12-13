;; Set initial configuration and state for the game.
.macro INIT_NES
  sei                                  ; Disable all IRQ interrupts.
  cld                                  ; Clear decimal mode.
  ldx #$FF
  txs                                  ; Initialize the stack pointer at address $FF.

  inx                                  ; Overflow from $FF to $00.
  stx PPU_CTRL                         ; Disable NMI.
  stx PPU_MASK                         ; Disable rendering (masking background and sprites).
  stx $4010                            ; Disable DMC IRQs.
  
  lda #$40
  sta $4017                            ; Disable APU frame IRQ.

  bit PPU_STATUS                       ; Read from PPU_STATUS to reset the VBlank flag.

  Wait1stVBlank:                       ; Wait for the first VBlank from the PPU.
    bit PPU_STATUS                     ; Perform a bit-wise check with the PPU_STATUS port.
    bpl Wait1stVBlank                  ; Loop until bit-7 is 1 (inside VBlank).

    lda #0
  ClearRAM:
    sta $0000,x                        ; Zero RAM addr $00XX.
    sta $0100,x                        ; Zero RAM addr $01XX.

    lda #$FF                           ; Set OAM addr $02XX to $FF (sprites off-screen).
    sta $0200,x

    lda #0
    sta $0300,x                        ; Zero RAM addr $03XX.
    sta $0400,x                        ; Zero RAM addr $04XX.
    sta $0500,x                        ; Zero RAM addr $05XX.
    sta $0600,x                        ; Zero RAM addr $06XX.
    sta $0700,x                        ; Zero RAM addr $07XX.
    inx
    bne ClearRAM

  Wait2ndVBlank:                       ; Wait for the second VBlank from the PPU.
    bit PPU_STATUS
    bpl Wait2ndVBlank
.endmacro

