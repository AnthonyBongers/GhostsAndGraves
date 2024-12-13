;; Disable PPU rendering and NMI.
.macro PPU_DISABLE_NMI
  lda #0
  sta PPU_CTRL
  sta PPU_MASK
.endmacro

;; Set a 16-bit address to the PPU_ADDR.
.macro PPU_SETADDR addr
  bit PPU_STATUS                       ; Read from PPU_STATUS to reset the address latch.
  lda #>addr                           ; Load the hi-byte.
  sta PPU_ADDR                         ; Store the hi-byte into PPU_ADDR.
  lda #<addr                           ; Load the lo-byte.
  sta PPU_ADDR                         ; Store the lo-byte into PPU_ADDR.
.endmacro

;; Send a value to PPU_DATA.
.macro PPU_SETDATA val
  lda val
  sta PPU_DATA
.endmacro

;; Push registers A, X, Y, and status flags on the stack.
.macro PUSH_REGS
  pha                                  ; Push A to the stack.
  txa
  pha                                  ; Push X to the stack.
  tya
  pha                                  ; Push Y to the stack.
  php                                  ; Push Processor Status flags to the stack.
.endmacro

;; Pull registers A, X, Y, and status flags from the stack.
.macro PULL_REGS
  plp                                  ; Pull the the status flags from the stack.
  pla                                  ; Pull the old value of X from the stack.
  tay
  pla                                  ; Pull the old value of X from the stack.
  tax
  pla                                  ; Pull the old value of A from the stack.
.endmacro

