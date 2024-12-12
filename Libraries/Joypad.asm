; =========================================================================================================================================================
; Joypad functions
; =========================================================================================================================================================
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; Read joypad input
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; ARGUMENTS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
; RETURNS:
;	Nothing
; ---------------------------------------------------------------------------------------------------------------------------------------------------------
ReadJoypads:
	lea	ctrlDataP1.w,a0			; 8	; load RAM space for joypad data
	lea	PORT_A_DATA-1,a1		; 12	; load I/O data port A
	moveq	#%00000000,d0			; 4	; prepare TH = 0 request value
	moveq	#%01000000,d1			; 4	; prepare TH = 1 request value

	; Repeat the following twice to
	; collect input from both pads
	rept	2
		move.w	d0,(a1)			; 8	; set TH = 0 (burn 8 cycles to wait for returned data by setting up bitmasks below)
		moveq	#%00110000,d2		; 4	; button bitmask mask for TH = 0
		moveq	#%00111111,d3		; 4	; button bitmask for TH = 1
		and.w	(a1),d2			; 8	; collect current button data for TH = 0 (A and Start)
		move.w	d1,(a1)			; 8	; set TH = 1 (burn 8 cycles again below to wait)
		add.b	d2,d2			; 4	; shift TH = 0 button bits to the left by two
		add.b	d2,d2			; 4	; (A and start will be bits $6 and $7 in saved data)
		and.w	(a1)+,d3		; 8	; collect current button data for TH = 1 (Up, Down, Left, Right, B, and C)
		or.b	d3,d2			; 4	; combine collected button bits
		not.b	d2			; 4	; flip bits (now pressed = 1 and not pressed = 0)
		move.b	(a0),d3			; 8	; d3 = last collected button data
		eor.b	d2,d3			; 4	; remove any currently pressed buttons from d3
		move.b	d2,(a0)+		; 8	; save d2 (current button presses) as current held buttons
		and.b	d2,d3			; 4	; limit d3 (pressed buttons) to only include current buttons
		move.b	d3,(a0)+		; 8	; save all pressed buttons for this frame
	endr

	rts					; 16	; return

; =========================================================================================================================================================