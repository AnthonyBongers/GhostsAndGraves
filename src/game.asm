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

.segment "SAV"
MagicValue1: .res 1
MagicValue2: .res 1

.segment "ZEROPAGE"
IsDrawComplete: .res 1                 ; Flag to indicate when VBlank is done drawing.
NeedsSRAMUpdate: .res 1

.segment "CODE"

;; Set the SRAM values on first launch of the game.
;; Check for a two byte magic value.
;; If that value isn't set, reset all SRAM values.
;; Then set the magic value for next runs.
;;
;; This is done because SRAM may be in a random state on actual carts.
;; Emulators are usually all zeros in SRAM, so bad data was never seen.
.proc FirstLaunchClearSRAM
  ;; Set to needing to clear by default.
  lda #1
  sta NeedsSRAMUpdate

  ;; If the first magic byte doesn't match, jump to clearing SRAM.
  lda MagicValue1
  cmp #92
  bne EndMagicValueCheck

  ;; If the second magic byte doesn't match, jump to clearing SRAM.
  lda MagicValue2
  cmp #112
  bne EndMagicValueCheck

  ;; If we get here, both magic bytes matched, so don't clear the SRAM.
  lda #0
  sta NeedsSRAMUpdate

  EndMagicValueCheck:

  ;; If we need to clear SRAM...
  lda NeedsSRAMUpdate
  cmp #0
  beq :+
    ;; Zero out all game save data.
    lda #0
    sta PlayerProgressWorld
    sta PlayerProgressLevel
    sta PlayerProgressTutorialCompleted

    ;; Then set the magic bytes.
    lda #92
    sta MagicValue1
    lda #112
    sta MagicValue2
  :

  rts
.endproc

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

  jsr FirstLaunchClearSRAM

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
