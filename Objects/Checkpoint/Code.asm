; =========================================================================================================================================================
; Checkpoint object
; =========================================================================================================================================================
		rsset	_objLvlSSTs
_objDongleX	rs.w	1				; Ball dongle X
_objDongleY	rs.w	1				; Ball dongle Y
_objDongleTime	rs.w	1				; Ball dongle timer
_objDonglePar	rs.w	1				; Ball dongle parent
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjCheckpoint:
		moveq	#0,d0
		move.b	_objRoutine(a0),d0			; Get routine ID
		jsr	.Index(pc,d0.w)			; Jump to it
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Index:
		bra.w	ObjChkpoint_Init
		bra.w	ObjChkpoint_Main
		bra.w	ObjChkpoint_Animate
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjChkpoint_Init:
		addq.b	#4,_objRoutine(a0)			; Next routine
		
		move.l	#Map_ObjChkpoint,_objMapping(a0)	; Mappings
		move.w	#$57E,_objVRAM(a0)			; Tile properties
		move.b	#4,_objRender(a0)			; Render flags
		move.b	#8,_objDrawW(a0)			; Sprite width
		move.b	#$20,_objDrawH(a0)			; Sprite height
	displaySprite	5,a0,a1,0			; Priority
		
		move.w	_objRespawn(a0),d0			; Get respawn table address
		movea.w	d0,a2				; ''
		btst	#0,(a2)				; Is it already set?
		bne.s	.AlreadySet			; If so, branch

		move.b	_objSubtype(a0),d1			; Get checkpoint ID
		cmp.b	chkIDLast.w,d1		; Has a later checkpoint already been hit?
		bgt.s	ObjChkpoint_Main		; If not, branch

.AlreadySet:
		bset	#0,(a2)				; Mark as set
		move.b	#2,_objAnim(a0)			; ''
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjChkpoint_Main:
		tst.b	debugMode.w			; Are we in debug placement mode?
		bne.w	ObjChkpoint_Animate		; If so, branch
		
		movea.w	playerPtrP1.w,a1		; Player object
		move.b	chkIDLast.w,d1		; Get last checkpoint hit
		cmp.b	_objSubtype(a0),d1			; Has a later checkpoint already been hit?
		bhs.w	.ChkSetAnim			; If so, branch

		move.w	_objXPos(a1),d0			; Get player's X position
		sub.w	_objXPos(a0),d0			; Get delta X from current position
		addq.w	#8,d0				; Add 8
		cmpi.w	#$10,d0				; Is the player within horizontal boundaries?
		bcc.w	ObjChkpoint_Animate		; If not, branch
		move.w	_objYPos(a1),d0			; Get player's Y position
		sub.w	_objYPos(a0),d0			; Get delta Y from current position
		addi.w	#$40,d0				; Add $40
		cmpi.w	#$68,d0				; Is the player within vertical boundaries?
		bcc.w	ObjChkpoint_Animate		; If not, branch
		
		;playsnd	#sCheckpoint, 2			; Play checkpoint sound
			move.b	#SndID_Checkpoint,d0
		jsr	SOUND_PlaySFX

		jsr	FindFreeObj.w			; Find a free object slot
		beq.s	.SetPoint			; If there is none, branch
		move.l	#ObjChkPoint_Dongle,_objAddress(a1)	; Load the checkpoint ball dongle object
		move.w	_objXPos(a0),_objDongleX(a1)		; Dongle X
		move.w	_objYPos(a0),_objDongleY(a1)		; Dongle Y
		subi.w	#$14,_objDongleY(a1)		; ''
		move.l	_objMapping(a0),_objMapping(a1)		; Mappings
		move.w	_objVRAM(a0),_objVRAM(a1)		; Tile properties
		move.b	#4,_objRender(a1)			; Render flags
		move.b	#8,_objDrawW(a1)			; Sprite width
		move.b	#8,_objDrawH(a1)			; Sprite height
	displaySprite	4,a1,a2,0			; Priority
		move.b	#2,_objFrame(a1)			; Map frame
		move.w	#$20,_objDongleTime(a1)		; Dongle timer
		move.w	a0,_objDonglePar(a1)		; Dongle parent

.SetPoint:
		move.w	_objRespawn(a0),d0			; Get respawn table address
		movea.w	d0,a2				; ''
		bset	#0,(a2)				; Mark as set
		
		move.b	#1,_objAnim(a0)			; Use dongling animation
		move.b	_objSubtype(a0),chkIDLast.w	; Set checkpoint ID

		addq.b	#4,_objRoutine(a0)
		pea	ObjChkpoint_Animate		; Animate
		jmp	Level_SaveInfo			; Save data
		
.ChkSetAnim:
		addq.b	#4,_objRoutine(a0)
		tst.b	_objAnim(a0)			; Are we still unset?
		bne.s	ObjChkpoint_Animate		; If not, branch
		move.b	#2,_objAnim(a0)			; Use the set animation
; ---------------------------------------------------------------------------------------------------------------------------------------------------------		
ObjChkpoint_Animate:
		lea	Ani_ObjChkpoint,a1		; Animate
		jsr	AnimateObject.w			; ''
		jmp	CheckObjActive.w		; Display
; ---------------------------------------------------------------------------------------------------------------------------------------------------------		
; Ball dongle object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------		
ObjChkPoint_Dongle:
		subq.w	#1,_objDongleTime(a0)		; Decrement timer
		bpl.s	.MoveDongle			; If it hasn't run out, branch
		movea.w	_objDonglePar(a0),a1		; Get parent
		move.b	#2,_objAnim(a1)			; Set set animation for parent
		clr.b	_objFrame(a1)			; Reset map frame for parent
		jsr	DeleteObject.w			; Delete ourselves
	nextObject

.MoveDongle:
		move.b	_objAngle(a0),d0			; Get angle
		subi.b	#$10,_objAngle(a0)			; Decrement angle
		subi.b	#$40,d0				; Subtract $40
		jsr	MATH_GetSinCos.w			; Get sine and cosine
		muls.w	#$C00,d1			; Multiply cosine with $C00
		swap	d1				; Get high word
		add.w	_objDongleX(a0),d1			; Add dongle X
		move.w	d1,_objXPos(a0)			; Set actual X
		muls.w	#$C00,d0			; Multiply sine with $C00
		swap	d0				; Get high word
		add.w	_objDongleY(a0),d0			; Add dongle X
		move.w	d0,_objYPos(a0)			; Set actual X
		jsr	CheckObjActive.w		; Display
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Ani_ObjChkpoint:
		dc.w	.Ani0-Ani_ObjChkpoint
		dc.w	.Ani1-Ani_ObjChkpoint
		dc.w	.Ani2-Ani_ObjChkpoint
.Ani0:		dc.b	$F, 0, $FF
		even
.Ani1:		dc.b	$F, 1, $FF
		even
.Ani2:		dc.b	3, 0, 4, $FF
		even
Map_ObjChkpoint:
		include	"Objects/Checkpoint/Mappings.asm"
; =========================================================================================================================================================