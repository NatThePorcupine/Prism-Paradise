; =========================================================================================================================================================
; Spring object
; =========================================================================================================================================================
		rsset	_objLvlSSTs
_objSprSpd		rs.w	1				; Spring strength
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjSpring:
		move.l	#Map_ObjSpring,_objMapping(a0)		; Mappings
		move.w	#$5BA,_objVRAM(a0)			; Tile properties
		ori.b	#4,_objRender(a0)			; Render flags
		move.b	#$10,_objDrawW(a0)			; Sprite width
		move.b	#8,_objDrawH(a0)			; Sprite height
		move.b	#$1C/2,_objColW(a0)		; Collision width
	displaySprite	4,a0,a1,0			; Priority
		
		move.b	_objSubtype(a0),d0			; Get subtype
		lsr.w	#3,d0				; Turn into offset
		andi.w	#$E,d0				; ''
		jmp	.Subtypes(pc,d0.w)		; Jump to it
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Subtypes:
		bra.s .Init_Up				; Up
		bra.s .Init_Horizontal			; Horizontal
		bra.s .Init_Down			; Down
		bra.s .Init_DiagonallyUp		; Diagonally up
		bra.s .Init_DiagonallyDown		; Diagonally down
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Init_Horizontal:
		move.b	#2,_objAnim(a0)			; Animation
		move.b	#2,_objFrame(a0)			; Mapping frame
		move.w	#$5CA,_objVRAM(a0)			; Tile properties
		move.b	#8,_objDrawW(a0)			; Sprite width
		move.b	#$10,_objDrawH(a0)			; Sprite height
		move.b	#$1C/2,_objColW(a0)		; Collision width
		move.l	#ObjSpring_Horizontal,_objAddress(a0)	; Next routine
		bra.s	.Init_Common			; Continue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Init_Down:
		bset	#1,_objStatus(a0)			; Flip vertically
		move.l	#ObjSpring_Down,_objAddress(a0)	; Next routine
		bra.s	.Init_Common			; Continue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Init_DiagonallyUp:
		move.b	#4,_objAnim(a0)			; Animation
		move.b	#4,_objFrame(a0)			; Map frame
		move.w	#$5D9,_objVRAM(a0)			; Tile properties
		move.l	#ObjSpring_DiagonallyUp,_objAddress(a0); Next routine
		bra.s	.Init_Common			; Continue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Init_DiagonallyDown:
		move.b	#4,_objAnim(a0)			; Animation
		move.b	#6,_objFrame(a0)			; Map frame
		move.w	#$5D9,_objVRAM(a0)			; Tile properties
		bset	#1,_objStatus(a0)			; Flip vertically
		move.l	#ObjSpring_DiagonallyDown,_objAddress(a0); Next routine
		bra.s	.Init_Common			; Continue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Init_Up:
		move.l	#ObjSpring_Up,_objAddress(a0)		; Next routine

.Init_Common:
		move.b	_objSubtype(a0),d0			; Get subtype
		andi.w	#2,d0				; Turn into offset
		move.w	.Strengths(pc,d0.w),_objSprSpd(a0)	; Get spring strength
		btst	#1,d0				; Is the spring supposed to be yellow?
		beq.s	.NotYellow			; If not, branch
		bset	#5,_objVRAM(a0)			; Make the spring yellow

.NotYellow:
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Strengths:
		dc.w	-$1000				; Strength of red spring
		dc.w	-$A00				; Strength of yellow spring
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjSpring_Up:
		move.w	#27-1,d1			; Width
		move.w	#16/2,d2			; Height
		move.w	d2,d3				; ''
		move.w	_objXPos(a0),d4			; X position
		jsr	SolidObject_Always		; Set object as solid
		btst	#cStandBit,_objStatus(a0)		; Has the player touched the top of the of spring?
		beq.s	.Display			; If not, branch
		bsr.s	.Bounce				; Bounce the player up

.Display:
		lea	Ani_ObjSpring(pc),a1		; Animate sprite
		jsr	AnimateObject.w			; ''
		jsr	CheckObjActive.w		; Display sprite
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Bounce:
		move.w	#$100,_objAnim(a0)			; Reset animation
		addq.w	#8,_objYPos(a1)			; Align player to spring
		move.w	_objSprSpd(a0),_objYVel(a1)		; Set the player's Y velocity
		bset	#1,_objStatus(a1)			; Set the player's "in air" flag
		bclr	#cStandBit,_objStatus(a1)		; Make the player no longer be on the spring
		clr.b	_objJumping(a1)			; Clear the player's jump flag
		move.b	#$10,_objAnim(a1)			; Set the player's animation to the spring animation
		move.b	#4,_objRoutine(a1)			; Reset the player's routine
		
		move.b	_objSubtype(a0),d0			; Get subtype
		bpl.s	.ChkPath1			; Branch if the player can still move horizontally
		clr.w	_objXVel(a1)			; Stop the player's X movement

.ChkPath1:
		andi.b	#$C,d0				; Only get path swap bits
		cmpi.b	#4,d0				; Does the player need to switch to path 1?
		bne.s	.ChkPath2			; If not, branch
		move.b	#$C,_objTopSolid(a1)		; Switch to path 1
		move.b	#$D,_objLRBSolid(a1)		; ''

.ChkPath2:
		cmpi.b	#8,d0				; Does the player need to switch to path 2?
		bne.s	.PlaySound			; If not, branch
		move.b	#$E,_objTopSolid(a1)		; Switch to path 2
		move.b	#$F,_objLRBSolid(a1)		; ''

.PlaySound:
		;playsnd	#sSpring, 2			; Play spring sound
		move.b	#SndID_Spring,d0
		jmp	SOUND_PlaySFX
		;rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjSpring_Horizontal:
		move.w	#20-1,d1			; Width
		move.w	#28/2,d2			; Height
		move.w	d2,d3				; ''
		move.w	_objXPos(a0),d4			; X position
		jsr	SolidObject_Always		; Set object as solid
		btst	#cTouchSideBit,d6		; Has the player touched the side of the spring?
		beq.s	.Display			; If not, branch
		move.b	_objStatus(a0),d1			; Get status
		move.w	_objXPos(a0),d0			; Get which side of the spring the player is facing
		sub.w	_objXPos(a1),d0			; ''
		bcs.s	.NoFlip				; If the player is on the left side of the spring, branch
		eori.b	#1,d1				; Flip so that we check for the other side of the spring

.NoFlip:
		andi.b	#1,d1				; Is the player touching the bouncy side of the spring?
		bne.s	.Display			; If not, branch
		bsr.s	.Bounce				; Bounce the player

.Display:
		lea	Ani_ObjSpring(pc),a1		; Animate sprite
		jsr	AnimateObject.w			; ''
		jsr	CheckObjActive.w		; Display sprite
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Bounce:	
		move.w	#$300,_objAnim(a0)			; Reset animation
		addq.w	#8,_objXPos(a1)			; Align player to spring
		move.w	_objSprSpd(a0),_objXVel(a1)		; Set the player's X velocity
		bset	#0,_objStatus(a1)			; Make the player face the left
		btst	#0,_objStatus(a0)			; Is this spring facing the left?
		bne.s	.SetMoveLock			; If so, branch
		bclr	#0,_objStatus(a1)			; Make the player face the right
		subi.w	#$10,_objXPos(a1)			; Align player to spring
		neg.w	_objXVel(a1)			; Move the player to the right

.SetMoveLock:
		move.b	#$F,_objMoveLock(a1)		; Lock the player's movement for a bit
		move.w	_objXVel(a1),_objGVel(a1)		; Set the player's ground velocity
		
		btst	#2,_objStatus(a1)			; Is the player jumping?
		bne.s	.ChkYStop			; If so, branch
		clr.b	_objAnim(a1)			; Set the animation to the walking animation
		
.ChkYStop:
		move.b	_objSubtype(a0),d0			; Get subtype
		bpl.s	.ChkPath1			; Branch if the player can still move vertically
		clr.w	_objXVel(a1)			; Stop the player's Y movement

.ChkPath1:
		andi.b	#$C,d0				; Only get path swap bits
		cmpi.b	#4,d0				; Does the player need to switch to path 1?
		bne.s	.ChkPath2			; If not, branch
		move.b	#$C,_objTopSolid(a1)		; Switch to path 1
		move.b	#$D,_objLRBSolid(a1)		; ''

.ChkPath2:
		cmpi.b	#8,d0				; Does the player need to switch to path 2?
		bne.s	.PlaySound			; If not, branch
		move.b	#$E,_objTopSolid(a1)		; Switch to path 2
		move.b	#$F,_objLRBSolid(a1)		; ''

.PlaySound:
		bclr	#cPushBit,_objStatus(a0)		; Clear "push" flags
		bclr	#cPushBit,_objStatus(a1)		; ''
		;playsnd	#sSpring, 2			; Play spring sound
		move.b	#SndID_Spring,d0
		jmp	SOUND_PlaySFX
		;rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjSpring_Down:
		move.w	#19-1,d1			; Width
		move.w	#16/2,d2			; Height
		move.w	d2,d3				; ''
		move.w	_objXPos(a0),d4			; X position
		jsr	SolidObject_Always		; Set object as solid
		cmpi.w	#-2,d4				; Has the player touched the bottom of the spring?
		bne.s	.Display			; If not, branch
		bsr.s	.Bounce				; Bounce the player

.Display:
		lea	Ani_ObjSpring(pc),a1		; Animate sprite
		jsr	AnimateObject.w			; ''
		jsr	CheckObjActive.w		; Display sprite
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Bounce:
		move.w	#$100,_objAnim(a0)			; Reset animation
		subq.w	#8,_objYPos(a1)			; Align player with the spring
		move.w	_objSprSpd(a0),_objYVel(a1)		; Set the player's Y velocity
		neg.w	_objYVel(a1)			; Move the player down
		
		move.b	_objSubtype(a0),d0			; Get subtype
		bpl.s	.ChkPath1			; Branch if the player can still move horizontally
		clr.w	_objXVel(a1)			; Stop the player's X movement

.ChkPath1:
		andi.b	#$C,d0				; Only get path swap bits
		cmpi.b	#4,d0				; Does the player need to switch to path 1?
		bne.s	.ChkPath2			; If not, branch
		move.b	#$C,_objTopSolid(a1)		; Switch to path 1
		move.b	#$D,_objLRBSolid(a1)		; ''

.ChkPath2:
		cmpi.b	#8,d0				; Does the player need to switch to path 2?
		bne.s	.PlaySound			; If not, branch
		move.b	#$E,_objTopSolid(a1)		; Switch to path 2
		move.b	#$F,_objLRBSolid(a1)		; ''

.PlaySound:
		bset	#1,_objStatus(a1)			; Set the player's "in air" flag
		bclr	#cStandBit,_objStatus(a1)		; Make the player no longer be on the spring
		move.b	#4,_objRoutine(a1)			; Reset the player's routine
		;playsnd	#sSpring, 2			; Play spring sound
		move.b	#SndID_Spring,d0
		jmp	SOUND_PlaySFX
		;rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjSpring_DiagonallyUp:
		move.w	#26-1,d1			; Width
		move.w	#32/2,d2			; Height
		move.w	_objXPos(a0),d4			; X position
		lea	.SlopeData(pc),a2		; Slope Data
		jsr	SlopedSolid			; Set object as a solid slope
		
		btst	#cStandBit,_objStatus(a0)		; Has the player touched the spring?
		beq.s	.End				; If not, branch
		bsr.s	.Bounce				; Bounce the player

.End:
		lea	Ani_ObjSpring(pc),a1		; Animate sprite
		jsr	AnimateObject.w			; ''
		jsr	CheckObjActive.w		; Display sprite
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Bounce:
		btst	#0,_objStatus(a0)			; Is the spring facing left?
		bne.s	.FaceLeft			; If so, branch
		move.w	_objXPos(a0),d0			; Get X position
		subq.w	#4,d0				; Subtract 4
		cmp.w	_objXPos(a1),d0			; Is the player
		blo.s	.DoBounce
		rts

.FaceLeft:
		move.w	_objXPos(a0),d0
		addq.w	#4,d0
		cmp.w	_objXPos(a1),d0
		bhs.s	.DoBounce
		rts

.DoBounce:
		move.w	#$500,_objAnim(a0)
		move.w	_objSprSpd(a0),_objYVel(a1)
		move.w	_objSprSpd(a0),_objXVel(a1)
		addq.w	#6,_objYPos(a1)
		addq.w	#6,_objXPos(a1)
		bset	#0,_objStatus(a1)
		btst	#0,_objStatus(a0)
		bne.s	.SetAni
		bclr	#0,_objStatus(a1)
		subi.w	#$C,_objXPos(a1)
		neg.w	_objXVel(a1)

.SetAni:
		bset	#1,_objStatus(a1)
		bclr	#3,_objStatus(a1)
		move.b	#$10,_objAnim(a1)
		move.b	#4,_objRoutine(a1)

		move.b	_objSubtype(a0),d0
		andi.b	#$C,d0				; Only get path swap bits
		cmpi.b	#4,d0				; Does the player need to switch to path 1?
		bne.s	.ChkPath2			; If not, branch
		move.b	#$C,_objTopSolid(a1)		; Switch to path 1
		move.b	#$D,_objLRBSolid(a1)		; ''

.ChkPath2:
		cmpi.b	#8,d0				; Does the player need to switch to path 2?
		bne.s	.PlaySound			; If not, branch
		move.b	#$E,_objTopSolid(a1)		; Switch to path 2
		move.b	#$F,_objLRBSolid(a1)		; ''

.PlaySound:
		;playsnd	#sSpring, 2			; Play spring sound
		move.b	#SndID_Spring,d0
		jmp	SOUND_PlaySFX
		;rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.SlopeData:
		dc.b	$10, $10, $10, $10, $10, $10, $10
		dc.b	$10, $10, $10, $10, $10, $0E, $0C
		dc.b	$0A, $08, $06, $04, $02, $00, $FE
		dc.b	$FC, $FC, $FC, $FC, $FC, $FC, $FC
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjSpring_DiagonallyDown:
		move.w	#26-1,d1			; Width
		move.w	#32/2,d2
		move.w	_objXPos(a0),d4
		lea	.SlopeData(pc),a2
		jsr	SlopedSolid			; Set object as a solid slope
		cmpi.w	#-2,d4				; Has the player touched the spring?
		bne.s	.End				; If not, branch
		bsr.s	.Bounce				; Bounce the player

.End:
		lea	Ani_ObjSpring(pc),a1		; Animate sprite
		jsr	AnimateObject.w			; ''
		jsr	CheckObjActive.w		; Display sprite
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.Bounce:
		move.w	#$500,_objAnim(a0)
		move.w	_objSprSpd(a0),_objYVel(a1)
		neg.w	_objYVel(a1)
		move.w	_objSprSpd(a0),_objXVel(a1)
		addq.w	#6,_objYPos(a1)
		addq.w	#6,_objXPos(a1)
		bset	#0,_objStatus(a1)
		btst	#0,_objStatus(a0)
		bne.s	.SetAni
		bclr	#0,_objStatus(a1)
		subi.w	#$C,_objXPos(a1)
		neg.w	_objXVel(a1)

.SetAni:
		bset	#1,_objStatus(a1)
		bclr	#3,_objStatus(a1)
		move.b	#4,_objRoutine(a1)

		move.b	_objSubtype(a0),d0
		andi.b	#$C,d0				; Only get path swap bits
		cmpi.b	#4,d0				; Does the player need to switch to path 1?
		bne.s	.ChkPath2			; If not, branch
		move.b	#$C,_objTopSolid(a1)		; Switch to path 1
		move.b	#$D,_objLRBSolid(a1)		; ''

.ChkPath2:
		cmpi.b	#8,d0				; Does the player need to switch to path 2?
		bne.s	.PlaySound			; If not, branch
		move.b	#$E,_objTopSolid(a1)		; Switch to path 2
		move.b	#$F,_objLRBSolid(a1)		; ''

.PlaySound:
		;playsnd	#sSpring, 2			; Play spring sound
		move.b	#SndID_Spring,d0
		jmp	SOUND_PlaySFX
		;rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.SlopeData:
		dc.b	$F4, $F0, $F0, $F0, $F0, $F0, $F0
		dc.b	$F0, $F0, $F0, $F0, $F0, $F2, $F4
		dc.b	$F6, $F8, $FA, $FC, $FE, $00, $02
		dc.b	$04, $04, $04, $04, $04, $04, $04
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Ani_ObjSpring:
		include	"Objects/Spring/Animations.asm"
Map_ObjSpring:
		include	"Objects/Spring/Mappings.asm"
; =========================================================================================================================================================