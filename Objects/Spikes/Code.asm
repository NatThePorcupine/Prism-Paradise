; ===========================================================================
; Spike object
; ===========================================================================
		rsset	_objLvlSSTs
_objSpikeX	rs.w	1
_objSpikeY	rs.w	1
_objSpkMvOff	rs.w	1
_objSpkMvState	rs.w	1
_objSpkMvTime	rs.w	1
; ===========================================================================
ObjSpike:
		moveq	#0,d0
		move.b	_objRoutine(a0),d0
		jsr	ObjSpike_Index(pc,d0.w)
	nextObject
; ===========================================================================
ObjSpike_Index:
		bra.w ObjSpike_Init
		bra.w ObjSpike_Upright
		bra.w ObjSpike_Sideways
		bra.w ObjSpike_UpsideDown
; ===========================================================================
;ObjSpike_InitData:
;		dc.b $10,$10	; 0	- Upright or ceiling spikes
;		dc.b $10,$10	; 2	- Sideways spikes
; ===========================================================================
ObjSpike_Init:
		addq.b	#4,_objRoutine(a0)
		move.l	#Map_ObjSpike,_objMapping(a0)
		move.w	#$6A8,_objVRAM(a0)
		ori.b	#4,_objRender(a0)
	displaySprite	4,a0,a1,0			; Priority
		move.b	_objSubtype(a0),d0
		andi.b	#$F,_objSubtype(a0)
		andi.w	#$F0,d0
		moveq	#$10,d1
		move.b	d1,_objDrawW(a0)
		move.b	d1,_objColW(a0)
		move.b	d1,_objDrawH(a0)
		move.b	d1,_objColH(a0)
		lsr.w	#4,d0
		move.b	d0,_objFrame(a0)
		cmpi.b	#1,d0
		bne.s	.ChkUpsideDown
		addq.b	#4,_objRoutine(a0)
		move.w	#$6AC,_objVRAM(a0)

.ChkUpsideDown:
		btst	#1,_objStatus(a0)
		beq.s	.SavePos
		move.b	#$C,_objRoutine(a0)

.SavePos:
		move.w	_objXPos(a0),_objSpikeX(a0)
		move.w	_objYPos(a0),_objSpikeY(a0)

		bsr.w	MoveSpikes		; make the object move
		cmpi.b	#1,_objFrame(a0)		; is object type $1x ?
		beq.s	ObjSpike_SideWays	; if yes, branch
; ===========================================================================
; Upright spikes
; ===========================================================================
ObjSpike_Upright:
		bsr.w	MoveSpikes
		moveq	#0,d1
		move.b	_objDrawW(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	_objDrawH(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	_objXPos(a0),d4
		jsr	SolidObject
		btst	#cStandBit,_objStatus(a0)
		beq.s	ObjSpike_UprightEnd
		movea.w	playerPtrP1.w,a1
		bsr.w	Touch_ChkHurt2

ObjSpike_UprightEnd:
		move.w	_objSpikeX(a0),d0
		jmp	CheckObjActive.w
; ===========================================================================
; Sideways spikes
; ===========================================================================
ObjSpike_Sideways:
		move.w	_objXPos(a0),-(sp)	
		bsr.w	MoveSpikes
		moveq	#0,d1
		move.b	_objDrawW(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	_objDrawH(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	(sp)+,d4
		jsr	SolidObject
		btst	#cTouchSideBit,d6
		beq.s	ObjSpike_SidewaysEnd
		movea.w	playerPtrP1.w,a1
		bsr.w	Touch_ChkHurt2

ObjSpike_SidewaysEnd:
		move.w	_objSpikeX(a0),d0
		jmp	CheckObjActive.w
; ===========================================================================
; Upside down spikes
; ===========================================================================
ObjSpike_UpsideDown:
		bsr.w	MoveSpikes
		moveq	#0,d1
		move.b	_objDrawW(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	_objDrawH(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	_objXPos(a0),d4
		jsr	SolidObject
		btst	#cTouchBtmBit,d6
		beq.s	ObjSpike_UpsideDownEnd
		movea.w	playerPtrP1.w,a1
		bsr.w	Touch_ChkHurt2

ObjSpike_UpsideDownEnd:
		move.w	_objSpikeX(a0),d0
		jmp	CheckObjActive.w
; ===========================================================================
Touch_ChkHurt2:
		tst.b	_objInvulTime(a1)			; is Sonic invincible?
		bne.s	.End				; if yes, branch
		cmpi.b	#8,_objRoutine(a1)
		beq.s	.End
		move.l	_objYPos(a1),d3
		move.w	_objYVel(a1),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,_objYPos(a1)
		movea.l	a0,a2
		movea.l	a1,a0
		jsr	ObjPlayer_GetHurt
		movea.l	a2,a0

.End:
		rts
; ===========================================================================
MoveSpikes:	
		moveq	#0,d0
		move.b	_objSubtype(a0),d0
		add.w	d0,d0
		jmp	MoveSpikes_Behaviors(pc,d0.w)
; ===========================================================================
MoveSpikes_Behaviors:
		bra.s MoveSpikes_Still
		bra.s MoveSpikes_Vertical
		bra.s MoveSpikes_Horizontal
; ===========================================================================
MoveSpikes_Still:
		rts			; don't move the object
; ===========================================================================
MoveSpikes_Vertical:
		bsr.w	MoveSpikes_Delay
		moveq	#0,d0
		move.b	_objSpkMvOff(a0),d0
		add.w	_objSpikeY(a0),d0
		move.w	d0,_objYPos(a0)	; move the object vertically
		rts
; ===========================================================================
MoveSpikes_Horizontal:
		bsr.w	MoveSpikes_Delay
		moveq	#0,d0
		move.b	_objSpkMvOff(a0),d0
		add.w	_objSpikeX(a0),d0
		move.w	d0,_objXPos(a0)	; move the object horizontally
		rts
; ===========================================================================
MoveSpikes_Delay:
		tst.w	_objSpkMvTime(a0)		; is time delay	= zero?
		beq.s	MoveSpikes_ChkDir		; if yes, branch
		subq.w	#1,_objSpkMvTime(a0)	; subtract 1 from time delay
		bne.s	locret_CFE6
		tst.b	_objRender(a0)
		bpl.s	locret_CFE6
		;playsnd	#sSpikeMove, 2		; Play spike move sound
		move.b	#SndID_SpikesMove,d0
		jsr	SOUND_PlaySFX
		
		bra.s	locret_CFE6
; ===========================================================================
MoveSpikes_ChkDir:
		tst.w	_objSpkMvState(a0)
		beq.s	MoveSpikes_Retract
		subi.w	#$800,_objSpkMvOff(a0)
		bcc.s	locret_CFE6
		move.w	#0,_objSpkMvOff(a0)
		move.w	#0,_objSpkMvState(a0)
		move.w	#60,_objSpkMvTime(a0)	; set time delay to 1 second
		bra.s	locret_CFE6
; ===========================================================================
MoveSpikes_Retract:
		addi.w	#$800,_objSpkMvOff(a0)
		cmpi.w	#$2000,_objSpkMvOff(a0)
		bcs.s	locret_CFE6
		move.w	#$2000,_objSpkMvOff(a0)
		move.w	#1,_objSpkMvState(a0)
		move.w	#60,_objSpkMvTime(a0)	; set time delay to 1 second

locret_CFE6:
		rts
; ===========================================================================
; Spike object mappings
; ===========================================================================
Map_ObjSpike:
	include "Objects/Spikes/Mappings.asm"
; ===========================================================================