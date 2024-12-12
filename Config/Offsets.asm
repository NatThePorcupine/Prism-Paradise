; =========================================================================================================================================================
; User defined constants
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Game mode IDs
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsreset
gTitle		rs.l	1				; Title screen game mode
gLevel		rs.l	1				; Level game mode
gEnd		rs.l	1				; Ending game mode
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; V-INT routine IDs
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsreset
vLag		rs.w	1				; Lag updates
vGeneral	rs.w	1				; General updates
vLevel		rs.w	1				; Level updates
vLvlLoad	rs.w	1				; Level load updates
vTitle		rs.w	1				; Title screen updates
vFade		rs.w	1				; Fade updates
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Level IDs
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsreset
zWWZ		rs.b	1				; Wacky Workbench

ZONE_COUNT	equ	__rs				; Number of zones

lWWZ		equ	zWWZ<<8				; Wacky Workbench

	if	0
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Music definitions
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsset	MusOff
mFirst		rs.b	0
mSega		rs.b	1				; SEGA jingle
mWWZ		rs.b	1				; Wacky Workbench music
mBoss		rs.b	1				; Boss music
mInvincible	rs.b	1				; Invincibility music
mEnd		rs.b	0
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; SFX definitions
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsset	SFXoff
sFirst		rs.b	0
sLeap		rs.b	1				; Jump sound
sSkid		rs.b	1				; Skid sound
sHurt		rs.b	0				; Hurt sound
sDeath		rs.b	1				; Death sound
sPush		rs.b	1				; Push sound
sBubble		rs.b	1				; Bubble sound
sDrown		rs.b	1				; Drowning sound
sDrownWarn	rs.b	1				; Drown warning sound
sDrownCount	rs.b	1				; Drown countdown sound
sCheckpoint	rs.b	1				; Checkpoint sound
sSpikeMove	rs.b	1				; Spike movement sound
sRing		rs.b	1				; Ring sound
sRingLoss	rs.b	1				; Ring loss sound
sSpring		rs.b	1				; Spring sound
sShield		rs.b	1				; Shield sound
sSplash		rs.b	1				; Water splash sound
sBumper		rs.b	1				; Bumper sound
sSwitch		rs.b	1				; Switch sound
sSignpost	rs.b	1				; Signpost sound
sCollapse	rs.b	1				; Collapse sound
sWallSmash	rs.b	1				; Wall smash sound
sRumble		rs.b	1				; Rumble sound
sWarp		rs.b	1				; Warp sound
sBossHit	rs.b	1				; Boss hit sound
sBomb		rs.b	1				; Bomb sound
sBreakItem	rs.b	1				; Break item sound
sFloorBounce	rs.b	1				; Floor bounce sound
sCharge		rs.b	1				; Charge sound
sChargeStop	rs.b	1				; Charge stop sound
sChargeRelease	rs.b	1				; Charge release sound
sDiamBreak	rs.b	1				; Diamond break sound
sEnd		rs.b	0

	endif
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Object SSTs
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsreset
_objPrevDPLC	rs.b	0				; Previous DPLC ID (only used by a few objects)
_objAddress	rs.l	1				; Pointer to object code
_objNext	rs.w	1				; Pointer to next object in the linked list
_objPrev	rs.w	1				; Pointer to previous object in the linked list
_objDrawNext	rs.w	1				; Pointer to next object to display
_objDrawPrev	rs.w	1				; Pointer to previous object to display

_objFlags	rs.b	1				; Object flags
_objRender	rs.b	1				; Render flags
_objVRAM	rs.w	1				; Sprite tile properties
_objFrame	rs.b	0				; Mapping frame ID (top byte of the following long)
_objMapping	rs.l	1				; Sprite mappings

_objXPos	rs.l	1				; X position
_objDrawW	equ	__rs-1				; Sprite width
_objYPos	rs.l	1				; Y position
_objDrawH	equ	__rs-1				; Sprite height
_objXVel	rs.w	1				; X velocity
_objYVel	rs.w	1				; Y velocity

_objAnim	rs.b	1				; Animation ID
_objPrevAnim	rs.b	1				; Saved animation ID
_objAnimFrame	rs.b	1				; Animation script frame ID
_objAnimTimer	rs.b	1				; Animation timer

_objSubtype	rs.b	1				; Subtype ID (top byte of the following long)
_objRoutine	rs.b	1				; Routine ID
_objRespawn	rs.w	1				; Respawn table entry pointer
_objStatus	rs.b	1				; Status flags
_objShield	rs.b	1				; Shield flags

_objDynSSTs	rs.b	$60-__rs			; Dynamic SSTs
_objSize	rs.b	0				; Size of the SSTs
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Dynamic SSTs
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsset	_objDynSSTs
_objColType	rs.b	1				; Collision type
_objColStat	rs.b	1				; Collision status
_objHitCnt	equ	_objColStat			; Boss hit count
_objColW	rs.b	1				; Collision width
_objColH	rs.b	1				; Collision height
_objNextTilt	rs.b	1				; Next tilt value
_objTilt	rs.b	1				; Tilt value
_objLvlSSTs	rs.b	0				; Beginning of dynamic level SSTs
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Sub sprite SSTs
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsset	_objNextTilt			; Allow some reserved SSTs
_objSubSSTs	rs.b	0				; Start of sub sprite SSTs
_objSubCnt	rs.w	1				; Main sprite sub sprite count
_objSubStart	rs.b	0				; Actual sub sprite SSTs start
ct		=	0

	rept	8					; Allow 8 sub sprites per object
_objSub\$ct\XPos	rs.w	1			; Sub sprite X position
_objSub\$ct\YPos	rs.w	1			; Sub sprite Y position
_objSub\$ct\Free	rs.b	1			; Sub sprite free byte
_objSub\$ct\Frame	rs.b	1			; Sub sprite mapping frame
ct		=	ct+1
	endr
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Sprite drawing input list definitions
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsset _objDrawPrev-6			; this awkward thing will make dPrev == _objDrawPrev
dNext		rs.w 1					; pointer to first display object in linked list
dN2		rs.w 1					; must be 0
dN1		rs.w 1					; must be 0
dPrev		rs.w 1					; pointer to last display object in linked list
dSize =		__rs-dNext				; size of display layer
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Solid object collision bits
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
cStandBit	equ	3
cStand		equ	1<<cStandBit

cPushDelta	equ	2

cPushBit	equ	cStandBit+cPushDelta
cPush		equ	1<<cPushBit

cTouchSideBit	equ	0
cTouchSide	equ	1<<cTouchSideBit

cTouchBtmBit	equ	cTouchSideBit+cPushDelta
cTouchBtm	equ	1<<cTouchBtmBit

cTouchTopBit	equ	cTouchBtmBit+cPushDelta
cTouchTop	equ	1<<cTouchTopBit
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Macro to calculate the RAM space used by objects without going over the given max size
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	size	- Max size for this object SST space
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
curobj		=	0
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
maxObjRAM	macro	size
curobj_size	=	0
		while curobj_size<(\size)
rObj_\$curobj		rs.b	_objSize
curobj_size		=	curobj_size+_objSize
curobj			=	curobj+1
		endw
		endm
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Level drawing variables
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsreset
cXPos		rs.l	1				; Plane X position
cXPrev		rs.w	1				; Plane previous X position
cXPrevR		rs.w	1				; Plane previous X position (rounded)
cYPos		rs.l	1				; Plane Y position
cYPrev		rs.w	1				; Plane previous Y position
cYPrevR		rs.w	1				; Plane previous Y position (rounded)
cRBlks		rs.b	1				; Number of blocks in the first set of tiles in a row
cCBlks		rs.b	1				; Number of blocks in the first set of tiles in a column
cVDP		rs.l	1				; VDP command
cLayout		rs.w	1				; Layout offset
cUpdate		rs.l	1				; Update routine
cRedraw		rs.w	1				; Redraw flag
cSize2		rs.b	0				; Variable list size
; =========================================================================================================================================================
