; =========================================================================================================================================================
; Water surface object
; =========================================================================================================================================================
		rsset	_objLvlSSTs

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjBumper:
		move.l	#ObjBumperMain,_objAddress(a0)	; Next routine
		move.l	#Map_ObjBumper,_objMapping(a0)		; Mappings
		move.w	#$35B,_objVRAM(a0)			; Tile properties
		move.b	#4,_objRender(a0)			; Render flags
	displaySprite	1,a0,a1,0			; Priority
		moveq	#$10,d1
		move.b	d1,_objDrawW(a0)
		move.b	d1,_objColW(a0)
		move.b	d1,_objDrawH(a0)
		move.b	d1,_objColH(a0)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjBumperMain:
		tst.b	debugMode.w
		bne.w	.Display

		lea	.RangeData(pc),a1		; Range data
		movea.w	playerPtrP1.w,a2		; Player object
		cmpi.b	#$C,_objRoutine(a2)
		bcc.w	.Display
		jsr	CheckObjInRange.w		; Is the player in range?
		tst.w	d0				; ''
		beq.w	.Display			; If not, branch

		move.w	_objXPos(a0),d1
		move.w	_objYPos(a0),d2
		sub.w	_objXPos(a2),d1
		sub.w	_objYPos(a2),d2
		jsr	MATH_GetArctan.w
		move.b	(frameCounter+3).w,d1
		andi.w	#3,d1
		add.w	d1,d0
		jsr	MATH_GetSinCos.w
		muls.w	#-$700,d1
		asr.l	#8,d1
		move.w	d1,_objXVel(a2)
		muls.w	#-$700,d0
		asr.l	#8,d0
		move.w	d0,_objYVel(a2)
		cmpi.b	#8,_objRoutine(a2)
		bne.s	.NotHurt
		move.b	#2,_objAnim(a2)
		addq.w	#5,_objYPos(a2)
		move.b	#$E,_objColH(a2)
		move.b	#7,_objColW(a2)
		bset	#2,_objStatus(a2)

.NotHurt:
		move.b	#4,_objRoutine(a2)
		bset	#1,_objStatus(a2)
		bclr	#5,_objStatus(a2)
		clr.b	_objJumping(a2)
		move.b	#1,_objAnim(a0)
		;playsnd	#sBumper, 2
		move.b	#SndID_Bumper,d0
		jsr	SOUND_PlaySFX

.Display:
		lea	Ani_ObjBumper(pc),a1
		jsr	AnimateObject.w
		jsr	CheckObjActive.w		; Display
		jsr	AddToColResponse		; Allow collision
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.RangeData:
		dc.w	-$18, $30
		dc.w	-$18, $30
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Map_ObjBumper:
		include	"Objects/Bumper/Mappings.asm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Ani_ObjBumper:
		dc.w	.Ani0-Ani_ObjBumper
		dc.w	.Ani1-Ani_ObjBumper
.Ani0:		dc.b	5, 0, $FF, 0
.Ani1:		dc.b	5, 1, 2, 1, 2, $FD, 0
		even
; =========================================================================================================================================================