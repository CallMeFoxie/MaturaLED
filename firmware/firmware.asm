/*
 * bootloader.asm
 *
 *  Created: 16.2.2012 9:27:09
 *   Author: Ondra
 */ 
 .dseg
ADDRLD: .BYTE 2

.cseg


.org 0x0000 ; reset
	JMP		BOOTSTRAP 
.org OC1Aaddr ;timer1compa
	JMP		GAME_IFACE_TIMER0
.org OC1Baddr ;timer1compb
	JMP		GAME_IFACE_TIMER1
.org OVF1addr ;timer1ovf
	JMP		GAME_IFACE_TIMER2
.org OC0addr ; timer0comp
	JMP		DISPLAY_TIMER_CLEAR
.org OVF0addr ; timer0ovf.. about 1920Hz...
	JMP		DISPLAY_TIMER

.org	0x0046 ; after all interrupts

.include "strings.inc"
.include "../shared/macros.inc"
.include "../shared/pcserial.asm"
.include "../shared/eeprom.asm"
.include "../shared/display.asm"
.include "../shared/spi.asm"
.include "boot.asm"
.include "commands.asm"
;.include "game/pong.asm"
.include "game/iface.asm"



BOOTSTRAP:

	; DDRB contains the most safe way how to disable the display... It must be done first, NO MATTER WHAT
	LDI		R16, (1<<PB0)|(1<<PB1)|(1<<PB2)|(1<<PB4)|(1<<PB5)|(1<<PB6)|(1<<PB7)
	OUT		DDRB, R16

	DISPLAY_DISABLE ; safety! If there was WDT reset for example... will check that lateron

	CLR		R0
	CLR		R1
	CLR		R2
	CLR		R3
	CLR		R4
	CLR		R5
	CLR		R6
	CLR		R7
	CLR		R8
	CLR		R9
	CLR		R10
	CLR		R11
	CLR		R12
	CLR		R13
	CLR		R14
	CLR		R15
	CLR		R16
	CLR		R17
	CLR		R18
	CLR		R19
	CLR		R20
	CLR		R21
	CLR		R22
	CLR		R23
	CLR		R24
	CLR		R25
	CLR		R26
	CLR		R27
	CLR		R28
	CLR		R29
	CLR		R30
	CLR		R31

	
	LDI		R16, LOW(RAMEND) ; reset stack
	OUT		SPL, R16

	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16


	LDI		R16, (1<<PE1)|(1<<PE2)|(1<<PE3)|(1<<PE4)|(1<<PE5)|(1<<PE6)|(1<<PE7)
	OUT		DDRE, R16

	LDI		R16, 0xFF
	OUT		DDRD, R16

	LDI		R25, 0 ; set the A16 pin of extmem as output and set it to low (bank0)
	OUT		PORTD, R25

	RCALL	SPI_Init
	; safety - clear out all the LED registers!
	; send all 00s everywhere (aka 12+1)... except the ENABLE OUTPUT pins to the 154s!
	Reset_Drivers
	
	RCALL	PC_Init
	
	RCALL	DISPLAY_TIMER_INIT
	;RCALL	DISPLAY_PWM_INIT ; should override now the display enable, but keep the value at 0.. PWM works even without interrupts, FYI
	

	LDI		R16, (1 << SRE) ; enable xmem
	OUT		MCUCR, R16

	PC_Send_String	STR_HELLO

	; .. now check if it is cold or warm start... cold = test RAM, warm (WDT reset, ..) = skip it and notice the owner of the fault!
	PC_Send_String STR_POWERON

	; copy the MCUCSR to some lower register so we can use the SBIC instruction

	IN		R16, MCUCSR
	OUT		EEARL, R16

	SBIC	EEARL, JTRF
	RJMP	START_JTRF
	SBIC	EEARL, WDRF
	RJMP	START_WDRF
	SBIC	EEARL, BORF
	RJMP	START_BORF
	SBIC	EEARL, EXTRF
	RJMP	START_EXTRF
	SBIC	EEARL, PORF
	RJMP	START_PORF
	
BOOT_MEMTEST:
	; start memtest -- tests external memory and cleans it lateron.
	PC_Send_String	STR_MEMTEST
	;RCALL	START_MEMTEST

BOOT_FINISH:
	RCALL	START_MEMTEST
	; reset MCUCSR reset flags + disable JTAG for now (safety first!)
	LDI		R16, 0x9F
	;OUT		MCUCSR, R16
	;OUT		MCUCSR, R16

	; start Watchdog
	LDI		R16, (1<<WDCE)|(1<<WDE)
	OUT		WDTCR, R16

	; PortD is set higher, PortF is ADC + JTAG. Not gonna mess about that!

	; we should be all setup... let's enable interrupts!
	SEI

	; now since all is set up, we can start the game interface itself
.ifdef GAME_IFACE_INIT
	CALL	GAME_IFACE_INIT
.endif
	SBI		PortE, PE7 ; enable display relay

LOOP:
	PC_Send_String STR_CMDLINE

	RCALL	PC_Receive

	PUSH	R16
	PC_Send_String STR_CRLF

	POP		R16

	CPI		R16, 'r' //read memory
	BREQ	B_COMMAND_READ

	CPI		R16, 'j' // enable JTAG
	BREQ	B_COMMAND_JTAG

	CPI		R16, 'w' // write memory
	BREQ	B_COMMAND_WRITE

	CPI		R16, 'a' // load address to X
	BREQ	B_COMMAND_ADDR

	CPI		R16, 'A' // binary: load address to X
	BREQ	B_COMMAND_BIN_ADDR

	CPI		R16, 'R' // binary: read from address
	BREQ	B_COMMAND_BIN_READ

	CPI		R16, 'W' // binary: write to address 
	BREQ	B_COMMAND_BIN_WRITE

	CPI		R16, 't'
	BREQ	B_COMMAND_GPU_RESET

	CPI		R16, 'b'
	BREQ	B_COMMAND_BRIGHTNESS

	CPI		R16, 'x'
	BREQ	B_COMMAND_LDPASS

	CPI		R16, 's' // binary: swap buffer
	BREQ	B_COMMAND_BUFFER

	CPI		R16, 'v' ; set number of views
	BREQ	B_COMMAND_SETV

	CPI		R16, 'p' ; save to address and auto post-increment address ptr
	BREQ	B_COMMAND_BIN_PWRITE

	CPI		R16, 'c' ; loads address, loads length and then waits for LENGTH worth of data
	BREQ	B_COMMAND_BIN_CWRITE

	PC_Send_String	STR_UNKNOWN_COMMAND

	RJMP LOOP

B_COMMAND_GPU_RESET:
	RCALL	COMMAND_GPU_RESET
	RJMP	LOOP

B_COMMAND_BRIGHTNESS:
	RCALL	COMMAND_BRIGHTNESS
	RJMP	LOOP

B_COMMAND_JTAG:
	RCALL	COMMAND_JTAG
	RJMP	LOOP

B_COMMAND_BIN_ADDR:
	RCALL	COMMAND_BIN_ADDR
	RJMP	LOOP

B_COMMAND_BIN_READ:
	LD		R16, X
	RCALL	PC_Send
	RJMP	LOOP

B_COMMAND_BIN_WRITE:
	RCALL	PC_Receive
	ST		X, R16
	RJMP	LOOP

B_COMMAND_ADDR:
	RCALL	COMMAND_ADDR
	RJMP	LOOP

B_COMMAND_READ:
	LDI		R16, 1
	MOV		ZL, XL
	MOV		ZH, XH
	LDI		R17, 0x1
	;LDI		R18, 1 ; flash
	LDI		R18, 0 ; RAM
	CALL	PC_DUMPBINARY
	RJMP	LOOP

B_COMMAND_WRITE:
	PUSH	XL
	PUSH	XH
	LDI		R18, 1 ; one byte
	RCALL	PC_LOADBINARY
	POP		XH
	POP		XL
	RJMP	LOOP

B_COMMAND_LDPASS:
	CALL	COMMAND_LDPASS
	RJMP	LOOP

B_COMMAND_BUFFER:
	RCALL	COMMAND_BIN_BUFFER
	RJMP	LOOP

B_COMMAND_SETV:
	RCALL	COMMAND_SETV
	RJMP	LOOP

B_COMMAND_BIN_PWRITE:
	RCALL	PC_Receive
	ST		X+, R16
	RJMP	LOOP

B_COMMAND_BIN_CWRITE:
	RCALL	COMMAND_BIN_CWRITE
	RJMP	LOOP