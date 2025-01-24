; =========================================================================================================================================================
; User defined RAM addresses
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Standard variables
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsset	RAM_START

		; --- BUFFERS ---

miscBuff	rs.b	0				; General buffer
lvlLayoutBuff	rs.b	$8000				; Buffer in RAM used to store the level layout data
miscBuff_End	rs.b	0

		rsset	RAM_WORD_START

kosMBuff	rs.b	$1000				; Kosinski decompression buffer

dmaQueue	rs.b	$FC				; DMA queue buffer
dmaSlot		rs.w	1				; DMA queue buffer slot

hScrollBuff	rs.b	$380				; HScroll table
hScrollBuff_End	rs.b	0				; ''

vScrollBuff	rs.b	$50				; VScroll table
vScrollBuff_End	rs.b	0				; ''
vScrollBuffFG	EQU	vScrollBuff			; VScroll foreground value
vScrollBuffBG	EQU	vScrollBuff+2			; VScroll background value

spriteBuff	rs.b	$280				; Sprite table
spriteBuff_End	rs.b	0				; ''

; NTP: we won't be able to save ram like this until we switch to SWAP mappings (and we'll need per-piece limit checks on lest we overwrite the water palette)
;palFadeBuffAlt	equ	spriteBuff_End-$100		; Target water palette buffer
;palFadeBuff	equ	spriteBuff_End-$80		; Target palette buffer

palFadeBuffAlt	rs.b	$80				; Target water palette buffer
palFadeBuff	rs.b	$80				; Target palette buffer
paletteBuffAlt	rs.b	$80				; Water palette buffer
paletteBuff	rs.b	$80				; Palette buffer

kosVars		rs.b	0				; Kosinski decompression queue variables
kosCount	rs.w	1				; Kosinski decompression queue count
kosRegisters	rs.b	$1A				; Kosinski decompression stored registers
kosStatusReg	rs.w	1				; Kosinski decompression stored SR
kosBookmark	rs.l	1				; Kosinski decompression bookmark
kosList		rs.b	$20				; Kosinski decompression queue
kosSource	equ	kosList				; ''
kosDestination	equ	kosList+4			; ''
kosList_End	rs.b	0				; ''
kosMModules	rs.w	1				; Kosinski moduled decompression modules left
kosMLastSize	rs.w	1				; Kosinski moduled decompression last module size
kosMList	rs.b	$20*6				; Kosinski moduled decompression queue
kosMSource	equ	kosMList			; ''
kosMDestination	equ	kosMList+4			; ''
kosMList_End	rs.b	0				; ''
kosVars_End	rs.b	0				; End of Kosinski decompression queue variables

objRespawn	rs.b	$300				; Object respawn table
objRespawn_End	rs.b	0				; ''

objMemory	rs.b	0				; Object SSTs
		maxObjRAM $2400				; ''
objMemory_End	rs.b	0

OBJECT_COUNT	equ	(objMemory_End-objMemory)/_objSize

objExecute	rs.b	0				; Object execution list variables (DO NOT REARRANGE THE ORDER OF THESE!)
objExecExit	rs.l	1				; Pointer to a return intstruction that will exit object execution
objExecFirst	rs.w	1				; Pointer to the first object to be executed in the list
objExecLast	rs.w	1				; Pointer to the last object to be executed in the list
objExecFree	rs.w	1				; Pointer to the next free slot in object memory
objExecute_End	rs.b	0

objDisplay	equ __rs-dnext
		rs.b	dSize*8				; Sprite display input list (8 priority levels)
objDisplay_End	rs.b	0				; 

fgRowBuff	rs.b	$102				; Foreground horizontal plane buffer
fgColBuff	rs.b	$82				; Foreground vertical plane buffer
bgRowBuff	rs.b	$102				; Background horizontal plane buffer
bgColBuff	rs.b	$82				; Background vertical plane buffer

;ampsVars		rs.b	0			; AMPS variables
;		include	"Sound/amps/code/ram.asm"

		; --- ENGINE VARIABLES ---

ctrlDataP1	rs.b	0				; Controller 1 data
ctrlHoldP1	rs.b	1				; Controller 1 held button data
ctrlPressP1	rs.b	1				; Controller 1 pressed button data

ctrlDataP2	rs.b	0				; Controller 2 data
ctrlHoldP2	rs.b	1				; Controller 2 held button data
ctrlPressP2	rs.b	1				; Controller 2 pressed button data

hwVersion	rs.b	1				; Hardware version
vIntFlag	rs.b	0				; V-INT flag
vIntRoutine	rs.b	1				; V-INT routine

palFadeVars	rs.b	0				; Palette fade properties
palFadeStart	rs.b	1				; Palette fade start index
palFadeLength	rs.b	1				; Palette fade size
palFadeVars_End	rs.b	0

lagCounter	rs.b	1				; Lag frame counter
hIntFlag	rs.b	1				; H-INT run flag

vIntJump	rs.w	1				; Header will point here for V-INT
vIntAddress	rs.l	1				; V-INT address

hIntJump	rs.w	1				; Header will point here for H-INT
hIntAddress	rs.l	1				; H-INT address

frameCounter	rs.l	1				; Frame counter

opmode		rs.b	1				; Game opmode ID
spriteCount	rs.b	1				; Sprite count
pauseFlag	rs.b	1				; Pause flag
hIntUpdates	rs.b	1				; Level updates in H-INT flag

hIntCounter	rs.b	0
hIntCntReg	rs.b	1				; H-INT counter register
hIntCntValue	rs.b	1				; H-INT counter value

randomSeed	rs.l	1				; RNG seed

vdpReg1		rs.w	1				; VDP register 1 register ID and value
vdpWindowY	rs.w	1				; Window Y position (VDP register)

moveCheat	rs.b	1
artCheat	rs.b	1

oscillators	rs.b	0				; Oscillation numbers
oscControl	rs.w	1				; Oscillation control
oscValues	rs.w	$20				; Oscialltion data
oscillators_End	rs.b	0				; ''

		; --- GLOBAL VARIABLES ---

levelID		rs.b	0				; Level ID
zoneID		rs.b	1				; Zone ID
actID		rs.b	1				; Act ID

checkpoint	rs.b	0				; Checkpoint RAM
chkIDLast	rs.b	1				; Last checkpoint hit
		rs.b	1
chkSavedXPos	rs.w	1				; Saved player X position
chkSavedYPos	rs.w	1				; Saved player Y position
checkpoint_End	rs.b	0				; End of checkpoint RAM

objManager	rs.b	0
objMgrInit	rs.b	1				; Object manager initialized flag

rStartFall	rs.b	1				; Start level by falling flag

objMgrLayout	rs.l	1				; Object position data pointer
objMgrLoadR	rs.l	1				; Object data address (for going right)
objMgrLoadL	rs.l	1				; Object data address (for going left)
objMgrRespR	rs.w	1				; Object respawn address (for going right)
objMgrRespL	rs.w	1				; Object respawn address (for going left)
objMgrCoarseX	rs.w	1				; Object manager's coarse X position
objMgrCoarseY	rs.w	1				; Object manager's coarse Y position
objMgrCameraX	rs.w	1				; Object manager's camera X position
objMgrCameraY	rs.w	1				; Object manager's camera Y position
objManager_End	rs.b	0

palCycTimer	rs.b	1				; Palette cycle timer
palCycIndex	rs.b	1				; Palette cycle index

		; --- LOCAL VARIABLES ---

opmodeVars	rs.b	0				; Start of local game variables
		rs.b	((-__rs)&$FFFF)-$100		; You have the rest of RAM here for local variables
opmodeVars_End	rs.b	0				; End of local game variables

		; --- STACK SPACE ---

stackSpace	rs.b	$100				; Stack space
stack		rs.b	0				; ''
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Title screen variables
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsset	opmodeVars

	if __rs>=opmodeVars_End
		inform	3,"Title screen variables take too much space!"
	endif
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Level variables
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		rsset	opmodeVars
blockData	rs.b	$2000				; Block table

ringStatus	rs.b	$400				; Ring status table
ringStatus_End	rs.b	0				; ''

ringCollect	rs.b	0				; Ring collection table
ringColCount	rs.w	1				; Ring collection count
ringColList	rs.b	$7E				; Ring collection list
ringCollect_End	rs.b	0				; ''

scrollSects	rs.b	$384				; Scroll sections
scrollSects_End	rs.b	0				; ''

collideList	rs.b	$80				; Collision response list
collideList_End	rs.b	0				; ''

lvlLayout	rs.b	0				; Level layout addresses
lvlLayoutFG	rs.l	1				
lvlLayoutBG	rs.l	1

chunkDataPtr	rs.l	1

ringCount	rs.w	1				; Ring count
ringAnimFrame	rs.b	1				; Ring animation frame
ringAnimTime	rs.b	1				; Ring animation timer

ringLossAnimA	rs.w	1
ringLossAnimT	rs.b	1
ringLossAnimF	rs.b	1

ringMgrRoutine	rs.b	1				; Ring manager routine
hudUpdateRings	rs.b	1				; Update Ring counter in the HUD flag

ringMgrLayout	rs.l	1				; Ring position data pointer
ringMgrLoadL	rs.l	1				; Ring data address for the left side of the screen
ringMgrLoadR	rs.l	1				; Ring data address for the right side of the screen
ringMgrStatPtr	rs.w	1				; Ring status address

playerPtrP1	rs.w	1				; Player 1 object address
shieldPtrP1	rs.w	1				; Player 1 shield address
invincPtrP1	rs.w	1				; Player 1 invincibility address
afterImgPtrP1	rs.w	1				; Player 1 after image address

playerPtrP2	rs.w	1				; Player 2 object address
shieldPtrP2	rs.w	1				; Player 2 shield address
invincPtrP2	rs.w	1				; Player 2 invincibility address
afterImgPtrP2	rs.w	1				; Player 2 after image address

waterObjPtr1	rs.w	1				; Water surface 1 address
waterObjPtr2	rs.w	1				; Water surface 2 address

cameraVars	rs.b	0				; Camera RAM
fgCamVars	rs.b	cSize2				; Foreground variables
bgCamVars	rs.b	cSize2				; Background variables

targetMaxCamPos	rs.b	0				; Target maximum camera positions
targetMaxCamX	rs.w	1				; Target maximum camera X position
targetMaxCamY	rs.w	1				; Target maximum camera Y position

maxCamPos	rs.b	0				; Maximum camera positions
maxCamXPos	rs.w	1				; Maximum camera X position
maxCamYPos	rs.w	1				; Maximum camera Y position

targetMinCamPos	rs.b	0				; Target minimum camera positions
targetMinCamX	rs.w	1				; Target minimum camera X position
targetMinCamY	rs.w	1				; Target minimum camera Y position

minCamPos	rs.b	0				; Minimum camera positions
minCamXPos	rs.w	1				; Minimum camera X position
minCamYPos	rs.w	1				; Minimum camera Y position

panCamPos	rs.b	0
panCamXPos	rs.w	1				; Camera X center
panCamYPos	rs.w	1				; Distance from the player's Y position and the camera's

camLocked	rs.b	0				; Camera locked flags
camLockX	rs.b	1				; Camera locked horizontally flag
camLockY	rs.b	1				; Camera locked vertically flag

chgCamMaxY	rs.b	1				; Camera max Y position changing flag
cameraVars_End	rs.b	0				; End of camera RAM

debugMode	rs.b	1				; Debug placement mode

plrCtrlData	rs.b	0				; Player control data
plrCtrlHold	rs.b	1				; Player control held button data
plrCtrlPress	rs.b	1				; Player control pressed button data

lvlMusic	rs.b	1				; Level music ID
bossMusic	rs.b	1				; Boss music ID

primaryColPtr	rs.l	1				; Primary level collision data pointer
secondaryColPtr	rs.l	1				; Secondary level collision data pointer

currentColAddr	rs.l	1				; Current collsion address

layerPosition	rs.w	1				; Fake layer position

angleValPtr	rs.l	1				; Angle value array pointer
normColArrayPtr	rs.l	1				; Normal height map array pointer
rotColArrayPtr	rs.l	1				; Rotated height map array pointer

gotoNextLvl	rs.b	1				; Flag to go to the next level
bossDefeated	rs.b	1

lvlHasWater	rs.b	1				; Water in level flag
waterFullscr	rs.b	1				; Water fullscreen flag
waterYPos	rs.w	1				; Water height
destWaterYPos	rs.w	1				; Target water height

lvlFrameCnt	rs.w	1				; Level frame counter
lvlReload	rs.b	1				; Level reload flag
timeOver	rs.b	1				; Time over flag

dynEventRout	rs.b	1				; Dynamic event routine ID

rFlooactIDive	rs.b	1				; Floor active flag
rFloorTimer	rs.w	1				; Floor timer

lvlAnimCntrs	rs.b	$10				; Level art animation counters

	if __rs>=opmodeVars_End
		inform	3,"Level variables take too much space!"
	endif
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Camera variables
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
fgCamXPos	equ	fgCamVars+cXPos			; Camera X position
fgCamYPos	equ	fgCamVars+cYPos			; Camera Y position
bgCamXPos	equ	bgCamVars+cXPos			; Background camera X position
bgCamYPos	equ	bgCamVars+cYPos			; Background camera Y position
fgRedraw	equ	fgCamVars+cRedraw		; Foreground redraw flag
bgRedraw	equ	bgCamVars+cRedraw		; Background redraw flag
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Variables for the vector table
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
vInterrupt	equ	vIntJump			; V-INT
hInterrupt	equ	hIntJump			; H-INT
; =========================================================================================================================================================