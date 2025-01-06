; =========================================================================================================================================================
; Wall spring object
; =========================================================================================================================================================
ObjWallSpring:
		move.l	#ObjWallSpring_Main,_objAddress(a0)	; Next routine
	;	move.l	#Map_ObjWallSpring,_objMapping(a0)	; Mappings
	;	clr.w	_objVRAM(a0)			; Tile properties
	;	ori.b	#4,_objRender(a0)			; Render flags
	;	move.w	#rSprInput+$200,oPrio(a0)	; Priority
	;	move.b	#8,_objDrawW(a0)			; Sprite width
	;	move.b	#$40,_objDrawH(a0)			; Sprite height
		move.b	#8,_objColW(a0)			; Collision width
		move.b	#$40,_objColH(a0)			; Collision height

		move.b	_objSubtype(a0),d0			; Get subtype
		lsr.b	#4,d0				; Get map frame
		andi.b	#7,d0				; ''
		move.b	d0,_objFrame(a0)			; Set map frame
		beq.s	ObjWallSpring_Main		; If it was 0, branch
	;	move.b	#$80,_objDrawH(a0)			; Larger sprite height
		move.b	#$80,_objColH(a0)			; Larger collision height
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjWallSpring_Main:
		moveq	#8,d1				; Width
		moveq	#0,d2
		move.b	_objColH(a0),d2			; Height
		move.w	d2,d3				; ''
		addq.w	#1,d3				; ''
		move.w	_objXPos(a0),d4			; X position
		jsr	SolidObject_Always		; Make us solid

		btst	#cTouchSideBit,d6		; Has Sonic touched the side of the spring?
		beq.s	.Display			; If not, branch
		bset	#1,_objStatus(a1)			; Set in air
		move.b	_objStatus(a0),d1			; Get status
		move.w	_objXPos(a0),d0			; Get distance between us and Sonic
		sub.w	_objXPos(a1),d0			; ''
		bcs.s	.ChkXStat			; If Sonic is towards the right of the spring, branch
		eori.b	#1,d1				; Go the other way

.ChkXStat:
		andi.b	#1,d1				; Has Sonic touched the front of spring?
		bne.s	.Display			; If not, branch
		bsr.s	.Bounce

.Display:
		jsr	CheckObjActive.w		; Delete if inactive
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Bounce:
		cmpi.b	#$C,_objRoutine(a1)			; Is Sonic dead?
		blo.s	.DoBounce			; If not, branch
		rts

.DoBounce:
		move.b	#4,_objRoutine(a1)			; Make Sonic not hurt if he is
		move.w	#-$800,_objXVel(a1)		; Bounce left
		move.w	#-$800,_objYVel(a1)		; Bounce up
		bset	#0,_objStatus(a1)			; Face left
		btst	#0,_objStatus(a0)			; Are we facing left?
		bne.s	.MoveLock			; If so, branch
		bclr	#0,_objStatus(a1)			; Face right
		neg.w	_objXVel(a1)			; Go right

.MoveLock:
		move.b	#$F,_objMoveLock(a1)		; Set move lock timer
		btst	#2,_objStatus(a1)			; Was Sonic jumping?
		bne.s	.ChkN_objYVel			; If so, branch
		clr.b	_objAnim(a1)			; Reset animation

.ChkN_objYVel:
		move.b	_objSubtype(a0),d0			; Get subtype
		bpl.s	.ChkFlip			; If Sonic should still bounce up, branch
		clr.b	_objYVel(a1)			; Stop Y velocity

.ChkFlip:
		btst	#0,d0				; Should Sonic tumble?
		beq.s	.PlaySnd			; If not, branch
		move.w	#1,_objFlipDir(a1)			; Set flip direction
		move.b	#1,_objFlipAngle(a1)		; Set flip angle
		clr.b	_objAnim(a1)			; Reset animation
		move.b	#1,_objFlipRemain(a1)		; Set flips remaining
		move.b	#8,_objFlipSpeed(a1)		; Set flip speed
		btst	#1,d0				; Should Sonic do 3 flips?
		bne.s	.ChkDir				; If not, branch
		move.b	#3,_objFlipRemain(a1)		; Do 3 flips isntead

.ChkDir:
		btst	#0,_objStatus(a1)			; Was Sonic facing left?
		beq.s	.PlaySnd			; If not, branch
		neg.b	_objFlipAngle(a1)			; Flip the other way
		neg.w	_objFlipDir(a1)			; ''

.PlaySnd:
		bclr	#cPushBit,_objStatus(a0)		; Stop pushing
		bclr	#cPushBit,_objStatus(a1)		; ''
		;playsnd	#sSpring, 2			; Play spring sound
		move.b	#SndID_Spring,d0
		jmp	SOUND_PlaySFX
		;rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Map_ObjWallSpring:
		include	"Objects/Wall Spring/Mappings.asm"
		even
; =========================================================================================================================================================