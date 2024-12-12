; =========================================================================================================================================================
; Interrupt functions
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Vertical Interrupts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_Standard:
		intsOff					; Turn interrupts off
		push.l	d0-a6				; Save registers
		
		lea	VDP_CTRL,a6			; VDP control port
		lea	-4(a6),a5			; VDP data port

.WaitForVBLANK:
		move.w	(a6),d0				; Get VDP status
		andi.w	#8,d0				; Are we in a VBLANK period?
		beq.s	.WaitForVBLANK			; If not, wait

		btst	#6,hwVersion.w		; Is this a PAL system?
		beq.s	.SetVScroll			; If not, branch
		move.w	#$700,d0			; Do a delay
		dbf	d0,*				; ''

.SetVScroll:
		dma68k	vScrollBuff,0,$50,VSRAM		; Load VScroll buffer into VSRAM

		tst.b	vIntRoutine.w			; Is the game lagging?
		beq.w	VInt_Lag_Main			; If so, branch
		clr.b	lagCounter.w			; Clear lag frame counter

		moveq	#0,d0
		move.b	vIntRoutine.w,d0		; Get V-INT routine ID
		clr.b	vIntRoutine.w			; Clear V-INT routine ID
		st	hIntFlag.w			; Allow the H-INT to run
		move.w	VInt_Routines(pc,d0.w),d0	; Get V-INT routine offset
		jsr	VInt_Routines(pc,d0.w)		; Jump to the routine

VInt_FinishUpdates:
	;	jsr	UpdateAMPS			; Run the AMPS driver

VInt_End:
		addq.l	#1,frameCounter.w		; Increment frame count
		bsr.w	MATH_GetRandom			; Generate a random number
		
		pop.l	d0-a6				; Restore registers
		intsOn					; Turn interrupts on
		lagOn					; Turn on the lag-o-meter
		rte
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; V-INT routines
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_Routines:
		dc.w	VInt_Lag-VInt_Routines		; Lag routine
		dc.w	VInt_General-VInt_Routines	; General routine
		dc.w	VInt_Level-VInt_Routines	; Level routine
		dc.w	VInt_LevelLoad-VInt_Routines	; Level load routine
		dc.w	VInt_Title-VInt_Routines	; Title screen routine
		dc.w	VInt_Fade-VInt_Routines		; Fade routine
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; V-INT lag routine
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_Lag:
		addq.w	#4,sp				; Don't return to caller

VInt_Lag_Main:
		tst.b	waterFullscr.w		; Is water fullscreen?
		bne.s	.WaterPal			; If so, branch
		dma68k	paletteBuff,0,$80,CRAM		; Load palette into CRAM
		bra.s	.Cont				; Continue

.WaterPal:
		dma68k	paletteBuffAlt,0,$80,CRAM		; Load water palette into CRAM

.Cont:	
		move.w	hIntCntReg.w,(a6)		; Set H-INT counter

		addq.b	#1,lagCounter.w		; Increment lag counter
		bra.w	VInt_FinishUpdates		; Go update SMPS
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; V-INT general routine
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_General:
		bsr.w	VInt_Update			; Do updates
		bra.w	SetKosBookmark			; Set Kosinski decompression bookmark
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; V-INT level load routine
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_LevelLoad:
		bsr.w	ReadJoypads			; Read joypads

		tst.b	waterFullscr.w		; Is water fullscreen?
		bne.s	.WaterPal			; If so, branch
		dma68k	paletteBuff,0,$80,CRAM		; Load palette into CRAM
		bra.s	.Cont				; Continue

.WaterPal:
		dma68k	paletteBuffAlt,0,$80,CRAM		; Load water palette into CRAM

.Cont:
		move.w	hIntCntReg.w,(a6)		; Set H-INT counter
		
		dma68k	spriteBuff,$F800,$280,VRAM	; Load sprite table into VRAM
		dma68k	hScrollBuff,$FC00,$380,VRAM	; Load H-Scroll table into VRAM
		bsr.w	ProcessDMAQueue			; Process DMA queue
		
		bra.w	SetKosBookmark			; Set Kosinski decompression bookmark
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; V-INT level routine
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_Level:
		lea	fgCamVars.w,a1			; Foreground level drawing variables
		lea	fgColBuff.w,a3		; Foreground column plane buffer
		lea	fgRowBuff.w,a4		; Foreground row plane buffer
		jsr	VInt_DrawLevel			; Update the foreground plane
		lea	bgCamVars.w,a1			; Background level drawing variables
		lea	bgColBuff.w,a3		; Background column plane buffer
		lea	bgRowBuff.w,a4		; Background row plane buffer
		jsr	VInt_DrawLevel			; Update the background plane

		bsr.w	ReadJoypads			; Read joypads

		tst.b	waterFullscr.w		; Is water fullscreen?
		bne.s	.WaterPal			; If so, branch
		dma68k	paletteBuff,0,$80,CRAM		; Load palette into CRAM
		bra.s	.Cont				; Continue

.WaterPal:
		dma68k	paletteBuffAlt,0,$80,CRAM		; Load water palette into CRAM

.Cont:
		move.w	hIntCntReg.w,(a6)		; Set H-INT counter

		dma68k	spriteBuff,$F800,$280,VRAM	; Load sprite table into VRAM
		dma68k	hScrollBuff,$FC00,$380,VRAM	; Load H-Scroll table into VRAM
		bsr.w	ProcessDMAQueue			; Process DMA queue
		
		cmpi.b	#92,hIntCntValue.w		; Would V-INT be unable to do updates in the next frame?
		bhs.s	.DoUpdates			; If not, branch
		st	hIntUpdates.W		; Set updates in H-INT flag
		addq.w	#4,sp				; Skip SMPS update routine afterwards
		bsr.w	SetKosBookmark			; Set Kosinski decompression bookmark
		bra.w	VInt_End			; Continue

.DoUpdates:
		jsr	Level_UpdateHUD			; Update the HUD
		bra.w	SetKosBookmark			; Set Kosinski decompression bookmark
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; V-INT title screen update routine
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_Title:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
;		bsr.w	ReadJoypads			; Read joypads
;
;		move.l	#$C0000000,VDP_CTRL		; Write palette to CRAM
;		lea	paletteBuff.w,a0			; ''
;		moveq	#$80>>2-1,d0			; ''
;
;.WritePal:
;		move.l	(a0)+,VDP_DATA			; ''
;		dbf	d0,.WritePal			; ''
;
;		move.l	#$78000003,VDP_CTRL		; Write sprite data to VRAM
;		lea	spriteBuff.w,a0			; ''
;		move.w	#$280>>2-1,d0			; ''
;
;.WriteSprs:
;		move.l	(a0)+,VDP_DATA			; ''
;		dbf	d0,.WriteSprs			; ''
;
;		move.l	#$7C000003,VDP_CTRL		; Write HScroll table to VRAM
;		lea	hScrollBuff.w,a0			; ''
;		move.w	#$380>>2-1,d0			; ''
;
;.WriteHScrl:
;		move.l	(a0)+,VDP_DATA			; ''
;		dbf	d0,.WriteHScrl			; ''
;		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Do standard updates in V-INT
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_Update:
	; NTP: We don't want to update sprites during a fade, thus it's not shared with the below interrupt routine
		dma68k	spriteBuff,$F800,$280,VRAM	; Load sprite table into VRAM
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; V-INT fade routine
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_Fade:
		bsr.w	ReadJoypads			; Read joypads

		tst.b	waterFullscr.w		; Is water fullscreen?
		bne.s	.WaterPal			; If so, branch
		dma68k	paletteBuff,0,$80,CRAM		; Load palette into CRAM
		bra.s	.Cont				; Continue

.WaterPal:
		dma68k	paletteBuffAlt,0,$80,CRAM		; Load water palette into CRAM

.Cont:
		move.w	hIntCntReg.w,(a6)		; Set H-INT counter

		dma68k	hScrollBuff,$FC00,$380,VRAM	; Load H-Scroll table into VRAM
		bra.w	ProcessDMAQueue			; Process DMA queue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; V-INT routine that only runs the SMPS driver
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_RunSMPS:
		push.l	d0-a6				; Save registers
		
.WaitForVBLANK:
		move.w	VDP_CTRL,d0			; Get VDP status
		andi.w	#8,d0				; Are we in a VBLANK period?
		beq.s	.WaitForVBLANK			; If not, wait

		btst	#6,hwVersion.w		; Is this a PAL system?
		beq.s	.UpdateSMPS			; If not, branch
		move.w	#$700,d0			; Do a delay
		dbf	d0,*				; ''

.UpdateSMPS:
	;	jsr	UpdateAMPS			; Run the AMPS driver

		addq.l	#1,frameCounter.w		; Increment frame count
		bsr.w	MATH_GetRandom			; Generate a random number
		
		pop.l	d0-a6				; Restore registers
		rte

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Wait for the vertical interrupt to run and finish
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VSync:
		st	vIntFlag.w			; Set V-INT flag

VSync_Routine:
		intsOn					; Enable interrupts
		lagOff					; Turn off the lag-o-meter

.Wait:
		tst.b	vIntFlag.w			; Has the V-INT run yet?
		bne.s	.Wait				; If not, wait some more
		rts

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Horizontal interrupt for palette swapping (for water)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
HInt_Water:
		intsOff					; Disable interrupts

		tst.b	hIntFlag.w			; Is the H-INT allowed to run?
		beq.s	.End				; If not, branch
		clr.b	hIntFlag.w			; Clear the H-INT flag

		push.l	a0-a1				; Save registers

		lea	VDP_DATA,a1			; VDP data port
		move.w	#$8AFF,4(a1)			; Don't do any more H-INT calls for the rest of the frame
		lea	paletteBuffAlt.w,a0		; Water palette
		vdpCmd	move.l, 0, CRAM, WRITE, 4(a1)	; Set VDP command
		rept	32
			move.l	(a0)+,(a1)		; Tranfer palette
		endr
		pop.l	a0-a1				; Restore registers
		
		tst.b	hIntUpdates.w		; Do we need to do level updates in here?
		bne.s	.DoUpdates			; If so, branch

.End:
		rte

.DoUpdates:
		clr.b	hIntUpdates.w		; Clear the update flag
		push.l	d0-a6				; Save registers
		lea	VDP_CTRL,a6			; VDP control port
		lea	-4(a6),a5			; VDP data port
		jsr	Level_UpdateHUD			; Update the HUD
	;	jsr	UpdateAMPS			; Run the AMPS driver
		pop.l	d0-a6				; Restore registers
		rte
; =========================================================================================================================================================