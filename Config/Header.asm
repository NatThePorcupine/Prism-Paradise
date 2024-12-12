; =========================================================================================================================================================
; MegaDrive Header
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Based on MarkeyJester's shortened header and initialization
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Store a string in memory with a character limit (also pads to that limit if it doesn't exceed it)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	string	- The string
;	limit	- character limit
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
headStr		macro	string, limit
		local	p
p =		*
		dcb.b	\limit, " "
		org	p
		dc.b	\string
		org	p+\limit
		endm
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		org	0
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Vector table
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		dc.l	($F0<<24)|PORT_C_CTRL-1		; Stack pointer (set like so for initialization routine) (also manufacture lineF exception)

		dc.l	.PrgInit			; Entry pointer

		dc.l	exBus				; Bus error
		dc.l	exAddr				; Address error
		dc.l	exIll				; Illegal instruction error
		dc.l	exDiv				; Division by zero error
		dc.l	exChk				; CHK out of bounds error
		dc.l	Trapv				; TRAPV interrupt
		dc.l	exPriv				; Privilege violation error
		dc.l	exTrace				; TRACE interrupt
		dc.l	exLineA				; Line A emulation
		dc.l	exLineF				; Line F emulation

.InitVals:	dc.w	$18-1				; Number of registers to set up
		dc.w	$8004				; VDP register base (preset for register 0 - H-INT disabled)
		dc.w	$100				; Register increment (also used for Z80 later)

		dc.b	$34				; DMA enabled, V-INT enabled
		dc.b	$C000/$400			; Plane A at $C000
		dc.b	$D000/$400			; Plane W at $D000
		dc.b	$E000/$2000			; Plane B at $E000
		dc.b	$F800/$200			; Sprite table at $F800
		dc.b	$00				; Unused
		dc.b	$00				; BG color line 0 entry 0
		dc.b	$00				; Unused
		dc.b	$00				; Unused
		dc.b	$FF				; H-INT every 255th line
		dc.b	$00				; EXT-INT off, VScroll by screen, HScroll by screen
		dc.b	$81				; H40 width, interalce disabled, S/H disabled
		dc.b	$FC00/$400			; HScroll table at $FC00
		dc.b	$00				; Unused
		dc.b	$02				; Autoincrement by 2
		dc.b	$01				; Plane size 64x32
		dc.b	$00				; Disable window
		dc.b	$00				; ''
		dc.b	$FF				; DMA length $FFFF
		dc.b	$FF				; ''
		dc.b	$00				; DMA source 0
		dc.b	$00				; ''
		dc.b	$80				; '' + VRAM fill mode

		dc.b	$40				; Port initialization value

		vdpCmd	dc.l,0,VRAM,DMA			; VDP DMA at $0000

		dc.w	$E, $2000-2-1			; Checksum error color, amount of Z80 to clear
		dc.l	Z80_RAM				; Z80 RAM
		dc.l	Z80_BUS_REQ			; Z80 bus request
		dc.l	Z80_RESET			; Z80 reset

		vdpCmd	dc.l,0,CRAM,WRITE		; CRAM WRITE at $0000
		vdpCmd	dc.l,0,VSRAM,WRITE		; VSRAM WRITE at $0000

		dc.b	$9F, $BF, $DF, $FF		; PSG mute values

		dc.b	$F3, $C3			; di and jp instructions for Z80

		dc.l	hInterrupt			; Horizontal interrupt
.VDPDPort:	dc.l	VDP_DATA			; Interrupt level 5
		dc.l	vInterrupt			; Vertical interrupt
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Program initialization
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ICD_BLK		EQU	.PrgInit
.PrgInit:
		intsOff

		; --- CHECK WARM BOOT ---

		tst.w	(sp)				; Has port C been initialized already?
		bne.w	.WarmBoot			; If so, branch

		moveq	#0,d4				; Register that holds 0
		moveq	#0,d6				; Checksum value

		; --- CHECK TMSS ---

		move.b	-$B(sp),d3			; Get hardware version
		asl.b	#4,d3				; ''
		beq.s	.NoTMSS				; If this is a non-TMSS system, branch
		move.l	$100.w,$3FF4(sp)		; Satisfy the TMSS

.NoTMSS:

		; --- SET UP VDP REGISTERS ---

		movea.l	.VDPDPort.w,a5			; VDP data port
		lea	4(a5),a6			; VDP control port

.WaitDMA:
		move.w	(a6),ccr			; Load status
		bvs.s	.WaitDMA			; If there's a DMA, wait

		lea	.InitVals.w,a0			; VDP registers
		movem.w	(a0)+,d1/d2/d5			; Get number of entries, register base, and register increment

.InitVDPRegs:
		move.w	d2,(a6)				; Set register data
		add.w	d5,d2				; Next register
		move.b	(a0)+,d2			; Get register data
		dbf	d1,.InitVDPRegs			; Loop

		; --- CLEAR VRAM ---

		move.l	(a0)+,(a6)			; Set DMA fill destination
		move.w	d4,(a6)				; Set DMA fill value

		; --- CLEAR RAM ---

		movea.l	d4,a2				; End of RAM
		move.w	#(RAM_END-RAM_START)>>2-1,d1	; Longwords to clear

.ClearRAM:
		move.l	d4,-(a2)			; Clear RAM
		dbf	d1,.ClearRAM			; Loop

		; --- SET UP FOR Z80 ---

		movem.l	(a0)+,d0/a1/a3/a4		; Load Z80 addresses and values
		move.w	d5,(a3)				; Request Z80 stop

		; --- CLEAR CRAM AND VSRAM AND INITIALIZE JOYPADS ---

		neg.w	d1				; Run the next bit 2 times

.InitVDPJoypads:
		move.l	(a0)+,(a6)			; Set VDP command
		moveq	#$80>>2-1,d3			; Longwords to clear

.ClearVDPMem:
		move.l	d4,(a5)				; Clear memory
		dbf	d3,.ClearVDPMem			; Loop
		move.w	d2,-(sp)			; Initialize port
		dbf	d1,.InitVDPJoypads		; Loop

		move.w	d5,(a4)				; Cancel Z80 reset

		; --- MUTE PSG ---

		moveq	#4-1,d3				; Number of PSG channels

.MutePSG:
		move.b	(a0)+,$D(a6)			; Mute channel
		dbf	d3,.MutePSG			; Loop

		; --- INITIALIZE Z80 ---

		move.b	(a0)+,(a1)+			; Write di (disable Z80 interrupts)
		move.b	(a0)+,(a1)+			; Write jp (Will end up just looping forever at the beginning)

.ClearZ80:
		move.b	d4,(a1)+			; Clear Z80
		dbf	d0,.ClearZ80			; Loop

		move.w	d4,(a4)				; Reset the Z80

		; --- CHECK THE CHECKSUM ---

		lea	$200.w,a0			; Start reading data at the end of the header
		move.l	$1A4.w,d1			; Get ROM end address

		bra.s	.ChkChecksum			; Continue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Header
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		dc.b	"SEGA"				; Hardware system ID
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Program initialization (part 2)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.ChkChecksum:
		add.w	(a0)+,d6			; Add ROM data to the checksum value
		cmp.l	a0,d1				; Are we at the end of the ROM?
		bcc.s	.ChkChecksum			; If not, keep adding
		cmp.w	$18E.w,d6			; Is the checksum correct?
		beq.s	.ChksumPassed			; If not, branch

.ChksumError:
		vdpCmd	move.l,0,CRAM,WRITE,(a6)	; Set background to red
		move.l	d0,(a5)				; ''
		bra.s	.ChksumError			; Loop here forever

.ChksumPassed:
		move.w	d5,(a4)				; Cancel Z80 reset
		move.w	d4,(a3)				; Start the Z80

		; --- FINISH I/O INITIALIZATION ---

		move.w	d2,4(sp)			; Initialize port C

.WarmBoot:
		lea	stack.w,sp		; Set the stack pointer
		movem.l	(a4),d0-a6			; Clear registers

		jmp	GameInit			; Go to the game initialization
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Header (part 2)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		headStr	"\NOTES", $20			; Notes
		headStr	"\GAME_NAME", $30		; International game name
		dc.b	"GM 00000000-00"		; Version
		dc.w	$BEEF				; Checksum value (replaced by external program)
		headStr	"\IO_SUPPORT", $10		; I/O support
		dc.l	ROM_START, ROM_END-1		; ROM start and end addresses (replaced by external program)
		dc.l	RAM_START, RAM_END-1		; RAM start and end addresses
		dc.l	SRAM_SUPPORT			; SRAM support
		dc.l	SRAM_START, SRAM_END		; SRAM start and end addresses
; =========================================================================================================================================================
