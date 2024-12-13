;; INES Header info. 
; 
; Cartridge configuration for nes binary.
; More info at https://www.nesdev.org/wiki/INES

.segment "HEADER"

;; Bytes 0-3
; 4-byte string with the characters 'NES\n'.
.byte $4E, $45, $53, $1A

;; Byte 4
; How many 16KiB units of PRG-ROM the game will use.
.byte $02

;; Byte 5
; How many 8KiB units of CHR-ROM the game will use.
.byte $05

;; Flags 6
; Mapper, mirroring, battery, trainer.
.byte %00110011
;      ||||||||
;      |||||||+- Nametable arrangement: 0: vertical arrangement ("horizontal mirrored")
;      |||||||                          1: horizontal arrangement ("vertically mirrored")
;      ||||||+-- 1: Cartridge contains battery-backed PRG RAM ($6000-7FFF) or other persistent memory
;      |||||+--- 1: 512-byte trainer at $7000-$71FF (stored before PRG data)
;      ||||+---- 1: Alternative nametable layout
;      ++++----- Lower nybble of mapper number

;; Flags 7
; Mapper, VS/Playchoice, NES 2.0.
.byte %00000000
;      ||||||||
;      |||||||+- VS Unisystem
;      ||||||+-- PlayChoice-10 (8 KB of Hint Screen data stored after CHR data)
;      ||||++--- If equal to 2, flags 8-15 are in NES 2.0 format
;      ++++----- Upper nybble of mapper number

;; Flags 8
; PRG-RAM size.
.byte $00

;; Flags 9
; TV system.
.byte %00000000
;             |
;             +- TV system (0: NTSC / 1: PAL)

;; Flags 10
; Not part of the official specification, and relatively few emulators honor it.
.byte %00000000
;        ||  ||
;        ||  ++- TV system (0: NTSC; 2: PAL; 1/3: dual compatible)
;        |+----- PRG RAM ($6000-$7FFF) (0: present; 1: not present)
;        +------ 0: Board has no bus conflicts; 1: Board has bus conflicts

;; Flags 11-15
; Unused Padding.
.byte $00, $00, $00, $00, $00

