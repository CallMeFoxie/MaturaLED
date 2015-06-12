/*
 * bootloader.asm
 *
 *  Created: 24.3.2012 20:15:28
 *   Author: Ondra
 */ 

.equ BOOTLOADER=1

.dseg
	FLASH_IMAGE: .byte PAGESIZE*2

.eseg
	BOOT_CFG: .byte 1

.cseg

.org LARGEBOOTSTART
	JMP		BOOTSTRAP

.include "../shared/eeprom.asm"
.include "../shared/spi.asm"
.include "../shared/pcserial.asm"
.include "commands.asm"

BOOTSTRAP:
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16

	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

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



	LDI		R16, 0xFF
	OUT		DDRA, R16
	OUT		DDRC, R16
	OUT		DDRD, R16

	LDI		R16, (1<<PB0)|(1<<PB1)|(1<<PB2)|(1<<PB4)|(1<<PB5)|(1<<PB6)|(1<<PB7)
	OUT		DDRB, R16

	LDI		R16, (1<<PE1)|(1<<PE2)|(1<<PE3)|(1<<PE4)|(1<<PE5)|(1<<PE6)|(1<<PE7)
	OUT		DDRE, R16

	; check EEPROM's first byte if there isn't flag for us "WAIT YO DUDE"

	LDI		XL, LOW(BOOT_CFG)
	LDI		XH, HIGH(BOOT_CFG)
	RCALL	EEPROM_Read

	ANDI	R16, 0x01
	BRNE	BOOTLOADER_STAY

	; setup all IOs needed for bootloader...

	; now check buttons...

	RCALL	SPI_Init
	LDI		R16, 0xFF
	SBI		PortB, PB4 ; controller 1
	RCALL	SPI_Send
	
	IN		R16, SPDR
	ANDI	R16, (1<<4) | (1<<0)
	BRNE	BOOTLOADER_STAY ; middle button and top buttons pressed on 1st controller

	; we can assume we want to jump outtahere
	JMP		0

BOOTLOADER_STAY:
	
BOOTLOADER_LOOP:
	RCALL	PC_Receive

	CPI		R16, 'p' ; set page pointer
	BREQ	B_COMMAND_PGPTR

	CPI		R16, 'e' ; page erase
	BREQ	B_COMMAND_ERASE

	CPI		R16, 'a' ; activate RWW section
	BREQ	B_COMMAND_ACTIVATE

	CPI		R16, 'l' ; load buffer
	BREQ	B_COMMAND_LOAD

	CPI		R16, 'w' ; write data
	BREQ	B_COMMAND_WRITE

	LDI		R16, '?'
	RCALL	PC_Send

	RJMP	BOOTLOADER_LOOP

B_COMMAND_PGPTR:
	RCALL	COMMAND_PGPTR
	RJMP	BOOTLOADER_LOOP

B_COMMAND_ERASE:
	LDI		R16, (1<<PGERS)|(1<<SPMEN)
	RCALL	DO_SPM_WAIT
	LDI		R16, 0x01
	RCALL	PC_Send
	RJMP	BOOTLOADER_LOOP

B_COMMAND_ACTIVATE:
	LDI		R16, (1<<RWWSRE)|(1<<SPMEN)
	RCALL	DO_SPM
	RJMP	BOOTLOADER_LOOP

B_COMMAND_LOAD:
	RCALL	COMMAND_LOAD
	RJMP	BOOTLOADER_LOOP

B_COMMAND_WRITE:
	RCALL	COMMAND_WRITE
	RJMP	BOOTLOADER_LOOP