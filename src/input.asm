;; Controller input state and logic.

;; Constants
CONTROLLER = $4016

BUTTON_A      = %10000000
BUTTON_B      = %01000000
BUTTON_SELECT = %00100000
BUTTON_START  = %00010000
BUTTON_UP     = %00001000
BUTTON_DOWN   = %00000100
BUTTON_LEFT   = %00000010
BUTTON_RIGHT  = %00000001

.segment "ZEROPAGE"

;; Buttons states, see input constants for byte layout.

Buttons:         .res 1                ; Player 1 down buttons from curr frame.
PrevButtons:     .res 1                ; Player 1 down buttons from prev frame.
PressedButtons:  .res 1                ; Player 1 pressed buttons.
ReleasedButtons: .res 1                ; Player 1 released buttons.

.segment "CODE"

;; Update the state of controller input in memory.
; Reads all 8 buttons into the Buttons byte.
; Copies over the previous value of Buttons into PrevButtons.
; Compared current and previous button state to determine press and relase states.
.proc InputUpdate
  lda Buttons
  sta PrevButtons
  
  lda #1
  sta Buttons
  sta CONTROLLER                       ; Set Latch=1 to begin 'Input' mode
  lsr
  sta CONTROLLER                       ; Set Latch=0 to begin 'Output' mode

  : lda CONTROLLER                     ; Read a bit from the controller data line.
    lsr                                ; Shift right to place the bit we just read into the Carry flag.
    rol Buttons                        ; Rotate bits left, placing the Carry into the 1st bit of Buttons.
    bcc :-                             ; Loop until Carry is set from the initial 1 we loaded inside Buttons.

  lda Buttons
  eor PrevButtons
  and Buttons
  sta PressedButtons                   ; Compare current and previous state to set pressed state.

  lda Buttons
  eor PrevButtons
  and PrevButtons
  sta ReleasedButtons                  ; Compare current and previous state to set released state.

  rts
.endproc

