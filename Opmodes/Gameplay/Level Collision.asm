; =========================================================================================================================================================
; Level collision functions
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Check if a player object has touched any level collision
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerChkCollision:
		move.l	primaryColPtr.w,currentColAddr.w	; Get primary collision address
		cmpi.b	#$C,_objTopSolid(a0)		; Are we on the primary path?
		beq.s	.NotPrimary			; If not, branch
		move.l	secondaryColPtr.w,currentColAddr.w	; Get secondary collision address

.NotPrimary:
		move.b	_objLRBSolid(a0),d5		; Get LRB solid bits
		
		move.w	_objXVel(a0),d1			; Get X velocity
		move.w	_objYVel(a0),d2			; Get Y velocity
		jsr	MATH_GetArctan.w			; Get the angle
		subi.b	#$20,d0				; Shift it over
		andi.b	#$C0,d0				; Get the quadrant
		cmpi.b	#$40,d0				; Are we hitting a left wall?
		beq.w	PlayerHitLWall			; If so, branch
		cmpi.b	#$80,d0				; Are we hitting a ceiling?
		beq.w	PlayerHitCeilAndWalls		; If so, branch
		cmpi.b	#$C0,d0				; Are we hitting a right wall?
		beq.w	PlayerHitRWall			; If so, branch
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerHitFloorAndWalls:
		bsr.w	PlayerChkLeftWallDist		; Get left wall distance
		tst.w	d1				; Have we hit the wall?
		bpl.s	.NoLeftHit			; If not, branch
		sub.w	d1,_objXPos(a0)			; Move out of the wall
		clr.w	_objXVel(a0)			; Stop moving

.NoLeftHit:
		bsr.w	PlayerChkRightWallDist		; Get right wall distance
		tst.w	d1				; Have we hit the wall?
		bpl.s	.NoRightHit			; If not, branch
		add.w	d1,_objXPos(a0)			; Move out of the wall
		clr.w	_objXVel(a0)			; Stop moving

.NoRightHit:
		bsr.w	PlayerChkFloor			; Get floor distance
		tst.w	d1				; Have we hit the floor?
		bpl.s	.End				; If not, branch

		move.b	_objYVel(a0),d2			; Get the integer part of the Y velocity
		addq.b	#8,d2				; Get the max distance we have to have from the floor in order to collide with it
		neg.b	d2				; Negate it since we are in the floor
		cmp.b	d2,d1				; Is the chosen primary distance small enough?
		bge.s	.TouchFloor			; If so, branch
		cmp.b	d2,d0				; What about the other angle that was found?
		blt.s	.End				; If not, branch

.TouchFloor:
		move.b	d3,_objAngle(a0)			; Set the angle
		add.w	d1,_objYPos(a0)			; Move out of the floor
		move.b	d3,d0				; Copy angle
		addi.b	#$20,d0				; Shift it
		andi.b	#$40,d0				; Are we on a wall?
		bne.s	.HitWall			; If so, branch
		move.b	d3,d0				; Copy angle
		addi.b	#$10,d0				; Shift it
		andi.b	#$20,d0				; Are we on a slope?
		beq.s	.HitFloor			; If not, branch
		asr	_objYVel(a0)			; Divide the Y velocity by 2
		bra.s	.HitSlope			; Continue

.HitFloor:
		clr.w	_objYVel(a0)			; Stop Y movement
		move.w	_objXVel(a0),_objGVel(a0)		; Set ground velocity
		bra.w	PlayerResetOnFloor		; Reset status on floor

.HitWall:
		clr.w	_objXVel(a0)			; Stop X movement
		cmpi.w	#$FC0,_objYVel(a0)			; Cap the Y velocity at $FC0
		ble.s	.HitSlope			; ''
		move.w	#$FC0,_objYVel(a0)			; ''

.HitSlope:
		bsr.w	PlayerResetOnFloor		; Reset status on floor
		move.w	_objYVel(a0),_objGVel(a0)		; Set ground velocity
		tst.b	d3				; Have we touched a right side angle ($80-$FF)?
		bpl.s	.End				; If so, branch
		neg.w	_objGVel(a0)			; Negate the ground velocity

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerHitLWall:
		bsr.w	PlayerChkLeftWallDist		; Get left wall distance
		tst.w	d1				; Have we hit the wall?
		bpl.s	.ChkCeil			; If not, branch
		sub.w	d1,_objXPos(a0)			; Move out of the wall
		clr.w	_objXVel(a0)			; Stop moving
		move.w	_objYVel(a0),_objGVel(a0)		; Set ground velocity

.ChkCeil:
		bsr.w	PlayerChkCeiling		; Get ceiling distance
		tst.w	d1				; Have we hit the ceiling?
		bpl.s	.ChkFloor			; If not, branch
		neg.w	d1				; Get the distance inside the ceiling
		cmpi.w	#$14,d1				; Are we too far into the ceiling?
		bhs.s	.ChkRightWall			; If so, branch
		add.w	d1,_objYPos(a0)			; Move out of the ceiling
		tst.w	_objYVel(a0)			; Are we moving up?
		bpl.s	.End				; If not, branch
		clr.w	_objYVel(a0)			; Stop Y movement

.End:
		rts

.ChkRightWall:
		bsr.w	PlayerChkRightWallDist		; Get right wall distance
		tst.w	d1				; Have we hit the wall?
		bpl.s	.End2				; If not, branch
		add.w	d1,_objXPos(a0)			; Move out of the wall
		clr.w	_objXVel(a0)			; Stop moving
		
.End2:
		rts

.ChkFloor:
		tst.w	_objYVel(a0)			; Are we moving up?
		bmi.s	.End3				; If so, branch
		bsr.w	PlayerChkFloor			; Get floor distance
		tst.w	d1				; Have we hit the ceiling?
		bpl.s	.End3				; If not, branch
		add.w	d1,_objYPos(a0)			; Move out of the ceiling
		move.b	d3,_objAngle(a0)			; Set angle
		clr.w	_objYVel(a0)			; Stop Y movement
		move.w	_objXVel(a0),_objGVel(a0)		; Set ground velocity
		bra.w	PlayerResetOnFloor		; Reset status on floor
		
.End3:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerHitCeilAndWalls:
		bsr.w	PlayerChkLeftWallDist		; Get left wall distance
		tst.w	d1				; Have we hit the wall?
		bpl.s	.NoLeftHit			; If not, branch
		sub.w	d1,_objXPos(a0)			; Move out of the wall
		clr.w	_objXVel(a0)			; Stop moving

.NoLeftHit:
		bsr.w	PlayerChkRightWallDist		; Get right wall distance
		tst.w	d1				; Have we hit the wall?
		bpl.s	.NoRightHit			; If not, branch
		add.w	d1,_objXPos(a0)			; Move out of the wall
		clr.w	_objXVel(a0)			; Stop moving

.NoRightHit:
		bsr.w	PlayerChkCeiling		; Get ceiling distance
		tst.w	d1				; Have we hit the floor?
		bpl.s	.End				; If not, branch
		sub.w	d1,_objYPos(a0)			; Move out of ceiling
		move.b	d3,d0				; Get angle
		addi.b	#$20,d0				; Shift it
		andi.b	#$40,d0				; Are we on a wall?
		bne.s	.HitWall			; If so, branch
		clr.w	_objYVel(a0)			; Stop Y movement
		rts

.HitWall:
		move.b	d3,_objAngle(a0)			; Set angle
		bsr.w	PlayerResetOnFloor		; Reset status on floor
		move.w	_objYVel(a0),_objGVel(a0)		; Set ground velocity
		tst.b	d3				; Have we touched a right side angle ($80-$FF)?
		bpl.s	.End				; If so, branch
		neg.w	_objGVel(a0)			; Negate the ground velocity

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerHitRWall:
		bsr.w	PlayerChkRightWallDist		; Get right wall distance
		tst.w	d1				; Have we hit the wall?
		bpl.s	.ChkCeil			; If not, branch
		add.w	d1,_objXPos(a0)			; Move out of the wall
		clr.w	_objXVel(a0)			; Stop moving
		move.w	_objYVel(a0),_objGVel(a0)		; Set ground velocity

.ChkCeil:
		bsr.w	PlayerChkCeiling		; Get ceiling distance
		tst.w	d1				; Have we hit the ceiling?
		bpl.s	.ChkFloor			; If not, branch
		sub.w	d1,_objYPos(a0)			; Move out of the ceiling
		tst.w	_objYVel(a0)			; Are we moving up?
		bpl.s	.End				; If not, branch
		clr.w	_objYVel(a0)			; Stop Y movement

.End:
		rts

.ChkFloor:
		tst.w	_objYVel(a0)			; Are we moving up?
		bmi.s	.End2				; If so, branch
		bsr.w	PlayerChkFloor			; Get floor distance
		tst.w	d1				; Have we hit the ceiling?
		bpl.s	.End2				; If not, branch
		add.w	d1,_objYPos(a0)			; Move out of the ceiling
		move.b	d3,_objAngle(a0)			; Set angle
		clr.w	_objYVel(a0)			; Stop Y movement
		move.w	_objXVel(a0),_objGVel(a0)		; Set ground velocity
		bra.s	PlayerResetOnFloor		; Reset status on floor
		
.End2:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Reset a player object's status on the floor
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerResetOnFloor:
		tst.b	_objBallMode(a0)			; Are we in ball mode?
		bne.s	PlayerResetOnFloorPart3	; If so, branch
		clr.b	_objAnim(a0)			; Set walking animation
		
PlayerResetOnFloorPart2:
		btst	#2,_objStatus(a0)			; Was Sonic rolling?
		beq.s	PlayerResetOnFloorPart3	; If so, branch
		bclr	#2,_objStatus(a0)			; Clear roll flag
		move.b	_objInitColW(a0),_objColW(a0)		; Reset collision width
		move.b	_objInitColH(a0),_objColH(a0)		; Reset collision height
		clr.b	_objAnim(a0)			; Set walking animation
		subq.w	#5,_objYPos(a0)			; Align with floor

PlayerResetOnFloorPart3:
		andi.b	#$DD,_objStatus(a0)		; Clear "pushing", and "jumping" flag
		clr.b	_objJumping(a0)			; Clear jumping flag
		clr.b	_objFlipAngle(a0)			; Reset flip angle
		clr.b	_objFlipTurned(a0)			; Reset flip inverted flag
		clr.b	_objFlipRemain(a0)			; Reset flips remaining
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Calculate the room in front of a player object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerCalcRoomInFront:
		move.l	primaryColPtr.w,currentColAddr.w	; Get primary collision address
		cmpi.b	#$C,_objTopSolid(a0)		; Are we on the primary path?
		beq.s	.NotPrimary			; If not, branch
		move.l	secondaryColPtr.w,currentColAddr.w	; Get secondary collision address

.NotPrimary:
		move.b	_objLRBSolid(a0),d5		; Get LRB solid bits
		
		move.l	_objXPos(a0),d3			; Get X position
		move.l	_objYPos(a0),d2			; Get Y position
		move.w	_objXVel(a0),d1			; Get X velocity
		ext.l	d1				; ''
		asl.l	#8,d1				; Shift it
		add.l	d1,d3				; Add onto X position
		move.w	_objYVel(a0),d1			; Get Y velocity
		ext.l	d1				; ''
		asl.l	#8,d1				; Shift it
		add.l	d1,d2				; Add onto Y position
		swap	d2				; Get actual Y
		swap	d3				; Get actual X
		move.b	d0,_objNextTilt(a0)		; Set primary angle
		move.b	d0,_objTilt(a0)			; Set secondary angle
		move.b	d0,d1				; Copy angle
		btst	#6,d0				; Are we in quadrants 0 or $80? (use 5 instaead of 6 for 8 directions)
		beq.s	.DownUp				; If not, branch
		addq.b	#1,d0				; Shift the angle

.DownUp:
		addi.b	#$1F,d0				; Shift the angle (use $F instaead of $1F for 8 directions)
		andi.b	#$C0,d0				; Get quadrant
		beq.w	PlayerChkFloorDist_Part2	; If quadrant 0, get the floor distance
		cmpi.b	#$80,d0				; Are we in quadrant $80?
		beq.w	PlayerChkCeilingDist_Part2	; If so, branch
		andi.b	#$38,d1				; Are we on a flat enough surface?
		bne.s	.ChkWall			; If not, branch
		addq.w	#8,d2				; Add 8 to the Y position

.ChkWall:
		cmpi.b	#$40,d0				; Are we in quadrant $40?
		beq.w	PlayerChkLeftWallDist_Part2	; If so, branch
		bra.w	PlayerChkRightWallDist_Part2	; Get the right wall distance
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Calculate the room over a player object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerCalcRoomOverHead:
		move.l	primaryColPtr.w,currentColAddr.w	; Get primary collision address
		cmpi.b	#$C,_objTopSolid(a0)		; Are we on the primary path?
		beq.s	.NotPrimary			; If not, branch
		move.l	secondaryColPtr.w,currentColAddr.w	; Get secondary collision address

.NotPrimary:
		move.b	_objLRBSolid(a0),d5		; Get LRB solid bits
		move.b	d0,_objNextTilt(a0)		; Set primary angle
		move.b	d0,_objTilt(a0)			; Set secondary angle
		
		addi.b	#$20,d0				; Shift the angle
		andi.b	#$C0,d0				; Get quadrant
		cmpi.b	#$40,d0				; Are we in quadrant $40?
		beq.w	PlayerChkLeftCeilDist		; If so, branch
		cmpi.b	#$80,d0				; Are we in quadrant $80?
		beq.w	PlayerChkCeiling		; If so, branch
		cmpi.b	#$C0,d0				; Are we in quadrant $C0?
		beq.w	PlayerChkRightCeilDist		; If so, branch
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between the floor and a player object (with primary and secondary angles)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerChkFloor:
		move.l	primaryColPtr.w,currentColAddr.w	; Get primary collision address
		cmpi.b	#$C,_objTopSolid(a0)		; Are we on the primary path?
		beq.s	.NotPrimary			; If not, branch
		move.l	secondaryColPtr.w,currentColAddr.w	; Get secondary collision address

.NotPrimary:
		move.b	_objTopSolid(a0),d5		; Get top solid bits
		
		; Get the angle on the bottom right sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		add.w	d0,d2				; Add onto Y position
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		add.w	d0,d3				; Add onto X position
		lea	_objNextTilt(a0),a4		; Get primary angle
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; Don't switch any flip bits for blocks
		bsr.w	Level_FindFloor			; Find the floor
		push.w	d1				; Save the primary floor distance

		; Get the angle on the bottom left sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		add.w	d0,d2				; Add onto Y position
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		sub.w	d0,d3				; Subtract from X position
		lea	_objTilt(a0),a4			; Get secondary angle
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; Don't switch any flip bits for blocks
		bsr.w	Level_FindFloor			; Find the floor
		
		; Update the object's angle
		pop.w	d0				; Restore the primary floor distance
		clr.b	d2				; Angle value for when the object touched an odd angle (usually $FF)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerPickAngle:
		move.b	_objTilt(a0),d3			; Get secondary angle
		cmp.w	d0,d1				; Is the primary floor distance lower than the secondary?
		ble.s	.ChkSetAngle			; If not, branch
		move.b	_objNextTilt(a0),d3		; Get primary angle
		exg.l	d0,d1				; Switch floor distance values
		
.ChkSetAngle:
		btst	#0,d3				; Is this an odd angle (usually $FF)?
		beq.s	.End				; If not, branch
		move.b	d2,d3				; Set the new angle value
		
.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between the floor and the player object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerChkFloorDist:
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position

PlayerChkFloorDist_Part2:
		addi.w	#10,d2				; Check 10 pixels down
		lea	_objNextTilt(a0),a4		; Primary angle
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; No flip bits
		bsr.w	Level_FindFloor			; Find the floor
		clr.b	d2				; Angle value for when the object touched an odd angle (usually $FF)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerGetPrimaryAngle:
		move.b	_objNextTilt(a0),d3		; Get primary angle
		btst	#0,d3				; Is this an odd angle (usually $FF)?
		beq.s	.End				; If not, branch
		move.b	d2,d3				; Set the new angle value
		
.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
sub_F846:
		move.w	_objXPos(a0),d3
		move.w	_objYPos(a0),d2
		subq.w	#4,d2
		move.l	primaryColPtr.w,currentColAddr.w	; Get primary collision address
		cmpi.b	#$D,_objLRBSolid(a0)		; Are we on the primary path?
		beq.s	.NotPrimary			; If not, branch
		move.l	secondaryColPtr.w,currentColAddr.w	; Get secondary collision address

.NotPrimary:
		lea	_objNextTilt(a0),a4		; Primary angle
		clr.b	(a4)				; Clear it
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; No flip bits
		move.b	_objLRBSolid(a0),d5		; Solidity bits
		bsr.w	Level_FindFloor			; Find the floor
		move.b	_objNextTilt(a0),d3		; Get primary angle
		btst	#0,d3				; Are we on an odd angle (usually $FF)?
		beq.s	.End				; If not, branch
		clr.b	d3				; Angle value for when the object touched an odd angle (usually $FF)

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Check for the edge of a floor
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerChkFloorEdge:
		move.w	_objXPos(a0),d3			; Get X position

PlayerChkFloorEdge_Part2:
		move.w	_objYPos(a0),d2			; Get Y position
		moveq	#0,d0
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		add.w	d0,d2				; Add onto Y position

PlayerChkFloorEdge_Part3:
		move.l	primaryColPtr.w,currentColAddr.w	; Get primary collision address
		cmpi.b	#$C,_objTopSolid(a0)		; Are we on the primary path?
		beq.s	.NotPrimary			; If not, branch
		move.l	secondaryColPtr.w,currentColAddr.w	; Get secondary collision address

.NotPrimary:
		lea	_objNextTilt(a0),a4		; Primary angle
		clr.b	(a4)				; Clear it
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; No flip bits
		move.b	_objTopSolid(a0),d5		; Solidity bits
		bsr.w	Level_FindFloor			; Find the floor
		move.b	_objNextTilt(a0),d3		; Get primary angle
		btst	#0,d3				; Are we on an odd angle (usually $FF)?
		beq.s	.End				; If not, branch
		clr.b	d3				; Angle value for when the object touched an odd angle (usually $FF)

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between the floor and an object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjCheckFloorDist:
		move.w	_objXPos(a0),d3			; Get X position
		
ObjCheckFloorDist_Part2:
		move.w	_objYPos(a0),d2			; Get Y position

ObjCheckFloorDist_Part3:
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		add.w	d0,d2				; Add onto Y position
		lea	_objNextTilt(a0),a4		; Primary angle
		clr.b	(a4)				; Clear it
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; No flip bits
		moveq	#$C,d5				; Solidity bits
		bsr.w	Level_FindFloor			; Find the floor
		move.b	_objNextTilt(a0),d3		; Get primary angle
		btst	#0,d3				; Are we on an odd angle (usually $FF)?
		beq.s	.End				; If not, branch
		clr.b	d3				; Angle value for when the object touched an odd angle (usually $FF)

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between a right ceiling and a player object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerChkRightCeilDist:
		; Get the angle on the bottom right (rotated) sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColW(a0),d0			; Get collision height
		ext.w	d0				; ''
		sub.w	d0,d2				; Subtract from Y position
		move.b	_objColH(a0),d0			; Get collision width
		ext.w	d0				; ''
		add.w	d0,d3				; Add onto X position
		lea	_objNextTilt(a0),a4		; Get primary angle
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; Don't switch any flip bits for blocks
		bsr.w	Level_FindWall			; Find the wall
		push.w	d1				; Save the primary floor distance

		; Get the angle on the bottom left (rotated) sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColW(a0),d0			; Get collision height
		ext.w	d0				; ''
		add.w	d0,d2				; Add onto Y position
		move.b	_objColH(a0),d0			; Get collision width
		ext.w	d0				; ''
		add.w	d0,d3				; Add onto X position
		lea	_objTilt(a0),a4			; Get secondary angle
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; Don't switch any flip bits for blocks
		bsr.w	Level_FindWall			; Find the wall

		; Update the object's angle
		pop.w	d0				; Restore the primary floor distance
		move.b	#-$40,d2			; Angle value for when the object touched an odd angle (usually $FF)
		bra.w	PlayerPickAngle		; Get the angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between a right wall and a player object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerChkRightWallDist:
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position

PlayerChkRightWallDist_Part2:
		addi.w	#10,d3				; Check 10 pixels to the right
		lea	_objNextTilt(a0),a4		; Primary angle
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; No flip bits
		bsr.w	Level_FindWall			; Find the wall
		move.b	#-$40,d2			; Angle value for when the object touched an odd angle (usually $FF)
		bra.w	PlayerGetPrimaryAngle		; Get angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between a right wall and an object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjCheckRightWallDist:
		add.w	_objXPos(a0),d3			; Add X position
		move.w	_objYPos(a0),d2			; Get Y position
		lea	_objNextTilt(a0),a4		; Primary angle
		clr.b	(a4)				; Clear it
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; No flip bits
		moveq	#$D,d5				; Solidity bits
		bsr.w	Level_FindWall			; Find the wall
		move.b	_objNextTilt(a0),d3		; Get primary angle
		btst	#0,d3				; Are we on an odd angle (usually $FF)?
		beq.s	.End				; If not, branch
		move.b	#-$40,d3			; Angle value for when the object touched an odd angle (usually $FF)

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between a ceiling and a player object (with primary and secondary angles)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerChkCeiling:
		; Get the angle on the bottom right sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		sub.w	d0,d2				; Subtract from Y position
		eori.w	#$F,d2				; Flip it
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		add.w	d0,d3				; Add onto X position
		lea	_objNextTilt(a0),a4		; Get primary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$800,d6			; Vertical flip
		bsr.w	Level_FindFloor			; Find the floor
		push.w	d1				; Save the primary floor distance

		; Get the angle on the bottom left sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		sub.w	d0,d2				; Subtract from Y position
		eori.w	#$F,d2				; Flip it
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		sub.w	d0,d3				; Subtract from X position
		lea	_objTilt(a0),a4			; Get secondary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$800,d6			; Vertical flip
		bsr.w	Level_FindFloor			; Find the floor
		
		; Update the object's angle
		pop.w	d0				; Restore the primary floor distance
		move.b	#$80,d2				; Angle value for when the object touched an odd angle (usually $FF)
		bra.w	PlayerPickAngle		; Get the angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between a ceiling and a player object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerChkCeilingDist:
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position

PlayerChkCeilingDist_Part2:
		subi.w	#10,d2				; Check 10 pixels up
		eori.w	#$F,d2				; Flip it
		lea	_objNextTilt(a0),a4		; Primary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$800,d6			; Vertical flip
		bsr.w	Level_FindFloor			; Find the floor
		move.b	#$80,d2				; Angle value for when the object touched an odd angle (usually $FF)
		bra.w	PlayerGetPrimaryAngle		; Get angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between a ceiling and an object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjCheckCeilingDist:
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColH(a0),d0		; Get collision height
		ext.w	d0				; ''
		sub.w	d0,d2				; Subtract it from Y position
		eori.w	#$F,d2				; Flip it
		lea	_objNextTilt(a0),a4		; Primary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$800,d6			; Vertical flip
		moveq	#$D,d5				; Solidity bits
		bsr.w	Level_FindWall			; Find the wall
		move.b	_objNextTilt(a0),d3		; Get primary angle
		btst	#0,d3				; Are we on an odd angle (usually $FF)?
		beq.s	.End				; If not, branch
		move.b	#$80,d3				; Angle value for when the object touched an odd angle (usually $FF)

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between a left ceiling and a player object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerChkLeftCeilDist:
		; Get the angle on the bottom right (rotated) sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		sub.w	d0,d2				; Subtract from Y position
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		sub.w	d0,d3				; Subtract from X position
		eori.w	#$F,d3				; Flip it
		lea	_objNextTilt(a0),a4		; Get primary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$400,d6			; Horizontal flip
		bsr.w	Level_FindWall			; Find the wall
		push.w	d1				; Save the primary floor distance

		; Get the angle on the bottom left (rotated) sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		add.w	d0,d2				; Add onto Y position
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		sub.w	d0,d3				; Subtract from X position
		eori.w	#$F,d3				; Flip it
		lea	_objTilt(a0),a4			; Get secondary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$400,d6			; Horizontal flip
		bsr.w	Level_FindWall			; Find the wall

		; Update the object's angle
		pop.w	d0				; Restore the primary floor distance
		move.b	#$40,d2				; Angle value for when the object touched an odd angle (usually $FF)
		bra.w	PlayerPickAngle		; Get the angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between a left wall and a player object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerChkLeftWallDist:
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position

PlayerChkLeftWallDist_Part2:
		subi.w	#10,d3				; Check 10 pixels to the left
		eori.w	#$F,d3				; Flip it
		lea	_objNextTilt(a0),a4		; Primary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$400,d6			; Horizontal flip
		bsr.w	Level_FindWall			; Find the wall
		move.b	#$40,d2				; Angle value for when the object touched an odd angle (usually $FF)
		bra.w	PlayerGetPrimaryAngle		; Get angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Get the distance between a left wall and an object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjCheckLeftWallDist:
		add.w	_objXPos(a0),d3			; Add X position
		eori.w	#$F,d3				; Flip it
		move.w	_objYPos(a0),d2			; Get Y position
		lea	_objNextTilt(a0),a4		; Primary angle
		clr.b	(a4)				; Clear it
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$400,d6			; Horizontal flip
		moveq	#$D,d5				; Solidity bits
		bsr.w	Level_FindWall			; Find the wall
		move.b	_objNextTilt(a0),d3		; Get primary angle
		btst	#0,d3				; Are we on an odd angle (usually $FF)?
		beq.s	.End				; If not, branch
		move.b	#$40,d3				; Angle value for when the object touched an odd angle (usually $FF)

.End:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Move a player object along on the ground
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerAnglePos:
		move.l	primaryColPtr.w,currentColAddr.w	; Get primary collision address
		cmpi.b	#$C,_objTopSolid(a0)		; Are we on the primary path?
		beq.s	.NotPrimary			; If not, branch
		move.l	secondaryColPtr.w,currentColAddr.w	; Get secondary collision address

.NotPrimary:
		move.b	_objTopSolid(a0),d5		; Get top solid bits
		btst	#3,_objStatus(a0)			; Are we standing on a player object?
		beq.s	.NotOnObj			; If not, branch
		clr.w	_objNextTilt(a0)			; Set the angles to 0
		rts

.NotOnObj:
		move.w	#$0303,_objNextTilt(a0)		; Set the angles to 3
		
		; Get which quadrant the object is in on the ground
		; This makes it so that angles:
		; 	$E0-$20 = Quadrant 0 (floor)
		;	$1F-$5F = Quadrant $40 (left wall)
		;	$60-$A0 = Quadrant $80 (ceiling)
		;	$A1-$DF = Quadrant $C0 (right wall)
		move.b	_objAngle(a0),d0			; Get the angle
		btst	#6,d0				; Are we in quadrants 0 or $80? (use 5 instaead of 6 for 8 directions)
		beq.s	.DownUp				; If not, branch
		addq.b	#1,d0				; Shift the angle

.DownUp:
		addi.b	#$1F,d0				; Shift the angle (use $F instaead of $1F for 8 directions)
		andi.b	#$C0,d0				; Get which quadrant we are in (use $E0 instaead of $C0 for 8 directions)
		cmpi.b	#$40,d0				; Are we in quadrant $40 (left wall)?
		beq.w	PlayerMoveLWall		; If so, branch
		cmpi.b	#$80,d0				; Are we in quadrant $80 (ceiling)?
		beq.w	PlayerMoveCeiling		; Is so, branch
		cmpi.b	#$C0,d0				; Are we in quadrant $C0 (right wall)?
		beq.w	PlayerMoveRWall		; If so, branch
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Move the object along the floor
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerMoveFloor:
		; Get the angle on the bottom right sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		add.w	d0,d2				; Add onto Y position
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		add.w	d0,d3				; Add onto X position
		lea	_objNextTilt(a0),a4		; Get primary angle
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; Don't switch any flip bits for blocks
		bsr.w	Level_FindFloor			; Find the floor
		push.w	d1				; Save the primary floor distance

		; Get the angle on the bottom left sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		add.w	d0,d2				; Add onto Y position
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		sub.w	d0,d3				; Add onto X position
		lea	_objTilt(a0),a4			; Get secondary angle
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; Don't switch any flip bits for blocks
		bsr.w	Level_FindFloor			; Find the floor
		
		; Update the object's angle
		pop.w	d0				; Restore the primary floor distance
		bsr.w	PlayerSetAngle			; Set the new angle
		
		; Check if the object has hit a wall or is about to fall
		tst.w	d1				; Is we already perfectly standing on the surface?
		beq.s	.End				; If so, branch
		bpl.s	.ChkFall			; If the there's possibly a floor below us, branch
		cmpi.w	#-$E,d1				; Have we hit a wall?
		blt.s	.End				; If so, branch
		add.w	d1,_objYPos(a0)			; Move us on to the surface

.End:
		rts

.ChkFall:
		move.b	_objXVel(a0),d0			; Get the integer part of the X velocity
		bpl.s	.GetMinDist			; If it's already positive, branch
		neg.b	d0				; Force it to be positive

.GetMinDist:
		addq.b	#4,d0				; The Y distance must be at least 4 pixels down
		cmpi.b	#$E,d0				; ...but cannot be more than 14 pixels down
		blo.s	.ChkDist			; ...for us to not fall off the surface
		move.b	#$E,d0				; ''

.ChkDist:
		cmp.b	d0,d1				; Are we about to fall off?
		bgt.s	.SetAir				; If so, branch
		add.w	d1,_objYPos(a0)			; Move us on to the surface
		rts

.SetAir:
		bset	#1,_objStatus(a0)			; Set "in air" flag
		bclr	#5,_objStatus(a0)			; Clear "pushing" flag
		move.b	#1,_objPrevAnim(a0)			; Reset the animation
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Set the objects's angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerSetAngle:
		move.b	_objTilt(a0),d2			; Get secondary angle
		cmp.w	d0,d1				; Is the primary floor distance lower than the secondary?
		ble.s	.ChkSetAngle			; If not, branch
		move.b	_objNextTilt(a0),d2		; Get primary angle
		move.w	d0,d1				; Get primary floor distance
		
.ChkSetAngle:
		btst	#0,d2				; Is this an odd angle (usually $FF)?
		bne.s	.LatchOnFlat			; If so, branch
		move.b	d2,d0				; Get angle change
		sub.b	_objAngle(a0),d0			; ''
		bpl.s	.ChkDist			; ''
		neg.b	d0				; ''

.ChkDist:
		cmpi.b	#$20,d0				; Has the player moved $20 degrees or more?
		bhs.s	.LatchOnFlat			; If so, branch
		move.b	d2,_objAngle(a0)			; Set the new angle value
		rts

.LatchOnFlat:
		move.b	_objAngle(a0),d2			; Get old angle value
		addi.b	#$20,d2				; Shift the angle
		andi.b	#$C0,d2				; Flatten the angle
		move.b	d2,_objAngle(a0)			; Set the new angle value
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Move the object along the right wall
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerMoveRWall:
		; Get the angle on the bottom right (rotated) sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		sub.w	d0,d2				; Add onto Y position
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		add.w	d0,d3				; Add onto X position
		lea	_objNextTilt(a0),a4		; Get primary angle
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; Don't switch any flip bits for blocks
		bsr.w	Level_FindWall			; Find the wall
		push.w	d1				; Save the primary floor distance

		; Get the angle on the bottom left (rotated) sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		add.w	d0,d2				; Add onto Y position
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		add.w	d0,d3				; Add onto X position
		lea	_objTilt(a0),a4			; Get secondary angle
		movea.w	#$10,a3				; Height of bottom right sensor
		clr.w	d6				; Don't switch any flip bits for blocks
		bsr.w	Level_FindWall			; Find the wall
		
		; Update the object's angle
		pop.w	d0				; Restore the primary floor distance
		bsr.w	PlayerSetAngle			; Set the new angle

		; Check if the object has hit a wall or is about to fall
		tst.w	d1				; Is we already perfectly standing on the surface?
		beq.s	.End				; If so, branch
		bpl.s	.ChkFall			; If the there's possibly a floor below us, branch
		cmpi.w	#-$E,d1				; Have we hit a wall?
		blt.s	.End				; If so, branch
		add.w	d1,_objXPos(a0)			; Move us on to the surface

.End:
		rts

.ChkFall:
		move.b	_objYVel(a0),d0			; Get the integer part of the Y velocity
		bpl.s	.GetMinDist			; If it's already positive, branch
		neg.b	d0				; Force it to be positive

.GetMinDist:
		addq.b	#4,d0				; The X distance must be at least 4 pixels down
		cmpi.b	#$E,d0				; ...but cannot be more than 14 pixels down
		blo.s	.ChkDist			; ...for us to not fall off the surface
		move.b	#$E,d0				; ''

.ChkDist:
		cmp.b	d0,d1				; Are we about to fall off?
		bgt.s	.SetAir				; If so, branch
		add.w	d1,_objXPos(a0)			; Move us on to the surface
		rts

.SetAir:
		bset	#1,_objStatus(a0)			; Set "in air" flag
		bclr	#5,_objStatus(a0)			; Clear "pushing" flag
		move.b	#1,_objPrevAnim(a0)			; Reset the animation
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Move the object along the ceiling
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerMoveCeiling:
		; Get the angle on the bottom right (rotated) sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		sub.w	d0,d2				; Subtract from the Y position
		eori.w	#$F,d2				; Flip it
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		add.w	d0,d3				; Add onto X position
		lea	_objNextTilt(a0),a4		; Get primary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$800,d6			; Vertical flip
		bsr.w	Level_FindFloor			; Find the floor
		push.w	d1				; Save the primary floor distance

		; Get the angle on the bottom left (rotated) sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		sub.w	d0,d2				; Subtract from the Y position
		eori.w	#$F,d2				; Flip it
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		sub.w	d0,d3				; Subtract from the X position
		lea	_objTilt(a0),a4			; Get secondary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$800,d6			; Vertical flip
		bsr.w	Level_FindFloor			; Find the floor
		
		; Update the object's angle
		pop.w	d0				; Restore the primary floor distance
		bsr.w	PlayerSetAngle			; Set the new angle
		
		; Check if the object has hit a wall or is about to fall
		tst.w	d1				; Is we already perfectly standing on the surface?
		beq.s	.End				; If so, branch
		bpl.s	.ChkFall			; If the there's possibly a floor below us, branch
		cmpi.w	#-$E,d1				; Have we hit a wall?
		blt.s	.End				; If so, branch
		sub.w	d1,_objYPos(a0)			; Move us on to the surface

.End:
		rts

.ChkFall:
		move.b	_objXVel(a0),d0			; Get the integer part of the X velocity
		bpl.s	.GetMinDist			; If it's already positive, branch
		neg.b	d0				; Force it to be positive

.GetMinDist:
		addq.b	#4,d0				; The Y distance must be at least 4 pixels down
		cmpi.b	#$E,d0				; ...but cannot be more than 14 pixels down
		blo.s	.ChkDist			; ...for us to not fall off the surface
		move.b	#$E,d0				; ''

.ChkDist:
		cmp.b	d0,d1				; Are we about to fall off?
		bgt.s	.SetAir				; If so, branch
		sub.w	d1,_objYPos(a0)			; Move us on to the surface
		rts

.SetAir:
		bset	#1,_objStatus(a0)			; Set "in air" flag
		bclr	#5,_objStatus(a0)			; Clear "pushing" flag
		move.b	#1,_objPrevAnim(a0)			; Reset the animation
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Move the object along the left wall
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayerMoveLWall:
		; Get the angle on the bottom right (rotated) sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		sub.w	d0,d2				; Subtract from the Y position
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		sub.w	d0,d3				; Subtract from X position
		eori.w	#$F,d3				; Flip it
		lea	_objNextTilt(a0),a4		; Get primary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$400,d6			; Horizontal flip
		bsr.w	Level_FindWall			; Find the wall
		push.w	d1				; Save the primary floor distance

		; Get the angle on the bottom left (rotated) sensor
		move.w	_objYPos(a0),d2			; Get Y position
		move.w	_objXPos(a0),d3			; Get X position
		moveq	#0,d0
		move.b	_objColW(a0),d0			; Get collision width
		ext.w	d0				; ''
		add.w	d0,d2				; Add onto Y position
		move.b	_objColH(a0),d0			; Get collision height
		ext.w	d0				; ''
		sub.w	d0,d3				; Subtract from X position
		eori.w	#$F,d3				; Flip it
		lea	_objTilt(a0),a4			; Get secondary angle
		movea.w	#-$10,a3			; Height of bottom right sensor
		move.w	#$400,d6			; Horizontal flip
		bsr.w	Level_FindWall			; Find the wall
		
		; Update the object's angle
		pop.w	d0				; Restore the primary floor distance
		bsr.w	PlayerSetAngle			; Set the new angle
		
		; Check if the object has hit a wall or is about to fall
		tst.w	d1				; Is we already perfectly standing on the surface?
		beq.s	.End				; If so, branch
		bpl.s	.ChkFall			; If the there's possibly a floor below us, branch
		cmpi.w	#-$E,d1				; Have we hit a wall?
		blt.s	.End				; If so, branch
		sub.w	d1,_objXPos(a0)			; Move us on to the surface

.End:
		rts

.ChkFall:
		move.b	_objYVel(a0),d0			; Get the integer part of the Y velocity
		bpl.s	.GetMinDist			; If it's already positive, branch
		neg.b	d0				; Force it to be positive

.GetMinDist:
		addq.b	#4,d0				; The X distance must be at least 4 pixels down
		cmpi.b	#$E,d0				; ...but cannot be more than 14 pixels down
		blo.s	.ChkDist			; ...for us to not fall off the surface
		move.b	#$E,d0				; ''

.ChkDist:
		cmp.b	d0,d1				; Are we about to fall off?
		bgt.s	.SetAir				; If so, branch
		sub.w	d1,_objXPos(a0)			; Move us on to the surface
		rts

.SetAir:
		bset	#1,_objStatus(a0)			; Set "in air" flag
		bclr	#5,_objStatus(a0)			; Clear "pushing" flag
		move.b	#1,_objPrevAnim(a0)			; Reset the animation
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Find the nearest floor from the object's position
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d2.w	- Y position of the object's bottom sensor
;	d3.w	- X position of the object's bottom sensor
;	d5.w	- Bit to chect for solidity
;	d6.w	- Flip bits (for walls and ceilings)
;	a3.w	- Distance in pixels to check for blocks above or below the sensor
;	a4.w	- Pointer to where the angle value will be stored
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	d1.w	- The distance from the object to the floor
;	(a1).w	- The block ID in the chunk where the object is standing
;	(a4).w	- The floor angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_FindFloor:
		bsr.w	Level_FindBlock			; Find the nearest tile
		move.w	(a1),d0				; Get block ID
		move.w	d0,d4				; Copy that
		andi.w	#$3FF,d0			; Get only the block ID
		beq.s	.IsBlank			; If it's blank, branch
		btst	d5,d4				; Is the block solid?
		bne.s	.IsSolid			; If so, branch

.IsBlank:
		add.w	a3,d2				; Check below the sensor
		bsr.w	Level_FindFloor2		; Try to find a solid block there
		sub.w	a3,d2				; Restore Y position of sensor
		addi.w	#$10,d1				; Return distance to floor
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.IsSolid:
		movea.l	currentColAddr.w,a2		; Get collision data pointer
		add.w	d0,d0				; Turn ID into offset
		move.b	(a2,d0.w),d0			; Get collision block ID
		andi.w	#$FF,d0				; ''
		beq.s	.IsBlank			; If the angle is 0, branch

		movea.l	angleValPtr.w,a2		; Angle value array
		move.b	(a2,d0.w),(a4)			; Get angle value and store it
		lsl.w	#4,d0				; Turn collision block ID into offset

		move.w	d3,d1				; Get the object's X position
		btst	#$A,d4				; Is the block flipped horizontally?
		beq.s	.NoXFlip			; If not, branch
		not.w	d1				; Flip the X position
		neg.b	(a4)				; Flip the angle
		
.NoXFlip:
		btst	#$B,d4				; Is the block vertically flipped?
		beq.s	.NoYFlip			; If not, branch
		addi.b	#$40,(a4)			; Flip the angle
		neg.b	(a4)				; ''
		subi.b	#$40,(a4)			; ''

.NoYFlip:
		andi.w	#$F,d1				; Get the X offset in the collsion block
		add.w	d0,d1				; Add the collision block's offset

		movea.l	normColArrayPtr.w,a2		; Get the normal collision array
		move.b	(a2,d1.w),d0			; Get height value
		ext.w	d0				; ''
		eor.w	d6,d4				; Flip the flip bits from the block
		btst	#$B,d4				; Is the block vertically flipped?
		beq.s	.NoYFlip2			; If not, branch
		neg.w	d0				; Flip the height

.NoYFlip2:
		tst.w	d0				; Check the height
		beq.s	.IsBlank			; If the height is 0, branch
		bmi.s	.NegHeight			; If the height is negative, branch
		cmpi.b	#$10,d0				; Is the height 16 (the max height)?
		beq.s	.MaxFloor			; If so, branch
		move.w	d2,d1				; Get the object's Y position
		andi.w	#$F,d1				; Get the Y offset in the height
		add.w	d1,d0				; Add onto the height
		move.w	#$F,d1				; Get actual distance
		sub.w	d0,d1				; ''
		rts

.NegHeight:
		move.w	d2,d1				; Get the object's Y position
		andi.w	#$F,d1				; Get the Y offset in the height
		add.w	d1,d0				; Add onto the height
		bpl.w	.IsBlank			; If the object is outside of the collision, branch

.MaxFloor:
		sub.w	a3,d2				; Check above the sensor
		bsr.s	Level_FindFloor2		; Try to find a solid block there
		add.w	a3,d2				; Restore Y position of sensor
		subi.w	#$10,d1				; Return distance to floor
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_FindFloor2:
		bsr.w	Level_FindBlock			; Find the nearest tile
		move.w	(a1),d0				; Get block ID
		move.w	d0,d4				; Copy that
		andi.w	#$3FF,d0			; Get only the block ID
		beq.s	.IsBlank			; If it's blank, branch
		btst	d5,d4				; Is the block solid?
		bne.s	.IsSolid			; If so, branch

.IsBlank:
		move.w	#$F,d1				; Get max distance
		move.w	d2,d0				; Get the object's Y position
		andi.w	#$F,d0				; Get the Y offset in the height
		sub.w	d0,d1				; Get actual distance
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.IsSolid:
		movea.l	currentColAddr.w,a2			; Get collision data pointer
		add.w	d0,d0				; Turn ID into offset
		move.b	(a2,d0.w),d0			; Get collision block ID
		andi.w	#$FF,d0				; ''
		beq.s	.IsBlank			; If the angle is 0, branch

		movea.l	angleValPtr.w,a2		; Angle value array
		move.b	(a2,d0.w),(a4)			; Get angle value and store it
		lsl.w	#4,d0				; Turn collision block ID into offset

		move.w	d3,d1				; Get the object's X position
		btst	#$A,d4				; Is the block flipped horizontally?
		beq.s	.NoXFlip			; If not, branch
		not.w	d1				; Flip the X position
		neg.b	(a4)				; Flip the angle

.NoXFlip:
		btst	#$B,d4				; Is the block vertically flipped?
		beq.s	.NoYFlip			; If not, branch
		addi.b	#$40,(a4)			; Flip the angle
		neg.b	(a4)				; ''
		subi.b	#$40,(a4)			; ''

.NoYFlip:
		andi.w	#$F,d1				; Get the X offset in the collsion block
		add.w	d0,d1				; Add the collision block's offset

		movea.l	normColArrayPtr.w,a2		; Get the normal collision array
		move.b	(a2,d1.w),d0			; Get height value
		ext.w	d0				; ''
		eor.w	d6,d4				; Flip the flip bits from the block
		btst	#$B,d4				; Is the block vertically flipped?
		beq.s	.NoYFlip2			; If not, branch
		neg.w	d0				; Flip the height

.NoYFlip2:
		tst.w	d0				; Check the height
		beq.s	.IsBlank			; If the height is 0, branch
		bmi.s	.NegHeight			; If the height is negative, branch
		move.w	d2,d1				; Get the object's Y position
		andi.w	#$F,d1				; Get the Y offset in the height
		add.w	d1,d0				; Add onto the height
		move.w	#$F,d1				; Get actual distance
		sub.w	d0,d1				; ''
		rts

.NegHeight:
		move.w	d2,d1				; Get the object's Y position
		andi.w	#$F,d1				; Get the Y offset in the height
		add.w	d1,d0				; Add onto the height
		bpl.w	.IsBlank			; If the object is outside of the collision, branch
		not.w	d1				; Flip the height
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Find the nearest wall from the object's position
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d2.w	- Y position of the object's bottom sensor
;	d3.w	- X position of the object's bottom sensor
;	d5.w	- Bit to chect for solidity
;	d6.w	- Flip bits (for walls and ceilings)
;	a3.w	- Distance in pixels to check for blocks left of or right of the sensor
;	a4.w	- Pointer to where the angle value will be stored
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	d1.w	- The distance from the object to the floor
;	(a1).w	- The block ID in the chunk where the object is standing
;	(a4).w	- The floor angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_FindWall:
		bsr.w	Level_FindBlock			; Find the nearest tile
		move.w	(a1),d0				; Get block ID
		move.w	d0,d4				; Copy that
		andi.w	#$3FF,d0			; Get only the block ID
		beq.s	.IsBlank			; If it's blank, branch
		btst	d5,d4				; Is the block solid?
		bne.s	.IsSolid			; If so, branch

.IsBlank:
		add.w	a3,d3				; Check right to the sensor
		bsr.w	Level_FindWall2			; Try to find a solid block there
		sub.w	a3,d3				; Restore X position of sensor
		addi.w	#$10,d1				; Return distance to floor
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.IsSolid:
		movea.l	currentColAddr.w,a2			; Get collision data pointer
		add.w	d0,d0				; Turn ID into offset
		move.b	(a2,d0.w),d0			; Get collision block ID
		andi.w	#$FF,d0				; ''
		beq.s	.IsBlank			; If the angle is 0, branch

		movea.l	angleValPtr.w,a2		; Angle value array
		move.b	(a2,d0.w),(a4)			; Get angle value and store it
		lsl.w	#4,d0				; Turn collision block ID into offset

		move.w	d2,d1				; Get the object's Y position
		btst	#$B,d4				; Is the block vertically flipped?
		beq.s	.NoYFlip			; If not, branch
		not.w	d1				; Flip the Y position
		addi.b	#$40,(a4)			; Flip the angle
		neg.b	(a4)				; ''
		subi.b	#$40,(a4)			; ''

.NoYFlip:
		btst	#$A,d4				; Is the block flipped horizontally?
		beq.s	.NoXFlip			; If not, branch
		neg.b	(a4)				; Flip the angle

.NoXFlip:
		andi.w	#$F,d1				; Get the X offset in the collsion block
		add.w	d0,d1				; Add the collision block's offset

		movea.l	rotColArrayPtr.w,a2		; Get the normal collision array
		move.b	(a2,d1.w),d0			; Get height value
		ext.w	d0				; ''
		eor.w	d6,d4				; Flip the flip bits from the block
		btst	#$A,d4				; Is the block horizontally flipped?
		beq.s	.NoYFlip2			; If not, branch
		neg.w	d0				; Flip the height

.NoYFlip2:
		tst.w	d0				; Check the height
		beq.s	.IsBlank			; If the height is 0, branch
		bmi.s	.NegHeight			; If the height is negative, branch
		cmpi.b	#$10,d0				; Is the height 16 (the max height)?
		beq.s	.MaxFloor			; If so, branch
		move.w	d3,d1				; Get the object's X position
		andi.w	#$F,d1				; Get the X offset in the height
		add.w	d1,d0				; Add onto the height
		move.w	#$F,d1				; Get actual distance
		sub.w	d0,d1				; ''
		rts

.NegHeight:
		move.w	d3,d1				; Get the object's X position
		andi.w	#$F,d1				; Get the X offset in the height
		add.w	d1,d0				; Add onto the height
		bpl.w	.IsBlank			; If the object is outside of the collision, branch

.MaxFloor:
		sub.w	a3,d3				; Check left to the sensor
		bsr.s	Level_FindWall2			; Try to find a solid block there
		add.w	a3,d3				; Restore X position of sensor
		subi.w	#$10,d1				; Return distance to floor
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_FindWall2:
		bsr.w	Level_FindBlock			; Find the nearest tile
		move.w	(a1),d0				; Get block ID
		move.w	d0,d4				; Copy that
		andi.w	#$3FF,d0			; Get only the block ID
		beq.s	.IsBlank			; If it's blank, branch
		btst	d5,d4				; Is the block solid?
		bne.s	.IsSolid			; If so, branch

.IsBlank:
		move.w	#$F,d1				; Get max distance
		move.w	d3,d0				; Get the object's X position
		andi.w	#$F,d0				; Get the X offset in the height
		sub.w	d0,d1				; Get actual distance
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.IsSolid:
		movea.l	currentColAddr.w,a2			; Get collision data pointer
		add.w	d0,d0				; Turn ID into offset
		move.b	(a2,d0.w),d0			; Get collision block ID
		andi.w	#$FF,d0				; ''
		beq.s	.IsBlank			; If the angle is 0, branch

		movea.l	angleValPtr.w,a2		; Angle value array
		move.b	(a2,d0.w),(a4)			; Get angle value and store it
		lsl.w	#4,d0				; Turn collision block ID into offset

		move.w	d2,d1				; Get the object's Y position
		btst	#$B,d4				; Is the block vertically flipped?
		beq.s	.NoYFlip			; If not, branch
		not.w	d1				; Flip the Y position
		addi.b	#$40,(a4)			; Flip the angle
		neg.b	(a4)				; ''
		subi.b	#$40,(a4)			; ''

.NoYFlip:
		btst	#$A,d4				; Is the block flipped horizontally?
		beq.s	.NoXFlip			; If not, branch
		neg.b	(a4)				; Flip the angle

.NoXFlip:
		andi.w	#$F,d1				; Get the X offset in the collsion block
		add.w	d0,d1				; Add the collision block's offset

		movea.l	rotColArrayPtr.w,a2		; Get the normal collision array
		move.b	(a2,d1.w),d0			; Get height value
		ext.w	d0				; ''
		eor.w	d6,d4				; Flip the flip bits from the block
		btst	#$A,d4				; Is the block horizontally flipped?
		beq.s	.NoYFlip2			; If not, branch
		neg.w	d0				; Flip the height

.NoYFlip2:
		tst.w	d0				; Check the height
		beq.s	.IsBlank			; If the height is 0, branch
		bmi.s	.NegHeight			; If the height is negative, branch
		move.w	d3,d1				; Get the object's X position
		andi.w	#$F,d1				; Get the X offset in the height
		add.w	d1,d0				; Add onto the height
		move.w	#$F,d1				; Get actual distance
		sub.w	d0,d1				; ''
		rts

.NegHeight:
		move.w	d3,d1				; Get the object's X position
		andi.w	#$F,d1				; Get the X offset in the height
		add.w	d1,d0				; Add onto the height
		bpl.w	.IsBlank			; If the object is outside of the collision, branch
		not.w	d1				; Flip the height
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Find the nearest block in the level from the player
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d2.w	- Y position of the object's sensor
;	d3.w	- X position of the object's sensor
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	(a1).w	- The block ID in the chunk where the object is standing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Level_FindBlock:
	;	movea.l	(chunkDataPtr).w,a1
	;	rts

		movea.l	(lvlLayout).w,a1		; Get level layout pointer address

		move.w	d3,d0				; Get X within layout data
		lsr.w	#5,d0				; ''
		andi.w	#$3FE,d0			; ''
		move.w	d2,d1				; Get Y within layout data
		lsr.w	#5,d1				; ''
		andi.w	#$3FE,d1			; ''

		add.w	4(a1,d1.w),d0			; Combine X and Y to get layout offset
		move.w	(a1,d0.w),d1			; Get chunk ID
		andi.l	#$3FFF,d1			; ''
		lsl.l	#5,d1				; Turn into offset by multiplying by 32 (number of bytes each chunk entry occupies)

		movea.l	(chunkDataPtr).w,a1		; Load base address of uncompressed chunk data in ROM
		adda.l	d1,a1				; Adjust by the offset of the current chunk ID

		move.w	d3,d0				; Get X within chunk data
		lsr.w	#3,d0				; ''
		andi.w	#6,d0				; ''
		move.w	d2,d1				; Get Y within chunk data
		lsr.w	#1,d1				; ''			
		andi.w	#$18,d1				; ''
		add.w	d0,d1				; Combine X and Y to get chunk offset

		adda.w	d1,a1				; Adjust by the offset of the block within the chunk
		rts

	;	move.w	d2,d0				; Get the object's Y position
	;	andi.w	#$7FE0,d0			; Get Y within layout data
	;	lsr.w	#4,d0				; ''			
	;	move.w	4(a1,d0.w),d0			; Get chunk row offset
	;	
	;	move.w	d3,d1				; Get the object's X position
	;	lsr.w	#3,d1				; Divide by 8
	;	move.w	d1,d4				; Save for later
	;	
	;	lsr.w	#2,d1				; Divide by 4 
	;	andi.w	#$3FE,d1			; logically AND against the maximum number of chunks per row * 2 (word alignment)
	;	add.w	d1,d0				; Combine to get the offset into the level layout
	;	
	;	move.w	(a1,d0.w),d1			; Get chunk ID
	;	andi.l	#$3FFF,d1			; ''
	;	lsl.l	#5,d1				; Turn into offset by multiplying by 32 (number of bytes each chunk entry occupies)
	;	
	;	move.w	d2,d0				; Get the object's Y position
	;	lsr.w	#1,d0				; Get Y position within chunk
	;	andi.l	#$18,d0				; ''
	;	or.l	d0,d1				; Combine with the offset
	;	andi.l	#6,d4				; Get the previously saved X position divided by 8 (for the row offset)
	;	or.l	d4,d1				; Combine with the offset
	;	
	;	movea.l	(chunkDataPtr).w,a1		; Load base address of uncompressed chunk data in ROM
	;	lea	(a1,d1.l),a1			; Load the address of the current chunk ID's data
	;	rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------