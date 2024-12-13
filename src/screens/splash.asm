.segment "ZEROPAGE"

SplashCounter: .res 1                  ; Track the frames in the splash screen.

SplashTimeout = 3 * 60                 ; Leave the splash screen after 3 seconds.

.segment "CODE"

.proc SplashInit
  ;; Disable VBlank.
  lda #0
  sta PPU_CTRL
  sta PPU_MASK

  SET_CHR_MAPPER CHR_MAP::SPLASH

  ldx #<SplashBackgroundPalette
  ldy #>SplashBackgroundPalette
  jsr LoadPalette

  ldx #<SplashBackgroundData
  ldy #>SplashBackgroundData
  jsr LoadBackgroundRLE

  ;; Enable VBlank.
  lda #(PPU_CTRL_FLAGS::ENABLE_VBLANK_NMI)
  sta PPU_CTRL

  rts
.endproc

.proc SplashUpdate
  inc SplashCounter

  lda SplashCounter
  cmp #SplashTimeout                   ; Has the splash timeout been reached?
  bne :+
    lda #SCREEN_TYPE::TITLE
    sta CurrScreen                     ; If so, switch to the title screen.
  :
  rts
.endproc

.proc SplashCleanup
  rts
.endproc

SplashBackgroundData:
.incbin "nametables/splash.rle"

SplashBackgroundPalette:
.byte $0d,$3c,$1a,$20, $0d,$3c,$27,$20, $0d,$3c,$27,$20, $0d,$3c,$27,$20
.byte $0d,$3c,$27,$20, $0d,$3c,$27,$20, $0d,$3c,$27,$20, $0d,$3c,$27,$20

