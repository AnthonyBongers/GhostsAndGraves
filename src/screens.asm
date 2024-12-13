.enum SCREEN_TYPE
  UNSET
  GAME_COMPLETE
  GAME_OVER
  GAME
  TITLE
  LEVEL_SELECT
  TUTORIAL
  SPLASH
.endenum

.include "./screens/splash.asm"
.include "./screens/title.asm"
.include "./screens/levelselect.asm"
.include "./screens/game.asm"
.include "./screens/gameover.asm"
.include "./screens/gamecomplete.asm"
.include "./screens/tutorial.asm"

.segment "ZEROPAGE"

PrevScreen: .res 1                     ; From screen, used for determining the cleanup routine to call.
CurrScreen: .res 1                     ; Destination screen, used for determining init and update routine to call.

.segment "CODE"

;; When the PrevScreen and CurrScreen don't match, we're moving to a new screen.
;; Call the init method on the new screen when the transition happens.
.proc ScreenInit
  lda CurrScreen

  cmp #SCREEN_TYPE::GAME_COMPLETE
  bne :+
    jsr GameCompleteInit
    rts
  :

  cmp #SCREEN_TYPE::GAME_OVER
  bne :+
    jsr GameOverInit
    rts
  :

  cmp #SCREEN_TYPE::GAME
  bne :+
    jsr GameInit
    rts
  :

  cmp #SCREEN_TYPE::TITLE
  bne :+
    jsr TitleInit
    rts
  :

  cmp #SCREEN_TYPE::LEVEL_SELECT
  bne :+
    jsr LevelSelectInit
    rts
  :

  cmp #SCREEN_TYPE::TUTORIAL
  bne :+
    jsr TutorialInit
    rts
  :

  cmp #SCREEN_TYPE::SPLASH
  bne :+
    jsr SplashInit
    rts
  :
.endproc

;; Determine which screen is the current screen, and call update on it.
.proc ScreenUpdate
  lda CurrScreen
  cmp PrevScreen                       ; If the current and prev screens DON'T match, cleanup the old one, init the new one.
  beq :+
    jsr ScreenCleanup
    jsr ScreenInit

    lda CurrScreen
    sta PrevScreen
    rts                                ; Hold off on the update until the next frame.
  :

  lda CurrScreen

  cmp #SCREEN_TYPE::GAME_COMPLETE
  bne :+
    jsr GameCompleteUpdate
    rts
  :

  cmp #SCREEN_TYPE::GAME_OVER
  bne :+
    jsr GameOverUpdate
    rts
  :
  
  cmp #SCREEN_TYPE::GAME
  bne :+
    jsr GameUpdate
    rts
  :

  cmp #SCREEN_TYPE::TITLE
  bne :+
    jsr TitleUpdate
    rts
  :

  cmp #SCREEN_TYPE::LEVEL_SELECT
  bne :+
    jsr LevelSelectUpdate
    rts
  :

  cmp #SCREEN_TYPE::TUTORIAL
  bne :+
    jsr TutorialUpdate
    rts
  :

  cmp #SCREEN_TYPE::SPLASH
  bne :+
    jsr SplashUpdate
    rts
  :
.endproc

;; When the PrevScreen and CurrScreen don't match, we're moving to a new screen.
;; Call the cleanup method on the old screen when the transition happens.
.proc ScreenCleanup
  lda PrevScreen

  cmp #SCREEN_TYPE::GAME_COMPLETE
  bne :+
    jsr GameCompleteCleanup
    rts
  :

  cmp #SCREEN_TYPE::GAME_OVER
  bne :+
    jsr GameOverCleanup
    rts
  :

  cmp #SCREEN_TYPE::GAME
  bne :+
    jsr GameCleanup
    rts
  :

  cmp #SCREEN_TYPE::LEVEL_SELECT
  bne :+
    jsr LevelSelectCleanup
    rts
  :

  cmp #SCREEN_TYPE::TITLE
  bne :+
    jsr TitleCleanup
    rts
  :
  
  cmp #SCREEN_TYPE::TUTORIAL
  bne :+
    jsr TutorialCleanup
    rts
  :

  cmp #SCREEN_TYPE::SPLASH
  bne :+
    jsr SplashCleanup
    rts
  :
.endproc

