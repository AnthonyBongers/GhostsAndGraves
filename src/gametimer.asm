.segment "ZEROPAGE"

TimerMillis: .res 1                    ; Counter for determining when a second has elapsed. 
TimerSeconds: .res 2                   ; Decimal mode conversion for seconds. Two bytes for high and low second (ex 26 would be hi-byte 2 and lo-byte 6).
TimerMinutes: .res 2                   ; Same as seconds, but for minutes.

TimerCountMode: .res 1                 ; Set the timer mode. `Down` is used for TimeAttack mode, and `Up` is for all others.

TimerRenderAddr: .res 2

.enum TimerMode
  Up
  Down
  Stopped
.endenum

.segment "CODE"

;; Reset the timer data for the level.
.proc ResetTimer
  lda #0
  sta TimerMillis
  sta TimerSeconds+0
  sta TimerSeconds+1
  sta TimerMinutes+0
  sta TimerMinutes+1
  sta TimerCountMode

  rts
.endproc

;; Called for TimeAttack mode.
;; Set TimerMode to `Down` and load in the `Time` data from the level into our timer.
.proc SetCountdownTimer
  lda #TimerMode::Down
  sta TimerCountMode

  ;; Load the minutes from the level into the timer.
  ldx Timer+0
  LoopTimerMinutes:
    cpx #0
    beq EndLoopTimerMinutes
    dex

    inc TimerMinutes+1
    lda TimerMinutes+1
    cmp #10                            ; Since the loaded data is in hex, we must manually convert to decimal...
    bne :+
      inc TimerMinutes+0               ; Increment the decimal hi-byte of the timer, and reset the lo-byte back to 0.
      lda #0
      sta TimerMinutes+1
    :
    jmp LoopTimerMinutes
  EndLoopTimerMinutes:

  ;; Load the minutes from the level into the timer.
  ldx Timer+1
  LoopTimerSeconds:
    cpx #0
    beq EndLoopTimerSeconds
    dex

    inc TimerSeconds+1
    lda TimerSeconds+1
    cmp #10                            ; Since the loaded data is in hex, we must manually convert to decimal...
    bne :+
      inc TimerSeconds+0               ; Increment the decimal hi-byte of the timer, and reset the lo-byte back to 0.
      lda #0
      sta TimerSeconds+1
    :
    jmp LoopTimerSeconds
  EndLoopTimerSeconds:

  rts
.endproc

;; Entry point for updating the timer. Branches on timer mode type.
.proc UpdateTimer
  lda TimerCountMode
  cmp #TimerMode::Up
  bne :+
    jsr UpdateTimerUp
    rts
  :

  lda TimerCountMode
  cmp #TimerMode::Down
  bne :+
    jsr UpdateTimerDown
    rts
  :

  rts
.endproc

;; Update method for counting up. Used in standard, shy ghost, and no shovel modes.
.proc UpdateTimerUp
  inc TimerMillis
  
  lda TimerMillis
  cmp #60                              ; Increment lo-seconds for 60fps.
  bne :+
    lda #0
    sta TimerMillis

    inc TimerSeconds+1
  :

  lda TimerSeconds+1
  cmp #10                              ; If we hit decimal 10, we increment the hi-byte of seconds.
  bne :+
    lda #0
    sta TimerSeconds+1

    inc TimerSeconds+0
  :

  lda TimerSeconds+0
  cmp #6                               ; If the hi-byte of the seconds is 6, then the lo-byte of minutes is incremented.
  bne :+
    lda #0
    sta TimerSeconds+0

    inc TimerMinutes+1
  :

  lda TimerMinutes+1
  cmp #10                              ; If the lo-byte of the minutes hits decimal 10, then we increment the minutes hi-byte.
  bne :+
    lda #0
    sta TimerMinutes+1

    inc TimerMinutes+0
  :

  lda TimerMinutes+0
  cmp #6                               ; We hit the max time of 1 hour. Just stop the timer and let the player do their thing.
  bne :+
    lda #TimerMode::Stopped
    sta TimerCountMode
  :

  jsr RenderTimerSeconds               ; Commit timer changes to the PPU.

  rts
.endproc

.proc UpdateTimerDown
  inc TimerMillis
  
  lda TimerMillis
  cmp #60                              ; Decrement lo-seconds for 60fps.
  bne :+
    lda #0
    sta TimerMillis

    dec TimerSeconds+1
  :

  lda TimerSeconds+1
  cmp #$ff                             ; If the lo-byte of seconds wraps around, then decrement the hi-byte of seconds.
  bne :+
    lda #9
    sta TimerSeconds+1

    dec TimerSeconds+0
  :

  lda TimerSeconds+0
  cmp #$ff                             ; If the hi-byte of seconds wraps around, then decrement the lo-byte of minutes.
  bne :+
    lda #5
    sta TimerSeconds+0

    dec TimerMinutes+1
  :

  lda TimerMinutes+1
  cmp #$ff                             ; If the lo-byte of minutes wraps around, then decrement the hi-byte of minutes.
  bne :+
    lda #9
    sta TimerMinutes+1

    dec TimerMinutes+0
  :

  lda TimerMinutes+0
  cmp #$ff                             ; If the hi-byte of minutes wraps around, game over. Stop the counter, and the level will run the logic to kick them out.
  bne :+
    lda #0
    sta TimerMinutes+0
    sta TimerMinutes+1
    sta TimerSeconds+0
    sta TimerSeconds+1

    lda #TimerMode::Stopped
    sta TimerCountMode
  :

  jsr RenderTimerSeconds               ; Commit any changes to the PPU.

  rts
.endproc

;; PPU addresses for drawing each digit of the timer.
TimerMinsHiPPUAddr = $20a1
TimerMinsLoPPUAddr = $20a2
TimerColonPPUAddr = $20a3
TimerSecsHiPPUAddr = $20a4
TimerSecsLoPPUAddr = $20a5
TimerEndPPUAddr = $20a6

;; Render the timer to the screen.
;; 
;; Since the bgcopy routine draws two tiles horizontally automatically,
;; and each digit of the timer is only one tile horizontally, 
;; we have to draw an empty space at the end to overdraw the last character.
.proc RenderTimerSeconds
  ;; Draw the hi-byte of the minutes
  lda #>TimerMinsHiPPUAddr
  sta TimerRenderAddr+1
  lda #<TimerMinsHiPPUAddr
  sta TimerRenderAddr+0

  ldy BgCopyOffset

  lda TimerRenderAddr+1
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda TimerMinutes+0
  clc
  adc #$c0
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  clc
  adc #$20
  sta TimerRenderAddr+0

  lda TimerRenderAddr+1
  adc #0
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda TimerMinutes+0
  clc
  adc #$d0
  sta (BgCopyPtr),y
  iny

  lda #0
  sta (BgCopyPtr),y

  sty BgCopyOffset

  ;; Draw the lo-byte of the minutes.
  lda #>TimerMinsLoPPUAddr
  sta TimerRenderAddr+1
  lda #<TimerMinsLoPPUAddr
  sta TimerRenderAddr+0

  ldy BgCopyOffset

  lda TimerRenderAddr+1
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda TimerMinutes+1
  clc
  adc #$c0
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  clc
  adc #$20
  sta TimerRenderAddr+0

  lda TimerRenderAddr+1
  adc #0
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda TimerMinutes+1
  clc
  adc #$d0
  sta (BgCopyPtr),y
  iny

  lda #0
  sta (BgCopyPtr),y

  sty BgCopyOffset

  ;; Draw the `:` character between the mins and seconds.
  lda #>TimerColonPPUAddr
  sta TimerRenderAddr+1
  lda #<TimerColonPPUAddr
  sta TimerRenderAddr+0

  ldy BgCopyOffset

  lda TimerRenderAddr+1
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda #$cc
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  clc
  adc #$20
  sta TimerRenderAddr+0

  lda TimerRenderAddr+1
  adc #0
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda #$dc
  sta (BgCopyPtr),y
  iny

  lda #0
  sta (BgCopyPtr),y

  sty BgCopyOffset

  ;; Draw the hi-byte of the seconds.
  lda #>TimerSecsHiPPUAddr
  sta TimerRenderAddr+1
  lda #<TimerSecsHiPPUAddr
  sta TimerRenderAddr+0

  ldy BgCopyOffset

  lda TimerRenderAddr+1
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda TimerSeconds+0
  clc
  adc #$c0
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  clc
  adc #$20
  sta TimerRenderAddr+0

  lda TimerRenderAddr+1
  adc #0
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda TimerSeconds+0
  clc
  adc #$d0
  sta (BgCopyPtr),y
  iny

  lda #0
  sta (BgCopyPtr),y

  sty BgCopyOffset

  ;; Draw the lo-byte of the seconds.
  lda #>TimerSecsLoPPUAddr
  sta TimerRenderAddr+1
  lda #<TimerSecsLoPPUAddr
  sta TimerRenderAddr+0

  ldy BgCopyOffset

  lda TimerRenderAddr+1
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda TimerSeconds+1
  clc
  adc #$c0
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  clc
  adc #$20
  sta TimerRenderAddr+0

  lda TimerRenderAddr+1
  adc #0
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda TimerSeconds+1
  clc
  adc #$d0
  sta (BgCopyPtr),y
  iny

  lda #0
  sta (BgCopyPtr),y

  sty BgCopyOffset

  ;; Overdraw the extra tiles from the lo-byte of the seconds.
  lda #>TimerEndPPUAddr
  sta TimerRenderAddr+1
  lda #<TimerEndPPUAddr
  sta TimerRenderAddr+0

  ldy BgCopyOffset

  lda TimerRenderAddr+1
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda #$cd
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  clc
  adc #$20
  sta TimerRenderAddr+0

  lda TimerRenderAddr+1
  adc #0
  sta (BgCopyPtr),y
  iny

  lda TimerRenderAddr+0
  sta (BgCopyPtr),y
  iny

  lda #$dd
  sta (BgCopyPtr),y
  iny

  lda #0
  sta (BgCopyPtr),y

  sty BgCopyOffset

  rts
.endproc
