/*
 * display.asm
 *
 *  Created: 23.11.2011 18:23:18
 *   Author: Ondra Moravek
 *   BOOTLOADER_NATIVE
 */ 

 .def R_ROW = R6
 .def R_VIEW = R2
 .def R_BUFFER = R3
 .def R_NBUFFER = R4 ; next buffer
 .def R_MAXVIEW = R5

.dseg
.org 0xC000
	BUFFER0: .byte 0x2000 ; 16 views 1 buffer... 16 views in total, each half kilobyte
	/* Organization:
		Buffer 0 (0xC000 - 0xDFFF)
			View 0 (0xC000 - 0xC1FF)
				R 8pixel (0xC000 - 0xC001)
				G 8pixel (0xC001 - 0xC002)
			View 1 (0xC200 - 0xC3FF)
			...
			View 15 (0xDE00 - 0xDFFF)
			...
	*/
	BUFFER1: .byte 0x2000 ; ... the same
.cseg

DISPLAY_TIMER_INIT: ; inits the timers and such. NOT an interrupt driven!
	LDI		R16, OCRVAL ;0xFE ;-- 0xFE - max brightness. Useless, 0x30 is for demo enough ; output compare shall fire up right before the main timer ovf fires up...
	OUT		OCR0, R16
	LDI		R16, (1<<CS01)|(1<<CS00) ; clk/32
	OUT		TCCR0, R16 ; timer is running now
	LDI		R16, (1<<TOIE0)|(1<<OCIE0) ; setup interrupts
	OUT		TIMSK, R16 ; interrupts enabled... but not the I flag yet!
	LDI		R16, 5
	MOV		R_MAXVIEW, R16
	RET
 

DISPLAY_TIMER_CLEAR: ; just clear the first 595 so the output MOSFETs can discharge. Good enough is few us before the main timer fires up
	PUSH	R16
	IN		R16, SREG
	PUSH	R16
	; disable display output..
	DISPLAY_DISABLE
	LDI		R16, 0xFF ; should disable both outputs... drive all MOSFETs high!
	RCALL	SPI_Send
	DISPLAY_TOGGLE_RCK
	;Reset_Drivers
	;DISPLAY_TOGGLE_RCK
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

DISPLAY_TIMER:
	/* PUSH ORDER: R16, SREG, YL, YH, ZL, ZH, R0, R1, R17, R20, R21, R22, R23
		Set new address pointer into Y register.
		Formula: BUFFER+Buffer*<buffer size>+View*<view size>+<row>*<row size>, second one +. Row size = 10h (4bit boundary), view size = 10h*32 = 200h, buffer size = 200h*16 = 2000h
		First run: <row> = row + 16, second run = row
		last byte sent (25th) is row.
		Then INC row
		and last reset wdr
	*/
	PUSH	R16
	IN		R16, SREG
	PUSH	R16
	PUSH	YL
	PUSH	YH
	PUSH	ZL
	PUSH	ZH
	PUSH	R0
	PUSH	R1
	PUSH	R17
	PUSH	R18
	PUSH	R19
	PUSH	R20
	PUSH	R21
	PUSH	R22
	PUSH	R23

	DISPLAY_DISABLE
	SBI		PortB, PB7
	;CBI		PortB, PB0

	LDI		R16, TCNTVAL
	OUT		TCNT0, R16

	TST		R_BUFFER
	BREQ	DISPLAY_TIMER_B0
	; DISPLAY_TIMER_B1
	LDI		YL, LOW(BUFFER1)
	LDI		YH, HIGH(BUFFER1)
	RJMP	DISPLAY_TIMER_VIEW
DISPLAY_TIMER_B0:
	LDI		YL, LOW(BUFFER0)
	LDI		YH, HIGH(BUFFER0)
	
DISPLAY_TIMER_VIEW:
	;ANDI	GAME_IFACE_CR, (1<<GAME_IFACE_VEN)
	;BREQ	DISPLAY_TIMER_ROW ;skip if only one view is enabled
	LDI		R23, 0x02
	LDI		R22, 0x00

	LDI		R21, 0x00
	MOV		R20, R_VIEW
	MUL16
	ADD16	YH, YL, R17, R16
	
DISPLAY_TIMER_ROW: ; add ROW. Remember that we start by (row+16)!
	LDI		R16, 16
	MOV		R17, R_ROW
	; continue with making this row number into address addition. One row = 12 bytes long, it is aligned to 16 bytes. Ergo << 4.
	CLR		R18
	LSL		R17
	LSL		R17
	LSL		R17
	LSL		R17
	; if we were doing line 15 (ergo the last one), we have reached the end of 8bits, need to add 9th bit!
	BRCC	DISPLAY_TIMER_ROW_CNT
	; we need the extra bit
	LDI		R18, 0x01
DISPLAY_TIMER_ROW_CNT:
	ADD16	YH, YL, R18, R17

	; FIRST FIX - these displays are FLIPPED, need to send always the 6 bytes in reverse!
	LDI		R17, 6
	CLR		R18
	ADD16	YH, YL, R18, R17

	; now we have hopefuly the ending address. Start sending from the end, 12 bytes.
	LDI			R17, 6

DISPLAY_TIMER_LOOP1:
	LD		R16, -Y
	; we need to flip here the two two-bits... 
	MOV		R18, R16
	MOV		R19, R16
	ANDI	R16, 0x0F
	LSR		R19
	LSR		R19
	ANDI	R19, 0x30
	OR		R16, R19
	LSL		R18
	LSL		R18
	ANDI	R18, 0xC0
	OR		R16, R18
	; now we can send it finally
	RCALL	SPI_Send
	DEC		R17
	BREQ	DISPLAY_TIMER_LOOP2_SET ; all 12 bytes sent
	RJMP	DISPLAY_TIMER_LOOP1

DISPLAY_TIMER_LOOP2_SET:
	LDI		R17, 12
	CLR		R18
	ADD16	YH, YL, R18, R17
	LDI		R17, 6
DISPLAY_TIMER_LOOP2:
	LD		R16, -Y
	; we need to flip here the two two-bits... 
	MOV		R18, R16
	MOV		R19, R16
	ANDI	R16, 0x0F
	LSR		R19
	LSR		R19
	ANDI	R19, 0x30
	OR		R16, R19
	LSL		R18
	LSL		R18
	ANDI	R18, 0xC0
	OR		R16, R18
	; send it
	RCALL	SPI_Send
	DEC		R17
	BREQ	DISPLAY_TIMER_LOOP3_SET ; all 12 bytes sent
	RJMP	DISPLAY_TIMER_LOOP2

; bottom half -- another FIX - the lines are flipped :o). Beginning address = c170, then goes to c100, then c1f0 to c180
DISPLAY_TIMER_LOOP3_SET:
	TST		R_BUFFER
	BREQ	DISPLAY_TIMER_B0B
	; DISPLAY_TIMER_B1B
	LDI		YL, LOW(BUFFER1)
	LDI		YH, HIGH(BUFFER1)
	RJMP	DISPLAY_TIMER_BOTTOM
DISPLAY_TIMER_B0B:
	LDI		YL, LOW(BUFFER0)
	LDI		YH, HIGH(BUFFER0)

	LDI		R23, 0x02
	LDI		R22, 0x00

	LDI		R21, 0x00
	MOV		R20, R_VIEW
	MUL16
	ADD16	YH, YL, R17, R16

	
DISPLAY_TIMER_BOTTOM:

; (7 - row)<<4
	LDI		R17, 7
	MOV		R16, R_ROW
	ANDI	R16, 0x07 ; bottom 3 bits
	SUB		R17, R16
	LSL		R17
	LSL		R17
	LSL		R17
	LSL		R17
	LDI		R18, 0x01
	LDI		R16, 0x06
	ADD		R17, R16
	MOV		R16, R_ROW
	CPI		R16, 0x08
	BRNE	DISPLAY_TIMER_BOTTOM_OVF_OK
	;INC		R18
	LDI		R16, 0x80
	ADD		R17, R16
DISPLAY_TIMER_BOTTOM_OVF_OK:
	ADD16	YH, YL, R18, R17

	MOV		R18, R_ROW
	LDI		R16, 0x08
	CP		R16, R18
	BRGE	DISPLAY_TIMER_BOTTOM_OK ; lower than
	LDI		R16, 0x00
	LDI		R17, 0x80
	ADD16	YH, YL, R16, R17
DISPLAY_TIMER_BOTTOM_OK:

	LDI		R17, 6 ; loop timer

	MOV		R16, R_ROW
	CPI		R16, 0x08
	BRNE	DISPLAY_TIMER_LOOP3
	;ADIW	Y, 6


DISPLAY_TIMER_LOOP3:
	LD		R16, -Y
	LDI		R18, 4
	CP		R18, R17
	BRGE	DISPLAY_TIMER_LOOP3_SEND
	; we need to flip here the two top two-bits... 
	MOV		R18, R16
	MOV		R19, R16
	ANDI	R16, 0x0F
	LSR		R19
	LSR		R19
	ANDI	R19, 0x30
	OR		R16, R19
	LSL		R18
	LSL		R18
	ANDI	R18, 0xC0
	OR		R16, R18
	; send it*/
DISPLAY_TIMER_LOOP3_SEND:
	RCALL	SPI_Send
	DEC		R17
	BREQ	DISPLAY_TIMER_LOOP4_SET
	RJMP	DISPLAY_TIMER_LOOP3

DISPLAY_TIMER_LOOP4_SET:
	LDI		R17, 12
	CLR		R18
	ADD16	YH, YL, R18, R17
	LDI		R17, 6

DISPLAY_TIMER_LOOP4:
	LD		R16, -Y
	RCALL	SPI_Send
	DEC		R17
	BREQ	DISPLAY_TIMER_SENT ; all 12 bytes sent
	RJMP	DISPLAY_TIMER_LOOP4


DISPLAY_TIMER_SENT: ; now take care about the row #
	MOV		R16, R_ROW
	RCALL	SPI_Send
	INC		R_ROW ; rise the row #
	;BRHS	DISPLAY_TIMER_VIEW_NEW ; if we're trying to switch to 16th line (counted from 0), nothx! ;; NOTE: INC doesn't set H flag... Gotta do it manually
	MOV		R16, R_ROW
	CPI		R16, 16
	BRGE	DISPLAY_TIMER_VIEW_NEW
	RJMP	DISPLAY_TIMER_DONE
DISPLAY_TIMER_VIEW_NEW:
	CLR		R_ROW ; clear row #
	INC		R_VIEW
	;BRHS	DISPLAY_TIMER_VIEW_OVF
	;MOV		R16, R_VIEW
	CP		R_VIEW, R_MAXVIEW
	BRGE	DISPLAY_TIMER_VIEW_OVF
	RJMP	DISPLAY_TIMER_DONE
DISPLAY_TIMER_VIEW_OVF:
	MOV		R_BUFFER, R_NBUFFER ; copy new buffer #
	CLR		R_VIEW ; clear view #

DISPLAY_TIMER_DONE:
	DISPLAY_TOGGLE_RCK
	DISPLAY_ENABLE
	; let's pop it all back
	POP		R23
	POP		R22
	POP		R21
	POP		R20
	POP		R19
	POP		R18
	POP		R17
	POP		R1
	POP		R0
	POP		ZH
	POP		ZL
	POP		YH
	POP		YL
	POP		R16
	OUT		SREG, R16
	POP		R16
	WDR ; reset watchdog
	RETI

DISPLAY_PWM_INIT: ; brightness PWM... reset (default) to 0 (aka completely shut... takes over safety after directly driving Display Enable pin to HIGH (active low, remember?)
	LDI		R16, 0
	OUT		OCR2, R16
	LDI		R16, 0x71
	OUT		TCCR2, R16
	RET