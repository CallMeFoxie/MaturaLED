 /*
 * macros.inc
 *
 *  Created: 9.12.2011 19:22:08
 *   Author: Ondra
 *  FIRMWARE_NATIVE
 */ 
.equ BINARY=1

.macro		SUB16
	SUB		@1, @3
	SBC		@0, @2
.endmacro

.macro		CPI16
	CPI		@1, LOW(@2)
	LDI		R22, HIGH(@2)
	CPC		R22, @0
.endmacro

// number+R19 number+R18+carry
.macro		ADDI16
	LDI		ZL, @0
	LDI		ZH, @1
	ADD		ZL, @2
	ADC		ZH, @3
.endmacro

// r17:r16 = r17:r16+r19:r18
.macro		ADD16
	ADD		@1, @3
	ADC		@0, @2
.endmacro

// r17:16 = r23:r22*r21:r20
.macro		MUL16
	MUL		R22, R20		; al * bl
	MOVW	R17:R16, R1:R0
	MUL		R23, R20		; ah * bl
	ADD		R17, R0
	MUL		R21, R22		; bh * al
	ADD		R17, R0
.endmacro

 .macro PC_Send_String ; sends string from data section
 .ifndef BINARY
	PUSH	TXflash
	PUSH	ZH
	PUSH	ZL
	PUSH	R18
	IN		R18, RAMPZ
	PUSH	R18

	LDI		TXflash, 1
	LDI		ZL, LOW(@0<<1)
	LDI		ZH, HIGH(@0<<1)
	LDI		R18, (@0>>15)
	OUT		RAMPZ, R18
	CALL	PC_DUMPSTRING

	POP		R18
	OUT		RAMPZ, R18
	POP		R18
	POP		ZL
	POP		ZH
	POP		TXflash
.endif
.endmacro

.macro PC_Send_String_RAM ; sends string from RAM
 .ifndef BINARY
	LDI		TXflash, 0
	LDI		ZL, LOW(@0)
	LDI		ZH, HIGH(@0)
	CALL 	PC_DUMPSTRING
.endif
.endmacro

.macro PC_DATA ; sends binary data to serial
	LDI		R16, @0
	CALL	PC_SEND
.endmacro

.macro SETBANK0
	CBI		PORTD, 7
.endmacro

.macro SETBANK1
	SBI		PORTD, 7
.endmacro	

.macro Send_SPI
	LDI		R16, @0
	RCALL	SPI_Send
.endmacro

.macro Reset_Drivers ; resets display drivers.. sends 24 times 0x00 and then one time 0x30 (0b00110000) to disable both 154s
	LDI		R16, 0
	LDI		R17, 24
Reset_SPI_LOOP:
	TST		R17
	BREQ	Reset_SPI_END
	RCALL	SPI_Send
	DEC		R17
	RJMP	Reset_SPI_LOOP
Reset_SPI_END:
	LDI		R16, 0xff
	RCALL	SPI_Send
.endmacro

.macro DISPLAY_DISABLE
	SBI		PortB, PB7
.endmacro

.macro DISPLAY_ENABLE
	CBI		PortB, PB7
.endmacro

.macro DISPLAY_TOGGLE_RCK
	SBI		PORTB, PB0
	NOP
	CBI		PORTB, PB0
.endmacro

.macro BUFFER_CURRENT_ADDR
	TST		R_BUFFER
	BREQ	BUFFER_CA_B0
	LDI		YL, LOW(BUFFER1)
	LDI		YH, HIGH(BUFFER1)
	RJMP	BUFFER_CURRENT_ADDR_OK
BUFFER_CA_B0:
	LDI		YL, LOW(BUFFER0)
	LDI		YH, HIGH(BUFFER1)
BUFFER_CURRENT_ADDR_OK:
.endmacro
