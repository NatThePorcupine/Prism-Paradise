; =========================================================================================================================================================
; Explosion object
; =========================================================================================================================================================
EXPLODE_ANI	EQU	3
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjBossExplode:
		;playsnd	#sBomb, 2			; Play explosion sound
		move.b	#SndID_BossExplosion,d0
		jsr	SOUND_PlaySFX
		bra.w	ObjExplosion_Init		; Continue
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ObjExplosion:
		;playsnd	#sBreakItem, 2			; Play explosion sound
		move.b	#SndID_Explosion,d0
		jsr	SOUND_PlaySFX

ObjExplosion_Init:
		move.l	#ObjExplosion_Main,_objAddress(a0)	; Next routine
		move.b	#4,_objRender(a0)			; Render flags
		move.w	#$86C0,_objVRAM(a0)		; Tile properties
		move.l	#Map_ObjExplosion,_objMapping(a0)	; Mappings
	displaySprite	1,a0,a1,0			; Priority
		move.b	#$C,_objDrawW(a0)			; Sprite width
		move.b	#$C,_objDrawH(a0)			; Sprite height
		move.b	#EXPLODE_ANI,_objAnimTimer(a0)	; Animation timer
		clr.b	_objFrame(a0)			; Mapping frame
		
ObjExplosion_Main:
		subq.b	#1,_objAnimTimer(a0)		; Decrement animation timer
		bpl.s	.Display			; If it hasn't run out, branch
		move.b	#EXPLODE_ANI,_objAnimTimer(a0)	; Reset animation timer
		addq.b	#1,_objFrame(a0)			; Next frame
		cmpi.b	#5,_objFrame(a0)			; Has it reached the last frame?
		bne.s	.Display			; If not, branch
		jsr	DeleteObject.w
		
.Display:
	nextObject
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
Map_ObjExplosion:
		include	"Objects/Explosion/Mappings.asm"
		even
; =========================================================================================================================================================