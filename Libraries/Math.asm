; =========================================================================================================================================================
; General Math Functions
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Generates a 32-bit pseudo-random number
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	None
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	d0.l	- Pseudo-random number
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
MATH_GetRandom:
		move.l	(randomSeed).w,d0		; Load the value of the previous random seed
		beq.s	.initSeed			; If the seed value is zero (uninitialized), branch ahead

		add.l	d0,d0				; Otherwise, double the current value seed value
		bls.s	.setSeed			; If the carry flag was set, or the result is zero, branch ahead

.initSeed:	
		eori.l  #$741B8CD7,d0			; Otherwise, perform an exclusive-OR against a magic number

.setSeed:	
		move.l  d0,(randomSeed).w		; Update the random seed value stored in memory
		rts					; Return

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Returns the sine/cosine values of a given angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d0.b	- Angle
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	d0.w	- Sine value
;	d1.w	- Cosine value	
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
MATH_GetSinCos:
		andi.w	#$FF,d0				; Restrict inputs to fall within a single rotation ($00-$FF)
		addq.w	#8,d0				; Turn the angle value into offset into the look-up table
		add.w	d0,d0				; ^
		move.w	.sinCosData-$10+$80(pc,d0.w),d1	; Get the cosine value
		move.w	.sinCosData-$10(pc,d0.w),d0	; Get the sine value
		rts					; Return
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.sinCosData:
		dc.w	$0000, $0006, $000C, $0012, $0019, $001F, $0025, $002B, $0031, $0038, $003E, $0044, $004A, $0050, $0056, $005C
		dc.w	$0061, $0067, $006D, $0073, $0078, $007E, $0083, $0088, $008E, $0093, $0098, $009D, $00A2, $00A7, $00AB, $00B0
		dc.w	$00B5, $00B9, $00BD, $00C1, $00C5, $00C9, $00CD, $00D1, $00D4, $00D8, $00DB, $00DE, $00E1, $00E4, $00E7, $00EA
		dc.w	$00EC, $00EE, $00F1, $00F3, $00F4, $00F6, $00F8, $00F9, $00FB, $00FC, $00FD, $00FE, $00FE, $00FF, $00FF, $00FF
		
		dc.w	$0100, $00FF, $00FF, $00FF, $00FE, $00FE, $00FD, $00FC, $00FB, $00F9, $00F8, $00F6, $00F4, $00F3, $00F1, $00EE
		dc.w	$00EC, $00EA, $00E7, $00E4, $00E1, $00DE, $00DB, $00D8, $00D4, $00D1, $00CD, $00C9, $00C5, $00C1, $00BD, $00B9
		dc.w	$00B5, $00B0, $00AB, $00A7, $00A2, $009D, $0098, $0093, $008E, $0088, $0083, $007E, $0078, $0073, $006D, $0067
		dc.w	$0061, $005C, $0056, $0050, $004A, $0044, $003E, $0038, $0031, $002B, $0025, $001F, $0019, $0012, $000C, $0006
		
		dc.w	$0000, $FFFA, $FFF4, $FFEE, $FFE7, $FFE1, $FFDB, $FFD5, $FFCF, $FFC8, $FFC2, $FFBC, $FFB6, $FFB0, $FFAA, $FFA4
		dc.w	$FF9F, $FF99, $FF93, $FF8B, $FF88, $FF82, $FF7D, $FF78, $FF72, $FF6D, $FF68, $FF63, $FF5E, $FF59, $FF55, $FF50
		dc.w	$FF4B, $FF47, $FF43, $FF3F, $FF3B, $FF37, $FF33, $FF2F, $FF2C, $FF28, $FF25, $FF22, $FF1F, $FF1C, $FF19, $FF16
		dc.w	$FF14, $FF12, $FF0F, $FF0D, $FF0C, $FF0A, $FF08, $FF07, $FF05, $FF04, $FF03, $FF02, $FF02, $FF01, $FF01, $FF01
		
		dc.w	$FF00, $FF01, $FF01, $FF01, $FF02, $FF02, $FF03, $FF04, $FF05, $FF07, $FF08, $FF0A, $FF0C, $FF0D, $FF0F, $FF12
		dc.w	$FF14, $FF16, $FF19, $FF1C, $FF1F, $FF22, $FF25, $FF28, $FF2C, $FF2F, $FF33, $FF37, $FF3B, $FF3F, $FF43, $FF47
		dc.w	$FF4B, $FF50, $FF55, $FF59, $FF5E, $FF63, $FF68, $FF6D, $FF72, $FF78, $FF7D, $FF82, $FF88, $FF8B, $FF93, $FF99
		dc.w	$FF9F, $FFA4, $FFAA, $FFB0, $FFB6, $FFBC, $FFC2, $FFC8, $FFCF, $FFD5, $FFDB, $FFE1, $FFE7, $FFEE, $FFF4, $FFFA
		
		dc.w	$0000, $0006, $000C, $0012, $0019, $001F, $0025, $002B, $0031, $0038, $003E, $0044, $004A, $0050, $0056, $005C
		dc.w	$0061, $0067, $006D, $0073, $0078, $007E, $0083, $0088, $008E, $0093, $0098, $009D, $00A2, $00A7, $00AB, $00B0
		dc.w	$00B5, $00B9, $00BD, $00C1, $00C5, $00C9, $00CD, $00D1, $00D4, $00D8, $00DB, $00DE, $00E1, $00E4, $00E7, $00EA
		dc.w	$00EC, $00EE, $00F1, $00F3, $00F4, $00F6, $00F8, $00F9, $00FB, $00FC, $00FD, $00FE, $00FE, $00FF, $00FF, $00FF
		
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Returns the arctangent (angle) value for a given x/y distance
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	d1.w	- X distance
;	d2.w	- Y distance
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	d0.w	- Arctangent (angle) value
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
MATH_GetArctan:
		movem.l	d3-d4,-(sp)			; Backup d3-d4 and initialize them
		moveq	#0,d3				; ^
		moveq	#0,d4				; ^

		move.w	d1,d3				; Copy the X and Y values
		move.w	d2,d4				; ^

		or.w	d3,d4				; Are both X and Y equal to 0?
		beq.s	.xyIsZero			; If so, branch to handle the edge-case
		move.w	d2,d4				; Otherwise, restore the Y value and continue
		
		tst.w	d3				; Get the absolute value of the X component
		bpl.s	.xIsAbsolute			; ^
		neg.w	d3				; ^

.xIsAbsolute:
		tst.w	d4				; Get the absolute value of the Y component
		bpl.s	.yIsAbsolute			; ^
		neg.w	d4				; ^

.yIsAbsolute:
		cmp.w	d3,d4				; Is the Y component greater than the X component?
		bhs.s	.yIsGreater			; If so, branch; Otherwise, continue

; ---------------------------------------------------------------------------------------------------------------------------------------------------------	
.xIsGreater:
		lsl.l	#8,d4				; Multiply the Y component by $100
		divu.w	d3,d4				; Divide it by the X component
		moveq	#0,d0				; Clear the output register
		move.b	.arctanData(pc,d4.w),d0		; Look-up the arctan value corresponding to the above division
		bra.s	.correctQuad			; Move on to correcting the arctan value's quadrant 

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.yIsGreater:
		lsl.l	#8,d3				; Multiply the X component by $100
		divu.w	d4,d3				; Divide it by the Y component
		moveq	#$40,d0				; Pre-load an arctan value of $40 into the output register
		sub.b	.arctanData(pc,d3.w),d0		; Subtract the arctan value corresponding to the above division

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.correctQuad:
		tst.w	d1				; Is the original X value positive?
		bpl.s	.xIsPositive			; If so, branch ahead and leave the output in the first quadrant for now
		neg.w	d0				; Otherwise, adjust the output's quadrant (reflect across the Y axis)
		addi.w	#$80,d0				; ^

.xIsPositive:
		tst.w	d2				; Is the original Y value positive?
		bpl.s	.yIsPositive			; If so, branch ahead and do not adjust the output's quadrant any further
		neg.w	d0				; Otherwise, adjust the output's quadrant (reflect across the X axis)
		addi.w	#$100,d0			; ^

.yIsPositive:
		movem.l	(sp)+,d3-d4			; Restore d3-d4 
		rts					; Return

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.xyIsZero:
		moveq	#$40,d0				; If both components are 0, return a default arctan value of $40
		movem.l	(sp)+,d3-d4			; Restore d3-d4 
		rts					; Return
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.arctanData:
		dc.b	$00, $00, $00, $00, $01, $01
		dc.b	$01, $01, $01, $01, $02, $02
		dc.b	$02, $02, $02, $02, $03, $03
		dc.b	$03, $03, $03, $03, $03, $04
		dc.b	$04, $04, $04, $04, $04, $05
		dc.b	$05, $05, $05, $05, $05, $06
		dc.b	$06, $06, $06, $06, $06, $06
		dc.b	$07, $07, $07, $07, $07, $07
		dc.b	$08, $08, $08, $08, $08, $08
		dc.b	$08, $09, $09, $09, $09, $09
		dc.b	$09, $0A, $0A, $0A, $0A, $0A
		dc.b	$0A, $0A, $0B, $0B, $0B, $0B
		dc.b	$0B, $0B, $0B, $0C, $0C, $0C
		dc.b	$0C, $0C, $0C, $0C, $0D, $0D
		dc.b	$0D, $0D, $0D, $0D, $0D, $0E
		dc.b	$0E, $0E, $0E, $0E, $0E, $0E
		dc.b	$0F, $0F, $0F, $0F, $0F, $0F
		dc.b	$0F, $10, $10, $10, $10, $10
		dc.b	$10, $10, $11, $11, $11, $11
		dc.b	$11, $11, $11, $11, $12, $12
		dc.b	$12, $12, $12, $12, $12, $13
		dc.b	$13, $13, $13, $13, $13, $13
		dc.b	$13, $14, $14, $14, $14, $14
		dc.b	$14, $14, $14, $15, $15, $15
		dc.b	$15, $15, $15, $15, $15, $15
		dc.b	$16, $16, $16, $16, $16, $16
		dc.b	$16, $16, $17, $17, $17, $17
		dc.b	$17, $17, $17, $17, $17, $18
		dc.b	$18, $18, $18, $18, $18, $18
		dc.b	$18, $18, $19, $19, $19, $19
		dc.b	$19, $19, $19, $19, $19, $19
		dc.b	$1A, $1A, $1A, $1A, $1A, $1A
		dc.b	$1A, $1A, $1A, $1B, $1B, $1B
		dc.b	$1B, $1B, $1B, $1B, $1B, $1B
		dc.b	$1B, $1C, $1C, $1C, $1C, $1C
		dc.b	$1C, $1C, $1C, $1C, $1C, $1C
		dc.b	$1D, $1D, $1D, $1D, $1D, $1D
		dc.b	$1D, $1D, $1D, $1D, $1D, $1E
		dc.b	$1E, $1E, $1E, $1E, $1E, $1E
		dc.b	$1E, $1E, $1E, $1E, $1F, $1F
		dc.b	$1F, $1F, $1F, $1F, $1F, $1F
		dc.b	$1F, $1F, $1F, $1F, $20, $20
		dc.b	$20, $20, $20, $20, $20, $00

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Initialize general-purpose oscillating values
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
MATH_InitOscillators:
		lea	(oscillators).w,a1
		lea	.oscInitData(pc),a2
		moveq	#(.oscInitData_End-.oscInitData)>>1-1,d1

.loadData:
		move.w	(a2)+,(a1)+
		dbf	d1,.loadData
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.oscInitData:
		dc.w	%0000000001111101
		dc.w	$0080, $0000
		dc.w	$0080, $0000
		dc.w	$0080, $0000
		dc.w	$0080, $0000
		dc.w	$0080, $0000
		dc.w	$0080, $0000
		dc.w	$0080, $0000
		dc.w	$0080, $0000
		dc.w	$0080, $0000
		dc.w	$3848, $00EE
		dc.w	$2080, $00B4
		dc.w	$3080, $010E
		dc.w	$5080, $01C2
		dc.w	$7080, $0276
		dc.w	$0080, $0000
		dc.w	$4000, $00FE
.oscInitData_End:

; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Update general-purpose oscillating values
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
MATH_UpdOscillators:
		lea	(oscillators).w,a1
		lea	.oscUpdateData(pc),a2
		move.w	(a1)+,d3
		moveq	#(.oscUpdateData_End-.oscUpdateData)>>2-1,d1

.oscLoop:
		move.w	(a2)+,d2
		move.w	(a2)+,d4
		btst	d1,d3
		bne.s	.sub
		move.w	2(a1),d0
		add.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,(a1)
		cmp.b	(a1),d4
		bhi.s	.doLoop
		bset	d1,d3
		bra.s	.doLoop

.sub:
		move.w	2(a1),d0
		sub.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,(a1)
		cmp.b	(a1),d4
		bls.s	.doLoop
		bclr	d1,d3

.doLoop:
		addq.w	#4,a1
		dbf	d1,.oscLoop

		move.w	d3,(oscControl).w

.end:
		rts
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
.oscUpdateData:
		dc.w	$02, $10
		dc.w	$02, $18
		dc.w	$02, $20
		dc.w	$02, $30
		dc.w	$04, $20
		dc.w	$08, $08
		dc.w	$08, $40
		dc.w	$04, $40
		dc.w	$02, $38
		dc.w	$02, $38
		dc.w	$02, $20
		dc.w	$03, $30
		dc.w	$05, $50
		dc.w	$07, $70
		dc.w	$02, $40
		dc.w	$02, $40
.oscUpdateData_End:
; =========================================================================================================================================================