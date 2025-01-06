; =========================================================================================================================================================
; Monitor object
; =========================================================================================================================================================
		rsset	_objLvlSSTs
_objMonFall	rs.b	1				; Fall flag
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitor:
		move.l	#ObjMonitorMain,_objAddress(a0)
		move.b	#$E,_objColH(a0)
		move.b	#$E,_objColW(a0)
		move.l	#Map_ObjMonitor,_objMapping(a0)
		move.w	#$588,_objVRAM(a0)
		move.b	#4,_objRender(a0)
	displaySprite	3,a0,a1,0			; Priority
		move.b	#$F,_objDrawW(a0)
		move.b	#$F,_objDrawH(a0)
		move.w	_objRespawn(a0),d0
		beq.s	ObjMonitorNotBroken
		movea.w	d0,a2
		btst	#0,(a2)				; has monitor been broken?
		beq.s	ObjMonitorNotBroken		; if not, branch
		move.b	#7,_objFrame(a0)		; use broken monitor frame
		move.l	#ObjMonitorCheckActive,_objAddress(a0)
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorNotBroken:
		move.b	#6,_objColType(a0)
		move.b	_objSubtype(a0),_objAnim(a0)

ObjMonitorMain:
		bsr.s	ObjMonitorFall
		move.w	#$19,d1
		move.w	#$10,d2
		move.w	d2,d3
		move.w	_objXPos(a0),d4
		movea.w	playerPtrP1.w,a1
		bsr.s	SolidObject_Monitor

		move.w	maxCamYPos.w,d0
		addi.w	#$E0,d0
		cmp.w	_objYPos(a0),d0
		blt.s	ObjMonitorDelete

		jsr	AddToColResponse
		lea	Ani_ObjMonitor(pc),a1
		jsr	AnimateObject.w
		jsr	CheckObjActive.w
	nextObject

ObjMonitorDelete:
		jsr	DeleteObject.w
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorAnimate:
		cmpi.b	#7,_objFrame(a0)
		bcs.s	.NotBroken
		move.l	#ObjMonitorCheckActive,_objAddress(a0)

.NotBroken:
		lea	Ani_ObjMonitor(pc),a1
		jsr	AnimateObject.w
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorCheckActive:
		jsr	CheckObjActive.w
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorFall:
		move.b	_objMonFall(a0),d0
		beq.s	.End
		jsr	ObjectMoveAndFall.w
		tst.w	_objYVel(a0)
		bmi.s	.End
		jsr	ObjCheckFloorDist
		tst.w	d1
		beq.s	.InGround
		bpl.s	.End

.InGround:
		add.w	d1,_objYPos(a0)
		clr.w	_objYVel(a0)
		clr.b	_objMonFall(a0)

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
SolidObject_Monitor:
		btst	#cStandBit,_objStatus(a0)
		bne.s	ObjMonitorChkOverEdge
		cmpi.b	#2,_objAnim(a1)
		beq.s	.End
		cmpi.b	#$17,_objAnim(a1)		; check if in drowning animation
		bne.s	.SetSolid

.End:
		rts

.SetSolid:
		jmp	SolidObject_ChkCollision

ObjMonitorChkOverEdge:
		move.w	d1,d2
		add.w	d2,d2
		btst	#1,_objStatus(a1)
		bne.s	.NotOnMonitor
		move.w	_objXPos(a1),d0
		sub.w	_objXPos(a0),d0
		add.w	d1,d0
		bmi.s	.NotOnMonitor
		cmp.w	d2,d0
		blo.s	ObjMonitorCharStandOn

.NotOnMonitor:
		bclr	#cStandBit,_objStatus(a1)
		bset	#1,_objStatus(a1)
		bclr	#cStandBit,_objStatus(a0)
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorCharStandOn:
		move.w	d4,d2
		jsr	PlayerMoveOnPtfm
		moveq	#0,d4
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorBreakOpen:
		;playsnd	#sBreakItem, 2			; Play destroy sound
		
		move.b	_objStatus(a0),d0
		andi.b	#cStand|cPush,d0
		beq.s	ObjMonitorSpawnIcon
		movea.w	playerPtrP1.w,a1
		andi.b	#$D7,_objStatus(a1)
		ori.b	#2,_objStatus(a1)

ObjMonitorSpawnIcon:
		clr.b	_objStatus(a0)
		move.b	#0,_objColType(a0)
		jsr	FindFreeObj.w
		beq.s	.SkipIconCreation
		move.l	#ObjMonitorContents,_objAddress(a1)		; load monitor contents	object
		move.w	_objXPos(a0),_objXPos(a1)
		move.w	_objYPos(a0),_objYPos(a1)
		move.b	_objAnim(a0),_objAnim(a1)
		move.b	_objRender(a0),_objRender(a1)
		move.b	_objStatus(a0),_objStatus(a1)

.SkipIconCreation:
		jsr	FindFreeObj.w
		beq.s	.SkipExplosionCreation
		move.l	#ObjExplosion,_objAddress(a1)			; load explosion object
		move.w	_objXPos(a0),_objXPos(a1)
		move.w	_objYPos(a0),_objYPos(a1)

.SkipExplosionCreation:
		move.w	_objRespawn(a0),d0
		beq.s	.NotRemembered
		movea.w	d0,a2
		bset	#0,(a2)

.NotRemembered:
		move.b	#6,_objAnim(a0)
		move.l	#ObjMonitorAnimate,_objAddress(a0)
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Contents of monitor object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorContents:
		moveq	#0,d0
		move.b	_objRoutine(a0),d0
		jsr	ObjMonitorContents_Index(pc,d0.w)
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorContents_Index:
		bra.s	ObjMonitorContents_Main
		bra.s	ObjMonitorContents_Move
		bra.w	ObjMonitorContents_Delete
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorContents_Main:
		addq.b	#2,_objRoutine(a0)
		move.w	#$8588,_objVRAM(a0)
		move.b	#$24,_objRender(a0)
	displaySprite	3,a0,a1,0			; Priority
		move.b	#8,_objDrawW(a0)
		move.b	#8,_objDrawH(a0)
		move.w	#-$300,_objYVel(a0)
		moveq	#0,d0
		move.b	_objAnim(a0),d0
		addq.b	#1,d0
		movea.l	#Map_ObjMonitor,a1
		add.b	d0,d0
		adda.w	(a1,d0.w),a1
		addq.w	#2,a1
		move.l	a1,_objMapping(a0)

		move.b	_objAnim(a0),d0
		addq.b	#1,d0
		move.b	d0,_objFrame(a0)

ObjMonitorContents_Move:
		tst.w	_objYVel(a0)			; is object moving?
		bpl.w	ObjMonitorContents_GetType	; if not, branch
		jsr	ObjectMove.w
		addi.w	#$18,_objYVel(a0)			; reduce object	speed
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorContents_GetType:
		addq.b	#2,_objRoutine(a0)
		move.b	#29,_objAnimTimer(a0)
		move.b	_objAnim(a0),d0
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		cmpi.b	#1,d0
		bne.s	.ChkRings
		push.l	a0
		movea.l	a0,a2
		movea.w	playerPtrP1.w,a0
		jsr	ObjPlayer_GetHurt
		pop.l	a0
	
		move.b	#MusID_ExtraLife,d0
		jmp	SOUND_PlayMusic
		;rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.ChkRings:
		cmpi.b	#2,d0
		bne.s	.Display
		addi.w	#10,ringCount.w 				; add 10 rings to the number of rings you have
		ori.b	#1,hudUpdateRings.w 			; update the ring counter
		;playsnd	#sRing, 2				; Play ring sound
		move.b	#SndID_Ring,d0
		jmp	SOUND_PlaySFX

.Display:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjMonitorContents_Delete:
		subq.b	#1,_objAnimTimer(a0)
		bpl.s	.NoDelete
		jmp	DeleteObject.w

.NoDelete:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Map_ObjMonitor:
		include	"Objects/Monitor/Mappings.asm"
Ani_ObjMonitor:
		include	"Objects/Monitor/Animations.asm"
; =========================================================================================================================================================