; =========================================================================================================================================================
; Water surface object
; =========================================================================================================================================================
		rsset	_objLvlSSTs

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjRingLoss:
		movea.l	a0,a1
		moveq	#0,d5
		move.w	ringCount.w,d5
		moveq	#32,d0
		cmp.w	d0,d5
		bcs.s	.BelowMax
		move.w	d0,d5

.BelowMax:
		subq.w	#1,d5
		lea	ObjLostRing_Speeds,a3
		bra.s	.MakeRings

.Loop:
		jsr	FindFreeObj.w
		beq.s	.ResetCounter

.MakeRings:
		move.l	#ObjLostRing,_objAddress(a1)
		move.w	_objXPos(a0),_objXPos(a1)
		move.w	_objYPos(a0),_objYPos(a1)
		move.l	#Map_ObjLostRing,_objMapping(a1)	; Mappings
		move.w	#$26B4,_objVRAM(a1)		; Tile properties
		move.b	#4,_objRender(a1)			; Render flags
	displaySprite	3,a1,a2,0			; Priority
		move.b	#8,_objDrawW(a1)			; Sprite width
		move.b	#8,_objDrawH(a1)			; Sprite height
		move.b	#8,_objColW(a1)			; Collision width
		move.b	#8,_objColH(a1)			; Collision height
		move.w	(a3)+,_objXVel(a1)
		move.w	(a3)+,_objYVel(a1)
		dbf	d5,.Loop
		move.b	#-1,ringLossAnimT.w

.ResetCounter:
		clr.w	ringCount.w
		move.b	#1,hudUpdateRings.w
		;playsnd	#sRingLoss, 2
		move.b	#SndID_RingSpill,d0
		jsr	SOUND_PlaySFX
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjLostRing:
		jsr	ObjectMove.w
		addi.w	#$18,_objYVel(a0)
		bmi.s	.ChkCol
		moveq	#0,d0
		and.b	(frameCounter+3).w,d0
		lsl.w	#5,d0
		add.w	a0,d0
		andi.w	#$60,d0
		bne.s	.ChkCol
		jsr	ObjCheckFloorDist
		tst.w	d1
		bpl.s	.ChkCol
		add.w	d1,_objYPos(a0)
		move.w	_objYVel(a0),d0
		asr.w	#2,d0
		sub.w	d0,_objYVel(a0)
		neg.w	_objYVel(a0)

.ChkCol:
		lea	.RangeData(pc),a1		; Range data
		movea.w	playerPtrP1.w,a2		; Player object
		jsr	CheckObjInRange.w		; Is the player in range?
		tst.w	d0				; ''
		beq.s	.ChkDel				; If not, branch
		cmpi.b	#105,_objInvulTime(a2)
		bhs.s	.ChkDel
		bra.s	ObjLostRing_Collect

.ChkDel:
		tst.b	ringLossAnimT.w
		beq.w	ObjLostRing_Delete
		move.w	maxCamYPos.w,d0		; Get max camera Y position
		addi.w	#224,d0				; Get bottom boundary position
		cmp.w	_objYPos(a0),d0			; Have we touched the bottom boundary?
		blt.s	ObjLostRing_Delete		; If so, branch
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.RangeData:
		dc.w	-$10, $20
		dc.w	-$10, $20
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjLostRing_Collect:
	removeSprite	a0,a1,0
	displaySprite	1,a0,a1,0
		jsr	CollectRing
		move.l	#ObjLostRing_Sparkle,(a0)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjLostRing_Sparkle:
		lea	Ani_ObjRing,a1
		jsr	AnimateObject.w
		tst.b	_objRoutine(a0)
		bne.s	ObjLostRing_Delete
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjLostRing_Delete:
		jsr	DeleteObject.w
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Ring Spawn Array
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjLostRing_Speeds:
		dc.w	$FF3C,$FC14,$00C4,$FC14,$FDC8,$FCB0,$0238,$FCB0
		dc.w	$FCB0,$FDC8,$0350,$FDC8,$FC14,$FF3C,$03EC,$FF3C
		dc.w	$FC14,$00C4,$03EC,$00C4,$FCB0,$0238,$0350,$0238
		dc.w	$FDC8,$0350,$0238,$0350,$FF3C,$03EC,$00C4,$03EC
		dc.w	$FF9E,$FE0A,$0062,$FE0A,$FEE4,$FE58,$011C,$FE58
		dc.w	$FE58,$FEE4,$01A8,$FEE4,$FE0A,$FF9E,$01F6,$FF9E
		dc.w	$FE0A,$0062,$01F6,$0062,$FE58,$011C,$01A8,$011C
		dc.w	$FEE4,$01A8,$011C,$01A8,$FF9E,$01F6,$0062,$01F6
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Map_ObjLostRing:
		include	"Objects/Ring/Mappings.asm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Ani_ObjRing:
		dc.w	.Ani0-Ani_ObjRing
.Ani0:		dc.b	5, 1, 2, 3, 4, $FC
		even
; =========================================================================================================================================================