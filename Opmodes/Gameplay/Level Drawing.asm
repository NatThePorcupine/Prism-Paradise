; =========================================================================================================================================================
; Level drawing functions (Based on Sonic Crackers' and S3K's level drawing engine)
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Initialize the planes
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_InitPlanes:
		lea	fgCamVars.w,a1			; Get foreground level drawing RAM
		lea	fgColBuff.w,a3			; Get foreground column plane buffer
		lea	fgRowBuff.w,a4			; Get foreground row plane buffer

		move.l	#$40000003,cVDP(a1)		; Set the base VDP command for drawing tiles
		clr.w	cLayout(a1)			; Set the offset for the level layout (foreground)
		
		move.w	levelID.w,d0			; Get level ID
		ror.b	#1,d0				; Turn into offset
		lsr.w	#3,d0				; ''
		lea	Level_RenderRouts,a0		; Get initialization routine list
		move.l	8(a0,d0.w),cUpdate(a1)		; Set the update routine pointer
		movea.l	(a0,d0.w),a0			; Get initialization pointer
		jsr	(a0)				; Jump to it

		move.w	cYPos(a1),vScrollBuffFG.w		; Set the V-Scroll value for the foreground

		lea	bgCamVars.w,a1			; Get background level drawing RAM
		lea	bgColBuff.w,a3			; Get background column plane buffer
		lea	bgRowBuff.w,a4			; Get background row plane buffer
		
		move.l	#$60000003,cVDP(a1)		; Set the base VDP command for drawing tils
		move.w	#4,cLayout(a1)			; Set the offset for the level layout (background)
		
		move.w	levelID.w,d0			; Get level ID
		ror.b	#1,d0				; Turn into offset
		lsr.w	#3,d0				; ''
		lea	Level_RenderRouts+4,a0		; Get initialization routine list
		move.l	8(a0,d0.w),cUpdate(a1)		; Set the update routine pointer
		movea.l	(a0,d0.w),a0			; Get initialization pointer
		jsr	(a0)				; Jump to it

		move.w	cYPos(a1),vScrollBuffBG.w		; Set the V-Scroll value for the background
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Update the planes
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_UpdatePlanes:
		lea	fgCamVars.w,a1			; Get foreground level drawing RAM
		lea	fgColBuff.w,a3		; Get foreground column plane buffer
		lea	fgRowBuff.w,a4		; Get foreground row plane buffer
		
		movea.l	cUpdate(a1),a0			; Get the update routine pointer
		jsr	(a0)				; Jump to it
		
		lea	bgCamVars.w,a1			; Get background level drawing RAM
		lea	bgColBuff.w,a3		; Get background column plane buffer
		lea	bgRowBuff.w,a4		; Get background row plane buffer

		movea.l	cUpdate(a1),a0			; Get the update routine pointer
		jsr	(a0)				; Jump to it

		lea	fgCamVars.w,a2			; Get foreground level drawing RAM
		move.w	cXPos(a2),cXPrev(a2)		; Update the previous X position for the foreground
		move.w	cYPos(a2),cYPrev(a2)		; Update the previous Y position for the foreground
		move.w	cYPos(a2),vScrollBuffFG.w		; Set the V-Scroll value for the foreground
		move.w	cXPos(a1),cXPrev(a1)		; Update the previous X position for the background
		move.w	cYPos(a1),cYPrev(a1)		; Update the previous Y position for the background
		move.w	cYPos(a1),vScrollBuffBG.w		; Set the V-Scroll value for the background

		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; General foreground initialization
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
General_InitFG:
		bra.w	Level_RefreshPlane		; Refresh the plane
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; General background initialization
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
General_InitBG:
		lea	fgCamVars.w,a2			; Get foreground level drawing RAM
		move.w	cXPos(a2),d0			; Get foreground X position
		asr.w	#1,d0				; Divide by 2
		move.w	d0,cXPos(a1)			; Set as background X position
		move.w	cYPos(a2),d0			; Get foreground Y position
		asr.w	#1,d0				; Divide by 2
		move.w	d0,cYPos(a1)			; Set as background Y position

		bsr.w	Level_RefreshPlane		; Refresh the plane
		
		bra.w	ScrollStaticBG			; Set up the scroll offsets
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; General foreground update
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
General_UpdateFG:
		bsr.w	Level_ChkRedrawPlane		; Check if the plane needs to be redrawn
		
		moveq	#(240/16)-1,d4			; Number of blocks per column
		moveq	#(336/16)-1,d5			; Number of blocks per row
		bra.w	Level_UpdatePlane		; Update the plane
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; General background update
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
General_UpdateBG:
		lea	fgCamVars.w,a2			; Get foreground level drawing RAM
		move.w	cXPos(a2),d0			; Get foreground X position
		asr.w	#1,d0				; Divide by 2
		move.w	d0,cXPos(a1)			; Set as background X position
		move.w	cYPos(a2),d0			; Get foreground Y position
		asr.w	#1,d0				; Divide by 2
		move.w	d0,cYPos(a1)			; Set as background Y position

		bsr.w	Level_ChkRedrawPlane		; Check if the plane needs to be redrawn
		moveq	#(240/16)-1,d4			; Number of blocks per column
		moveq	#(336/16)-1,d5			; Number of blocks per row
		bsr.w	Level_UpdatePlane		; Update the plane
		
		bra.w	ScrollStaticBG			; Scroll the planes
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Draw new tiles in the level
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a1.l	- Camera RAM
;	a2.l	- Plane buffer for columns
;	a3.l	- Plane buffer for rows
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
VInt_DrawLevel:
		move.w	cVDP(a1),d3			; High word of VDP command
		move.w	cVDP+2(a1),d4			; Low word of VDP command

		move.w	(a3),d0				; Get high VDP command word
		beq.w	VInt_DrawLvlRows2		; If it's 0, branch
		clr.w	(a3)+				; Reset high VDP command word in buffer
		move.w	#$8F80,(a6)			; Set auto-increment to $80

		; --- DRAW THE FIRST HALF OF THE COLUMN ---

		move.w	d0,d1				; Save high VDP command
		moveq	#(256/16)-1,d7			; Max number of blocks
		moveq	#0,d6
		move.b	cCBlks(a1),d6			; Get number of blocks in the first set
		sub.w	d6,d7				; Get number of blocks in the second set

		move.w	d0,(a6)				; Set VDP command
		move.w	d4,(a6)				; ''
		bra.s	.DrawCol1_1_Start		; Start

.DrawCol1_1_Loop:
		move.l	(a3)+,(a5)			; Draw blocks

.DrawCol1_1_Start:
		dbf	d6,.DrawCol1_1_Loop		; Loop

		move.w	d3,d2				; Wrap to the top of the plane
		addi.w	#$7C,d2				; ''
		and.w	d2,d0				; ''

		move.w	d0,(a6)				; Set VDP command
		move.w	d4,(a6)				; ''

.DrawCol1_2_Loop:
		move.l	(a3)+,(a5)			; Draw blocks
		dbf	d7,.DrawCol1_2_Loop		; Loop

		; --- DRAW THE SECOND HALF OF THE COLUMN ---

		addq.w	#2,d1				; Move over to the right
		moveq	#(256/16)-1,d7			; Max number of blocks
		moveq	#0,d6
		move.b	cCBlks(a1),d6			; Get number of blocks in the first set
		sub.w	d6,d7				; Get number of blocks in the second set

		move.w	d1,(a6)				; Set VDP command
		move.w	d4,(a6)				; ''
		bra.s	.DrawCol2_1_Start		; Start

.DrawCol2_1_Loop:
		move.l	(a3)+,(a5)			; Draw blocks

.DrawCol2_1_Start:
		dbf	d6,.DrawCol2_1_Loop		; Loop

		move.w	d3,d2				; Wrap to the top of the plane
		addi.w	#$7E,d2				; ''
		and.w	d2,d1				; ''

		move.w	d1,(a6)				; Set VDP command
		move.w	d4,(a6)				; ''

.DrawCol2_2_Loop:
		move.l	(a3)+,(a5)			; Draw blocks
		dbf	d7,.DrawCol2_2_Loop		; Loop

		move.w	#$8F02,(a6)			; Autoincrement by 2
		bra.s	VInt_DrawLvlRows2		; Continue

VInt_DrawLvlRows:
		move.w	cVDP(a1),d3			; High word of VDP command
		move.w	cVDP+2(a1),d4			; Low word of VDP command

VInt_DrawLvlRows2:
		move.w	(a4),d0				; Get high VDP command
		beq.w	.End				; If it's 0, branch
		clr.w	(a4)+				; Don't run this again unless necessary
		
		; --- DRAW THE FIRST HALF OF THE ROW ---

		move.w	d0,d1				; Save high VDP command
		moveq	#(512/16)-1,d7			; Max number of blocks
		moveq	#0,d6
		move.b	cRBlks(a1),d6			; Get number of blocks in the first set
		sub.w	d6,d7				; Get number of blocks in the second set

		move.w	d0,(a6)				; Set VDP command
		move.w	d4,(a6)				; ''
		bra.s	.DrawRow1_1_Start		; Start

.DrawRow1_1_Loop:
		move.l	(a4)+,(a5)			; Draw blocks

.DrawRow1_1_Start:
		dbf	d6,.DrawRow1_1_Loop		; Loop

		move.w	d3,d2				; Wrap to the leftmost side of the plane
		addi.w	#$F00,d2			; ''
		and.w	d2,d0				; ''

		move.w	d0,(a6)				; Set VDP command
		move.w	d4,(a6)				; ''

.DrawRow1_2_Loop:
		move.l	(a4)+,(a5)			; Draw blocks
		dbf	d7,.DrawRow1_2_Loop		; Loop

		; --- DRAW THE SECOND HALF OF THE ROW ---

		addi.w	#$80,d1				; Move over down
		moveq	#(512/16)-1,d7			; Max number of blocks
		moveq	#0,d6
		move.b	cRBlks(a1),d6			; Get number of blocks in the first set
		sub.w	d6,d7				; Get number of blocks in the second set

		move.w	d1,(a6)				; Set VDP command
		move.w	d4,(a6)				; ''
		bra.s	.DrawRow2_1_Start		; Start

.DrawRow2_1_Loop:
		move.l	(a4)+,(a5)			; Draw blocks

.DrawRow2_1_Start:
		dbf	d6,.DrawRow2_1_Loop		; Loop

		move.w	d3,d2				; Wrap to the leftmost side of the plane
		addi.w	#$F80,d2			; ''
		and.w	d2,d1				; ''

		move.w	d1,(a6)				; Set VDP command
		move.w	d4,(a6)				; ''

.DrawRow2_2_Loop:
		move.l	(a4)+,(a5)			; Draw blocks
		dbf	d7,.DrawRow2_2_Loop		; Loop

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Handle plane drawing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d4.w	- Number of blocks per column
;	d5.w	- Number of blocks per row
;	a1.l	- Camera variables
;	a2.l	- Layout pointer
;	a3.l	- Column plane buffer
;	a4.l	- Row plane buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_UpdatePlane:
		push.l	d5/a4				; Push row plane buffer address
		bsr.s	Level_UpdatePlaneX		; Handle horizontal plane updating
		pop.l	d5/a4				; Restore row plane buffer address
		move.w	d5,d4				; Number of blocks per column
		; Continue to update the plane vertically
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Handle plane drawing (vertical redrawing only)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d4.w	- Number of blocks per row
;	a1.l	- Camera variables
;	a4.l	- Row plane buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_UpdatePlaneY:
		move.w	cYPos(a1),d0			; Get Y
		andi.w	#$FFF0,d0			; Only allow multiples of $10
		move.w	cYPrevR(a1),d1			; Get previous y (rounded)
		move.w	d0,cYPrevR(a1)			; Save new rounded y
		
		sub.w	d0,d1				; Get distance travelled
		beq.s	.End				; If a new row doesn't need to be drawn, branch
		bmi.s	.DrawDown			; If a new column needs to be drawn on the bottom of the screen, branch
		
.DrawUp:
		move.w	cXPos(a1),d0			; Get X
		move.w	cYPos(a1),d1			; Get Y
		bra.w	Level_GetRow			; Draw a row

.DrawDown:
		move.w	cXPos(a1),d0			; Get X
		move.w	cYPrev(a1),d1			; Get Y
		addi.w	#224+16,d1			; Go to the bottom of the screen
		bra.w	Level_GetRow			; Draw a row

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Handle plane drawing (horizontal redrawing only)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d4.w	- Number of blocks per column
;	a1.l	- Camera variables
;	a3.l	- Column plane buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_UpdatePlaneX:
		move.w	cXPos(a1),d0			; Get X
		andi.w	#$FFF0,d0			; Only allow multiples of $10
		move.w	cXPrevR(a1),d1			; Get previous X (rounded)
		move.w	d0,cXPrevR(a1)			; Save new rounded X
		
		sub.w	d0,d1				; Get distance travelled
		beq.s	.End				; If a new column doesn't need to be drawn, branch
		bmi.s	.DrawRight			; If a new column needs to be drawn on the right side of the screen, branch
		
.DrawLeft:
		move.w	cXPos(a1),d0			; Get X
		move.w	cYPos(a1),d1			; Get Y
		bra.w	Level_GetCol			; Draw a column
		
.DrawRight:
		move.w	cXPrev(a1),d0			; Get previous X
		addi.w	#320+16,d0			; Go to the right side of the screen
		move.w	cYPos(a1),d1			; Get Y
		bra.w	Level_GetCol			; Draw a column

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Macro to calculate the high VDP command word for the plane buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a1.l	- Camera variables
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	d2.w	- The high VDP command word
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
calcHiVDP	macro
		move.w	d0,d2				; Copy X
		move.w	d1,d3				; Copy Y
		lsl.w	#4,d3				; Multiply Y by $10
		andi.w	#$F00,d3			; Only allow 0-$F00 with multiples of $100
		lsr.w	#2,d2				; Divide X by 4
		andi.w	#$7C,d2				; Only allow 0-$7C with multiples of 4
		add.w	d3,d2				; Add Y onto X
		or.w	cVDP(a1),d2			; Combine with high VDP command word
		endm
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Macro to get an address in chunk data relative to a position
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d1.l	- $FFFFXXXX
;	a2.l	- Layout data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	a6.l	- Pointer in chunk data to the correct block
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
getChunk	macro
		move.w	(a2,d0.w),d1			; Get chunk ID
		andi.l	#$3FFF,d1			; ''
		lsl.l	#5,d1				; Turn into offset by multiplying by 32 (number of bytes each chunk entry occupies)

		movea.l	(chunkDataPtr).w,a6		; Load base address of uncompressed chunk data in ROM
		adda.l	d1,a6				; Adjust by the offset of the current chunk ID
		endm
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get a block row and store it in a plane buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.w	- X position
;	d1.w	- Y position
;	d4.w	- Number of blocks to draw (minus 1)
;	a1.l	- Camera variables
;	a4.l	- Row plane buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_GetRow:
		lea	lvlLayout.w,a2			; Get level layout pointer address
		adda.w	cLayout(a1),a2			; Add camera offset value
		movea.l	(a2),a2				; Load address stored within the pointer

		lea	blockData.w,a3			; Get block table address
		lea	$82(a4),a5			; Store plane buffer address for the bottom tiles in the row

		calcHiVDP				; Get high VDP command word
		move.w	d2,(a4)+			; Store it

		move.w	d0,d2				; Get X
		lsr.w	#2,d2				; Divide X by 4
		andi.w	#$7C,d2				; Only allow 0-$7C with multiples of 4
		move.w	#512/4,d5			; Get max row size in pixels divided by 4
		sub.w	d2,d5				; Get number of pixels (divided by 4) that the first set of tiles for a row takes up
		andi.w	#$7C,d5				; Only allow 0-$7C with multiples of 4
		lsr.w	#2,d5				; Divide by 4
		move.b	d5,cRBlks(a1)			; Set tile count for the first set of tiles for a row
		
		asr.w	#3,d0				; Get X within chunk data
		move.w	d0,d2				; ''
		andi.w	#6,d2				; ''
		asr.w	#1,d1				; Get Y within chunk data
		move.w	d1,d3				; ''
		andi.w	#$18,d3				; ''
		add.w	d3,d2				; Combine X and Y to get chunk offset
		
		move.w	(a2),d7				; Get the layout width specified in the header
		asr.w	#3,d0				; Get X within layout data
		bpl.s	.LayoutXPositive		; Branch ahead if the layout X is positive
		add.w	d7,d0				; If not, fix it (only accounts for a single wrap)

.LayoutXPositive:
		andi.l	#$1FF,d0			; Keep within the maximum allowed width and clear the upper word
		divu.w	d7,d0				; Keep X value in-bounds
		swap	d0				; ''
		add.w	d0,d0				; Turn into an offset

		move.w	2(a2),d7			; Get the layout height specified in the header
		asr.w	#5,d1				; Get Y within layout data
		bpl.s	.LayoutYPositive		; Branch ahead if the layout Y is positive
		add.w	d7,d1				; If not, fix it (only accounts for a single wrap)

.LayoutYPositive:
		andi.l	#$1FF,d1			; Keep within the maximum allowed height and clear the upper word
		divu.w	d7,d1				; Keep Y value in-bounds
		swap	d1				; ''
		add.w	d1,d1				; Turn into an offset

		movem.w	d0-d1,-(sp)			; Backup layout X and Y 
		add.w	4(a2,d1.w),d0			; Combine X and Y to get layout offset
		getChunk				; Get chunk pointer at current location

.DrawBlock_Loop:
		move.w	(a6,d2.w),d5			; Get block properties
		move.w	d5,d6				; ''
		andi.w	#$3FF,d5			; Mask off flip bits
		lsl.w	#3,d5				; Get offset in block data
		
		move.l	(a3,d5.w),d7			; Get block tiles
		move.l	4(a3,d5.w),d5			; ''

		btst	#$A,d6				; Is this block flipped horizontally?
		beq.s	.ChkYFlip			; If not, branch
		eori.l	#$08000800,d7			; Flip the tiles horizontally
		eori.l	#$08000800,d5			; ''
		swap	d7				; ''
		swap	d5				; ''

.ChkYFlip:
		btst	#$B,d6				; Is this block flipped vertically?
		beq.s	.DrawBlock			; If not, branch
		eori.l	#$10001000,d7			; Flip the tiles vertically
		eori.l	#$10001000,d5			; ''
		exg.l	d7,d5				; ''

.DrawBlock:
		move.l	d7,(a4)+			; Save the tiles in the plane buffers
		move.l	d5,(a5)+			; ''

		addq.w	#2,d2				; Go to the next block
		andi.w	#6,d2				; Have we gone outside of the chunk?
		bne.s	.DrawBlock_Cont			; If not, branch
		
		movem.w	(sp)+,d0-d1			; Get saved layout X and Y from the stack
		lsr.w	#1,d0				; Turn the offset into index value
		addq.w	#1,d0				; Increment to the next chunk
		cmp.w	(a2),d0				; Are we still in-bounds?
		blo.s	.GetNextChunk			; If so, branch
		clr.w	d0				; Otherwise, correct the index value

.GetNextChunk:
		add.w	d0,d0				; Turn the index back into offset
		movem.w	d0-d1,-(sp)			; Push a backup copy back onto the stack
		add.w	4(a2,d1.w),d0			; Next chunk
		getChunk				; ''

.DrawBlock_Cont:
		add.w	d3,d2				; Recombine X and Y to get chunk offset
		dbf	d4,.DrawBlock_Loop		; Loop

		addq.w	#4,sp				; Discard backup layout X and Y from the stack 
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get a block column and store it in a plane buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.w	- X position
;	d1.w	- Y position
;	d4.w	- Number of blocks to draw (minus 1)
;	a1.l	- Camera RAM
;	a3.l	- Column plane buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_GetCol:

		lea	lvlLayout.w,a2			; Get level layout pointer address
		adda.w	cLayout(a1),a2			; Add camera offset value
		movea.l	(a2),a2				; Load address stored within the pointer
		
		lea	blockData.w,a4			; Get block table address
		lea	$42(a3),a5			; Store plane buffer address for the right tiles in the column
		
		calcHiVDP				; Get high VDP command word
		move.w	d2,(a3)+			; Store it

		move.w	d1,d3				; Get Y
		lsl.w	#4,d3				; Multiply by $10
		andi.w	#$F00,d3			; Only allow 0-$F00 with multiples of $100
		move.w	#256*16,d5			; Get max column size in pixels times 16
		sub.w	d3,d5				; Get number of pixels (times 16) that the first set of tiles for a column takes up
		andi.w	#$F00,d5			; Only allow 0-$F00 with multiples of $100
		lsr.w	#8,d5				; Divide by $100
		move.b	d5,cCBlks(a1)			; Set tile count for the first set of tiles for a column

		asr.w	#3,d0				; Get X within chunk data
		move.w	d0,d2				; ''
		andi.w	#6,d2				; ''
		asr.w	#1,d1				; Get Y within chunk data
		move.w	d1,d3				; ''
		andi.w	#$18,d3				; ''
		add.w	d2,d3				; Combine X and Y to get chunk offset

		move.w	(a2),d7				; Get the layout width specified in the header
		asr.w	#3,d0				; Get X within layout data
		bpl.s	.LayoutXPositive		; Branch ahead if the layout X is positive
		add.w	d7,d0				; If not, fix it (only accounts for a single wrap)

.LayoutXPositive:
		andi.l	#$1FF,d0			; Keep within the maximum allowed width and clear the upper word
		divu.w	d7,d0				; Keep X value in-bounds
		swap	d0				; ''
		add.w	d0,d0				; Turn into an offset

		move.w	2(a2),d7			; Get the layout height specified in the header
		asr.w	#5,d1				; Get Y within layout data
		bpl.s	.LayoutYPositive		; Branch ahead if the layout Y is positive
		add.w	d7,d1				; If not, fix it (only accounts for a single wrap)

.LayoutYPositive:
		andi.l	#$1FF,d1			; Keep within the maximum allowed height and clear the upper word
		divu.w	d7,d1				; Keep Y value in-bounds
		swap	d1				; ''
		add.w	d1,d1				; Turn into an offset

		movem.w	d0-d1,-(sp)			; Backup layout X and Y 
		add.w	4(a2,d1.w),d0			; Combine X and Y to get layout offset
		getChunk				; Get chunk pointer at current location

.DrawBlock_Loop:
		move.w	(a6,d3.w),d5			; Get block properties
		move.w	d5,d6				; ''
		andi.w	#$3FF,d5			; Mask off flip bits
		lsl.w	#3,d5				; Get offset in block data
	
		move.w	d5,d7				; Get block tiles
		move.l	2(a4,d7.w),d5			; ''
		move.w	d7,d5				; ''
		move.l	(a4,d5.w),d7			; ''
		move.w	4(a4,d5.w),d7			; ''
		move.w	6(a4,d5.w),d5			; ''

		btst	#$A,d6				; Is this block flipped horizontally?
		beq.s	.ChkYFlip			; If not, branch
		eori.l	#$08000800,d7			; Flip the tiles horizontally
		eori.l	#$08000800,d5			; ''
		exg.l	d7,d5				; ''

.ChkYFlip:
		btst	#$B,d6				; Is this block flipped vertically?
		beq.s	.DrawBlock			; If not, branch
		eori.l	#$10001000,d7			; Flip the tiles vertically
		eori.l	#$10001000,d5			; ''
		swap	d7				; ''
		swap	d5				; ''

.DrawBlock:
		move.l	d7,(a3)+			; Save the tiles in the plane buffers
		move.l	d5,(a5)+			; ''

		addq.w	#8,d3				; Go to the next block
		andi.w	#$18,d3				; Have we gone outside of the chunk?
		bne.s	.DrawBlock_Cont			; If not, branch

		movem.w	(sp)+,d0-d1			; Get saved layout X and Y from the stack
		lsr.w	#1,d1				; Turn the offset into index value
		addq.w	#1,d1				; Increase layout data Y index to the next pointer
		cmp.w	2(a2),d1			; Are we still in-bounds?
		blo.s	.GetNextChunk			; If so, branch
		clr.w	d1				; Otherwise, reset the index value

.GetNextChunk:
		add.w	d1,d1				; Turn the index back into offset
		movem.w	d0-d1,-(sp)			; Push a backup copy back onto the stack
		add.w	4(a2,d1.w),d0			; Next chunk
		getChunk				; ''

.DrawBlock_Cont:
		add.w	d2,d3				; Recombine X and Y to get chunk offset
		dbf	d4,.DrawBlock_Loop		; Loop

		addq.w	#4,sp				; Discard backup layout X and Y from the stack 
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Refresh a plane
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a1.l	- Camera variables
;	a4.l	- Row plane buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_RefreshPlane:
		move.w	cXPos(a1),d0			; Get X position
		move.w	d0,cXPrev(a1)			; Store as previous X position
		andi.w	#$FFF0,d0			; Only get multiples of $10
		move.w	d0,cXPrevR(a1)			; Store as previous X position (rounded)
		
		move.w	cYPos(a1),d1			; Get Y position
		move.w	d1,cYPrev(a1)			; Store as previous Y position
		andi.w	#$FFF0,d1			; Only get multiples of $10
		move.w	d1,cYPrevR(a1)			; Store as previous Y position (rounded)
		
		moveq	#(512/16)-1,d4			; Number of rows to draw
		moveq	#(256/16)-1,d6			; Number of blocks per row
		
		push.l	a4				; Save plane buffer address
		
.DrawRows:
		push.w	d0/d1/d4/d6			; Save registers
		movea.l	8(sp),a4			; Get plane buffer address
		bsr.w	Level_GetRow			; Transfer the row to the plane buffer
		movea.l	8(sp),a4			; Get plane buffer address
		lea	VDP_CTRL,a6			; VDP control port
		lea	-4(a6),a5			; VDP data port
		bsr.w	VInt_DrawLvlRows		; Draw the new row
		pop.w	d0/d1/d4/d6			; Restore registers
		
		addi.w	#$10,d1				; Increment Y
		dbf	d6,.DrawRows			; Loop
		
		pop.l	a4				; Restore a3
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Check if the plane needs to be redrawn
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a1.l	- Camera RAM
;	a3.l	- Row plane buffer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_ChkRedrawPlane:
		tst.b	cRedraw(a1)			; Does this plane need to be redrawn?
		; Comment out the following line to disable blast processing :^)
		beq.s	.End				; If not, branch
		clr.b	cRedraw(a1)			; Clear the redraw flag
		bra.s	Level_RefreshPlane		; Redraw the plane

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Scroll sections macro
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
SCROLL_AUTOMATIC	EQU	$8000			; Automatic scroll flag
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
scrollInit	macro	label
SCROLL_LABEL	equs	"\label"
\label\:	dc.w	((\label\_End-\label\-2)/6)-1	; Number of sections
		endm
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
scrollEnd	macro
\SCROLL_LABEL\_End:					; End label
		endm
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
scrollSection	macro
	if narg<3
		dc.w	\2, 0, \1			; Speed, 0, Size
	else
		dc.w	\2, \3, \1			; Speed, Flags, Size
	endif
		endm
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Do section scrolling
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; PARAMERERS:
;	a1.l	- Background camera RAM
;	a3.l	- Scroll section data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ScrollSections:
		lea	fgCamVars.w,a2			; Get foreground level drawing variables
		lea	scrollSects.w,a4		; Deformation offset buffer
		lea	hScrollBuff.w,a5			; Horizontal scroll buffer

		move.w	(a3)+,d0			; Get the total number of scroll sections

		move.w	cXPos(a2),d4			; Get camera speed
		sub.w	cXPrev(a2),d4			; ''
		ext.l	d4				; ''
		asl.l	#8,d4				; Shift over to use for calculation speeds
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		; Update each section offset
		push.w	d0/a4				; Save registers

.ScrollSects:
		move.w	(a3)+,d3			; Get section speed
		ext.l	d3				; ''

		tst.w	(a3)+				; Is this section set to scroll automatically?
		bpl.s	.NotAuto			; If not, branch
		move.w	d4,d6				; Get camera speed
		muls.w	d3,d6				; Multiply by section speed
		asl.l	#8,d3				; Shift section speed
		add.l	d6,d3				; Add camera speed to section speed
		bra.s	.ApplySpeed			; Apply that speed

.NotAuto:
		muls.w	d4,d3				; Multiply the the background's X scroll offset with the speed

.ApplySpeed:
		add.l	d3,(a4)+			; Set the new section offset
		move.w	(a3)+,(a4)+			; Save the section size for later
		dbf	d0,.ScrollSects			; If there are still sections to check, loop

		pop.w	d0/a4				; Restore registers
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		; Set the scroll offsets on screen
		move.w	#224,d5				; Scanline counter
		move.w	cYPos(a1),d6			; Get the background's Y position
		
.FindStart:
		move.l	(a4)+,d1			; Get section offset
		sub.w	(a4)+,d6			; Subtract the size of the section
		bmi.s	.FoundStart			; If the current section is on screen, branch
		dbf	d0,.FindStart			; If not, continue the search
		move.w	cXPos(a2),d1			; Get the foreground's X position
		neg.w	d1				; Make it scroll the right direction
		swap	d1				; Fix which planes the scroll values go to
		neg.w	d1				; Make the background scroll the right direction
		bra.s	.LastSection			; If there are no more sections to go through, branch

.FoundStart:
		neg.w	d6				; Get remaining size of the section
		move.w	cXPos(a2),d1			; Get the foreground's X position
		neg.w	d1				; Make it scroll the right direction
		swap	d1				; Fix which planes the scroll values go to
		neg.w	d1				; Make the background scroll the right direction
		bra.s	.CheckScroll			; Go set some scroll offsets

.NextSection:
		move.w	(a4)+,d1			; Set scroll offset
		neg.w	d1				; Make the section scroll the correct way
		move.l	(a4)+,d6			; Get section size
		
.CheckScroll:
		sub.w	d6,d5				; Subtract that from the scanline count
		bmi.s	.EndSection			; If there is still screen space to cover, loop
		subq.w	#1,d6				; Convert for use with dbf

.Scroll:
		move.l	d1,(a5)+			; Scroll the section
		dbf	d6,.Scroll			; Repeat
		dbf	d0,.NextSection			; If there are any sections left, branch
		addq.w	#1,d5				; Add 1 so that the foreground can still scroll properly
		
.EndSection:
		add.w	d6,d5				; Get remaining screen space
		
.LastSection:
		subq.w	#1,d5				; Convert to use with dbf
		bmi.s	.End				; If there are none, exit

.FillScroll:
		move.l	d1,(a5)+			; Set previous scroll values
		dbf	d5,.FillScroll			; Repeat

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Static background scrolling (no parallax)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; PARAMERERS:
;	a1.l	- Background camera RAM
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ScrollStaticBG:
		lea	fgCamVars.w,a2		; Get foreground level drawing variables
		lea	hScrollBuff.w,a5		; Horizontal scroll buffer
		
		move.l	cXPos(a2),d1			; Get foreground X position
		neg.l	d1				; Negate it so it scrolls properly
		move.w	cXPos(a1),d1			; Get background X position
		neg.w	d1				; Negate it so it scrolls properly

		move.w	#224-1,d0			; Number of scanlines to scroll

.Scroll:
		move.l	d1,(a5)+			; Set the scroll offsets
		dbf	d0,.Scroll			; Repeat
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Generate fake layer art
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a0.l	- Layer art data pointer
;	a1.l	- Layer tile ID mappings pointer
;	d0.w	- Layer offset
;	d1.l	- Buffer pointer
;	d2.w	- VRAM destination address
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_UpdateLayer:
		; Prepare for transfer
		move.w	(a1)+,d3			; Get number of tiles to copy
		movea.l	d1,a2				; Copy layer buffer pointer
		
		; Queue a DMA transfer for later
		push.l	d0/d3/a1			; Save registers
		addq.w	#1,d3				; Get size of transfer
		lsl.w	#4,d3				; ''
		jsr	QueueDMATransfer.w		; Queue the transfer
		pop.l	d0/d3/a1			; Restore registers

		; Copy the tiles for the layer
		add.w	d0,d0				; Double it
		adda.w	(a1,d0.w),a1			; Get pointer to layer data for the offset
		
.CopyTiles:
		move.w	(a1)+,d1			; Get tile offset
		lea	(a0,d1.w),a3			; Get pointer to tile data
		move.l	(a3)+,(a2)+			; Copy tile data
		move.l	(a3)+,(a2)+			; ''
		move.l	(a3)+,(a2)+			; ''
		move.l	(a3)+,(a2)+			; ''
		move.l	(a3)+,(a2)+			; ''
		move.l	(a3)+,(a2)+			; ''
		move.l	(a3)+,(a2)+			; ''
		move.l	(a3)+,(a2)+			; ''
		dbf	d3,.CopyTiles			; Loop

.End
		rts
; =========================================================================================================================================================