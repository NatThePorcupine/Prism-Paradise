; =========================================================================================================================================================
; Driver Definitions
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Music and Sample Playlists
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
zMasterPlaylist:	rsset 1
MusID__First:		equ __rs
MusID_MTZ:		music_entry Mus_MTZ
MusID_Invincible:	music_entry Mus_Invincible
MusID_ExtraLife:	music_entry Mus_ExtraLife
MusID_Boss:		music_entry Mus_Boss
MusID_GotThrough:	music_entry Mus_GotThrough
MusID_GameOver:		music_entry Mus_GameOver,1
MusID_Continue:		music_entry Mus_Continue
MusID_Drowning:		music_entry Mus_Drowning,1
MusID_Emerald:		music_entry Mus_Emerald
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
	pcm_id_entry	SampleID_Kick,6
	pcm_id_entry	SampleID_Snare,2
	pcm_id_entry	SampleID_Timpani,0Ch
	pcm_id_entry	SampleID_Timpani,5
	pcm_id_entry	SampleID_Timpani,8
	pcm_id_entry	SampleID_Timpani,0Ah
	pcm_id_entry	SampleID_Timpani,0Eh
	pcm_id_entry	SampleID_Clap,6+2
	pcm_id_entry	SampleID_Scratch,8+2
	pcm_id_entry	SampleID_Tom,0Ah+2
	pcm_id_entry	SampleID_Bongo,1Bh+2
	pcm_id_entry	SampleID_Tom,2+2
	pcm_id_entry	SampleID_Tom,5+2
	pcm_id_entry	SampleID_Tom,8+2
	pcm_id_entry	SampleID_Bongo,8+2
	pcm_id_entry	SampleID_Bongo,0Bh+2
	pcm_id_entry	SampleID_Bongo,12h+2

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
zSFXAddr:	address_entry	SOUND_SFXIndex

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
; ---------------------------------------------------------------------------------------------------------------------------------------------------------