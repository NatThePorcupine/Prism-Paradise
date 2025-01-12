; =========================================================================================================================================================
; Object functions
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Initialize object lists
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
InitObjectList:
		clrRAM	objRespawn,objMemory_End		; Clear respawn table and object memory

	; setup tail object
		move.w	#objExecExit,objExecFirst.w		; set the first object as the tail object
		move.w	#objExecExit,objExecLast.w		; set the last object as the tail object
		move.l	#.rts,objExecExit.w		; set the next rts as the tail object pointer

	; setup free object list
		lea	objMemory.w,a0			; load the objects list into a0
		move.w	a0,objExecFree.w			; set the first object as the first free object
		moveq	#OBJECT_COUNT-2,d0		; load object count to d0
		moveq	#_objSize,d1			; load object size to d1
; ---------------------------------------------------------------------------------------------------------------------------------------------------------

.load
		add.w	d1,a0				; go to the next object now
		move.w	a0,_objPrev-_objSize(a0)		; save new previous pointer
		clr.l	_objDrawNext(a0)			; clear the display link values
		dbf	d0,.load			; loop for every object

		clr.w	_objPrev(a0)			; set the last previous pointer to 0
; ---------------------------------------------------------------------------------------------------------------------------------------------------------

	; reset display table
		lea	objDisplay-dNext.w,a1		; get display table address to a1
		moveq	#8-1,d1				; loop for all the layers

.dsp
		move.w	a1,dPrev+dNext(a1)		; update prev pointer
		addq.w	#dNext,a1			; advance to the actual address
		move.w	a1,dNext(a1)			; update next pointer

		clr.l	dN2(a1)				; clear the list end pointers
		addq.w	#dSize-dNext,a1			; go to the next layer
		dbf	d1,.dsp				; loop for all layers

.rts
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Find the first free object space available
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	a1.l	- Pointer to the SST space in the free object space
;	a2.l	- Trashed
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
FindFreeObj:
		move.w	objExecFree.w,d0			; get pointer to the next free object
		beq.s	.rts				; if it's a null pointer (z=1), return
		movea.w	d0,a1				; load to a1
		move.w	_objPrev(a1),objExecFree.w		; copy the next free object pointer to list start

		move.w	objExecLast.w,a2			; load last object to a2
		move.w	a1,objExecLast.w			; save as the new last object
		move.w	_objNext(a2),_objNext(a1)		; copy the next pointer from old tail to new object
		move.w	a1,_objNext(a2)			; save new object as next pointer for old tail
		move.w	a2,_objPrev(a1)			; save old tail as prev pointer for new object

.rts:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Delete another object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a1.l	- Pointer to object space to clear
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	a1.l	- Trashed
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DeleteOtherObj:
		pea	(a0)
		move.l	a1,a0
		bsr.s	DeleteObject
		pop.l	a0
		rts

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Delete the current object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	a1.l	- Trashed
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
DeleteObject:
	removeSprite	a0, a1, 1			; remove object display
		move.w	_objPrev(a0),a1			; copy previous pointer to a1
		move.w	_objNext(a0),_objNext(a1)		; copy next pointer to previous object
		move.w	_objNext(a0),a1			; get next object to a1
		move.w	_objPrev(a0),_objPrev(a1)		; copy previous pointer

		move.w	objExecFree.w,_objPrev(a0)		; get the head of the free list to previous pointer of this object
		move.w	a0,objExecFree.w			; save as the new head of free list

; clear object memory
		moveq	#0,d0				; clear d0
		moveq	#(((_objSize-_objDrawPrev)>>2)-1),d1	; set loop count

		pea	(a2)				; backup a2
		lea	_objDrawPrev(a0),a2		; load the first property to clear to a2
		
.clrLoop:
		move.l	d0,(a2)+			; clear a longword of the object slot's memory
		dbf	d1,.clrLoop			; loop through to clear all object properties

	if (_objSize-_objDrawPrev)&2
		move.w	d0,(a2)+			; clear the last word of data if the object ram per slot does not divide evenly by 4
	endif

		pop.l	a2				; restore a2
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Render object sprites
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
RenderObjects:
		moveq	#($280/8)-1,d7			; Max sprite count
		moveq	#0,d6				; Render flags

		lea	fgCamVars.w,a3			; Foreground camera variables
		lea	objDisplay+dNext.w,a5	; Sprite input table
		lea	spriteBuff.w,a6			; Sprite table buffer

		cmpi.b	#gLevel,opmode.w		; Are we in level mode?
		bne.s	.PrioLvlLoop			; If not, branch
		jsr	Level_RenderHUDAndRings		; Render the HUD & Rings (in that order)

.PrioLvlLoop:
		move.w	(a5),a0				; Load priority level address to a0
		add.w	#dSize,a5			; Skip bunch of shit
		tst.w	_objDrawNext(a0)		; Is the next pointer for a valid object?
		beq.w	.NextPrioLvl			; If not, branch

.ObjectLoop:
	;	movea.w	(a4)+,a0			; Get object SST address
		tst.l	_objAddress(a0)			; Is this object slot used?
		beq.w	.NextObject			; If not, branch

		andi.b	#$7F,_objRender(a0)		; Clear on-screen flag
		move.b	_objRender(a0),d6			; Store render flags
		move.w	_objXPos(a0),d0			; Get X position
		move.w	_objYPos(a0),d1			; Get Y position

		btst	#6,d6				; Is the multi sprite flag set?
		bne.w	.MultiDraw			; If so, branch
		btst	#2,d6				; Is the sprite to be drawn via screen space?
		beq.s	.Render				; If not, branch

		sub.w	cXPos(a3),d0			; Subtract the camera's X position from the sprite's
		sub.w	cYPos(a3),d1			; Subtract the camera's Y position from the sprite's

.Render:
		moveq	#0,d2
		move.b	_objDrawW(a0),d2		; Get sprite width
		move.w	d0,d3				; Get sprite X position
		add.w	d2,d3				; Add width
		bmi.s	.NextObject			; If it's off screen on the left, branch
		move.w	d0,d3				; Get sprite X position
		sub.w	d2,d3				; Subtract width
		cmpi.w	#320,d3				; Is it off screen on the right?
		bge.s	.NextObject			; If so, branch
		addi.w	#128,d0				; Move sprite on screen

		moveq	#0,d2
		move.b	_objDrawH(a0),d2			; Get sprite height
		move.w	d1,d3				; Get sprite Y position
		add.w	d2,d3				; Add height
		bmi.s	.NextObject			; If it's off screen on the top, branch
		move.w	d1,d3				; Get sprite Y position
		sub.w	d2,d3				; Subtract height
		cmpi.w	#224,d3				; Is it off screen on the bottom?
		bge.s	.NextObject			; If so, branch
		addi.w	#128,d1				; Move sprite on screen

		ori.b	#$80,_objRender(a0)		; Set on-screen flag
		tst.w	d7				; Do we still have some sprite space left?
		bmi.s	.NextObject			; If not, branch

		move.l	_objMapping(a0),d4			; Get mappings pointer
		beq.s	.NextObject			; If blank, branch
		movea.l	d4,a1				; Store it
		moveq	#0,d4
		btst	#5,d6				; Is the static sprite flag set
		bne.s	.Static				; If so, branch
		move.b	_objFrame(a0),d4			; Get mapping frame
		add.w	d4,d4				; Turn into offset
		adda.w	(a1,d4.w),a1			; Get mapping frame data pointer
		move.w	(a1)+,d4			; Get mapping frame sprite count
		subq.w	#1,d4				; Subtract 1 from sprite count
		bmi.s	.NextObject			; If there are no sprites to draw, branch

.Static:
		move.w	_objVRAM(a0),d5			; Get sprite tile properties
		bsr.w	DrawSprite			; Draw the sprites

.NextObject:	
		move.w	_objDrawNext(a0),a0		; Load next object to a0
		tst.w	_objDrawNext(a0)		; Check the next pointer for valid object
		bne.w	.ObjectLoop			; If there are still some sprites to draw in this priority level, branch

.NextPrioLvl:
		cmpa.w	#objDisplay_End,a5		; Are we at the end of the input table?
		blo.w	.PrioLvlLoop			; If not, branch

		move.w	d7,d6				; Get remaining sprite count
		bmi.s	.SetDrawnSprites		; If we have filled the entire sprite table, branch
		moveq	#0,d0

.FillRest:
		move.w	d0,(a6)				; Move sprite off screen
		addq.w	#8,a6				; Next sprite
		dbf	d7,.FillRest			; Loop

.SetDrawnSprites:
		subi.w	#($280/8)-1,d6			; Get number of sprites drawn
		neg.w	d6				; ''
		move.b	d6,spriteCount.w		; Store it

		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.MultiDraw:
		btst	#2,d6				; Is the sprite to be drawn via screen space?
		beq.s	.RenderMain			; If not, branch

		sub.w	cXPos(a3),d0			; Subtract the camera's X position from the sprite's
		sub.w	cYPos(a3),d1			; Subtract the camera's Y position from the sprite's

.RenderMain:
		moveq	#0,d2
		move.b	_objDrawW(a0),d2			; Get main sprite width
		move.w	d0,d3				; Get main sprite X position
		add.w	d2,d3				; Add width
		bmi.s	.NextObject			; If it's off screen on the left, branch
		move.w	d0,d3				; Get main sprite X position
		sub.w	d2,d3				; Subtract width
		cmpi.w	#320,d3				; Is it off screen on the right?
		bge.s	.NextObject			; If so, branch
		addi.w	#128,d0				; Move sprite on screen

		move.b	_objDrawH(a0),d2			; Get main sprite height
		move.w	d1,d3				; Get main sprite Y position
		add.w	d2,d3				; Add height
		bmi.s	.NextObject			; If it's off screen on the top, branch
		move.w	d1,d3				; Get main sprite Y position
		sub.w	d2,d3				; Subtract height
		cmpi.w	#224,d3				; Is it off screen on the bottom?
		bge.s	.NextObject			; If so, branch
		addi.w	#128,d1				; Move sprite on screen

		ori.b	#$80,_objRender(a0)		; Set on-screen flag
		tst.w	d7				; Do we still have some sprite space left?
		bmi.w	.NextObject			; If not, branch

		move.w	_objVRAM(a0),d5			; Get sprite tile properties
		move.l	_objMapping(a0),d4			; Get mappings pointer
		beq.w	.NextObject			; If blank, branch
		movea.l	d4,a2				; Store it
		moveq	#0,d4
		move.b	_objFrame(a0),d4			; Get mapping frame
		add.w	d4,d4				; Turn into offset
		lea	(a2),a1				; Copy mappings data pointer
		adda.w	(a1,d4.w),a1			; Get mapping frame data pointer
		move.w	(a1)+,d4			; Get mapping frame sprite count
		subq.w	#1,d4				; Subtract 1 from sprite count
		bmi.s	.RenderSubSprites		; If there are no sprites to draw, branch
		move.w	d6,d3				; Store render flags
		bsr.w	DrawSprite_BoundChk		; Draw the sprites
		move.w	d3,d6				; Restore render flags

		tst.w	d7				; Do we still have some sprite space left?
		bmi.w	.NextObject			; If not, branch

.RenderSubSprites:
		move.w	_objSubCnt(a0),d3			; Get sub sprite count
		subq.w	#1,d3				; Subtract 1
		bmi.w	.NextObject			; If there are no sprites to draw, branch
		lea	_objSubStart(a0),a0		; Get sub sprite SSTs start

.RenderSubSprs_Loop:
		move.w	(a0)+,d0			; Get X position
		addi.w	#128,d0				; Move on screen
		move.w	(a0)+,d1			; Get Y position
		addi.w	#128,d1				; Move on screen

		btst	#2,d6				; Is the sprite to be drawn via screen space?
		beq.s	.RenderSub			; If not, branch

		sub.w	cXPos(a3),d0			; Subtract the camera's X position from the sprite's
		sub.w	cYPos(a3),d1			; Subtract the camera's Y position from the sprite's

.RenderSub:
		move.w	(a0)+,d4			; Get mapping frame
		add.w	d4,d4				; Turn into offset
		lea	(a2),a1				; Copy mappings data pointer
		adda.w	(a1,d4.w),a1			; Get mapping frame data pointer
		move.w	(a1)+,d4			; Get mapping frame sprite count
		subq.w	#1,d4				; Subtract 1 from sprite count
		bmi.s	.RenderSubSprs_ChkLoop		; If there are no sprites to draw, branch
		push.w	d6				; Store render flags
		bsr.w	DrawSprite_BoundChk		; Draw the sprites
		pop.w	d6				; Restore render flags

.RenderSubSprs_ChkLoop:
		tst.w	d7				; Do we still have some sprite space left?
		dbmi	d3,.RenderSubSprs_Loop		; If so, loop
		bra.w	.NextObject			; Continue on rendering other sprites
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Animate an object's sprite
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a0.l	- Object space pointer
;	a1.l	- Animation script pointer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
AnimateObject:
		moveq	#0,d0
		move.b	_objAnim(a0),d0			; Get animation ID
		cmp.b	_objPrevAnim(a0),d0			; Has it changed?
		beq.s	.Run				; If not, branch
		move.b	d0,_objPrevAnim(a0)			; Save the new ID
		clr.b	_objAnimFrame(a0)			; Reset animation
		clr.b	_objAnimTimer(a0)			; Reset animation timer

.Run:
		subq.b	#1,_objAnimTimer(a0)		; Decrement animation timer
		bpl.s	.Wait				; If it hasn't run out, branch
		add.w	d0,d0				; Turn ID into offset
		adda.w	(a1,d0.w),a1			; Get pointer to current animation script
		move.b	(a1),_objAnimTimer(a0)		; Set new animation timer

		moveq	#0,d1
		move.b	_objAnimFrame(a0),d1		; Get current value in the script
		move.b	1(a1,d1.w),d0			; ''
		cmpi.b	#$FA,d0				; Is it a command value?
		bhs.s	.CmdReset			; If so, branch

.Next:
		move.b	d0,_objFrame(a0)			; Set mapping frame ID
		move.b	_objStatus(a0),d0			; Get status
		andi.b	#3,d0				; Only get flip bits
		andi.b	#$FC,_objRender(a0)		; Mask out flip bits in render flags
		or.b	d0,_objRender(a0)			; Set flip bits
		addq.b	#1,_objAnimFrame(a0)		; Advance into the animation script

.Wait:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.CmdReset:
		addq.b	#1,d0				; Is this flag $FF (reset)?
		bne.s	.CmdJump			; If not, branch
		clr.b	_objAnimFrame(a0)			; Reset animation
		move.b	1(a1),d0			; Get first frame ID
		bra.s	.Next				; Continue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.CmdJump:
		addq.b	#1,d0				; Is this flag $FE (jump)?
		bne.s	.CmdSetAnim			; If not, branch
		move.b	2(a1,d1.w),d0			; Get jump offset
		sub.b	d0,_objAnimFrame(a0)		; Go back
		sub.b	d0,d1				; ''
		move.b	1(a1,d1.w),d0			; Get new frame ID
		bra.s	.Next				; Continue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.CmdSetAnim:
		addq.b	#1,d0				; Is this flag $FD (set animation ID)?
		bne.s	.CmdNextRout			; If not, branch
		move.b	2(a1,d1.w),_objAnim(a0)		; Set new animation ID
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.CmdNextRout:
		addq.b	#1,d0				; Is this flag $FC (next routine)?
		bne.s	.CmdReset2ndRout		; If not, branch
		addq.b	#2,_objRoutine(a0)			; Next routine
		clr.b	_objAnimTimer(a0)			; Reset animation timer
		addq.b	#1,_objAnimFrame(a0)		; Next animation frame
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.CmdReset2ndRout:
		addq.b	#1,d0				; Is this flag $FB (reset secondary routine)?
		bne.s	.CmdNext2ndRout			; If not, branch
		clr.b	_objAnimTimer(a0)			; Reset animation timer
;		clr.b	oWFZRout(a0)			; Reset routine
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.CmdNext2ndRout:
		addq.b	#1,d0				; Is this flag $FA (next secondary routine)?
		bne.s	.CmdEnd				; If not, branch
;		addq.b	#2,oWFZRout(a0)			; Next routine
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.CmdEnd:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load object DPLCs
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d4.w	- Target VRAM address
;	d6.l	- Pointer to uncompressed art
;	a2.l	- Pointer to DPLCs
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
LoadObjDPLCs:
		moveq	#0,d0
		move.b	_objFrame(a0),d0			; Get mapping frame
		cmp.b	_objPrevDPLC(a0),d0		; Do we need to update the art?
		beq.s	.End				; If not, branch
		move.b	d0,_objPrevDPLC(a0)		; Save the frame ID so we don't constantly load the art
		add.w	d0,d0				; Turn ID into offset
		adda.w	(a2,d0.w),a2			; Get pointer to DPLC data for the frame
		move.w	(a2)+,d5			; Get DPLC entry count
		subq.w	#1,d5				; Subtract 1
		bmi.s	.End				; If there are no more entires left, branch

.ReadEntries:
		moveq	#0,d1
		move.w	(a2)+,d1			; Get DPLC entry data
		move.w	d1,d3				; Copy that
		lsr.w	#8,d3				; Get tile count
		andi.w	#$F0,d3				; ''
		addi.w	#$10,d3				; ''
		andi.w	#$FFF,d1			; Get offset in art data
		lsl.l	#5,d1				; ''
		add.l	d6,d1				; Get pointer in art data
		move.w	d4,d2				; Copy VRAM address
		add.w	d3,d4				; Add tile count to VRAM address
		add.w	d3,d4				; ''
		jsr	QueueDMATransfer.w		; Queue the art
		dbf	d5,.ReadEntries			; Loop

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Move an object by it's velocity values
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a0.l	- Object space pointer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjectMove:
		move.w	_objXVel(a0),d0			; Get X velocity
		ext.l	d0				; ''
		lsl.l	#8,d0				; Shift
		add.l	d0,_objXPos(a0)			; Add to the X position
		move.w	_objYVel(a0),d0			; Get Y velocity
		ext.l	d0				; ''
		lsl.l	#8,d0				; Shift
		add.l	d0,_objYPos(a0)			; Add to the Y position
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Move an object by it's velocity values (with gravity)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a0.l	- Object space pointer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjectMoveAndFall:
		move.w	_objXVel(a0),d0			; Get X velocity
		ext.l	d0				; ''
		lsl.l	#8,d0				; Shift
		add.l	d0,_objXPos(a0)			; Add to the X position
		move.w	_objYVel(a0),d0			; Get Y velocity
		addi.w	#$38,_objYVel(a0)			; Apply gravity
		ext.l	d0				; ''
		lsl.l	#8,d0				; Shift
		add.l	d0,_objYPos(a0)			; Add to the Y position
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Check if a specific object is nearby
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a0.l	- Current object space pointer
;	a1.l	- Range data pointer
;	a2.l	- Object to check's space pointer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	d0.w	- Return status (0 if not in range, other object's space pointer if in range)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
CheckObjInRange:
		moveq	#0,d0
		move.w	_objXPos(a2),d1			; Get other object's position
		move.w	_objYPos(a2),d2			; ''
		move.w	_objXPos(a0),d3			; Get current object's position
		move.w	_objYPos(a0),d4			; ''
		add.w	(a1)+,d3			; Get left boundary
		move.w	d3,d5				; Copy
		add.w	(a1)+,d5			; Get right boundary
		add.w	(a1)+,d4			; Get top boundary
		move.w	d4,d6				; Copy
		add.w	(a1)+,d6			; Get bottom boundary
		cmp.w	d3,d1				; Is the object past the left boundary?
		blo.s	.End				; If not, branch
		cmp.w	d5,d1				; Is the object within the horizontal range?
		bhs.s	.End				; If not, branch
		cmp.w	d4,d2				; Is the object past the top boundary?
		blo.s	.End				; If not, branch
		cmp.w	d6,d2				; Is the object within the vertical range?
		bhs.s	.End				; If not, branch
		move.w	a2,d0				; Copy other object's RAM space pointer as the return status

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Object manager
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjectManager:
		tst.b	objMgrInit.w
		bne.s	ObjectManagerMain

ObjectManagerInit:
		st	objMgrInit.w			; Set the init flag

		movea.l	objMgrLayout.w,a0		; Get object data pointer
		move.l	a0,objMgrLoadR.w
		move.l	a0,objMgrLoadL.w			; Store address of object layout

		lea	objRespawn.w,a3			; Object respawn table

		move.w	fgCamXPos.w,d6			; Camera's X position
		subi.w	#$80,d6				; Subtract 128
		bhs.s	.NoReset			; Branch if it doesn't go past the left boundary
		moveq	#0,d6				; Cap at left boundary

.NoReset:
		andi.w	#$FF80,d6			; Keep in chunks of 128 pixels

		movea.l	objMgrLoadR.w,a0			; Get address of the object loader for the right side of the screen

.ChkObjsLeft:
		cmp.w	(a0),d6				; Compare object position
		bls.s	.ChkDone			; If higher than d6, branch
		addq.w	#6,a0				; Next object
		addq.w	#1,a3				; Next respawn table index
		bra.s	.ChkObjsLeft			; Loop

.ChkDone:
		move.l	a0,objMgrLoadR.w			; Store new addresses
		move.w	a3,objMgrRespL.w			; ''

		lea	objRespawn.w,a3			; Object respawn table

		movea.l	objMgrLoadL.w,a0
		subi.w	#$80,d6				; Subtract from camera's X position again
		bcs.s	.ChkDone2			; But is done to account for the object loader later on

.ChkObjsRight:
		cmp.w	(a0),d6				; Compate object position
		bls.s	.ChkDone2			; If higher than d6, branch
		addq.w	#6,a0				; Next object
		addq.w	#1,a3				; Next respawn table index
		bra.s	.ChkObjsRight			; Loop

.ChkDone2:
		move.l	a0,objMgrLoadL.w			; Store new addresses
		move.w	a3,objMgrRespR.w			; ''

		move.w	#-1,objMgrCameraX.w			; Reset manager's camera X position
		move.w	fgCamYPos.w,d0			; Get camera's Y position
		andi.w	#$FF80,d0			; Keep in range
		move.w	d0,objMgrCameraY.w			; Store it so unnecessary Y checks shouldn't be done
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjectManagerMain:
		move.w	fgCamYPos.w,d1			; Get camera's Y position
		subi.w	#$80,d1				; Subtract 128 pixels
		andi.w	#$FF80,d1			; Keep in range
		move.w	d1,objMgrCoarseY.w		; Store this

		move.w	fgCamXPos.w,d1			; Get camera's X position
		subi.w	#$80,d1				; Subtract 128 pixels
		andi.w	#$FF80,d1			; Keep in range
		move.w	d1,objMgrCoarseX.w		; Store this
		
		lea	Level_ObjIndex,a4		; Level object index

		move.w	fgCamYPos.w,d3			; Get camera's Y position
		andi.w	#$FF80,d3			; Keep in range
		move.w	d3,d4				; Copy
		addi.w	#$200,d4			; Lower Y boundary
		subi.w	#$80,d3				; Upper Y boundary
		bpl.s	.SetNoWrap			; If still positive, branch
		moveq	#0,d3				; Cap at upper level boundary

.SetNoWrap:
		move.w	#$FFF,d5
		move.w	fgCamXPos.w,d6			; Get camera's X position
		andi.w	#$FF80,d6			; Keep in range
		cmp.w	objMgrCameraX.w,d6			; Check against last range
		beq.w	Level_LoadObjs_SameXRange	; Branch if they are the same
		bge.s	Level_LoadObjs_Forward		; If new range is greater than the last, branch

		move.w	d6,objMgrCameraX.w			; Set new range

		movea.l	objMgrLoadL.w,a0			; Get current objects on the left side of the screen
		movea.w	objMgrRespR.w,a3			; And the appropriate respawn list

		subi.w	#$80,d6				; Subtract 128 from the X position
		blo.s	.EndLoad			; If outside of the level boundary, branch

		jsr	FindFreeObj.w			; Attempt to load a new object
		beq.s	.EndLoad			; Branch if it failed

.LoadLoop:
		cmp.w	-6(a0),d6			; Check if the last object is in range
		bge.s	.EndLoadRst			; If not, branch
		subq.l	#6,a0				; Get actual object address
		subq.w	#1,a3				; Get acutal respawn table address

		bsr.w	Level_LoadObject		; Attempt to spawn the object
		beq.s	.LoadFail			; Branch if it could not be loaded
		subq.l	#6,a0
		bra.s	.LoadLoop			; Attempt to load another object

.LoadFail:
		addq.l	#6,a0				; Undo object loading
		addq.w	#1,a3
		bra.s	.EndLoad
.EndLoadRst:
		jsr	DeleteOtherObj.w

.EndLoad:
		move.l	a0,objMgrLoadL.w			; Store new addresses
		move.w	a3,objMgrRespR.w

		movea.l	objMgrLoadR.w,a0			; Get current objects on the right side of the screen
		movea.w	objMgrRespL.w,a3			; And the appropriate respawn list

		addi.w	#$300,d6			; Load 2 chunks forward

.ChkLoop:
		cmp.w	-6(a0),d6			; Check if the last object is out of range
		bgt.s	.ChkDone			; If so, branch
		subq.l	#6,a0				; Get the object before this
		subq.w	#1,a3				; And its respawn index
		bra.s	.ChkLoop			; Check next object

.ChkDone:
		move.l	a0,objMgrLoadR.w			; Store new addresses
		move.w	a3,objMgrRespL.w
		bra.s	Level_LoadObjs_SameXRange	; Continue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_LoadObjs_Forward:
		move.w	d6,objMgrCameraX.w			; Set new range

		movea.l	objMgrLoadR.w,a0			; Get current objects on the right side of the screen
		movea.w	objMgrRespL.w,a3			; And the appropriate respawn list

		addi.w	#$280,d6			; Load 2 chunks forward

		jsr	FindFreeObj.w			; Attempt to load a new object
		beq.s	.EndLoad			; Branch if it failed

.LoadLoop:
		cmp.w	(a0),d6				; Check if the last obhect is in range
		bls.s	.EndLoadRst			; If not, branch
		bsr.w	Level_LoadObject		; Attempt to spawn the object
		addq.w	#1,a3				; Get acutal respawn table address
		beq.s	.EndLoad			; If it failed to, branch
		bra.s	.LoadLoop

.EndLoadRst:
		jsr	DeleteOtherObj.w

.EndLoad:
		move.l	a0,objMgrLoadR.w			; Store new addresses
		move.w	a3,objMgrRespL.w

		movea.l	objMgrLoadL.w,a0			; Get current objects on the left side of the screen
		movea.w	objMgrRespR.w,a3			; And the appropriate respawn list

		subi.w	#$300,d6			; Check 1 chunk backwards
		blo.s	.ChkDone			; If outside of level, branch

.ChkLoop:
		cmp.w	(a0),d6				; Check if the last object is out of range
		bls.s	.ChkDone			; If so, branch
		addq.l	#6,a0				; Get the object before this
		addq.w	#1,a3				; And its respawn index
		bra.s	.ChkLoop			; Check next object

.ChkDone:
		move.l	a0,objMgrLoadL.w			; Store new addresses
		move.w	a3,objMgrRespR.w
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_LoadObjs_SameXRange:
		move.w	fgCamYPos.w,d6			; Get camera's X position
		andi.w	#$FF80,d6			; Keep in range
		move.w	d6,d3				; Copy
		cmp.w	objMgrCameraY.w,d6			; Check against last range
		beq.w	.LoadEnd			; Branch if they are the same
		bge.s	.MovingDown			; If the new raqnge is greater than the last, branch

		subi.w	#$80,d3				; Loop 1 chunk up
		bmi.w	.LoadEnd
		bra.s	.YCheck

.MovingDown:
		addi.w	#$180,d3			; Look 1 chunk down

.YCheck:
		jsr	FindFreeObj.w			; Attempt to load a new object
		beq.s	.LoadEnd			; If failed, branch
		
		move.w	d3,d4				; Copy Y position
		addi.w	#$80,d4				; Look one chunk down
		move.w	#$FFF,d5

		movea.l	objMgrLoadL.w,a0			; Get current objects on the left side of the screen
		movea.w	objMgrRespR.w,a3			; And the appropriate respawn list
		move.l	objMgrLoadR.w,d7			; Get current objects on the right side of the screen
		sub.l	a0,d7				; Subtract the left position from the right
		beq.s	.LoadEndRst			; Branch if no objects
		addq.l	#2,a0				; Align to object's Y position

.LoadNext:
		tst.b	(a3)				; Has the object been loaded?
		bmi.s	.LoadFail			; If so, branch

		move.w	(a0),d1				; Get object's Y position
		and.w	d5,d1				; Keep in range of 0-$FFF
		cmp.w	d3,d1
		blo.s	.LoadFail			; Branch if out of range in the top
		cmp.w	d4,d1
		bhi.s	.LoadFail			; Branch if out of range in the botoom

		bset	#7,(a3)				; Mark as loaded
		move.w	-2(a0),_objXPos(a1)			; Set X position
		move.w	(a0),d1				; Get object's Y position
		move.w	d1,d2				; Copy it
		and.w	d5,d1				; Keep in range of 0-$FFF
		move.w	d1,_objYPos(a1)			; Set Y position

		rol.w	#3,d2				; Get X and Y flip bits
		andi.w	#3,d2				; ''
		move.b	d2,_objRender(a1)			; Set render flags
		move.b	d2,_objStatus(a1)			; Set status

		move.b	2(a0),d2			; Get ID
		add.w	d2,d2				; Make it an index in the level object index list
		add.w	d2,d2
		move.l	(a4,d2.w),_objAddress(a1)		; Set address

		move.b	3(a0),_objSubtype(a1)		; Set subtype
		move.w	a3,_objRespawn(a1)			; Set respawn address

		jsr	FindFreeObj.w			; Find a free object slot
		beq.s	.LoadEnd			; If none could be loaded, branch

.LoadFail:
		addq.l	#6,a0				; Next object
		addq.w	#1,a3				; ''
		subq.l	#6,d7				; Subtract the size of the entry
		bne.s	.LoadNext			; If there are some objects remaining, branch

.LoadEndRst:
		jsr	DeleteOtherObj.w

.LoadEnd:
		move.w	d6,objMgrCameraY.w		; Store manager's camera Y position
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load an object from the object layout
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d3.w	- Upper boundary
;	d4.w	- Lower boundary
;	d5.w	- Y position limit
;	a0.l	- Index of object layout
;	a1.l	- Target object
;	a3.l	- Respawn table address
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_LoadObject:
		tst.b	(a3)				; Has the object been loaded?
		bpl.s	.NotLoaded			; If not, branch
		addq.l	#6,a0				; Next object
		moveq	#1,d1				; Ensure that upstream code knows to continue loading
		rts

.NotLoaded:
		move.w	(a0)+,d7			; X position
		move.w	(a0)+,d1			; Y position
		move.w	d1,d2				; Copy
		bmi.s	.LoadNoY			; If the object is set to ignore Y checks, branch
		and.w	d5,d1				; Keey Y in range
		cmp.w	d3,d1
		bcs.s	.End				; Branch if in range
		cmp.w	d4,d1
		bls.s	.Spawn				; Branch if in range

.End:
		addq.w	#2,a0				; Next objeect
		moveq	#1,d1				; Ensure that upstream code knows to continue loading
		rts

.LoadNoY:
		and.w	d5,d1				; Keey Y in range

.Spawn:
		bset	#7,(a3)				; Mark as loaded
		move.w	d7,_objXPos(a1)			; Store X position
		move.w	d1,_objYPos(a1)			; Store Y position

		rol.w	#3,d2				; Get X and Y flip bits
		andi.w	#3,d2				; ''
		move.b	d2,_objRender(a1)			; Set render flags
		move.b	d2,_objStatus(a1)			; Set status

		move.b	(a0)+,d2			; Get ID
		add.w	d2,d2				; Make it an index in the level object index list
		add.w	d2,d2
		move.l	(a4,d2.w),_objAddress(a1)		; Set address

		move.b	(a0)+,_objSubtype(a1)		; Set subtype
		move.w	a3,_objRespawn(a1)			; Set respawn address
		
		bra.w	FindFreeObj			; Find a free object slot
		
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Check if the object is in range on the camera. If it isn't, delete it
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a0.l	- Object space pointer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
CheckObjActive:
		move.w	_objXPos(a0),d0			; Get X position

CheckObjActive2:
		andi.w	#$FF80,d0			; Only allow multiples of $80
		sub.w	objMgrCoarseX.w,d0		; Subtract the camera's coarse X position
		cmpi.w	#$280,d0			; Has it gone offscreen?
		bhi.s	.Delete				; If so, branch
		rts

.Delete:
		move.w	_objRespawn(a0),d0			; Get respawn table entry address
		beq.s	.DoDelete			; If 0, branch
		movea.w	d0,a2
		bclr	#7,(a2)				; Mark as gone

.DoDelete:
		jmp	DeleteObject.w			; Delete the object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get orientation to player
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a0.l	- Object space pointer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	a1.l	- Player object
;	d0.w	- 0 if player is left from object, 2 if right
;	d1.w	- 0 if player is above object, 2 if below
;	d2.w	- Player's horizontal distance to object
;	d3.w	- Player's vertical distance to object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
GetOrientToPlayer:
		moveq	#0,d0
		moveq	#0,d1

		movea.w	playerPtrP1.w,a1		; Get player object

		move.w	_objXPos(a0),d2			; Get horizonal distance
		sub.w	_objXPos(a1),d2			; ''
		bpl.s	.GetY				; Branch if the player is left from the object
		addq.w	#2,d0				; Set flag to indicate that the player is right from the object

.GetY:
		move.w	_objYPos(a0),d3			; Get vertical distance
		sub.w	_objYPos(a1),d3			; ''
		bhs.s	.End				; Branch if the player is above the object
		addq.w	#2,d1				; Set flag to indicate that the player is below the object

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Cap an object's speed
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a0.l	- Object space pointer
;	d0.w	- Max X speed
;	d1.w	- Max Y speed
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
CapObjSpeed:
		move.w	_objXVel(a0),d2			; Get X velocity
		bpl.s	.ChkRight			; If we are going right, branch
		neg.w	d0				; Get absolute speed
		cmp.w	d0,d2				; Has it gone over the limit?
		bhs.s	.ChkUp				; If not, branch
		move.w	d0,d2				; Cap the speed
		bra.s	.ChkUp				; Continue

.ChkRight:
		cmp.w	d0,d2				; Has it gone over the limit?
		bls.s	.ChkUp				; If not, branch
		move.w	d0,d2				; Cap the speed

.ChkUp:
		move.w	_objYVel(a0),d3			; Get Y velocity
		bpl.s	.ChkDown			; If we are going right, branch
		neg.w	d1				; Get absolute speed
		cmp.w	d1,d3				; Has it gone over the limit?
		bhs.s	.UpdateVel			; If not, branch
		move.w	d1,d3				; Cap the speed
		bra.s	.UpdateVel			; Continue

.ChkDown:
		cmp.w	d1,d3				; Has it gone over the limit?
		bls.s	.UpdateVel			; If not, branch
		move.w	d1,d3				; Cap the speed

.UpdateVel:
		move.w	d2,_objXVel(a0)			; Set X velocity
		move.w	d2,_objYVel(a0)			; Set Y velocity
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load a child object	NTP: no idea wtf to do about this one. do we even need it since all objects are kinda linked anyway? we'll have to see
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	a2.l	- Object data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; LoadChildObject:
		bsr.w	FindFreeObj			; Find a free object slot
		bne.s	.End				; If there is non, branch
		move.w	(a2)+,d0			; Get parent object SST
		move.w	a0,(a1,d0.w)			; Store parent object
		move.w	(a2)+,d0			; Get child object SST
		move.w	a1,(a0,d0.w)			; Store child object
		move.l	(a2)+,_objAddress(a1)			; Set object pointer
		move.b	(a2)+,_objSubtype(a1)		; Set subtype
		move.w	_objXPos(a0),_objXPos(a1)			; Set X
		move.w	_objYPos(a0),_objYPos(a1)			; Set Y

.End:
		rts
; =========================================================================================================================================================
