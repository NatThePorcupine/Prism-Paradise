; =========================================================================================================================================================
; VDP functions
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Initialize the VDP
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
InitVDP:
		move.w	#$8134,vdpReg1.w		; Save VDP register 1 in RAM
		move.w	#$8AFF,hIntCntReg.w		; Save H-INT counter register in RAM

		bra.w	InitSpriteTable			; Initialize the sprite table
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Clear the screen and other VDP data (64 tile width)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ClearScreen:
		lea	VDP_CTRL,a6			; VDP control port
		dmaFill	0,$C000,$3000			; Clear planes

		clrRAM	hScrollBuff, vScrollBuff_End	; Clear scroll tables
		
		bra.w	InitSpriteTable			; Initialize the sprite table
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load a plane map
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.l	- VDP command for writing the data to VRAM
;	d1.w	- Width in tiles (minus 1)
;	d2.w	- Height in tiles (minus 1)
;	d3.w	- Base tile properties for each tile
;	d6.l	- Delta value for drawing to the next row (only required for just LoadPlaneMap_Custom)
;	a1.l	- Plane map address
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
LoadPlaneMap:
LoadPlaneMap_H64:
		move.l	#$800000,d6			; For planes with 64 tile width
		bra.s	LoadPlaneMap_Custom		; Load the map

LoadPlaneMap_H32:
		move.l	#$400000,d6			; For planes with 32 tile width
		bra.s	LoadPlaneMap_Custom		; Load the map

LoadPlaneMap_H128:
		move.l	#$1000000,d6			; For planes with 128 tile width

LoadPlaneMap_Custom:
.RowLoop:
		move.l	d0,VDP_CTRL			; Set VDP command
		move.w	d1,d4				; Store width

.TileLoop:
		move.w	(a1)+,d5			; Get tile ID and properties
		add.w	d3,d5				; Add base tile properties
		move.w	d5,VDP_DATA			; Save in VRAM
		dbf	d4,.TileLoop			; Loop until the row has been drawn
		add.l	d6,d0				; Next row
		dbf	d2,.RowLoop			; Loop until the plane has been drawn
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load a plane map into RAM
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d1.w	- Width in tiles (minus 1)
;	d2.w	- Height in tiles (minus 1)
;	d3.w	- Base tile properties for each tile
;	d6.l	- Delta value for drawing to the next row (only required for just LoadPlaneMap_Custom)
;	a0.l	- Buffer to load into
;	a1.l	- Plane map address
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
LoadPlaneMap_RAM:
.RowLoop:
		movea.l	a0,a2				; Copy buffer address
		move.w	d1,d4				; Store width

.TileLoop:
		move.w	(a1)+,d5			; Get tile ID and properties
		add.w	d3,d5				; Add base tile properties
		move.w	d5,(a2)+			; Save in RAM
		dbf	d4,.TileLoop			; Loop until the row has been drawn
		adda.w	#$80,a0				; Next row
		dbf	d2,.RowLoop			; Loop until the plane has been drawn
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Fill the plane map with a value in a specific region
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.l	- VDP command for writing the data to VRAM
;	d1.w	- Width in tiles (minus 1)
;	d2.w	- Height in tiles (minus 1)
;	d3.w	- Value to fill plane map with
;	d6.l	- Delta value for drawing to the next row
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FillPlaneMap:
FillPlaneMap_H64:
		move.l	#$800000,d6			; For planes with 64 tile width
		bra.s	FillPlaneMap_Custom		; Fill the map

FillPlaneMap_H32:
		move.l	#$400000,d6			; For planes with 32 tile width
		bra.s	FillPlaneMap_Custom		; Fill the map

FillPlaneMap_H128:
		move.l	#$1000000,d6			; For planes with 128 tile width

FillPlaneMap_Custom:
.RowLoop:
		move.l	d0,VDP_CTRL			; Set VDP command
		move.w	d1,d4				; Store width

.TileLoop:
		move.w	d3,VDP_DATA			; Save value in VRAM
		dbf	d4,.TileLoop			; Loop until the row has been drawn
		add.l	d6,d0				; Next row
		dbf	d2,.RowLoop			; Loop until the plane has been drawn
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Queue a VDP DMA command to VRAM, to be issued the next time ProcessDMAQueue is called. Can be called a maximum of 18 times before the queue needs
; to be cleared by issuing the commands (this checks for overflow)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
; 	d1.l	- Source address
; 	d2.w	- Destination address
; 	d3.w	- Transfer length
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; This option breaks DMA transfers that crosses a 128kB block into two. It is disabled by default because you can simply align the art in ROM
; and avoid the issue altogether. It is here so that you have a high-performance routine to do the job in situations where you can't align it in ROM.
Use128kbSafeDMA		= 1
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Option to mask interrupts while updating the DMA queue. This fixes many race conditions in the DMA funcion, but it costs 46(6/1) cycles. The
; better way to handle these race conditions would be to make unsafe callers (such as S3&K's KosM decoder) prevent these by masking off interrupts
; before calling and then restore interrupts after.
UseVIntSafeDMA		= 0
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Option to assume that transfer length is always less than $7FFF. Only makes sense if Use128kbSafeDMA is 1. Moreover, setting this to 1 will
; cause trouble on a 64kB DMA, so make sure you never do one if you set it to 1! Enabling this saves 4(1/0) cycles on the case where a DMA is
; broken in two and both transfers are properly queued, and nothing at all otherwise.
AssumeMax7FFFXfer	= 0&Use128kbSafeDMA
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Convenience macros, for increased maintainability of the code.
	if def(DMA)=0
DMA = %100111
	endif
	if def(VRAM)=0
VRAM = %100001
	endif
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
	if def(vdpCommReg_defined)=0
; Like vdpComm, but starting from an address contained in a register
vdpCommReg_defined = 1
vdpCommReg	macro	reg, type, rwd, clr
		local	cd
cd		= \type&\rwd
		lsl.l	#2,\reg				; Move high bits into (word-swapped) position, accidentally moving everything else
		if ((cd)&3)<>0
			addq.w	#((cd)&3),\reg		; Add upper access type bits
		endif
		ror.w	#2,\reg				; Put upper access type bits into place, also moving all other bits into their correct
							; (word-swapped) places
		swap	\reg				; Put all bits in proper places
		if \clr<>0
			andi.w	#3,\reg			; Strip whatever junk was in upper word of reg
		endif
		if ((cd)&$FC)=$20
			tas.b	\reg			; Add in the DMA flag -- tas fails on memory, but works on registers
		elseif ((cd)&$FC)<>0
			ori.w	#(((cd)&$FC)*4),\reg	; Add in missing access type bits
		endif
		endm
	endif
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
QueueDMATransfer:
		if UseVIntSafeDMA=1
			move.w	sr,-(sp)		; Save current interrupt mask
			intsOff				; Mask off interrupts
		endif

		movea.w	dmaSlot.w,a1
		cmpa.w	#dmaSlot,a1
		beq.s	.Done				; Return if there's no more room in the queue

		lsr.l	#1,d1				; Source address is in words for the VDP registers

		if Use128kbSafeDMA=1
			move.w  d3,d0			; d0 = length of transfer in words
			; Compute position of last transferred word. This handles 2 cases:
			; (1) zero length DMAs transfer length actually transfer $10000 words
			; (2) (source+length)&$FFFF = 0
			subq.w  #1,d0
			add.w   d1,d0			; d0 = ((src_address >> 1) & $FFFF) + ((xferlen >> 1) - 1)
			bcs.s   .DoubleTransfer		; Carry set = ($10000 << 1) = $20000, or new 128kB block
		endif

		; Store VDP commands for specifying DMA into the queue
		swap	d1				; Want the high byte first
		move.w	#$977F,d0			; Command to specify source address & $FE0000, plus bitmask for the given byte
		and.b	d1,d0				; Mask in source address & $FE0000, stripping high bit in the process
		move.w	d0,(a1)+			; Store command
		move.w	d3,d1				; Put length together with (source address & $01FFFE) >> 1...
		movep.l	d1,1(a1)			; ... and stuff them all into RAM in their proper places (movep for the win)
		lea	8(a1),a1			; Skip past all of these commands

		vdpCommReg d2,VRAM,DMA,1		; Make DMA destination command
		move.l	d2,(a1)+			; Store command

		clr.w	(a1)				; Put a stop token at the end of the used part of the queue
		move.w	a1,dmaSlot.w			; Set the next free slot address, potentially undoing the above clr (this is intentional!)

.Done:
		if UseVIntSafeDMA=1
			move.w	(sp)+,sr		; Restore interrupts to previous state
		endif
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		if Use128kbSafeDMA=1
.DoubleTransfer:
			; Hand-coded version to break the DMA transfer into two smaller transfers
			; that do not cross a 128kB boundary. This is done much faster (at the cost
			; of space) than by the method of saving arguments and calling the normal
			; DMA function twice, as Sonic3_Complete does.
			; d0 is the number of words-1 that got over the end of the 128kB boundary
			addq.w	#1,d0			; Make d0 the number of words past the 128kB boundary
			sub.w	d0,d3			; First transfer will use only up to the end of the 128kB boundary

			; Store VDP commands for specifying DMA into the queue
			swap	d1			; Want the high byte first

			; Sadly, all registers we can spare are in use right now, so we can't use
			; no-cost RAM source safety.
			andi.w	#$7F,d1			; Strip high bit
			ori.w	#$9700,d1		; Command to specify source address & $FE0000
			move.w	d1,(a1)+		; Store command
			addq.b	#1,d1			; Advance to next 128kB boundary (**)
			move.w	d1,12(a1)		; Store it now (safe to do in all cases, as we will overwrite later if queue got filled) (**)
			move.w	d3,d1			; Put length together with (source address & $01FFFE) >> 1...
			movep.l	d1,1(a1)		; ... and stuff them all into RAM in their proper places (movep for the win)
			lea	8(a1),a1		; Skip past all of these commands

			move.w	d2,d3			; Save for later
			vdpCommReg d2,VRAM,DMA,1	; Make DMA destination command
			move.l	d2,(a1)+		; Store command

			cmpa.w	#dmaSlot,a1		; Did this command fill the queue?
			beq.s	.SkipSecondTransfer	; Branch if so

			; Store VDP commands for specifying DMA into the queue
			; The source address high byte was done above already in the comments marked
			; with (**)
			if AssumeMax7FFFXfer=1
				ext.l	d0		; With maximum $7FFF transfer length, bit 15 of d0 is unset here
				movep.l	d0,3(a1)	; Stuff it all into RAM at the proper places (movep for the win)
			else
				moveq	#0,d2		; Need a zero for a 128kB block start
				move.w	d0,d2		; Copy number of words on this new block...
				movep.l	d2,3(a1)	; ... and stuff it all into RAM at the proper places (movep for the win)
			endif
			lea	10(a1),a1		; Skip past all of these commands

			; d1 contains length up to the end of the 128kB boundary
			add.w	d1,d1			; Convert it into byte length...
			add.w	d3,d1			; ... and offset destination by the correct amount
			vdpCommReg d1,VRAM,DMA,1	; Make DMA destination command
			move.l	d1,(a1)+		; Store command

			clr.w	(a1)			; Put a stop token at the end of the used part of the queue
			move.w	a1,dmaSlot.w		; Set the next free slot address, potentially undoing the above clr (this is intentional!)

			if UseVIntSafeDMA=1
				move.w	(sp)+,sr	; Restore interrupts to previous state
			endif
			rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.SkipSecondTransfer:
			move.w	a1,(a1)			; Set the next free slot address, overwriting what the second (**) instruction did
	
			if UseVIntSafeDMA=1
				move.w	(sp)+,sr	; Restore interrupts to previous state
			endif
			rts
		endif
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Issue all the queued VDP DMA commands from QueueDMATransfer, resets the queue when it's done
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a6.l	- VDP control port
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ProcessDMAQueue:
		lea	dmaQueue.w,a1
		move.w	a1,dmaSlot.w

		rept (dmaSlot-dmaQueue)/(7*2)
			move.w	(a1)+,d0
			beq.w	.Done			; Branch if we reached a stop token
			
			move.w	d0,(a6)			; Issue a set of VDP commands...
			move.l	(a1)+,(a6)
			move.l	(a1)+,(a6)
			move.w	(a1)+,(a6)
			move.w	(a1)+,(a6)
		endr
		moveq	#0,d0

.Done:
		move.w	d0,dmaQueue.w
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Initialize the DMA queue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
InitDMAQueue:
		lea	dmaQueue.w,a1
		move.w	#0,(a1)
		move.w	a1,dmaSlot.w
		move.l	#$96959493,d1
c		= 0
		rept (dmaSlot-dmaQueue)/(7*2)
			movep.l	d1,2+c(a1)
c			= c+14
		endr
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load a palette into the main palette buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.w	- Size of palette (divided by 2 minus 1)
;	a0.l	- Pointer to palette data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
LoadPalette:
		lea	paletteBuff.w,a1			; Main palette buffer
		bra.s	LoadPalToBuf			; Load the palette
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load a palette into the target palette buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.w	- Size of palette (divided by 2 minus 1)
;	a0.l	- Pointer to palette data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
LoadTargetPal:
		lea	palFadeBuff.w,a1			; Target palette buffer
		bra.s	LoadPalToBuf			; Load the palette
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load a palette into the main water palette buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.w	- Size of palette (divided by 2 minus 1)
;	a0.l	- Pointer to palette data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
LoadWaterPal:
		lea	paletteBuffAlt.w,a1		; Main water palette buffer
		bra.s	LoadPalToBuf			; Load the palette
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load a palette into the target water palette buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.w	- Size of palette (divided by 2 minus 1)
;	a0.l	- Pointer to palette data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
LoadTargetWaterPal:
		lea	palFadeBuffAlt.w,a1		; Target water palette buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load a palette into a palette buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.w	- Size of palette (divided by 2 minus 1)
;	a0.l	- Pointer to palette data
;	a1.l	- Pointer to destination buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
LoadPalToBuf:
		move.w	(a0)+,(a1)+			; Copy palette data
		dbf	d0,LoadPalToBuf			; Loop
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Fade the palette to black
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FadeToBlack:
		move.w	#$003F,palFadeVars.w		; Set to fade everything

FadeToBlack_Custom:
		moveq	#7,d4				; Set repeat times
		
.FadeLoop:
		rept	2
			move.b	#vFade,vIntRoutine.w	; Set V-INT routine
			bsr.w	VSync_Routine		; Do V-SYNC
		endr
		bsr.s	FadeToBlack_Once		; Fade the colors once
		dbf	d4,.FadeLoop			; Loop until we are done
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FadeToBlack_Once:
		moveq	#0,d0
		lea	paletteBuff.w,a0			; Palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''
		move.b	palFadeLength.w,d0			; Get fade size

.FadeLoop:
		bsr.s	.FadeColor			; Fade a color			
		dbf	d0,.FadeLoop			; Loop

		moveq	#0,d0
		lea	paletteBuffAlt.w,a0		; Water palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''
		move.b	palFadeLength.w,d0			; Get fade size

.FadeLoopWater:
		bsr.s	.FadeColor			; Fade a color			
		dbf	d0,.FadeLoopWater		; Loop
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.FadeColor:
		move.w	(a0),d5				; Load color
		beq.s	.NoRed				; If the color is already black, branch
		move.w	d5,d1				; Copy color
		move.b	d1,d2				; Load green and red
		move.b	d1,d3				; Load only red

		andi.w	#$E00,d1			; Get only blue
		beq.s	.NoBlue				; If blue is finished, branch
		subi.w	#$200,d5			; Decrease blue

.NoBlue:
		andi.b	#$E0,d2				; Get only green
		beq.s	.NoGreen			; If green is finished, branch
		subi.w	#$20,d5				; Decrease green

.NoGreen:
		andi.b	#$E,d3				; Get only red
		beq.s	.NoRed				; If red is finished, branch
		subq.w	#2,d5				; Decrease red

.NoRed:
		move.w	d5,(a0)+			; Save the color
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Fade the palette from black to the target palette
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FadeFromBlack:
		move.w	#$003F,palFadeVars.w		; Set to fade everything

FadeFromBlack_Custom:
		moveq	#$E,d4				; Maximum color check

.FadeLoop:
		rept	2
			move.b	#vFade,vIntRoutine.w	; Set V-INT routine
			bsr.w	VSync_Routine		; Do V-SYNC
		endr
		bsr.s	FadeFromBlack_Once		; Fade the colors once
		subq.b	#2,d4				; Decrement color check
		bne.s	.FadeLoop			; If we are not done, branch

		move.b	#vFade,vIntRoutine.w		; Set V-INT routine
		bra.w	VSync_Routine			; Do V-SYNC so that the colors transfer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FadeFromBlack_Once:
		moveq	#0,d0
		lea	paletteBuff.w,a0			; Palette buffer
		lea	palFadeBuff.w,a1			; Target palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''
		adda.w	d0,a1				; ''
		move.b	palFadeLength.w,d0			; Get fade size

.FadeLoop:
		bsr.s	.FadeColor			; Fade a color			
		dbf	d0,.FadeLoop			; Loop

		moveq	#0,d0
		lea	paletteBuffAlt.w,a0		; Water palette buffer
		lea	palFadeBuffAlt.w,a1		; Target water palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''
		adda.w	d0,a1				; ''
		move.b	palFadeLength.w,d0			; Get fade size

.FadeLoopWater:
		bsr.s	.FadeColor			; Fade a color			
		dbf	d0,.FadeLoopWater		; Loop
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.FadeColor:
		move.b	(a1),d5				; Load blue
		move.w	(a1)+,d1			; Load green and red
		move.b	d1,d2				; Load red
		lsr.b	#4,d1				; Get only green
		andi.b	#$E,d2				; Get only red

		move.w	(a0),d3				; Load current color
		cmp.b	d5,d4				; Should the blue fade?
		bhi.s	.NoBlue				; If not, branch
		addi.w	#$200,d3			; Increase blue

.NoBlue:
		cmp.b	d1,d4				; Should the green fade?
		bhi.s	.NoGreen			; If not, branch
		addi.w	#$20,d3				; Increase green

.NoGreen:
		cmp.b	d2,d4				; Should the red fade?
		bhi.s	.NoRed				; If not, branch
		addq.w	#2,d3				; Increase red

.NoRed:
		move.w	d3,(a0)+			; Save the color
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Fade the palette to white
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FadeToWhite:
		move.w	#$003F,palFadeVars.w		; Set to fade everything

FadeToWhite_Custom:
		moveq	#7,d4				; Set repeat times

.FadeLoop:
		rept	2
			move.b	#vFade,vIntRoutine.w	; Set V-INT routine
			bsr.w	VSync_Routine		; Do V-SYNC
		endr
		bsr.s	FadeToWhite_Once		; Fade the colors once
		dbf	d4,.FadeLoop			; Loop until we are done
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FadeToWhite_Once:
		moveq	#0,d0
		lea	paletteBuff.w,a0			; Palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''
		move.b	palFadeLength.w,d0			; Get fade size

.FadeLoop:
		bsr.s	.FadeColor			; Fade a color			
		dbf	d0,.FadeLoop			; Loop

		moveq	#0,d0
		lea	paletteBuffAlt.w,a0		; Water palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''
		move.b	palFadeLength.w,d0			; Get fade size

.FadeLoopWater:
		bsr.s	.FadeColor			; Fade a color			
		dbf	d0,.FadeLoopWater		; Loop
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.FadeColor:
		move.w	(a0),d5				; Load color
		cmpi.w	#$EEE,d5			; Is it already white?
		beq.s	.NoRed				; If so, branch
		move.w	d5,d1				; Copy color
		move.b	d1,d2				; Load green and red
		move.b	d1,d3				; Load only red

		andi.w	#$E00,d1			; Get only blue
		cmpi.w	#$E00,d1			; Is blue finished?
		beq.s	.NoBlue				; If do, branch
		addi.w	#$200,d5			; Increase blue

.NoBlue:
		andi.b	#$E0,d2				; Get only green
		cmpi.b	#$E0,d2				; Is green finished?
		beq.s	.NoGreen			; If so, branch
		addi.w	#$20,d5				; Increase green

.NoGreen:
		andi.b	#$E,d3				; Get only red
		cmpi.b	#$E,d3				; Is red finished?
		beq.s	.NoRed				; If so, branch
		addq.w	#2,d5				; Increase red

.NoRed:
		move.w	d5,(a0)+			; Save the color
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Fade the palette from white to the target palette
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FadeFromWhite:
		move.w	#$003F,palFadeVars.w		; Set to fade everything

FadeFromWhite_Custom:
		moveq	#0,d4				; Minimum color check
		
.FadeLoop:
		rept	2
			move.b	#vFade,vIntRoutine.w	; Set V-INT routine
			bsr.w	VSync_Routine		; Do V-SYNC
		endr
		bsr.s	FadeFromWhite_Once		; Fade the colors once
		addq.b	#2,d4				; Decrement color check
		cmpi.b	#$E,d4				; Are we done?
		bne.s	.FadeLoop			; If not, branch

		move.b	#vFade,vIntRoutine.w		; Set V-INT routine
		bra.w	VSync_Routine			; Do V-SYNC so that the colors transfer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FadeFromWhite_Once:
		moveq	#0,d0
		lea	paletteBuff.w,a0			; Palette buffer
		lea	palFadeBuff.w,a1			; Target palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''
		adda.w	d0,a1				; ''
		move.b	palFadeLength.w,d0			; Get fade size

.FadeLoop:
		bsr.s	.FadeColor			; Fade a color			
		dbf	d0,.FadeLoop			; Loop

		moveq	#0,d0
		lea	paletteBuffAlt.w,a0		; Water palette buffer
		lea	palFadeBuffAlt.w,a1		; Target water palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''
		adda.w	d0,a1				; ''
		move.b	palFadeLength.w,d0			; Get fade size

.FadeLoopWater:
		bsr.s	.FadeColor			; Fade a color			
		dbf	d0,.FadeLoopWater		; Loop
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.FadeColor:
		move.b	(a1),d5				; Load blue
		move.w	(a1)+,d1			; Load green and red
		move.b	d1,d2				; Load red
		lsr.b	#4,d1				; Get only green
		andi.b	#$E,d2				; Get only red

		move.w	(a0),d3				; Load current color
		cmp.b	d5,d4				; Should the blue fade?
		bcs.s	.NoBlue				; If not, branch
		subi.w	#$200,d3			; Decrease blue

.NoBlue:
		cmp.b	d1,d4				; Should the green fade?
		bcs.s	.NoGreen			; If not, branch
		subi.w	#$20,d3				; Decrease green

.NoGreen:
		cmp.b	d2,d4				; Should the red fade?
		bcs.s	.NoRed				; If not, branch
		subq.w	#2,d3				; Decrease red

.NoRed:
		move.w	d3,(a0)+			; Save the color
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Fade the palette from the current palette to the target palette
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FadeToPalette:
		move.w	#$003F,palFadeVars.w		; Set to fade everything

FadeToPalette_Custom:
		moveq	#0,d0
		lea	paletteBuff.w,a0			; Palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''

		moveq	#7,d4				; Set repeat times

.FadeLoop:
		rept	2
			move.b	#vFade,vIntRoutine.w	; Set V-INT routine
			bsr.w	VSync_Routine		; Do V-SYNC
		endr
		bsr.s	FadeToPalette_Once		; Fade the colors once
		dbf	d4,.FadeLoop			; Loop until we are done
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FadeToPalette_Once:
		moveq	#0,d0
		lea	paletteBuff.w,a0			; Palette buffer
		lea	palFadeBuff.w,a1			; Target palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''
		adda.w	d0,a1				; ''
		move.b	palFadeLength.w,d0			; Get fade size

.FadeLoop:
		bsr.s	.FadeColor			; Fade a color			
		dbf	d0,.FadeLoop			; Loop

		moveq	#0,d0
		lea	paletteBuffAlt.w,a0		; Water palette buffer
		lea	palFadeBuffAlt.w,a1		; Target water palette buffer
		move.b	palFadeStart.w,d0		; Add starting index offset
		adda.w	d0,a0				; ''
		adda.w	d0,a1				; ''
		move.b	palFadeLength.w,d0			; Get fade size

.FadeLoopWater:
		bsr.s	.FadeColor			; Fade a color			
		dbf	d0,.FadeLoopWater		; Loop
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.FadeColor:
		move.w	(a0),d3				; Get color
		cmp.w	(a1)+,d3			; Has the color already reached the target color?
		beq.s	.NoRed				; If so, branch
		
		move.w	-2(a1),d1			; Get green and red
		move.b	d1,d2				; Get red only
		andi.b	#$E,d2				; ''
		lsr.b	#4,d1				; Get green only

		move.b	-2(a1),d5			; Get blue
		cmp.b	(a0),d5				; Does blue need to fade?
		beq.s	.NoBlue				; If not, branch
		bcs.s	.DecBlue			; If it needs to be decreased, branch
		addi.w	#$200,d3			; Increase blue
		bra.s	.NoBlue				; Continue

.DecBlue:
		subi.w	#$200,d3			; Decrease blue

.NoBlue:
		move.w	(a0),d5				; Get green
		lsr.b	#4,d5				; ''
		cmp.b	d5,d1				; Does green need to fade?
		beq.s	.NoGreen			; If not, branch
		bcs.s	.DecGreen			; If it needs to be decreased, branch
		addi.b	#$20,d3				; Increase green
		bra.s	.NoGreen			; Continue

.DecGreen:
		subi.b	#$20,d3				; Decrease green

.NoGreen:
		move.w	(a0),d5				; Get red
		andi.b	#$E,d5				; ''
		cmp.b	d5,d2				; Does red need to fade?
		beq.s	.NoRed				; If not, branch
		bcs.s	.DecRed				; If it needs to be decreased, branch
		addq.b	#2,d3				; Increase red
		bra.s	.NoRed				; Continue

.DecRed:
		subq.b	#2,d3				; Decrease red

.NoRed:
		move.w	d3,(a0)+			; Save new color
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Initialize the sprite table
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
InitSpriteTable:
		moveq	#0,d0
		lea	spriteBuff.w,a0			; Sprite table buffer
		moveq	#1,d1				; Link value
		moveq	#($280/8)-1,d7			; Number of sprites

.Loop:
		move.w	d0,(a0)				; Move off screen
		move.b	d1,3(a0)			; Set link value
		addq.w	#1,d1				; Increment link value
		addq.w	#8,a0				; Next sprite
		dbf	d7,.Loop			; Loop
		move.b	d0,-5(a0)			; Set final link value to 0
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw the sprites from mappings
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.w	- X position
;	d1.w	- Y position
;	d4.w	- Number of sprites to draw
;	d5.w	- Sprite tile properties
;	d6.b	- Render flags
;	d7.w	- Max number of sprites left to draw
;	a1.l	- Mappings frame data
;	a6.l	- Sprite table buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite:
		lsr.b	#1,d6				; Is this sprite flipped horizontally?
		bcs.s	DrawSprite_FlipX		; If so, branch
		lsr.b	#1,d6				; Is this sprite flipped vertically?
		bcs.w	DrawSprite_FlipY		; If so, branch
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw the sprites from mappings with no flip checks
; (arguments inherited from DrawSprite, minus d6, a.k.a. render flags)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite_Loop:
		move.b	(a1)+,d2			; Get Y offset
		ext.w	d2				; ''
		add.w	d1,d2				; Add onto Y position
		move.w	d2,(a6)+			; Store in sprite table
		move.b	(a1)+,(a6)+			; Store sprite size
		addq.w	#1,a6				; Skip link data
		move.w	(a1)+,d2			; Get tile properties
		add.w	d5,d2				; Add base tile properties
		move.w	d2,(a6)+			; Store in sprite table
		move.w	(a1)+,d2			; Get X offset
		add.w	d0,d2				; Add onto X position
		move.w	d2,(a6)+			; Store in sprite table
		subq.w	#1,d7				; Decrement sprite count
		dbmi	d4,DrawSprite_Loop		; Loop if there are still enough sprites left
		
DrawSprite_End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw the sprites from mappings, horizontally flipped
; (arguments inherited from DrawSprite)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite_FlipX:
		lsr.b	#1,d6				; Is this sprite flipped vertically?
		bcs.s	DrawSprite_FlipXY		; If so, branch

.Loop:
		move.b	(a1)+,d2			; Get Y offset
		ext.w	d2				; ''
		add.w	d1,d2				; Add onto Y position
		move.w	d2,(a6)+			; Store in sprite table
		move.b	(a1)+,d6			; Get sprite size
		move.b	d6,(a6)+			; Store in sprite table
		addq.w	#1,a6				; Skip link data
		move.w	(a1)+,d2			; Get tile properties
		add.w	d5,d2				; Add base tile properties
		eori.w	#$800,d2			; Flip horizontally
		move.w	d2,(a6)+			; Store in sprite table
		move.w	(a1)+,d2			; Get X offset
		neg.w	d2				; Negate it
		move.b	DrawSprite_XFlipOff(pc,d6.w),d6	; Get the X offset to apply
		sub.w	d6,d2				; Subtract the new X offset
		add.w	d0,d2				; Add onto X position
		move.w	d2,(a6)+			; Store in sprite table
		subq.w	#1,d7				; Decrement sprite count
		dbmi	d4,.Loop			; Loop if there are still enough sprites left
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite_XFlipOff:
		dc.b	8, 8, 8, 8
		dc.b	$10, $10, $10, $10
		dc.b	$18, $18, $18, $18
		dc.b	$20, $20, $20, $20
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw the sprites from mappings, horizontally and vertically flipped
; (arguments inherited from DrawSprite, minus d6, a.k.a. render flags)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite_FlipXY:
		move.b	(a1)+,d2			; Get Y offset
		ext.w	d2				; ''
		neg.w	d2				; Negate it
		move.b	(a1),d6				; Get sprite sizes
		move.b	DrawSprite_YFlipOff(pc,d6.w),d6	; Get the Y offset to apply
		sub.w	d6,d2				; Subtract from the Y offset
		add.w	d1,d2				; Add onto Y position
		move.w	d2,(a6)+			; Store in sprite table
		move.b	(a1)+,d6			; Get sprite size
		move.b	d6,(a6)+			; Store in sprite table
		addq.w	#1,a6				; Skip link data
		move.w	(a1)+,d2			; Get tile properties
		add.w	d5,d2				; Add base tile properties
		eori.w	#$1800,d2			; Flip horizontally and vertically
		move.w	d2,(a6)+			; Store in sprite table
		move.w	(a1)+,d2			; Get X offset
		neg.w	d2				; Negate it
		move.b	DrawSprite_XFlipOff(pc,d6.w),d6	; Get the X offset to apply
		sub.w	d6,d2				; Subtract the new X offset
		add.w	d0,d2				; Add onto X position
		move.w	d2,(a6)+			; Store in sprite table
		subq.w	#1,d7				; Decrement sprite count
		dbmi	d4,DrawSprite_FlipXY		; Loop if there are still enough sprites left
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite_YFlipOff:
		dc.b	8, $10, $18, $20
		dc.b	8, $10, $18, $20
		dc.b	8, $10, $18, $20
		dc.b	8, $10, $18, $20
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw the sprites from mappings, vertically flipped
; (arguments inherited from DrawSprite)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite_FlipY:
		move.b	(a1)+,d2			; Get Y offset
		ext.w	d2				; ''
		neg.w	d2				; Negate it
		move.b	(a1)+,d6			; Get sprite sizes
		move.b	d6,2(a6)			; Store in sprite table
		move.b	DrawSprite_YFlipOff(pc,d6.w),d6	; Get the Y offset to apply
		sub.w	d6,d2				; Subtract from the Y offset
		add.w	d1,d2				; Add onto Y position
		move.w	d2,(a6)+			; Store in sprite table
		addq.w	#2,a6				; Skip link data
		move.w	(a1)+,d2			; Get tile properties
		add.w	d5,d2				; Add base tile properties
		eori.w	#$1000,d2			; Flip vertically
		move.w	d2,(a6)+			; Store in sprite table
		move.w	(a1)+,d2			; Get X offset
		add.w	d0,d2				; Add onto X position
		move.w	d2,(a6)+			; Store in sprite table
		subq.w	#1,d7				; Decrement sprite count
		dbmi	d4,DrawSprite_FlipY		; Loop if there are still enough sprites left
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw the sprites from mappings (with boundary checks)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.w	- X position
;	d1.w	- Y position
;	d4.w	- Number of sprites to draw
;	d5.w	- Sprite tile properties
;	d6.b	- Render flags
;	d7.w	- Max number of sprites left to draw
;	a1.l	- Mappings frame data
;	a6.l	- Sprite table buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite_BoundChk:
		lsr.b	#1,d6				; Is this sprite flipped horizontally?
		bcs.s	DrawSprite_BndChk_FlipX		; If so, branch
		lsr.b	#1,d6				; Is this sprite flipped vertically?
		bcs.w	DrawSprite_BndChk_FlipY		; If so, branch
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw the sprites from mappings (with boundary checks) with no flip checks
; (arguments inherited from DrawSprite_BoundChk, minus d6, a.k.a. render flags)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprBndChk_Loop:
		move.b	(a1)+,d2			; Get Y offset
		ext.w	d2				; ''
		add.w	d1,d2				; Add onto Y position
		cmpi.w	#-32+128,d2			; Is it above the screen?
		bls.s	.Next_YOffScr			; If so, branch
		cmpi.w	#224+128,d2			; Is it below the screen?
		bhs.s	.Next_YOffScr			; If so, branch
		move.w	d2,(a6)+			; Store in sprite table
		move.b	(a1)+,(a6)+			; Store sprite size
		addq.w	#1,a6				; Skip link data
		move.w	(a1)+,d2			; Get tile properties
		add.w	d5,d2				; Add base tile properties
		move.w	d2,(a6)+			; Store in sprite table
		move.w	(a1)+,d2			; Get X offset
		add.w	d0,d2				; Add onto X position
		cmpi.w	#-32+128,d2			; Is it left of the screen?
		bls.s	.Next_XOffScr			; If so, branch
		cmpi.w	#320+128,d2			; Is it right of the screen?
		bhs.s	.Next_XOffScr			; If so, branch
		move.w	d2,(a6)+			; Store in sprite table
		subq.w	#1,d7				; Decrement sprite count
		dbmi	d4,DrawSprBndChk_Loop		; Loop if there are still enough sprites left
		rts

.Next_XOffScr:
		subq.w	#6,a6				; Go back to the start of the current sprite entry
		dbf	d4,DrawSprBndChk_Loop		; Loop if there are still enough sprites left
		rts

.Next_YOffScr:
		addq.w	#5,a1				; Go to the next sprite in the mappings in the mappings
		dbf	d4,DrawSprBndChk_Loop		; Loop if there are still enough sprites left
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw the sprites from mappings (with boundary checks), horizontally flipped
; (arguments inherited from DrawSprite_BoundChk)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite_BndChk_FlipX:
		lsr.b	#1,d6				; Is this sprite flipped vertically?
		bcs.s	DrawSprite_BndChk_FlipXY	; If so, branch

.Loop:
		move.b	(a1)+,d2			; Get Y offset
		ext.w	d2				; ''
		add.w	d1,d2				; Add onto Y position
		cmpi.w	#-32+128,d2			; Is it above the screen?
		bls.s	.Next_YOffScr			; If so, branch
		cmpi.w	#224+128,d2			; Is it below the screen?
		bhs.s	.Next_YOffScr			; If so, branch
		move.w	d2,(a6)+			; Store in sprite table
		move.b	(a1)+,d6			; Get sprite size
		move.b	d6,(a6)+			; Store in sprite table
		addq.w	#1,a6				; Skip link data
		move.w	(a1)+,d2			; Get tile properties
		add.w	d5,d2				; Add base tile properties
		eori.w	#$800,d2			; Flip horizontally
		move.w	d2,(a6)+			; Store in sprite table
		move.w	(a1)+,d2			; Get X offset
		neg.w	d2				; Negate it
		move.b	DrwSprBndChk_XFlips(pc,d6.w),d6; Get the X offset to apply
		sub.w	d6,d2				; Subtract the new X offset
		add.w	d0,d2				; Add onto X position
		cmpi.w	#-32+128,d2			; Is it left of the screen?
		bls.s	.Next_XOffScr			; If so, branch
		cmpi.w	#320+128,d2			; Is it right of the screen?
		bhs.s	.Next_XOffScr			; If so, branch
		move.w	d2,(a6)+			; Store in sprite table
		subq.w	#1,d7				; Decrement sprite count
		dbmi	d4,.Loop			; Loop if there are still enough sprites left
		rts

.Next_XOffScr:
		subq.w	#6,a6				; Go back to the start of the current sprite entry
		dbf	d4,.Loop			; Loop if there are still enough sprites left
		rts

.Next_YOffScr:
		addq.w	#5,a1				; Go to the next sprite in the mappings
		dbf	d4,.Loop			; Loop if there are still enough sprites left
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrwSprBndChk_XFlips:
		dc.b	8, 8, 8, 8
		dc.b	$10, $10, $10, $10
		dc.b	$18, $18, $18, $18
		dc.b	$20, $20, $20, $20
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw the sprites from mappings (with boundary checks), horizontally and vertically flipped
; (arguments inherited from DrawSprite, minus d6, a.k.a. render flags)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite_BndChk_FlipXY:
		move.b	(a1)+,d2			; Get Y offset
		ext.w	d2				; ''
		neg.w	d2				; Negate it
		move.b	(a1),d6				; Get sprite sizes
		move.b	DrwSprBndChk_YFlips(pc,d6.w),d6; Get the Y offset to apply
		sub.w	d6,d2				; Subtract from the Y offset
		add.w	d1,d2				; Add onto Y position
		cmpi.w	#-32+128,d2			; Is it above the screen?
		bls.s	.Next_YOffScr			; If so, branch
		cmpi.w	#224+128,d2			; Is it below the screen?
		bhs.s	.Next_YOffScr			; If so, branch
		move.w	d2,(a6)+			; Store in sprite table
		move.b	(a1)+,d6			; Get sprite size
		move.b	d6,(a6)+			; Store in sprite table
		addq.w	#1,a6				; Skip link data
		move.w	(a1)+,d2			; Get tile properties
		add.w	d5,d2				; Add base tile properties
		eori.w	#$1800,d2			; Flip horizontally and vertically
		move.w	d2,(a6)+			; Store in sprite table
		move.w	(a1)+,d2			; Get X offset
		neg.w	d2				; Negate it
		move.b	DrwSprBndChk_XFlips(pc,d6.w),d6; Get the X offset to apply
		sub.w	d6,d2				; Subtract the new X offset
		add.w	d0,d2				; Add onto X position
		cmpi.w	#-32+128,d2			; Is it left of the screen?
		bls.s	.Next_XOffScr			; If so, branch
		cmpi.w	#320+128,d2			; Is it right of the screen?
		bhs.s	.Next_XOffScr			; If so, branch
		move.w	d2,(a6)+			; Store in sprite table
		subq.w	#1,d7				; Decrement sprite count
		dbmi	d4,DrawSprite_BndChk_FlipXY	; Loop if there are still enough sprites left
		rts

.Next_XOffScr:
		subq.w	#6,a6				; Go back to the start of the current sprite entry
		dbf	d4,DrawSprite_BndChk_FlipXY	; Loop if there are still enough sprites left
		rts

.Next_YOffScr:
		addq.w	#5,a1				; Go to the next sprite in the mappings
		dbf	d4,DrawSprite_BndChk_FlipXY	; Loop if there are still enough sprites left
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrwSprBndChk_YFlips:
		dc.b	8, $10, $18, $20
		dc.b	8, $10, $18, $20
		dc.b	8, $10, $18, $20
		dc.b	8, $10, $18, $20
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw the sprites from mappings (with boundary checks), vertically flipped
; (arguments inherited from DrawSprite_BoundChk)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DrawSprite_BndChk_FlipY:
		move.b	(a1)+,d2			; Get Y offset
		ext.w	d2				; ''
		neg.w	d2				; Negate it
		move.b	(a1)+,d6			; Get sprite sizes
		move.b	d6,2(a6)			; Store in sprite table
		move.b	DrwSprBndChk_YFlips(pc,d6.w),d6; Get the Y offset to apply
		sub.w	d6,d2				; Subtract from the Y offset
		add.w	d1,d2				; Add onto Y position
		cmpi.w	#-32+128,d2			; Is it above the screen?
		bls.s	.Next_YOffScr			; If so, branch
		cmpi.w	#224+128,d2			; Is it below the screen?
		bhs.s	.Next_YOffScr			; If so, branch
		move.w	d2,(a6)+			; Store in sprite table
		addq.w	#2,a6				; Skip link data
		move.w	(a1)+,d2			; Get tile properties
		add.w	d5,d2				; Add base tile properties
		eori.w	#$1000,d2			; Flip vertically
		move.w	d2,(a6)+			; Store in sprite table
		move.w	(a1)+,d2			; Get X offset
		add.w	d0,d2				; Add onto X position
		cmpi.w	#-32+128,d2			; Is it left of the screen?
		bls.s	.Next_XOffScr			; If so, branch
		cmpi.w	#320+128,d2			; Is it right of the screen?
		bhs.s	.Next_XOffScr			; If so, branch
		move.w	d2,(a6)+			; Store in sprite table
		subq.w	#1,d7				; Decrement sprite count
		dbmi	d4,DrawSprite_BndChk_FlipY	; Loop if there are still enough sprites left
		rts

.Next_XOffScr:
		subq.w	#6,a6				; Go back to the start of the current sprite entry
		dbf	d4,DrawSprite_BndChk_FlipY	; Loop if there are still enough sprites left
		rts

.Next_YOffScr:
		addq.w	#5,a1				; Go to the next sprite in the mappings
		dbf	d4,DrawSprite_BndChk_FlipY	; Loop if there are still enough sprites left
		rts
; =========================================================================================================================================================