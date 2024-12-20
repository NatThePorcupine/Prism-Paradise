; =========================================================================================================================================================
; Hedgebrew Engine (Clean, Overhauled, Enhanced S3&K Engine)
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Configuration
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		include	"Config/Configuration.asm"	; Configuration

		include	"Config/Constants.asm"		; Constants
		include	"Config/Macros.asm"		; Macros
		include	"Config/Offsets.asm"		; Offsets
		include	"Config/Variables.asm"		; Variables

		include	"Config/Error/debugger.asm"	; Debugger macro set
		include "Sound/Definitions.asm"		; Include sound driver macros and functions
		
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Header
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		include	"Config/Header.asm"

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Entry point
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
GameInit:
		intsOff						; Disable interrupts
		
		clrRAM	RAM_START, RAM_END			; Clear RAM
		
		bsr.w	InitDMAQueue				; Initialize the DMA queue
		bsr.w	InitVDP					; Initialize the VDP
	;	jsr	LoadDualPCM				; Load Dual PCM
		
		move.b	HW_VERSION,d0				; Get hardware version
		andi.b	#$C0,d0					; Just get region bits
		move.b	d0,hwVersion.w				; Store in RAM

		move.w	#$4EF9,d0				; JMP opcode
		move.w	d0,vIntJump.w				; Set the "JMP" command for V-INT
		move.w	d0,hIntJump.w				; Set the "JMP" command for H-INT
		move.l	#VInt_Standard,vIntAddress.w		; Set the V-INT pointer to the standard V-INT routine
		move.l	#HInt_Water,hIntAddress.w			; Set the H-INT pointer to the standard V-INT routine

		clr.w	dmaQueue.w				; Set stop token at the beginning of the DMA queue
		move.w	#dmaQueue,dmaSlot.w			; Reset the DMA queue slot

		move.b	#gLevel,opmode.w			; Set game mode to "title"
		jmp	Level					; Go to the title screen

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Go to the correct game mode
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
GotoGameMode:
		moveq	#0,d0
		move.b	opmode.w,d0				; Get game mode ID
		movea.l	.GameModes(pc,d0.w),a0			; Get pointer
		jmp	(a0)					; Jump to it
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.GameModes:
		dc.l	TitleScreen				; Title screen
		dc.l	Level					; Level mode
		dc.l	Ending					; Ending

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Function libraries
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		include	"Libraries/VDP.asm"			; VDP functions
		include	"Libraries/Joypad.asm"			; Joypad functions
		include	"Libraries/Decompression.asm"		; Decompression functions
		include	"Libraries/Math.asm"			; Math functions
		include	"Libraries/Object.asm"			; Object functions
		include	"Libraries/Interrupt.asm"		; Interrupt functions

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Opmode Main Code
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		include	"Opmodes/Title/Main.asm"
		include	"Opmodes/Gameplay/Main.asm"
		include	"Opmodes/Ending/Main.asm"

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Object Code
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjNull:
		jmp	DeleteObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		include	"Objects/Player/Code.asm"		; Player object
		include	"Objects/Ring/Code.asm"			; Ring loss object
		include	"Objects/Explosion/Code.asm"		; Explosion object
		include	"Objects/Water Surface/Code.asm"	; Water surface object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		include	"Objects/Monitor/Code.asm"		; Monitor object
		include	"Objects/Spikes/Code.asm"		; Spike object
		include	"Objects/Spring/Code.asm"		; Spring object
		include	"Objects/Checkpoint/Code.asm"		; Checkpoint object
		include	"Objects/Wall Spring/Code.asm"		; Wall spring object
		include	"Objects/Ball Mode/Code.asm"		; Ball mode switch object
		include	"Objects/Bumper/Code.asm"		; Bumper object
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Unused/Temporary
;		include	"Objects/Slicer/Code.asm"		; Slicer object
;		include	"Objects/Shellcracker/Code.asm"		; Shellcracker object
;		include	"Objects/Asteron/Code.asm"		; Asteron object
;		include	"Objects/Boss - WFZ/Code.asm"		; WFZ boss object
;		include	"Objects/Harpoon/Code.asm"		; Harpoon object
;		include	"Objects/CNZ Barrel/Code.asm"		; CNZ barrel object
;		include	"Objects/Diamond/Code.asm"		; Diamond object
;		include	"Objects/Orbinaut/Code.asm"		; Orbinaut object

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Object Art
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtUnc_Sonic:
		incbin	"Graphics/Sprites/Sonic/Art.unc"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtKosM_Bumper:
		incbin	"Graphics/Sprites/Bumper/Art.kosm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtKosM_Chkpoint:
		incbin	"Graphics/Sprites/Checkpoint/Art.kosm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtKosM_DrownCnt:
		incbin	"Graphics/Sprites/Drown Countdown/Art.kosm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtKosM_Explosion:
		incbin	"Graphics/Sprites/Explosion/Art.kosm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtKosM_Monitor:
		incbin	"Graphics/Sprites/Monitor/Art.kosm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtUnc_Ring:
		incbin	"Graphics/Sprites/Ring/Art - Ring.unc"
		even

ArtKosM_RingSparkle:
		incbin	"Graphics/Sprites/Ring/Art - Sparkle.kosm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtKosM_SpikesN:
		incbin	"Graphics/Sprites/Spikes/Art - Normal.kosm"
		even

ArtKosM_SpikesS:
		incbin	"Graphics/Sprites/Spikes/Art - Sideways.kosm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtKosM_SpringH:
		incbin	"Graphics/Sprites/Spring/Art - Horizontal.kosm"
		even

ArtKosM_SpringV:
		incbin	"Graphics/Sprites/Spring/Art - Vertical.kosm"
		even

ArtKosM_SpringD:
		incbin	"Graphics/Sprites/Spring/Art - Diagonal.kosm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtKosM_WaterSplash:
		incbin	"Graphics/Sprites/Water Splash/Art.kosm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtKosM_WaterSurface:
		incbin	"Graphics/Sprites/Water Surface/Art.kosm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ArtKosM_HUD:
		incbin	"Graphics/Sprites/HUD/Art - HUD Base.kosm"
		even

ArtUnc_HUDNumbers:
		incbin	"Graphics/Sprites/HUD/Art - HUD Numbers.unc"
		dcb.l	16, 0
		even

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Level data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Wacky Workbench Zone

WWZ_FGLayout:
		incbin	"Zones/Wacky Workbench/Foreground.lvl"
		even
WWZ_BGLayout:
		incbin	"Zones/Wacky Workbench/Background.lvl"
		even

		dc.w	$FFFF, 0, 0				; Null object list entry
WWZ_Objects:
		incbin	"Zones/Wacky Workbench/Objects.bin"
		even
WWZ_Rings:
		incbin	"Zones/Wacky Workbench/Rings.bin"
		even
WWZ_Collision:
		dc.l	.ColData, .Angles, .Heights, .HeightsR
.ColData:
		incbin	"Zones/Wacky Workbench/Collision.bin"
		even
.Angles:
		incbin	"Zones/Wacky Workbench/Angle Values.bin"
		even
.Heights:
		incbin	"Zones/Wacky Workbench/Height Values.bin"
		even
.HeightsR:
		incbin	"Zones/Wacky Workbench/Height Values (Rotated).bin"
		even
WWZ_Chunks:
		incbin	"Zones/Wacky Workbench/Chunks.bin"
		even
WWZ_Blocks:
		incbin	"Zones/Wacky Workbench/Blocks.bin"
		even
WWZ_Pal:
		dc.w	$100>>1-1
		incbin	"Graphics/Palettes/Wacky Workbench/Normal.pal"
		incbin	"Graphics/Palettes/Wacky Workbench/Water.pal"
		even
WWZ_Tiles:
		incbin	"Graphics/Tilesets/Wacky Workbench/Tiles.kosm"
		even
ArtUnc_Electricity:
		incbin	"Graphics/Tilesets/Wacky Workbench/Electricity.unc"
		even
ArtUnc_ElectricOrbs:
		incbin	"Graphics/Tilesets/Wacky Workbench/Electric Orbs.unc"
		even
ArtUnc_Sirens:
		incbin	"Graphics/Tilesets/Wacky Workbench/Sirens.unc"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Sound driver
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		include "Sound/Engine/Sonic 2 Clone Driver v2.asm"	; Modified Clownacy's Sonic 2 Clone Driver
		include "Sound/Engine/MegaPCM.asm"			; Vladikcomper's MegaPCM 2.0

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Error handler
; -------------------------------------------------------------------------------------------------------------------------------------------------------
		include	"Config/Error/error.asm"
; =========================================================================================================================================================