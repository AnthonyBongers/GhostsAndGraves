;; Constants for PPU registers.
; See https://www.nesdev.org/wiki/PPU_registers

;; PPU control register.
; Various flags controlling general PPU operation.
; Access: write
;
; 7  bit  0
; ---- ----
; VPHB SINN
; |||| ||||
; |||| ||++- Base nametable address
; |||| ||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
; |||| |+--- VRAM address increment per CPU read/write of PPUDATA
; |||| |     (0: add 1, going across; 1: add 32, going down)
; |||| +---- Sprite pattern table address for 8x8 sprites
; ||||       (0: $0000; 1: $1000; ignored in 8x16 mode)
; |||+------ Background pattern table address (0: $0000; 1: $1000)
; ||+------- Sprite size (0: 8x8 pixels; 1: 8x16 pixels – see PPU OAM#Byte 1)
; |+-------- PPU master/slave select
; |          (0: read backdrop from EXT pins; 1: output color on EXT pins)
; +--------- Generate an NMI at the start of the
;            vertical blanking interval (0: off; 1: on)
PPU_CTRL     = $2000

.enum PPU_CTRL_FLAGS
  VERTICAL_DATA_INCR    = %00000100
  SPRITE_ADDR           = %00001000
  BG_IN_SECOND_CHR_ADDR = %00010000
  SPRITE_SIZE_USE_8x16  = %00100000
  MASTER_SLAVE_SELECT   = %01000000
  ENABLE_VBLANK_NMI     = %10000000
.endenum

;; PPU mask register.
; Controls the rendering of sprites and backgrounds, as well as colour effects.
; Access: write
;
; 7  bit  0
; ---- ----
; BGRs bMmG
; |||| ||||
; |||| |||+- Greyscale (0: normal color, 1: produce a greyscale display)
; |||| ||+-- 1: Show background in leftmost 8 pixels of screen, 0: Hide
; |||| |+--- 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
; |||| +---- 1: Show background
; |||+------ 1: Show sprites
; ||+------- Emphasize red (green on PAL/Dendy)
; |+-------- Emphasize green (red on PAL/Dendy)
; +--------- Emphasize blue
PPU_MASK    = $2001

.enum PPU_MASK_FLAGS
  GREYSCALE            = %00000001
  SHOW_LEFT_BACKGROUND = %00000010
  SHOW_LEFT_SPRITES    = %00000100
  SHOW_BACKGROUND      = %00001000
  SHOW_SPRITES         = %00010000
  EMPHASIZE_RED        = %00100000
  EMPHASIZE_GREEN      = %01000000
  EMPHASIZE_BLUE       = %10000000
.endenum

;; PPU status register.
; Reflects the state of various functions inside the PPU.
; Access: read
;
; 7  bit  0
; ---- ----
; VSO. ....
; |||| ||||
; |||+-++++- PPU open bus. Returns stale PPU bus contents.
; ||+------- Sprite overflow. The intent was for this flag to be set
; ||         whenever more than eight sprites appear on a scanline, but a
; ||         hardware bug causes the actual behavior to be more complicated
; ||         and generate false positives as well as false negatives; see
; ||         https://www.nesdev.org/wiki/PPU_sprite_evaluation. 
; ||         This flag is set during sprite evaluation and cleared at dot 1 
; ||         (the second dot) of the pre-render line.
; |+-------- Sprite 0 Hit.  Set when a nonzero pixel of sprite 0 overlaps
; |          a nonzero background pixel; cleared at dot 1 of the pre-render
; |          line. Used for raster timing.
; +--------- Vertical blank has started (0: not in vblank; 1: in vblank).
;            Set at dot 1 of line 241 (the line *after* the post-render
;            line); cleared after reading $2002 and at dot 1 of the
;            pre-render line.
PPU_STATUS  = $2002

;; OAM address port.
; Write the address of OAM you want to access here.
; Access: write
OAM_ADDR    = $2003

;; OAM data port.
; Write OAM data here. Writes will increment OAM ADDR after the write; reads do not.
; Access: read/write
OAM_DATA    = $2004

;; PPU scrolling position register.
; Tells the PPU which pixel of the nametable should be at the top left corner of the rendered screen.
; Access: write x2 (first is the X scroll and the second is the Y scroll)
PPU_SCROLL  = $2005

;; PPU address register.
; Access: write x2 (first is hi-byte and the second is the lo-byte)
PPU_ADDR    = $2006

;; PPU data port.
; Access increments video memory address by amout determined by bit 2 of PPU_CTRL.
; Access: read/write
PPU_DATA    = $2007

;; OAM DMA register (high byte).
; Writing $XX will upload 256 bytes of data from CPU page $XX00–$XXFF to the internal PPU OAM.
; Access: write
PPU_OAM_DMA = $4014

