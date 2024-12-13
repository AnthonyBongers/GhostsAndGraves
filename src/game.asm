.include "header.asm"
.include "reset.asm"
.include "utils.asm"
.include "ppu.asm"
.include "palette.asm"
.include "bgcopy.asm"
.include "rle.asm"
.include "input.asm"
.include "chr.asm"
.include "screens.asm"
.include "audio.asm"

.segment "ZEROPAGE"
IsDrawComplete: .res 1                 ; Flag to indicate when VBlank is done drawing.

.segment "CODE"

;; Lock execution until the NMI is done drawing.
.proc WaitForVBlank
: lda IsDrawComplete
  beq :-
  lda #0
  sta IsDrawComplete
  rts
.endproc

;; Reset ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Reset:
  INIT_NES

  jsr BgCopyReset

  lda #SCREEN_TYPE::SPLASH
  sta CurrScreen                       ; Start the game in the splash screen.

  ldx #<sounds
  ldy #>sounds
  jsr famistudio_sfx_init

  GameLoop:
    jsr famistudio_update

    jsr InputUpdate
    jsr ScreenUpdate

    jsr WaitForVBlank
    jmp GameLoop

;; NMI ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NMI:
  PUSH_REGS                            ; Save registers from before the interrupt.

  ;; Show sprites and background, don't crop the left of the screen. 
  lda #(PPU_MASK_FLAGS::SHOW_LEFT_BACKGROUND | PPU_MASK_FLAGS::SHOW_LEFT_SPRITES | PPU_MASK_FLAGS::SHOW_BACKGROUND | PPU_MASK_FLAGS::SHOW_SPRITES)
  sta PPU_MASK

  ;; Start DMA copy of OAM data from RAM to PPU.
  lda #$02                             ; Copy spite data starting at $02**.
  sta PPU_OAM_DMA                      ; Trigger OAM-DMA copy on write.

  jsr BgCopy                           ; Commit any background changes to the PPU.
  jsr AttributeCopy                    ; Commit any attribute changes to the PPU.

  lda #0
  sta PPU_SCROLL
  sta PPU_SCROLL                       ; Turn off scrolling.

  ;; Notify game loop that the vblank has started.
  lda #1
  sta IsDrawComplete                   ; Flag once done drawing to the PPU.

  PULL_REGS                            ; Restore registers from interrupt.
  rti

;; IRQ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IRQ:
  rti

.segment "VECTORS"
.word NMI
.word Reset
.word IRQ

