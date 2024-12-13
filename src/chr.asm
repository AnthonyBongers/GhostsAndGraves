.segment "CODE"

.segment "CHARS1"
.incbin "chr/splash.chr"

.segment "CHARS2"
.incbin "chr/title.chr"

.segment "CHARS3"
.incbin "chr/tutorial.chr"

.segment "CHARS4"
.incbin "chr/levelselect.chr"

.segment "CHARS5"
.incbin "chr/game.chr"

CHR_ROM_SWITCH = $8000

.enum CHR_MAP
  SPLASH
  TITLE
  TUTORIAL
  LEVEL_SELECT
  GAME
.endenum

;; Change the CHR mapper to the given index.
; Updates the A register to the mapper index.
.macro SET_CHR_MAPPER idx
  lda #idx
  sta CHR_ROM_SWITCH
.endmacro
