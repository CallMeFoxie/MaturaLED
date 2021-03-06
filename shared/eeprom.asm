/*
 * eeprom.inc
 *
 *  Created: 23.11.2011 19:14:33
 *   Author: Ondra Moravek
 *   BOOTLOADER_NATIVE
 */ 

 .cseg

EEPROM_Init: ; nothing here
	RET

/* EEPROM_Read: Reads data from EEPROM
 *	Params:
 *   X - offset
 *	Returns:
 *   R16 - data
*/
EEPROM_Read:
	PUSH	R31
EEPROM_Read_WAIT:
	LDI		R31, EECR
	ANDI	R31, (1 << EEWE)
	BRNE EEPROM_Read_WAIT
	; EEWE flag cleared if we got here
	OUT		EEARL, XL
	OUT		EEARH, XH
	LDI		R31, EECR
	ORI		R31, (1 << EERE)
	OUT		EECR, R31
	IN		R16, EEDR
	POP		R31
	RET

/* EEPROM_Write: Saves data to EEPROM
 *	Params:
 *   X - offset
 *   R16 - data
*/
EEPROM_Write:
	PUSH	R31
EEPROM_Write_WAIT:
	LDI		R31, EECR
	ANDI	R31, (1 << EEWE)
	BRNE EEPROM_Write_WAIT
	; EEWE flag cleared if we got here
	OUT		EEARL, XL
	OUT		EEARH, XH
	OUT		EEDR, R16
	LDI		R31, EECR
	ORI		R31, (1 << EEMWE)
	OUT		EECR, R31
	ORI		R31, (1 << EEWE)
	OUT		EECR, R31
	POP		R31
	RET