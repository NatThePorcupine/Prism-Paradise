; =============================================================================================
; Created by Flamewing, based on S1SMPS2ASM version 1.1 by Marc Gordon (AKA Cinossu)
; =============================================================================================

; PSG conversion to S3/S&K/S3D drivers require a tone shift of 12 semi-tones.
psgdelta	EQU 12

; SMPS2ASM uses nMaxPSG for songs from S1/S2 drivers.
; nMaxPSG1 and nMaxPSG2 are used only for songs from S3/S&K/S3D drivers.
; The use of psgdelta is intended to undo the effects of PSGPitchConvert
; and ensure that the ending note is indeed the maximum PSG frequency.
nMaxPSG				EQU nBb6-psgdelta
nMaxPSG1			EQU nBb6
nMaxPSG2			EQU nB6
; ---------------------------------------------------------------------------------------------
; Standard Octave Pitch Equates
smpsPitch10lo:	EQU -120	; $88
smpsPitch09lo:	EQU -108	; $94
smpsPitch08lo:	EQU  -96	; $A0
smpsPitch07lo:	EQU  -84	; $AC
smpsPitch06lo:	EQU  -72	; $B8
smpsPitch05lo:	EQU  -60	; $C4
smpsPitch04lo:	EQU  -48	; $D0
smpsPitch03lo:	EQU  -36	; $DC
smpsPitch02lo:	EQU  -24	; $E8
smpsPitch01lo:	EQU  -12	; $F4
smpsPitch00:	EQU    0	; $00
smpsPitch01hi:	EQU  +12	; $0C
smpsPitch02hi:	EQU  +24	; $18
smpsPitch03hi:	EQU  +36	; $24
smpsPitch04hi:	EQU  +48	; $30
smpsPitch05hi:	EQU  +60	; $3C
smpsPitch06hi:	EQU  +72	; $48
smpsPitch07hi:	EQU  +84	; $54
smpsPitch08hi:	EQU  +96	; $60
smpsPitch09hi:	EQU +108	; $6C
smpsPitch10hi:	EQU +120	; $78
; ---------------------------------------------------------------------------------------------
; Note Equates
	enumset	$80
	enum	nRst,nC0,nCs0,nD0,nEb0,nE0,nF0,nFs0,nG0,nAb0,nA0,nBb0,nB0,nC1,nCs1,nD1
	enum	nEb1,nE1,nF1,nFs1,nG1,nAb1,nA1,nBb1,nB1,nC2,nCs2,nD2,nEb2,nE2,nF2,nFs2
	enum	nG2,nAb2,nA2,nBb2,nB2,nC3,nCs3,nD3,nEb3,nE3,nF3,nFs3,nG3,nAb3,nA3,nBb3
	enum	nB3,nC4,nCs4,nD4,nEb4,nE4,nF4,nFs4,nG4,nAb4,nA4,nBb4,nB4,nC5,nCs5,nD5
	enum	nEb5,nE5,nF5,nFs5,nG5,nAb5,nA5,nBb5,nB5,nC6,nCs6,nD6,nEb6,nE6,nF6,nFs6
	enum	nG6,nAb6,nA6,nBb6,nB6,nC7,nCs7,nD7,nEb7,nE7,nF7,nFs7,nG7,nAb7,nA7,nBb7
; ---------------------------------------------------------------------------------------------
; PSG volume envelope equates
	enumset	$01
	enum	fTone_01,fTone_02,fTone_03,fTone_04,fTone_05,fTone_06
	enum	fTone_07,fTone_08,fTone_09
	enum	fTone_0A,fTone_0B,fTone_0C,fTone_0D
; ---------------------------------------------------------------------------------------------
; DAC Equates
	enumset	$81
	enum	dKick,dSnare,dTimpani,dHiTimpani,dMidTimpani,dLowTimpani,dVLowTimpani
	enum	dClap,dScratch,dHiTom,dVLowClap,dMidTom,dLowTom,dFloorTom,dHiClap
	enum	dMidClap,dLowClap
; ---------------------------------------------------------------------------------------------
; Channel IDs for SFX
cPSG1				EQU $80
cPSG2				EQU $A0
cPSG3				EQU $C0
cNoise				EQU $E0	; Not for use in S3/S&K/S3D
cFM3				EQU $02
cFM4				EQU $04
cFM5				EQU $05
cFM6				EQU $06	; Only in S3/S&K/S3D, overrides DAC
; ---------------------------------------------------------------------------------------------
; Conversion macros and functions

; conv0To256  function n,((n==0)<<8)|n
; s2TempotoS1 function n,(((768-n)>>1)/(256-n))&$FF
; s2TempotoS3 function n,($100-((n==0)|n))&$FF
; s1TempotoS2 function n,((((conv0To256(n)-1)<<8)+(conv0To256(n)>>1))/conv0To256(n))&$FF
; s1TempotoS3 function n,s2TempotoS3(s1TempotoS2(n))
; s3TempotoS1 function n,s2TempotoS1(s2TempotoS3(n))
; s3TempotoS2 function n,s2TempotoS3(n)

s2TempotoS3	macro	mod
		dc.b	($100-((-(\mod=0))|\mod))&$FF
		endm

s1TempotoS3	macro	mod
		local	conv0To256, s1TempotoS2
conv0To256	=	((-(\mod=0))<<8)|\mod
s1TempotoS2	=	((((conv0To256-1)<<8)+(conv0To256>>1))/conv0To256)&$FF
	s2TempotoS3	(s1TempotoS2)
		endm

convertMainTempoMod macro mod
	if SourceDriver=2
		s2TempotoS3	\mod
	elseif SourceDriver=1
		if \mod=1
			inform	3,"Invalid main tempo of 1 in song from Sonic 1"
		endif
		s1TempotoS3	\mod
	else;if SourceDriver>=3
		if \mod=0
			inform	0,"Performing approximate conversion of Sonic 3 main tempo modifier of 0"
		endif
		dc.b	\mod
	endif
	endm

; PSG conversion to S3/S&K/S3D drivers require a tone shift of 12 semi-tones.
PSGPitchConvert macro pitch
	if SourceDriver<3
		dc.b	(\pitch+psgdelta)&$FF
	else
		dc.b	\pitch
	endif
	endm
; ---------------------------------------------------------------------------------------------
; Header Macros
smpsHeaderStartSong macro ver
SourceDriver set ver
songStart set *
	endm

smpsHeaderStartSongConvert macro ver
SourceDriver set ver
songStart set *
	endm

smpsHeaderVoiceNull macro
	if songStart<>*
		inform	3,"Missing smpsHeaderStartSong or smpsHeaderStartSongConvert"
	endif
	dc.w	$0000
	endm

; Header - Set up Voice Location
; Common to music and SFX
smpsHeaderVoice macro loc
	if songStart<>*
		inform	3,"Missing smpsHeaderStartSong or smpsHeaderStartSongConvert"
	endif
	ptr_entry	\loc
	endm

; Header - Set up Voice Location as S3's Universal Voice Bank
; Common to music and SFX
smpsHeaderVoiceUVB macro
	if songStart<>*
		inform	3,"Missing smpsHeaderStartSong or smpsHeaderStartSongConvert"
	endif
	inform	3,"This driver does not support UVB"
	endm

; Header macros for music (not for SFX)
; Header - Set up Channel Usage
smpsHeaderChan macro fm, psg
	dc.b	\fm, \psg
	endm

; Header - Set up Tempo
smpsHeaderTempo macro div, mod
	dc.b	\div
	convertMainTempoMod \mod
	endm

; Header - Set up DAC Channel
smpsHeaderDAC macro loc, pitch, vol
	ptr_entry	\loc
	
	if narg>=2
		dc.b	\pitch
	else
		dc.b	$00
	endif
	
	if narg>=3
		dc.b	\vol
	else
		dc.b	$00
	endif
	endm

; Header - Set up FM Channel
smpsHeaderFM macro loc, pitch, vol
	ptr_entry	\loc
	dc.b	\pitch, \vol
	endm

; Header - Set up PSG Channel
smpsHeaderPSG macro loc, pitch, vol, mod, voice
	ptr_entry	\loc
	PSGPitchConvert	\pitch
	dc.b	\vol, \mod, \voice
	endm

; Header macros for SFX (not for music)
; Header - Set up Tempo
smpsHeaderTempoSFX macro div
	dc.b	\div
	endm

; Header - Set up Channel Usage
smpsHeaderChanSFX macro chan
	dc.b	\chan
	endm

; Header - Set up FM Channel
smpsHeaderSFXChannel macro chanid, loc, pitch, vol
	if \chanid=cFM6
		inform	3,"Using channel ID of FM6 ($06) in Sonic 1 or Sonic 2 drivers is unsupported. Change it to another channel."
	endif
	dc.b	$80, \chanid
	ptr_entry	\loc
	if (\chanid&$80)<>0
		PSGPitchConvert \pitch
	else
		dc.b	\pitch
	endif
	dc.b	\vol
	endm
; ---------------------------------------------------------------------------------------------
; Co-ord Flag Macros and Equates
; E0xx - Panning, AMS, FMS
smpsPan macro direction, amsfms
panNone set $00
panRight set $40
panLeft set $80
panCentre set $C0
panCenter set $C0
	dc.b $E0, \direction+\amsfms
	endm

; E1xx - Set channel frequency displacement to xx
smpsAlterNote macro val
	dc.b	$E1, \val
	endm

; E2xx - Useless
smpsNop macro val
	dc.b	$E2, \val
	endm

; Return (used after smpsCall)
smpsReturn macro val
	dc.b	$E3
	endm

; Fade in previous song (ie. 1-Up)
smpsFade macro val
	dc.b	$E4
	endm

; E5xx - Set channel tempo divider to xx
smpsChanTempoDiv macro val
	dc.b	$E5, \val
	endm

; E6xx - Alter Volume by xx
smpsAlterVol macro val
	dc.b	$E6, \val
	endm

; E7 - Prevent attack of next note
smpsNoAttack	EQU $E7

; E8xx - Set note fill to xx
smpsNoteFill macro val
	if SourceDriver>=3
		inform	0,"Note fill will not work as intended unless you multiply the fill value by the tempo divider."
	endif
	dc.b	$E8, \val
	endm

; Add xx to channel pitch
smpsAlterPitch macro val
	dc.b	$E9, \val
	endm

; Set music tempo modifier to xx
smpsSetTempoMod macro mod
	dc.b	$EA
	convertMainTempoMod \mod
	endm

; Set music tempo divider to xx
smpsSetTempoDiv macro val
	dc.b	$EB, \val
	endm

; ECxx - Set Volume to xx
smpsSetVol macro val
	inform	3,"Coord. Flag to set volume (instead of volume attenuation) does not exist in S1 or S2 drivers."
	endm

; Works on all drivers
smpsPSGAlterVol macro vol
	dc.b	$EC, \vol
	endm

smpsPSGAlterVolS2 macro vol
	; Sonic 2's driver allows the FM command to be used on PSG channels, but others do not.
	smpsPSGAlterVol \vol
	endm

; Clears pushing sound flag in S1
smpsClearPush macro
	dc.b	$ED
	endm

; Stops special SFX (S1 only) and restarts overridden music track
smpsStopSpecial macro
	dc.b	$EE
	endm

; EFxx[yy] - Set Voice of FM channel to xx; xx < 0 means yy present
smpsSetvoice macro voice, songID
	dc.b	$EF, \voice
	endm

; F0wwxxyyzz - Modulation - ww: wait time - xx: modulation speed - yy: change per step - zz: number of steps
smpsModSet macro wait, speed, change, step
	local	step0To256, speed0To256
	dc.b	$F0
	if SourceDriver>=3
step0To256	=	((-(\step=0))<<8)|\step
speed0To256	=	((-(\speed=0))<<8)|\speed
		dc.b	\wait-1, \speed, \change, step0To256/speed0To256-1
	else
		dc.b	\wait, \speed, \change, \step
	endif
	;dc.b	speed,change,step
	endm

; Turn on Modulation
smpsModOn macro
	dc.b	$F1
	endm

; F2 - End of channel
smpsStop macro
	dc.b	$F2
	endm

; F3xx - PSG waveform to xx
smpsPSGform macro form
	dc.b	$F3, \form
	endm

; Turn off Modulation
smpsModOff macro
	dc.b	$F4
	endm

; F5xx - PSG voice to xx
smpsPSGvoice macro voice
	dc.b	$F5, \voice
	endm

; F6xxxx - Jump to xxxx
smpsJump macro loc
	dc.b	$F6
	ptr_entry	\loc
	endm

; F7xxyyzzzz - Loop back to zzzz yy times, xx being the loop index for loop recursion fixing
smpsLoop macro index, loops, loc
	dc.b	$F7
	dc.b	\index, \loops
	ptr_entry	\loc
	endm

; F8xxxx - Call pattern at xxxx, saving return point
smpsCall macro loc
	dc.b	$F8
	ptr_entry	\loc
	endm
; ---------------------------------------------------------------------------------------------
; Alter Volume
smpsFMAlterVol macro val1, val2
	dc.b	$E6, \val1
	endm

; ---------------------------------------------------------------------------------------------
; S1/S2 only coordination flag
; Sets D1L to maximum volume (minimum attenuation) and RR to maximum for operators 3 and 4 of FM1
smpsWeirdD1LRR macro
	dc.b	$F9
	endm
; ---------------------------------------------------------------------------------------------
; Macros for FM instruments
; Voices - Feedback
smpsVcFeedback macro val
vcFeedback set \val
	endm

; Voices - Algorithm
smpsVcAlgorithm macro val
vcAlgorithm set \val
	endm

smpsVcUnusedBits macro val
vcUnusedBits set \val
	endm

; Voices - Detune
smpsVcDetune macro op1, op2, op3, op4
vcDT1 set \op1
vcDT2 set \op2
vcDT3 set \op3
vcDT4 set \op4
	endm

; Voices - Coarse-Frequency
smpsVcCoarseFreq macro op1, op2, op3, op4
vcCF1 set \op1
vcCF2 set \op2
vcCF3 set \op3
vcCF4 set \op4
	endm

; Voices - Rate Scale
smpsVcRateScale macro op1, op2, op3, op4
vcRS1 set \op1
vcRS2 set \op2
vcRS3 set \op3
vcRS4 set \op4
	endm

; Voices - Attack Rate
smpsVcAttackRate macro op1, op2, op3, op4
vcAR1 set \op1
vcAR2 set \op2
vcAR3 set \op3
vcAR4 set \op4
	endm

; Voices - Amplitude Modulation
smpsVcAmpMod macro op1, op2, op3, op4
vcAM1 set \op1
vcAM2 set \op2
vcAM3 set \op3
vcAM4 set \op4
	endm

; Voices - First Decay Rate
smpsVcDecayRate1 macro op1, op2, op3, op4
vcD1R1 set \op1
vcD1R2 set \op2
vcD1R3 set \op3
vcD1R4 set \op4
	endm

; Voices - Second Decay Rate
smpsVcDecayRate2 macro op1, op2, op3, op4
vcD2R1 set \op1
vcD2R2 set \op2
vcD2R3 set \op3
vcD2R4 set \op4
	endm

; Voices - Decay Level
smpsVcDecayLevel macro op1, op2, op3, op4
vcDL1 set \op1
vcDL2 set \op2
vcDL3 set \op3
vcDL4 set \op4
	endm

; Voices - Release Rate
smpsVcReleaseRate macro op1, op2, op3, op4
vcRR1 set \op1
vcRR2 set \op2
vcRR3 set \op3
vcRR4 set \op4
	endm

; Voices - Total Level
smpsVcTotalLevel macro op1, op2, op3, op4
vcTL1 set \op1
vcTL2 set \op2
vcTL3 set \op3
vcTL4 set \op4
	dc.b	(vcUnusedBits<<6)+(vcFeedback<<3)+vcAlgorithm
;   0     1     2     3     4     5     6     7
;%1000,%1000,%1000,%1000,%1010,%1110,%1110,%1111
vcTLMask4 set ((vcAlgorithm=7)<<7)
vcTLMask3 set ((vcAlgorithm>=4)<<7)
vcTLMask2 set ((vcAlgorithm>=5)<<7)
vcTLMask1 set $80
	dc.b	(vcDT4<<4)+vcCF4 ,(vcDT2<<4)+vcCF2 ,(vcDT3<<4)+vcCF3 ,(vcDT1<<4)+vcCF1
	dc.b	(vcRS4<<6)+vcAR4 ,(vcRS2<<6)+vcAR2 ,(vcRS3<<6)+vcAR3 ,(vcRS1<<6)+vcAR1
	dc.b	(vcAM4<<5)+vcD1R4,(vcAM2<<5)+vcD1R2,(vcAM3<<5)+vcD1R3,(vcAM1<<5)+vcD1R1
	dc.b	vcD2R4           ,vcD2R2           ,vcD2R3           ,vcD2R1
	dc.b	(vcDL4<<4)+vcRR4 ,(vcDL2<<4)+vcRR2 ,(vcDL3<<4)+vcRR3 ,(vcDL1<<4)+vcRR1
	dc.b	vcTL4|vcTLMask4  ,vcTL2|vcTLMask2  ,vcTL3|vcTLMask3  ,vcTL1|vcTLMask1
	endm

