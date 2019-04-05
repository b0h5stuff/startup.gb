;*****************************************
;*  Reiner Ziegler Multicart2 V1.3       *
;*****************************************
;
;  last edit 28-Jun-97 by Jeff Frohwein
;
;  Compiled with RGBASM V1.10.
;
;  last edit 12-July-99 by Reiner Ziegler
;
; 1.3   GBC code is now running
; 1.2   add support for GBC
; 1.1   support max 6 banks
;       check for nintendo logo
;       set ret and reti to selected bank 
; 1.0   select between 1 bank and 3 carts
;
;*****************************************

	INCLUDE "memory1.asm"
	INCLUDE "keypad.asm"
	INCLUDE "ibmpc1.inc"

;Version 1.1 or later of 'memory1.asm' is required.
	rev_Check_memory1_asm 1.1

;Version 1.2 or later of 'keypad.asm' is required.
	rev_Check_keypad_asm 1.2

;Version 1.1 or later of 'ibmpc1.inc' is required.
	rev_Check_ibmpc1_inc 1.1

GoRom           EQU     $C002
WR_Draw_Titles  EQU     $C100
WR_Check_Logo   EQU     $C200
Ram_table       EQU     $C300

Max_Banks       EQU     7               ; max 6 banks 
Max_Carts       EQU     4               ; max 3 carts

	SECTION "Low Ram",WRAM0

UtilityVars     DS      2               ; used by keypad.asm
ExecStore       DS      300             ; Storage for ExecStart routine
buttonPressed   DS      1
autoRunTimeout  DS      2
NumberOfRoms    DS      1
NumberOfBanks   DS      1
NumberOfAll     DS      1
LogoFound       DS      1
GBType          DS      1
	
	SECTION "Org $00",ROM0[$00]     ; RST $00
;	jp  $4000
        DB  $80,$40,$20,$10,$08,$04,$02,$01

	SECTION "Org $08",ROM0[$08]     ; RST $08
	jp  $4008
	
	SECTION "Org $10",ROM0[$10]     ; RST $10
	jp  $4010
	
	SECTION "Org $18",ROM0[$18]     ; RST $18
	jp  $4018
	
	SECTION "Org $20",ROM0[$20]     ; RST $20
	jp  $4020
	
	SECTION "Org $28",ROM0[$28]     ; RST $28
	jp  $4028
	
	SECTION "Org $30",ROM0[$30]     ; RST $30
	jp  $4030
	
	SECTION "Org $38",ROM0[$38]     ; RST $38
	jp  $4038
	
	SECTION "Org $40",ROM0[$40]     ; Vertical Blank Interrupt
	jp  $4040
	
	SECTION "Org $48",ROM0[$48]     ; LCDC Status Interrupt
	jp  $4048
	
	SECTION "Org $50",ROM0[$50]     ; Timer Overflow Interrupt
	jp  $4050

	SECTION "Org $58",ROM0[$58]     ; Serial Transfer Interrupt
	jp  $4058
	
	SECTION "Org $60",ROM0[$60]     ; High-to-Low of P10-P13 Interrupt
	jp  $4060

	SECTION "Org $80",ROM0[$80]

	DB      "Reiner Ziegler  "
	DB      "Date 12.Jul 1999"

	SECTION "Org $100",ROM0[$100]

;*** Beginning of rom execution point ***

	nop
	jp      begin

	NINTENDO_LOGO

;Rom Header Info

 db "MULTICART2 1.3 "         ; Cart name   16bytes
 db $20       
 db $30,$31,0                 ; Licensee codes
 db 3                         ; Cart type   ROM+MBC1+RAM+Battery
 db 0                         ; ROM Size    
 db 2                         ; RAM Size    
 db 1                         ; Non-Japanese
 db $33                       ; Maker ID
 db 2                         ; Version 
 db $72                       ; Complement check (important)
 dw $845A                     ; Checksum (not important)

begin:
	di
			       ; The stack initializes to $FFFE
        ld     [GBType],a      ; save type of GB
	xor    a               ; a = 0
	ldh    [rIF],a         ; clear pending interrupts

	ld     a,0
	ldh    [rIE],a         ; disable interrupts

	ld     a,0
	ldh    [$26],a         ; kill all sounds

	lcd_WaitVRAM           ; Must be in VBL before turning the screen off.

	ld     a,%00010101     ; LCD Controller = Off [No picture on screen]
			       ; WindowBank = $9800 [Not used]
			       ; Window = OFF
			       ; BG Chr = $8000
			       ; BG Bank= $9800
			       ; OBJ    = 8x16
			       ; OBJ    = Off
			       ; BG     = On
        ldh    [rLCDC],a

        ld     a,[GBType]      ; color GB ?
        cp     $11
        jp     nz,oldgb


gowait: ldh     a,[$44]         ;LY LCDC compare
	cp	144
        jr      nc,gowait
	ld	a,0
	ldh	[$40],a		;LCDC lcd control

	ld	a,%10000000
	ldh	[$68],a		;BCPS
	ld	a,%00000000	;palette 0 0  bg
	ldh	[$69],a		;BCPD
	ld	a,%00000000
	ldh	[$69],a

	ld	a,%11111110	;palette 0 1
	ldh	[$69],a
	ld	a,%00011110
	ldh	[$69],a

	ld	a,%11111111	;palette 0 2  fg
	ldh	[$69],a
	ld	a,%01111111
	ldh	[$69],a

	ld	a,%00011111	;palette 0 3
	ldh	[$69],a
	ld	a,%00000000
	ldh	[$69],a

	ld	a,%00000000	;palette 1 0  bg
	ldh	[$69],a
	ld	a,%00000000
	ldh	[$69],a

	ld	a,%01100000	;palette 1 1
	ldh	[$69],a
	ld	a,%00011110
	ldh	[$69],a

	ld	a,%11100000	;palette 1 2  fg
	ldh	[$69],a
	ld	a,%00111111
	ldh	[$69],a

	ld	a,%11100000	;palette 1 3
	ldh	[$69],a
	ld	a,%01111111
	ldh	[$69],a

; Load char set

oldgb:
	ld      bc,TileData
	call    Move_Char        ; Move the charset to $8000

	ld      a,$e4
	ldh     [rBGP],a

; Clear Screen

	ld      hl,$9800
	ld      bc,32*18
	ld      a,32
	call    mem_Set

	ld      hl,MakeSel
	ld      de,$9800+(32)
	ld      bc,MakeSelEnd-MakeSel
	call    mem_Copy

	ld      hl,GetModuleStart
	ld      de,GoRom
	ld      bc,GetModuleEnd-GetModuleStart
	call    mem_Copy
	ld      hl,Draw_Titles   ; move draw_titles into WRAM0
	ld      de,WR_Draw_Titles
	ld      bc,Check_Logo-Draw_Titles
	call    mem_Copy
	ld      hl,Check_Logo   ; move check_logo into WRAM0
	ld      de,WR_Check_Logo
	ld      bc,Move_Char-Check_Logo
	call    mem_Copy
	call    GoRom           ; get module names

	ld      a,%10010101     ; LCD Controller = On
	ldh     [rLCDC],a

; Load RAM bootstrap ROM exec routine

	ld      hl,ExecStart
	ld      de,GoRom
	ld      bc,ExecEnd-ExecStart
	call    mem_Copy

	xor     a
	ld      [buttonPressed],a       ; No button pressed yet

	ld      hl,10000                ; delay for approximately 10 secs
	ld      a,l
	ld      [autoRunTimeout],a
	ld      a,h
	ld      [autoRunTimeout+1],a

	ld      d,0

;Draw program selection pointer

draw_pointer:

	ld      e,d
	inc     e
	ld      hl,$9800+1+(7*32)
	ld      bc,32
draw_p:
	add     hl,bc
	dec     e
	jr      nz,draw_p

; Erase old pointer.... On whatever line it's on.

	call    erase_old

; Draw new selection pointer at this position

	lcd_WaitVRAM
	ld      a,16
	ld      [hl],a

; Delay between draws & keypad read

	ld      hl,$8000
delay:  dec     hl
	ld      a,h
	or      l
	jr      nz,delay

; Check for auto-run

AutoRunTest:
	ld      a,220                   ; small delay
small_delay:
	dec     a
	jr      nz,small_delay

	ld      a,[buttonPressed]
	or      a                       ; has a button been pressed yet?
	jr      nz,TestUp               ; yes

	ld      a,[autoRunTimeout]      ; decrement timeout counter
	ld      l,a
	ld      a,[autoRunTimeout+1]
	ld      h,a

	dec     hl

	ld      a,l
	ld      [autoRunTimeout],a
	ld      a,h
	ld      [autoRunTimeout+1],a

	ld      a,h
	or      l                       ; Has timeout clock reached zero ?
	jr      nz,TestUp               ; no, user input hasn't timed out yet

        ld      d,$00
        ld      a,[NumberOfRoms]        ; ROMïs found ?
        cp      0
        jp      z,ProgRun               ; no
        ld      a,[NumberOfBanks]
        ld      d,a
	jp      ProgRun                 ; Auto run first ROM image in list

; Get User input if available

TestUp:
	call    pad_Read
	bit     PADB_UP,a               ; Has user pressed up ?
	jr      z,TestDown              ; no

	ld      a,1
	ld      [buttonPressed],a       ; kill auto run since button pressed

	dec     d
	ld      a,d
	cp      $80
	jr      c,draw_pointer

	ld      a,[NumberOfAll]
	dec     a
	ld      d,a
	jp      draw_pointer

TestDown:
	bit     PADB_DOWN,a             ; Has user pressed down ?
	jr      z,TestStart             ; no

	ld      a,1
	ld      [buttonPressed],a       ; kill auto run since button pressed

	inc     d
	ld      a,[NumberOfAll]
	ld      e,a
	ld      a,d
	cp      e
	jp      c,draw_pointer

	ld      d,0
	jp      draw_pointer

TestStart:
	bit     PADB_START,a            ; Has user pressed start ?
	jr      nz,ProgRun              ; yes, goto progrun

	bit     PADB_A,a                ; Has user pressed B ?
	jr      nz,ProgRun              ; yes, goto progrun
	
	bit     PADB_SELECT,a 
	jr      z,AutoRunTest           ; return to countdown loop

;self erase code if select pressed

;BANK SA2 into 4000-7fff	

		
    ld a,$aa        ;gb_flash_write_address_byte(0x555, 0xAA);
    ld [$5555],a
    ld a,$55        ;gb_flash_write_address_byte(0x2AA, 0x55);
    ld [$2AAA],a
    ld a,$80        ;gb_flash_write_address_byte(0x555, 0x80);
    ld [$5555],a
    ld a,$aa        ;gb_flash_write_address_byte(0x555, 0xAA);
    ld [$5555],a
    ld a,$55        ;gb_flash_write_address_byte(0x2AA, 0x55);
    ld [$2AAA],a
	xor 	a               
	ld      [$6000],a       ;enable 16MBit mode 
	inc     a               ; select cart no#1 offset $20000 = start of SA02
	ld      [$4000],a       ;set cartridge register
	ld      [$6000],a       ;protect register
	ld      [$2100],a       ;enable bank 	
	ld hl,$7fff   ;SA2=010  this is bank no 8 (bank 9 to be safe)
                  ;SA = Address of the sector to be erased. Address bits A18–A16 select a unique sector
	ld [hl],a      ;gb_flash_write_address_byte(sector << 14, 0x30)
	ld a,$30      ;$30 = erase sector  , hl=$5555 & $10 = entire cart

erase_delay:  dec     hl

	ld      a,h
	or      l
	jr      nz,erase_delay

	xor 	a               
	ld      [$6000],a       ;enable 16MBit mode 
	ld      [$4000],a       ;reset cartridge register to 0 (back to menu)
    inc     a
	ld      [$6000],a       ;protect register
	ld      [$2100],a       ;enable bank 
	jp 0100 ; reset the cart
	
	

; Execute program pointed to by d

ProgRun:
	ld      hl,$0100
	ld      a,[NumberOfBanks]
	dec     a
	cp      d               ;bank or rom ?
	jr      c,GoCart

	ld      hl,$4100        ;start address program
	ld      a,d
	inc     a
	ld      [$2100],a       ;enable bank
	xor     a          
	jp      GoRom           ;cart = 0, hl = ROM code start, Run ROM!

GoCart: ld      a,[NumberOfBanks]
	ld      e,a
	ld      a,d
	sub     e
	inc     a
	jp      GoRom           ;a = cartridge, hl = ROM code start, Run ROM!

; This routine gets loaded into RAM and
; is the bootstrap to execute ROMS.

ExecStart:
	push    af
	push    hl
	ld      hl,$8000
.delay  dec     hl
	ld      a,h
	or      l
	jr      nz,.delay

	xor     a               ;a = 0
	ldh     [rIF],a         ;clear pending interrupts
	ldh     [rIE],a         ;disable interrupts
	ldh     [$26],a         ;kill all sounds
	ld      [$6000],a       ;enable 16MBit mode
	pop     hl
	pop     af
	ld      [$4000],a       ;enable Cart_Bank
	ld      a,1
	ld      [$6000],a       ;protect register

        ld      a,[GBType]      ;restore GB type

	jp      hl            ;Execute ROM
ExecEnd:

; This routine checks for modules and
; display modules name to screen

GetModuleStart:
    xor     a
	ld      c,a             ;start with cart 0, bank 1 ; c=counter
    inc     a
;	inc     a               ;skip bank 1 (32k menu or gb basic)
    ld      b,a
	ld      de,$9800+3+(8*32)
	ld      hl,$4134
Bank_Loop:
	ld      [$2100],a       ;enable bank 
    ld      [LogoFound],a   ;reset not found? put arbitary value into it
	call    WR_Check_Logo      ;Nintendo Logo ?
        ld      a,[LogoFound]
        cp      $46
    	jr      nz, bank_empty    ;display title if found
		call    WR_Draw_Titles 
	    inc     c
bank_empty:	
    inc     b
    ld      a, b
	cp      Max_Banks       ;all modules ? 7 banks in 128k 512/4
	jr      nz,Bank_Loop
	
	ld      a, c
	ld      [NumberOfBanks],a ;save number of games in banks
    
	ld      b,0				; reset counter
    ld      c,1             ;start with cart 1
	ld      hl,$0134        
Cart_Loop:
    xor 	a
	ld      [$6000],a       ;enable 16MBit mode 
	ld      a,c
	ld      [$4000],a       ;set cartridge register
	ld      a,1
	ld      [$6000],a       ;protect register
    ld      [LogoFound],a   ; reset not found
	call    WR_Check_Logo      ;Nintendo Logo ?
        ld      a,[LogoFound]
        cp      $46             ; cart found ?
    	jr      nz, cart_empty    ;display title if found
		call    WR_Draw_Titles 
	    inc     b 

cart_empty:
	inc     c               ;next mbc bank   ; doesnt count properly yet..... maybe sub games in each bank?
	ld      a,c
	cp      Max_Carts       ;all carts ?
	jr      nz,Cart_Loop

    ld      a,b
	ld      [NumberOfRoms],a
	ld      a,[NumberOfBanks]
	add     a,b
	ld      [NumberOfAll],a

	xor     a
	ld      [$6000],a       ;enable 16MBit mode
	ld      [$4000],a       ;reset cartridge register        
	inc     a
	ld      [$6000],a       ;protect register
	ret
GetModuleEnd:

;***************************************************************************
;* draw titles on GB screen
;*
;* input  hl - source  de - destination  length - 16
;***************************************************************************

Draw_Titles:
	push    af
    push    bc
	push    hl
	push    de
	ld      bc,16
	
	inc     b               ; mem_copy
	inc     c
	jr      .skip
.loop   ld      a,[hl+]
	cp      0
	jr      nz,.noblank     ; blank ?
	add     a,$20
.noblank
	ld      [de],a
	inc     de
.skip   dec     c
	jr      nz,.loop
	dec     b
	jr      nz,.loop

	pop     de

	ld      hl,32           ; de = de + 32
	add     hl,de
	ld      d,h
	ld      e,l
	pop     hl
	pop     bc
	pop     af
	ret

;***************************************************************************
;*
;* check for Nintendo Logo
;*
;* input  hl - address
;*
;***************************************************************************

Check_Logo:
	push    hl
	push    de
;push bc	
	push    af

	ld      a,l
	sub     $30
	ld      l,a             ; address 0x0104 or 0x4104
	xor     a
	ld      e,$30           ; length 48 bytes
.loop   add     a,[hl]
	inc     hl
	dec     e
	jr      nz,.loop        ; add all bytes
	cp      $46             ; checksum = $46 ?
	jr      nz,.fail
	ld      [LogoFound],a

.fail   pop     af
;pop bc
	pop     de
	pop     hl
	ret

; move charset to $8000

Move_Char:
	ld     hl,$8000
	ld     de,$1000
.lp1
	ld     a,[bc]
	ld     [hl+],a
	ld     [hl+],a
	inc    bc
	dec    e
	jr     nz,.lp1
	dec    d
	jr     nz,.lp1
	ret

; Erase old pointer.... On whatever line it's on.

erase_old:
	lcd_WaitVRAM
	ld      a,32
	ld      [$9800+1+(8*32)],a
	lcd_WaitVRAM
	ld      a,32
	ld      [$9800+1+(9*32)],a
	lcd_WaitVRAM
	ld      a,32
	ld      [$9800+1+(10*32)],a
	lcd_WaitVRAM
	ld      a,32
	ld      [$9800+1+(11*32)],a
	lcd_WaitVRAM
	ld      a,32
	ld      [$9800+1+(12*32)],a
	lcd_WaitVRAM
	ld      a,32
	ld      [$9800+1+(13*32)],a
	lcd_WaitVRAM
	ld      a,32
	ld      [$9800+1+(14*32)],a
	lcd_WaitVRAM
	ld      a,32
	ld      [$9800+1+(15*32)],a
	lcd_WaitVRAM
	ld      a,32
	ld      [$9800+1+(16*32)],a
	lcd_WaitVRAM
	ld      a,32
	ld      [$9800+1+(17*32)],a
	ret

TileData:
	chr_IBMPC1 1,4          ; include IBMPC char set

MakeSel:
    DB      " V1.3 (c) 2019 by               "
	DB      " Reiner Ziegler/J.F.            "
	DB      "                                "
    DB      " - Select Module -              "
;	DB      "                                "
	DB      " and press start...             "
MakeSelEnd:

