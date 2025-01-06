; =========================================================================================================================================================
; Bubble generator object
; =========================================================================================================================================================
		rsset	_objLvlSSTs
_objAirUnk2C	rs.w	1
_objBubXPos	rs.w	1
_objAirUnk32	rs.b	1
_objAirUnk33	rs.b	1
_objBubAngle	rs.b	1
_objAirUnk34	rs.b	1
_objAirUnk36	rs.w	1
_objDrownTime	rs.w	1
_objAirUnk3A	rs.w	1
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjDrownCnt:
		moveq	#0,d0
		move.b	_objRoutine(a0),d0			; Get routine ID
		move.w	.Index(pc,d0.w),d0		; Get routine offset
		jmp	.Index(pc,d0.w)			; Jump to it
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Index:
		dc.w	ObjDrownCnt_Init-.Index
		dc.w	ObjDrownCnt_Anim-.Index
		dc.w	ObjDrownCnt_ChkWater-.Index
		dc.w	ObjDrownCnt_Display-.Index
		dc.w	ObjDrownCnt_Delete-.Index
		dc.w	ObjDrownCnt_Count-.Index
		dc.w	ObjDrownCnt_AirLeft-.Index
		dc.w	ObjDrownCnt_DisplayNum-.Index
		dc.w	ObjDrownCnt_Delete-.Index
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjDrownCnt_Init:
		addq.b	#2,_objRoutine(a0)			; Next routine
		move.l	#Map_ObjBubbles,_objMapping(a0)	; Mappings
		move.w	#$8319,_objVRAM(a0)		; Tile properties
		move.b	#$84,_objRender(a0)		; Render flags
		move.w	#rSprInput+$80,oPrio(a0)	; Priority
		move.b	#$10,_objDrawW(a0)			; Sprite width
		move.b	#$10,_objDrawH(a0)			; Sprite height
		move.b	_objSubtype(a0),d0			; Get bubble type
		bpl.s	.SmallBubble			; If it's small, branch

		addq.b	#8,_objRoutine(a0)			; Go to countdown
		move.l	#Map_ObjDrownCnt,_objMapping(a0)	; Mappings
		andi.w	#$7F,d0				; Mask off high bit
		move.b	d0,_objAirUnk33(a0)		; Set max timer value
		bra.w	ObjDrownCnt_Count		; Continue

.SmallBubble:
		move.b	d0,_objAnim(a0)			; Set animation
		move.w	_objXPos(a0),_objBubXPos(a0)		; Save X position
		move.w	#-$88,_objYVel(a0)			; Y velocity
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjDrownCnt_Anim:
		lea	Ani_ObjDrownCnt,a1		; Animate
		jsr	AnimateObject.w			; ''
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjDrownCnt_ChkWater:
		move.w	waterYPos.w,d0		; Get water level
		cmp.w	_objYPos(a0),d0			; Have we gone beyond it?
		bcs.s	.Wobble				; If not, branch

		move.b	#6,_objRoutine(a0)			; Next routine
		addq.b	#7,_objAnim(a0)			; Next animation
		cmpi.b	#$D,_objAnim(a0)
		blo.w	ObjDrownCnt_Display
		move.b	#$D,_objAnim(a0)
		bra.w	ObjDrownCnt_Display		; Continue

.Wobble:
		move.b	_objBubAngle(a0),d0		; Get angle
		addq.b	#1,_objBubAngle(a0)		; Increment angle
		andi.w	#$7F,d0				; Keep angle in range
		lea	ObjDrownCnt_WobbleData(pc),a1	; Get wobble data
		move.b	(a1,d0.w),d0			; Get offset
		ext.w	d0				; ''
		add.w	_objBubXPos(a0),d0			; Add X position
		move.w	d0,_objXPos(a0)			; Set X position
		bsr.w	ObjDrownCnt_ShowNum		; Show a countdown number
		jsr	ObjectMove.w			; Move
		tst.b	_objRender(a0)			; Have we gone offscreen?
		bpl.s	ObjDrownCnt_Delete		; If so, branch
		jmp	DisplayObject.w			; Display

ObjDrownCnt_Delete:
		jmp	DeleteObject.w			; Delete ourselves
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjDrownCnt_WobbleData:
		dc.b	0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2
		dc.b	2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3
		dc.b	4, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2
		dc.b	2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0
		dc.b	0, -1, -1, -1, -1, -1, -2, -2, -2, -2, -2, -3, -3, -3, -3, -3
		dc.b	-3, -3, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b	-4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -3
		dc.b	-3, -3, -3, -3, -3, -3, -2, -2, -2, -2, -2, -1, -1, -1, -1, -1
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjDrownCnt_DisplayNum:
		cmpi.b	#12,(rObj_Player+_objAirTimer).w
		bhi.w	ObjDrownCnt_Delete

ObjDrownCnt_Display:
		bsr.s	ObjDrownCnt_ShowNum		; Show a countdown number if needed
		lea	Ani_ObjDrownCnt,a1		; Animate
		jsr	AnimateObject.w			; ''
		jmp	DisplayObject.w			; Display
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjDrownCnt_AirLeft:
		cmpi.b	#12,(rObj_Player+_objAirTimer).w	; Are we running out of air?
		bhi.w	ObjDrownCnt_Delete		; If not, branch
		subq.w	#1,_objDrownTime(a0)		; Decrement drown timer
		bne.s	.Display			; If it hasn't run out, branch
		move.b	#$E,_objRoutine(a0)		; Next routine
		addq.b	#7,_objAnim(a0)			; Next animation
		bra.s	ObjDrownCnt_Display		; Display

.Display:
		lea	Ani_ObjDrownCnt,a1		; Animate
		jsr	AnimateObject.w			; ''
		tst.b	_objRender(a0)			; Did we go offscreen?
		bpl.w	ObjDrownCnt_Delete		; If so, branch
		jmp	DisplayObject.w			; Display
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjDrownCnt_ShowNum:
		tst.w	_objDrownTime(a0)			; Is the drown timer at 0?
		beq.s	.NoNumber			; If so, branch
		subq.w	#1,_objDrownTime(a0)		; Decrement drown timer
		bne.s	.NoNumber			; If it hasn't run out, branch
		cmpi.b	#7,_objAnim(a0)
		bcc.s	.NoNumber			; If so, branch

		;playsnd	#sDrownCount, 2			; Play drown count sound

		move.w	#15,_objDrownTime(a0)		; Reset drown timer
		clr.w	_objYVel(a0)			; Don't move up
		move.b	#$80,_objRender(a0)		; Screen space
		ori.w	#$8000,_objVRAM(a0)		; High priority
		move.w	#$140/2,_objXPos(a0)			; Set position
		move.w	#$E0/2,_objYPos(a0)			; ''
		move.b	#$C,_objRoutine(a0)		; Next routine
		
.NoNumber:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjDrownCnt_Count:
		tst.w	_objAirUnk2C(a0)			; Is the drowned timer active?
		bne.w	.loc_13F86			; If so, branch
		cmpi.b	#6,(rObj_Player+_objRoutine).w	; Is Sonic dead?
		bcc.w	.NoCountdown			; If so, branch
		btst	#6,(rObj_Player+_objStatus).w	; Is Sonic underwater?
		beq.w	.NoCountdown			; If not, branch

		subq.w	#1,_objDrownTime(a0)		; Decrement the drown timer
		bpl.w	.NoChange			; If it hasn't run out, branch
		move.w	#59,_objDrownTime(a0)		; Reset timer

		move.w	#1,_objAirUnk36(a0)
		jsr	MATH_GetRandom.w			; Get a random number
		andi.w	#1,d0				; Only get 0-1
		move.b	d0,_objAirUnk34(a0)
		moveq	#0,d0
		move.b	(rObj_Player+_objAirTimer).w,d0	; Get air remaining
		cmpi.w	#25,d0				; Check to play the drown warn sound
		beq.s	.WarnSound			; ''
		cmpi.w	#20,d0				; ''
		beq.s	.WarnSound			; ''
		cmpi.w	#15,d0				; ''
		beq.s	.WarnSound			; ''
		cmpi.w	#12,d0				; ''
		bhi.s	.ReduceAir			; ''

		subq.b	#1,_objAirUnk32(a0)
		bpl.s	.ReduceAir
		move.b	_objAirUnk33(a0),_objAirUnk32(a0)
		bset	#7,_objAirUnk36(a0)
		bra.s	.ReduceAir

.WarnSound:
		;playsnd	#sDrownWarn, 2			; Play drown warn sound
		move.b	#SndID_DrownWarning,d0
		jsr	SOUND_PlaySFX

.ReduceAir:
		subq.b	#1,(rObj_Player+_objAirTimer).w	; Reduce air
		bcc.w	.MakeBubble			; If Sonic still has air left, branch

		bsr.w	ObjDrown_ResetDrown		; Reset drowning stuff
		move.w	#$FFFF,camLocked.w		; Lock the camera
		;playsnd	#sDrown, 2			; Play drowning sound
		move.b	#SndID_Drown,d0
		jsr	SOUND_PlaySFX
		
		move.b	#$A,_objAirUnk34(a0)
		move.w	#1,_objAirUnk36(a0)
		move.w	#$78,_objAirUnk2C(a0)
		push.l	a0
		lea	rObj_Player.w,a0		; Get Sonic
		jsr	PlayerResetOnFloor		; Reset Sonic's flags
		move.b	#$17,_objAnim(a0)			; Drown animation
		bset	#1,_objStatus(a0)			; Set "in air" flag
		bset	#7,_objVRAM(a0)			; Set priority bit
		clr.l	_objXVel(a0)			; Stop moving
		clr.w	_objGVel(a0)			; ''
		move.b	#$A,_objRoutine(a0)		; Drown routine
		pop.l	a0
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.loc_13F86:
		move.b	#$17,_objAnim(a0)			; Drown animation
		subq.w	#1,_objAirUnk2C(a0)
		bne.s	.NoChange
		move.b	#6,(rObj_Player+_objRoutine).w	; Make Sonic dead
		rts

.NoChange:
		tst.w	_objAirUnk36(a0)
		beq.w	.NoCountdown
		subq.w	#1,_objAirUnk3A(a0)
		bpl.w	.NoCountdown

.MakeBubble:
		jsr	MATH_GetRandom.w			; Get a random number
		andi.w	#$F,d0				; Only get 0-$F
		addq.w	#8,d0
		move.w	d0,_objAirUnk3A(a0)

		jsr	FindFreeObj.w			; Find a free object slot
		bne.w	.NoCountdown			; If there is none, branch
		move.l	_objAddress(a0),_objAddress(a1)		; Load a countdown number
		move.w	(rObj_Player+oX).w,_objXPos(a1)	; Set X position
		moveq	#6,d0				; X offset
		btst	#0,(rObj_Player+_objStatus).w	; Is Sonic facing left?
		beq.s	.NoFlip				; If not, branch
		neg.w	d0				; Negate offset
		move.b	#$40,_objBubAngle(a1)		; Set angle

.NoFlip:
		add.w	d0,_objXPos(a1)			; Add offset
		move.w	(rObj_Player+oY).w,_objYPos(a1)	; Set Y position
		move.b	#6,_objSubtype(a1)			; Set subtype
		tst.w	_objAirUnk2C(a0)
		beq.w	.loc_1403E
		andi.w	#7,_objAirUnk3A(a0)
		addi.w	#0,_objAirUnk3A(a0)
		move.w	(rObj_Player+oY).w,d0
		subi.w	#$C,d0
		move.w	d0,_objYPos(a1)
		jsr	MATH_GetRandom.w
		move.b	d0,_objBubAngle(a1)
		move.w	lvlFrameCnt.w,d0
		andi.b	#3,d0
		bne.s	.loc_14082
		move.b	#$E,_objSubtype(a1)
		bra.s	.loc_14082

.loc_1403E:
		btst	#7,_objAirUnk36(a0)
		beq.s	.loc_14082
		moveq	#0,d0
		move.b	(rObj_Player+_objAirTimer).w,d2
		cmpi.b	#$C,d2
		bhs.s	.loc_14082
		lsr.w	#1,d2
		jsr	MATH_GetRandom.w
		andi.w	#3,d0
		bne.s	.loc_1406A
		bset	#6,_objAirUnk36(a0)
		bne.s	.loc_14082
		move.b	d2,_objSubtype(a1)
		move.w	#$1C,_objDrownTime(a1)

.loc_1406A:
		tst.b	_objAirUnk34(a0)
		bne.s	.loc_14082
		bset	#6,_objAirUnk36(a0)
		bne.s	.loc_14082
		move.b	d2,_objSubtype(a1)
		move.w	#$1C,_objDrownTime(a1)

.loc_14082:
		subq.b	#1,_objAirUnk34(a0)
		bpl.s	.NoCountdown
		clr.w	_objAirUnk36(a0)

.NoCountdown:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Reset drowning
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjDrown_ResetDrown:
		move.b	#$1E,(rObj_Player+_objAirTimer).w
		clr.w	(rObj_Drown+_objAirUnk2C).w
		clr.w	(rObj_Drown+_objAirUnk36).w
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Map_ObjDrownCnt:
		include	"Objects/Drown Countdown/Mappings.asm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Ani_ObjDrownCnt:
		dc.w	.Zero-Ani_ObjDrownCnt
		dc.w	.One-Ani_ObjDrownCnt
		dc.w	.Two-Ani_ObjDrownCnt
		dc.w	.Three-Ani_ObjDrownCnt
		dc.w	.Four-Ani_ObjDrownCnt
		dc.w	.Five-Ani_ObjDrownCnt
		dc.w	.SmallBubble-Ani_ObjDrownCnt
		dc.w	.ZeroFlash-Ani_ObjDrownCnt
		dc.w	.OneFlash-Ani_ObjDrownCnt
		dc.w	.TwoFlash-Ani_ObjDrownCnt
		dc.w	.ThreeFlash-Ani_ObjDrownCnt
		dc.w	.FourFlash-Ani_ObjDrownCnt
		dc.w	.FiveFlash-Ani_ObjDrownCnt
		dc.w	.Blank-Ani_ObjDrownCnt
		dc.w	.MedBubble-Ani_ObjDrownCnt
.Zero:		dc.b	5, 0, 1, 2, 3, 4, 5, 9, $D, $FC
.One:		dc.b	5, 0, 1, 2, 3, 4, 5, $C, $12, $FC
.Two:		dc.b	5, 0, 1, 2, 3, 4, 5, $C, $11, $FC
.Three:		dc.b	5, 0, 1, 2, 3, 4, 5, $B, $10, $FC
.Four:		dc.b	5, 0, 1, 2, 3, 4, 5, 9, $F, $FC
.Five:		dc.b	5, 0, 1, 2, 3, 4, 5, $A, $E, $FC
.SmallBubble:	dc.b	$E, 0, 1, 2, $FC
.ZeroFlash:	dc.b	7, $16, $D, $16, $D, $16, $D, $FC
.OneFlash:	dc.b	7, $16, $12, $16, $12, $16, $12, $FC
.TwoFlash:	dc.b	7, $16, $11, $16, $11, $16, $11, $FC
.ThreeFlash:	dc.b	7, $16, $10, $16, $10, $16, $10, $FC
.FourFlash:	dc.b	7, $16, $F, $16, $F, $16, $F, $FC
.FiveFlash:	dc.b	7, $16, $E, $16, $E, $16, $E, $FC
.Blank:		dc.b	$E, $FC
.MedBubble:	dc.b	$E, 1, 2, 3, 4, $FC
		even
; =========================================================================================================================================================