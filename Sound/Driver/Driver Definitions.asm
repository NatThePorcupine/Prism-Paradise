; =========================================================================================================================================================
; Driver Definitions
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Music and Sample Playlists
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
zMasterPlaylist:	rsset 1
MusID__First:		equ __rs
MusID_MTZ:		music_entry MUSIC_MTZ
MusID_Invincible:	music_entry MUSIC_Invincible
MusID_ExtraLife:	music_entry MUSIC_ExtraLife
MusID_Boss:		music_entry MUSIC_Boss
MusID_GotThrough:	music_entry MUSIC_GotThrough
MusID_GameOver:		music_entry MUSIC_GameOver,1
MusID_Continue:		music_entry MUSIC_Continue
MusID_Drowning:		music_entry MUSIC_Drowning,1
MusID_Emerald:		music_entry MUSIC_Emerald
MusID__End:		equ __rs

zDACPtrTbl:		rsset 80h
SampleID_Kick:		pcm_ptr_entry SndDAC_Sample1
SampleID_Snare:		pcm_ptr_entry SndDAC_Sample2
SampleID_Timpani:	pcm_ptr_entry SndDAC_Sample5
SampleID_Clap:		pcm_ptr_entry SndDAC_Sample3
SampleID_Scratch:	pcm_ptr_entry SndDAC_Sample4
SampleID_Tom:		pcm_ptr_entry SndDAC_Sample6
SampleID_Bongo:		pcm_ptr_entry SndDAC_Sample7

zDACMasterPlaylist:	rsset 81h
	pcm_id_entry	SampleID_Kick,0Ch
	pcm_id_entry	SampleID_Snare,1
	pcm_id_entry	SampleID_Timpani,0Dh
	pcm_id_entry	SampleID_Timpani,9
	pcm_id_entry	SampleID_Timpani,0Bh
	pcm_id_entry	SampleID_Timpani,0Eh
	pcm_id_entry	SampleID_Timpani,0Fh
	pcm_id_entry	SampleID_Clap,2
	pcm_id_entry	SampleID_Scratch,6
	pcm_id_entry	SampleID_Tom,5
	pcm_id_entry	SampleID_Bongo,0Dh
	pcm_id_entry	SampleID_Tom,1
	pcm_id_entry	SampleID_Tom,2
	pcm_id_entry	SampleID_Tom,4
	pcm_id_entry	SampleID_Bongo,4
	pcm_id_entry	SampleID_Bongo,5
	pcm_id_entry	SampleID_Bongo,9

zDACBanks:
	bank_entry	SndDAC_Sample1
	bank_entry	SndDAC_Sample2
	bank_entry	SndDAC_Sample5
	bank_entry	SndDAC_Sample3
	bank_entry	SndDAC_Sample4
	bank_entry	SndDAC_Sample6
	bank_entry	SndDAC_Sample7

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Indeterminate Data (IDs, banks, and addresses that are unknown until the 68K ROM is built)
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
zSFXBank:	bank_entry	SOUND_SFXIndex
zSFXAddr:	ptr_entry	SOUND_SFXIndex

zSFXRingR:	id_entry	SndID_Ring
zSFXRingL:	id_entry	SndID_RingLeft
zSFXPushing:	id_entry	SndID_Push
zSFXSpinRev:	id_entry	SndID_SpindashRev
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Constants
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
CmdID__First: 	equ	0FBh
CmdID__End:	equ	100h
SndID__First:	equ	MusID__End
SndID__End:	equ	CmdID__First
FlgID_Pause:	equ	7Fh
FlgID_Unpause:	equ	80h
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Shared Symbols
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
	shared	zStreamOutput							; Labels
	shared	zQueueToPlay, zSFXToPlay, zSFXStereoToPlay, zSFXUnknown		; Sound Queue Variables
	shared	zAbsVar.StopMusic						; Additional Communication Variables
; ---------------------------------------------------------------------------------------------------------------------------------------------------------