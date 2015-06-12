/*
 * commands.asm
 *
 *  Created: 24.3.2012 20:43:36
 *   Author: Ondra
 */ 

COMMAND_PGPTR:
	RCALL	PC_Receive
	OUT		RAMPZ, R16
	RCALL	PC_Receive
	MOV		ZH, R16
	CLR		ZL
	RET

DO_SPM:
	LDS		R17, SPMCSR
	SBRC	R17, SPMEN
	RJMP	DO_SPM
	STS		SPMCSR, R16
	SPM
	RET

DO_SPM_WAIT:
	RCALL	DO_SPM
DO_SPM_WAIT_WAIT:
	LDS		R17, SPMCSR
	SBRC	R17, SPMEN
	RJMP	DO_SPM_WAIT_WAIT
	RET


COMMAND_WRITE:
	LDI		R24, LOW(PAGESIZE * 2)
	LDI		R25, HIGH(PAGESIZE * 2)
	LDI		YL, LOW(FLASH_IMAGE)
	LDI		YH, HIGH(FLASH_IMAGE)
COMMAND_WRITE_LOOP:
	LD		R0, Y+
	LD		R1, Y+
	LDI		R16, (1<<SPMEN)
	RCALL	DO_SPM
	ADIW	Z, 2
	SBIW	R24:R25, 2
	BRNE	COMMAND_WRITE_LOOP

	SUBI	ZL, LOW(PAGESIZE * 2)
	SBCI	ZH, HIGH(PAGESIZE * 2)

	LDI		R16, (1<<PGWRT) | (1<<SPMEN)
	RCALL	DO_SPM_WAIT

	LDI		R16, 0x01
	RCALL	PC_Send
	RET

COMMAND_LOAD:
	LDI		R24, LOW(PAGESIZE * 2)
	LDI		R25, LOW(PAGESIZE * 2)
	LDI		YL, LOW(FLASH_IMAGE)
	LDI		YH, HIGH(FLASH_IMAGE)
COMMAND_LOAD_LOOP:
	RCALL	PC_Receive
	ST		Y+, R16
	SBIW	R24:R25, 1
	BRNE	COMMAND_LOAD_LOOP
	RET