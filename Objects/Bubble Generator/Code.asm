; =========================================================================================================================================================
; Bubble generator object
; =========================================================================================================================================================
		rsset	_objLvlSSTs
_objBubOrgX	rs.w	1
_objBubInhale	rs.b	1
_objBubAng	rs.b	1
_objBubTime	rs.b	1
_objBubFreq	rs.b	1
_objBubTypeInd	rs.w	1
_objBubUnk36	rs.w	1
_objBubUnk38	rs.w	1
_objBubTypeAddr	rs.l	1
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjBubbles:
		moveq	#0,d0
		move.b	_objRoutine(a0),d0			; Get routine ID
		move.w	.Index(pc,d0.w),d0		; Get routine pointer
		jmp	.Index(pc,d0.w)			; Jump to it
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Index:
		dc.w	ObjBubbles_Init-.Index
		dc.w	ObjBubbles_Main-.Index
		dc.w	ObjBubbles_ChkWater-.Index
		dc.w	ObjBubbles_Display-.Index
		dc.w	ObjBubbles_Delete-.Index
		dc.w	ObjBubbles_Maker-.Index
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjBubbles_Init:
		addq.b	#2,_objRoutine(a0)			; Next routine
		move.l	#Map_ObjBubbles,_objMapping(a0)	; Mappings
		move.w	#$8319,_objVRAM(a0)		; Tile properties
		move.b	#$84,_objRender(a0)		; Render flags
		move.w	#rSprInput+$80,oPrio(a0)	; Priority
		move.b	#$10,_objDrawW(a0)			; Sprite width
		move.b	#$10,_objDrawH(a0)			; Sprite height
		move.b	_objSubtype(a0),d0
		bpl.s	.Bubble

		addq.b	#8,_objRoutine(a0)
		andi.w	#$7F,d0
		move.b	d0,_objBubTime(a0)
		move.b	d0,_objBubFreq(a0)
		move.b	#6,_objAnim(a0)
		bra.w	ObjBubbles_Maker

.Bubble:
		move.b	d0,_objAnim(a0)
		move.w	_objXPos(a0),_objBubOrgX(a0)
		move.w	#-$88,_objYVel(a0)
		jsr	MATH_GetRandom.w
		move.b	d0,_objBubAng(a0)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjBubbles_Main:
		lea	Ani_ObjBubbles,a1
		jsr	AnimateObject.w
		cmpi.b	#6,_objFrame(a0)
		bne.s	ObjBubbles_ChkWater
		st	_objBubInhale(a0)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjBubbles_ChkWater:
		move.w	waterYPos.w,d0		; Get water level
		cmp.w	_objYPos(a0),d0			; Have we gone beyond it?
		bcs.s	.Wobble				; If not, branch
		move.b	#6,_objRoutine(a0)			; Next routine
		addq.b	#3,_objAnim(a0)			; Next animation
		bra.w	ObjBubbles_Display		; Continue

.Wobble:
		move.b	_objBubAng(a0),d0
		addq.b	#1,_objBubAng(a0)
		andi.w	#$7F,d0
		lea	ObjDrownCnt_WobbleData,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	_objBubOrgX(a0),d0
		move.w	d0,_objXPos(a0)
		tst.b	_objBubInhale(a0)
		beq.s	.Display
		bsr.w	ObjBubbles_ChkSonic
		cmpi.b	#6,_objRoutine(a0)
		beq.s	ObjBubbles_Display

.Display:
		jsr	ObjectMove.w
		tst.b	_objRender(a0)
		bpl.s	ObjBubbles_Delete
		jmp	DisplayObject.w

ObjBubbles_Delete:
		jmp	DeleteObject.w
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjBubbles_Display:
		lea	Ani_ObjBubbles,a1
		jsr	AnimateObject.w
		tst.b	_objRender(a0)
		bpl.s	ObjBubbles_Delete
		jmp	DisplayObject.w
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjBubbles_Maker:
		tst.w	_objBubUnk36(a0)
		bne.s	.loc_12874
		move.w	waterYPos.w,d0		; Get water level
		cmp.w	_objYPos(a0),d0			; Have we gone beyond it?
		bcc.w	.ChkDel				; If so, branch
		tst.b	_objRender(a0)
		bpl.w	.ChkDel
		subq.w	#1,_objBubUnk38(a0)
		bpl.w	.loc_12914
		move.w	#1,_objBubUnk36(a0)

.TryAgain:
		jsr	MATH_GetRandom.w
		move.w	d0,d1
		andi.w	#7,d0
		cmpi.w	#6,d0
		bcc.s	.TryAgain

		move.b	d0,_objBubTypeInd(a0)
		andi.w	#$C,d1
		lea	.BubTypes(pc),a1
		adda.w	d1,a1
		move.l	a1,_objBubTypeAddr(a0)
		subq.b	#1,_objBubTime(a0)
		bpl.s	.loc_12872
		move.b	_objBubFreq(a0),_objBubTime(a0)
		bset	#7,_objBubUnk36(a0)

.loc_12872:
		bra.s	.loc_1287C

.loc_12874:
		subq.w	#1,_objBubUnk38(a0)
		bpl.w	.loc_12914

.loc_1287C:
		jsr	MATH_GetRandom.w
		andi.w	#$1F,d0
		move.w	d0,_objBubUnk38(a0)
		jsr	FindFreeObj.w
		bne.s	.Fail
		move.l	_objAddress(a0),_objAddress(a1)
		move.w	_objXPos(a0),_objXPos(a1)
		jsr	MATH_GetRandom.w
		andi.w	#$F,d0
		subq.w	#8,d0
		add.w	d0,_objXPos(a1)
		move.w	_objYPos(a0),_objYPos(a1)
		moveq	#0,d0
		move.b	_objBubTypeInd(a0),d0
		movea.l	_objBubTypeAddr(a0),a2
		move.b	(a2,d0.w),_objSubtype(a1)
		btst	#7,_objBubUnk36(a0)
		beq.s	.Fail
		jsr	MATH_GetRandom.w
		andi.w	#3,d0
		bne.s	.loc_buh
		bset	#6,_objBubUnk36(a0)
		bne.s	.Fail
		move.b	#2,_objSubtype(a1)

.loc_buh:
		tst.b	_objBubTypeInd(a0)
		bne.s	.Fail
		bset	#6,_objBubUnk36(a0)
		bne.s	.Fail
		move.b	#2,_objSubtype(a1)

.Fail:
		subq.b	#1,_objBubTypeInd(a0)
		bpl.s	.loc_12914
		jsr	MATH_GetRandom.w
		andi.w	#$7F,d0
		addi.w	#$80,d0
		add.w	d0,_objBubUnk38(a0)
		clr.w	_objBubUnk36(a0)

.loc_12914:
		lea	Ani_ObjBubbles,a1
		jsr	AnimateObject.w

.ChkDel:
		move.w	_objXPos(a0),d0
		andi.w	#$FF80,d0
		sub.w	objMgrCoarseX.w,d0
		cmpi.w	#$280,d0
		bhi.s	.Delete
		move.w	waterYPos.w,d0
		cmp.w	_objYPos(a0),d0
		blo.s	.Display
		rts

.Display:
		jmp	DisplayObject.w

.Delete:
		move.w	_objRespawn(a0),d0			; Get respawn table entry address
		beq.s	.DoDelete			; If 0, branch
		movea.w	d0,a2
		bclr	#7,(a2)				; Mark as gone

.DoDelete:
		jmp	DeleteObject.w
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.BubTypes:
		dc.b	0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjBubbles_ChkSonic:
		lea	rObj_Player.w,a1
		
		tst.b	debugMode.w
		bne.w	.End
		btst	#0,_objFlags(a1)
		bne.w	.End
		
		move.w	_objXPos(a1),d0
		move.w	_objXPos(a0),d1
		subi.w	#$10,d1
		cmp.w	d0,d1
		bcc.s	.End
		addi.w	#$20,d1
		cmp.w	d0,d1
		bcs.s	.End
		move.w	_objYPos(a1),d0
		move.w	_objYPos(a0),d1
		cmp.w	d0,d1
		bcc.s	.End
		addi.w	#$10,d1
		cmp.w	d0,d1
		bcs.s	.End

		jsr	ObjDrown_ResetDrown
		;playsnd	#sBubble, 2
		move.b	#SndID_InhalingBubble,d0
		jsr	SOUND_PlaySFX
		
		clr.l	_objXVel(a1)
		clr.w	_objGVel(a1)
		move.b	#$15,_objAnim(a1)
		move.b	#$23,_objMoveLock(a1)
		clr.b	_objJumping(a1)
		bclr	#5,_objStatus(a1)
		btst	#2,_objStatus(a1)
		beq.s	.Burst
		bclr	#2,_objStatus(a1)
		move.b	_objInitColH(a1),_objColH(a1)		; Reset collision height
		move.b	_objInitColW(a1),_objColW(a1)		; Reset collision width
		subq.w	#5,_objYPos(a1)			; Align Sonic with the ground

.Burst:
		cmpi.b	#6,_objRoutine(a0)
		beq.s	.End
		move.b	#6,_objRoutine(a0)
		addq.b	#3,_objAnim(a0)

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Map_ObjBubbles:
		include	"Objects/Bubble Generator/Mappings.asm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Ani_ObjBubbles:
		dc.w	.Small-Ani_ObjBubbles
		dc.w	.Medium-Ani_ObjBubbles
		dc.w	.Large-Ani_ObjBubbles
		dc.w	.IncRoutine-Ani_ObjBubbles
		dc.w	.IncRoutine-Ani_ObjBubbles
		dc.w	.Burst-Ani_ObjBubbles
		dc.w	.BubMaker-Ani_ObjBubbles
.Small:		dc.b	$A, 0, 1, 2, $FC, 0
.Medium:	dc.b	$A, 1, 2, 3, 4, $FC
.Large:		dc.b	$A, 2, 3, 4, 5, 6, $FC, 0
.IncRoutine:	dc.b	4, $FC
.Burst:		dc.b	4, 6, 7, 8, $FC, 0
.BubMaker:	dc.b	$F, $13, $14, $15, $FF
		even
; =========================================================================================================================================================