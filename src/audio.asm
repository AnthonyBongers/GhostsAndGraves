.segment "CODE"

;; Tie FamiStudio segments to the game cfg.
.define FAMISTUDIO_CA65_ZP_SEGMENT   ZEROPAGE
.define FAMISTUDIO_CA65_RAM_SEGMENT  RAM
.define FAMISTUDIO_CA65_CODE_SEGMENT CODE

;; FamiStudio options. Disable to save cycles and memory.
FAMISTUDIO_CFG_EXTERNAL       = 1
FAMISTUDIO_CFG_SFX_SUPPORT    = 1
FAMISTUDIO_USE_VOLUME_TRACK   = 1
FAMISTUDIO_USE_SLIDE_NOTES    = 1

; FAMISTUDIO_CFG_DPCM_SUPPORT   = 1
; FAMISTUDIO_CFG_SFX_STREAMS    = 2
; FAMISTUDIO_CFG_EQUALIZER      = 1
; FAMISTUDIO_USE_PITCH_TRACK    = 1
; FAMISTUDIO_USE_VIBRATO        = 1
; FAMISTUDIO_USE_ARPEGGIO       = 1
; FAMISTUDIO_CFG_SMOOTH_VIBRATO = 1
; FAMISTUDIO_USE_RELEASE_NOTES  = 1
; FAMISTUDIO_DPCM_OFF           = $E000

.include "./thirdparty/audioengine.asm"
.include "./sound/sfx.asm"
.include "./sound/title.asm"

;; The only music in the game is the title song.
;; Will loop until StopMusic is called.
.proc PlayTitleMusic
  ldx #<music_data_title
  ldy #>music_data_title
  lda #1
  jsr famistudio_init

  lda #0
  jsr famistudio_music_play

  rts
.endproc

;; Stop any playing song (the title song in this case).
.proc StopMusic
  jsr famistudio_music_stop

  rts
.endproc

;; Play the dig sound effect.
;; Preserves registers, and restores them before returning.
.proc PlaySoundDig
  PUSH_REGS

  lda #0
  ldx #FAMISTUDIO_SFX_CH0
  jsr famistudio_sfx_play

  PULL_REGS

  rts
.endproc

;; Play the click sound effect. Played when navigating the puzzle board.
;; Preserves registers, and restores them before returning.
.proc PlaySoundClick
  PUSH_REGS

  lda #1
  ldx #FAMISTUDIO_SFX_CH0
  jsr famistudio_sfx_play

  PULL_REGS

  rts
.endproc
