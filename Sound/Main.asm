; =========================================================================================================================================================
; Sound Driver Data & Functions
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Configuration
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
		include	"Sound/Definition Macros (68K).asm"	; Driver Definition Macros (68K-Side)
		include "Sound/_smps2asm_inc.asm"		; SMPS2ASM Definitions

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load the Z80 sound driver program
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
SOUND_LoadDriver:
		lea	SOUND_Z80Driver,a0		; Z80 sound driver program
		lea	Z80_RAM,a1			; Z80 RAM
		move.w	#SOUND_EndOfDriver-SOUND_Z80Driver-1,d1	; Size of the driver
		doZ80Stop				; Stop the Z80
		resetZ80Off				; Cancel Z80 reset
		waitZ80Stop				; Wait for the Z80 to be stopped

.transferData:
		move.b	(a0)+,(a1)+			; Copy driver to Z80 RAM
		dbf	d1,.transferData		; Loop

		resetZ80				; Reset the Z80
		moveq	#$7F,d1				; Wait
		dbf	d1,*				; ''
		startZ80				; Start the Z80
		resetZ80Off				; Cancel Z80 reset
		rts

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Play a Music Track
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.b	Music ID
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
SOUND_PlayMusic:
		intsOff
		doZ80Stop				; Stop the Z80 so the 68k can write to Z80 RAM
		waitZ80Stop
		tst.b	(Z80_RAM+zQueueToPlay).l	; If this (zQueueToPlay) isn't $00, the driver is processing a previous sound request.
		bne.s	.altQueue			; If so, we'll put this sound in a different queue
		move.b	d0,(Z80_RAM+zQueueToPlay).l	; Queue sound
		startZ80				; Start the Z80 back up again so the sound driver can continue functioning
		intsOn
		rts

.altQueue:
		move.b  d0,(Z80_RAM+zSFXUnknown).l      ; Queue sound
		startZ80				; Start the Z80 back up again so the sound driver can continue functioning
		intsOn
		rts

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Play a Sound Effect
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.b	SFX ID
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
SOUND_PlaySFX:
		intsOff
		doZ80Stop				; Stop the Z80 so the 68k can write to Z80 RAM
		waitZ80Stop
		tst.b	(Z80_RAM+zSFXToPlay).l		; Is this queue occupied?
		bne.s	.altQueue			; If so, we'll put this sound in a different queue
		move.b	d0,(Z80_RAM+zSFXToPlay).l	; Queue sound
		startZ80				; Start the Z80 back up again so the sound driver can continue functioning
		intsOn
		rts

.altQueue:
		move.b  d0,(Z80_RAM+zSFXStereoToPlay).l	; Queue sound
		startZ80				; Start the Z80 back up again so the sound driver can continue functioning
		intsOn
		rts

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Z80 Sound Driver
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
SOUND_Z80Driver:
	pusho
	opt	an+, ae-
	obj	$0000	
		incbin	"Sound/Driver/Driver Program.bin"
		include	"Sound/Driver/Driver Definitions.asm"
	objend
	popo
SOUND_EndOfDriver:

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; SFX Pointers and Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
SOUND_SFXBank:		start_bank

SOUND_SFXIndex:		rsset	SndID__First
SndID_Jump		sfx_ptr_entry	SFX_Jump
SndID_Checkpoint	sfx_ptr_entry	SFX_Checkpoint
SndID_Hurt		sfx_ptr_entry	SFX_Hurt
SndID_Skidding		sfx_ptr_entry	SFX_Skidding
SndID_Push		sfx_ptr_entry	SFX_Pushing
SndID_Splash		sfx_ptr_entry	SFX_Splash
SndID_BossHit		sfx_ptr_entry	SFX_BossHit
SndID_InhalingBubble	sfx_ptr_entry	SFX_InhalingBubble
SndID_LavaBall		sfx_ptr_entry	SFX_LavaBall
SndID_Shield		sfx_ptr_entry	SFX_Shield
SndID_Drown		sfx_ptr_entry	SFX_Drown
SndID_Bumper		sfx_ptr_entry	SFX_Bumper
SndID_Ring		sfx_ptr_entry	SFX_RingRight
SndID_SpikesMove	sfx_ptr_entry	SFX_SpikesMove
SndID_Smash		sfx_ptr_entry	SFX_Smash
SndID_SpindashRelease	sfx_ptr_entry	SFX_SpindashRelease
SndID_Roll		sfx_ptr_entry	SFX_Roll
SndID_TallyEnd		sfx_ptr_entry	SFX_TallyEnd
SndID_RingSpill		sfx_ptr_entry	SFX_RingSpill
SndID_Spring		sfx_ptr_entry	SFX_Spring
SndID_Switch		sfx_ptr_entry	SFX_Switch
SndID_RingLeft		sfx_ptr_entry	SFX_RingLeft
SndID_Signpost		sfx_ptr_entry	SFX_Signpost
SndID_LargeBumper	sfx_ptr_entry	SFX_LargeBumper
SndID_SpindashRev	sfx_ptr_entry	SFX_SpindashRev
SndID_Flipper		sfx_ptr_entry	SFX_Flipper

SFX_Jump:		include	"Sound/SFX/A0 - Jump.asm"
SFX_Checkpoint:		include "Sound/SFX/A1 - Checkpoint.asm"
SFX_Hurt:		include "Sound/SFX/A3 - Hurt.asm"
SFX_Skidding:		include "Sound/SFX/A4 - Skidding.asm"
SFX_Pushing:		include "Sound/SFX/A5 - Block Push.asm"
SFX_SpikesHurt:		include "Sound/SFX/A6 - Hurt by Spikes.asm"
SFX_Splash:		include "Sound/SFX/AA - Splash.asm"
SFX_BossHit:		include "Sound/SFX/AC - Boss Hit.asm"
SFX_InhalingBubble:	include "Sound/SFX/AD - Inhaling Bubble.asm"
SFX_LavaBall:		include "Sound/SFX/AE - Lava Ball.asm"
SFX_Shield:		include "Sound/SFX/AF - Shield.asm"
SFX_Drown:		include "Sound/SFX/B2 - Drown.asm"
SFX_Bumper:		include "Sound/SFX/B4 - Bumper.asm"
SFX_RingRight:		include "Sound/SFX/B5 - Ring.asm"
SFX_SpikesMove:		include "Sound/SFX/B6 - Spikes Move.asm"
SFX_Smash:		include "Sound/SFX/B9 - Smash.asm"
SFX_SpindashRelease:	include "Sound/SFX/BC - Spin Dash Release.asm"
SFX_Roll:		include "Sound/SFX/BE - Roll.asm"
SFX_TallyEnd:		include "Sound/SFX/C5 - Tally End.asm"
SFX_RingSpill:		include "Sound/SFX/C6 - Ring Spill.asm"
SFX_Spring:		include "Sound/SFX/CC - Spring.asm"
SFX_Switch:		include "Sound/SFX/CD - Switch.asm"
SFX_RingLeft:		include "Sound/SFX/CE - Ring Left Speaker.asm"
SFX_Signpost:		include "Sound/SFX/CF - Signpost.asm"
SFX_LargeBumper:	include "Sound/SFX/D9 - Large Bumper.asm"
SFX_SpindashRev:	include "Sound/SFX/E0 - Spin Dash Rev.asm"
SFX_Flipper:		include "Sound/SFX/E3 - Flipper.asm"
			end_bank

; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Music Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
SOUND_MusicBank:	start_bank

MUSIC_MTZ:		include	"Sound/Music/Metropolis Zone.asm"
MUSIC_Invincible:	include	"Sound/Music/Invincibility.asm"
MUSIC_ExtraLife:	include	"Sound/Music/Extra Life.asm"
MUSIC_Boss:		include	"Sound/Music/Boss.asm"
MUSIC_GotThrough:	include	"Sound/Music/Act Clear.asm"
MUSIC_GameOver:		include	"Sound/Music/Game Over.asm"
MUSIC_Continue:		include	"Sound/Music/Continue.asm"
MUSIC_Drowning:		include	"Sound/Music/Drowning.asm"
MUSIC_Emerald:		include	"Sound/Music/Got Emerald.asm"
			end_bank
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; PCM Data
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
SndDAC_Sample1:	incbin	"Sound/PCM/kick.pcm"
		even
SndDAC_Sample2:	incbin	"Sound/PCM/snare.pcm"
		even
SndDAC_Sample5:	incbin	"Sound/PCM/timpani.pcm"
		even
SndDAC_Sample6:	incbin	"Sound/PCM/Tom.pcm"
		even
SndDAC_Sample3:	incbin	"Sound/PCM/Clap.pcm"
		even
SndDAC_Sample4:	incbin	"Sound/PCM/Scratch.pcm"
		even
SndDAC_Sample7:	incbin	"Sound/PCM/Bongo.pcm"
		even
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
