; =========================================================================================================================================================
; MegaDrive constants
; =========================================================================================================================================================
ROM_START		equ	$000000				; ROM area start address
ROM_END			equ	$3FFFFF+1			; ROM area end address

Z80_RAM			equ	$A00000				; Z80 RAM start address
Z80_RAM_END		equ	$A02000				; Z80 RAM end address
Z80_BUS_REQ		equ	$A11100				; Z80 bus request
Z80_RESET		equ	$A11200				; Z80 reset

YM2612_A0		equ	$A04000				; M68K YM2612 register port 0
YM2612_D0		equ	$A04001				; M68K YM2612 data port 0
YM2612_A1		equ	$A04002				; M68K YM2612 register port 1
YM2612_D1		equ	$A04003				; M68K YM2612 data port 1
PSG_INPUT		equ	$C00011				; M68K PSG input

HW_VERSION		equ	$A10001				; Hardware version
TMSS_PORT		equ	$A14000				; TMSS port

PORT_A_DATA		equ	$A10003				; Port A data
PORT_B_DATA		equ	$A10005				; Port B data
PORT_C_DATA		equ	$A10007				; Port C data
PORT_A_CTRL		equ	$A10009				; Port A control
PORT_B_CTRL		equ	$A1000B				; Port B control
PORT_C_CTRL		equ	$A1000D				; Port C control
PORT_A_TX		equ	$A1000F				; Port A Tx data
PORT_A_RX		equ	$A10011				; Port A Rx data
PORT_A_SCTRL		equ	$A10013				; Port A S control
PORT_B_TX		equ	$A10015				; Port B Tx data
PORT_B_RX		equ	$A10017				; Port B Rx data
PORT_B_SCTRL		equ	$A10019				; Port B S control
PORT_C_TX		equ	$A1001B				; Port C Tx data
PORT_C_RX		equ	$A1001D				; Port C Rx data
PORT_C_SCTRL		equ	$A1001F				; Port C S control

SRAM_ACCESS		equ	$A130F1				; SRAM access register ($200000 - $3FFFFF)

MAPPER_BANK_1		equ	$A130F3				; Mapper bank 1 register ($080000 - $0FFFFF)
MAPPER_BANK_2		equ	$A130F5				; Mapper bank 2 register ($100000 - $17FFFF)
MAPPER_BANK_3		equ	$A130F7				; Mapper bank 3 register ($180000 - $1FFFFF)
MAPPER_BANK_4		equ	$A130F9				; Mapper bank 4 register ($200000 - $27FFFF)
MAPPER_BANK_5		equ	$A130FB				; Mapper bank 5 register ($280000 - $2FFFFF)
MAPPER_BANK_6		equ	$A130FD				; Mapper bank 6 register ($300000 - $37FFFF)
MAPPER_BANK_7		equ	$A130FF				; Mapper bank 7 register ($380000 - $3FFFFF)

VDP_DATA		equ	$C00000				; VDP data port
VDP_CTRL		equ	$C00004				; VDP control port
VDP_HVCOUNT		equ	$C00008				; VDP H/V counter
VDP_DEBUG		equ	$C0001C				; VDP debug register

RAM_START		equ	$FF0000				; M68K RAM start address
RAM_END			equ	$FFFFFF+1			; M68K RAM end address

RAM_WORD_START		equ	$FFFF8000			; Starting address of absolute word addressable M68K RAM
RAM_WORD_END		equ	$FFFFFFFF+1			; Ending address of absolute word addressable M68K RAM

VALLOC_START_TILE	equ	$400
VALLOC_END_TILE		equ	$600
VALLOC_MAX_NODES	equ	32
; =========================================================================================================================================================