; =========================================================================================================================================================
; Sound functions
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Load Mega PCM
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
LoadMegaPCM:
		nop
		lea	MegaPCM,a0			; Dual PCM driver
		lea	Z80_RAM,a1			; Z80 RAM
		move.w	#MegaPCM_End-MegaPCM-1,d1	; Size of the driver
		doZ80Stop				; Stop the Z80
		resetZ80Off				; Cancel Z80 reset
		waitZ80Stop				; Wait for the Z80 to be stopped

.LoadDriver:
		move.b	(a0)+,(a1)+			; Copy driver to Z80 RAM
		dbf	d1,.LoadDriver			; Loop

		resetZ80				; Reset the Z80
		moveq	#$7F,d1				; Wait
		dbf	d1,*				; ''
		startZ80				; Start the Z80
		resetZ80Off				; Cancel Z80 reset
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Play a DAC sample
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.b	- Sample ID
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
PlayDACSample:
		stopZ80
		move.b	d0,Z80_RAM+DAC_Number		; Play sample
		startZ80
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Play a DAC sample
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	cc	- Music not playing
;	cs	- Music playing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
CheckMusicPlaying:
		lea	rSMPS.w,a1			; Track RAM
		moveq	#9,d0				; Number of tracks

.CheckTrack:
		tst.b	(a1)				; Is the track playing?
		bmi.s	.IsPlaying			; If not, branch
		lea	SND_TRACK_LEN(a1),a1		; Next track
		dbf	d0,.CheckTrack			; Loop
		andi	#$FFFE,sr			; Music not playing
		rts

.IsPlaying:
		ori	#1,sr				; Music playing
		rts
; =========================================================================================================================================================