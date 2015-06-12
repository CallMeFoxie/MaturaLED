/*
 * spi.asm
 *
 *  Created: 23.11.2011 18:23:18
 *   Author: Ondra Moravek
 *   BOOTLOADER_NATIVE
 */ 
 
SPI_Init:
	LDI		R16, (1<<MSTR)|(1<<SPE);|(1<<DORD);|(1<<CPOL) ; SPI, fCLK/4 speed = 4MHz
	OUT		SPCR, R16
	LDI		R16, (1<<SPI2X) ; Double up SPI speed = 8MHz :o)
	OUT		SPSR, R16
	LDI		R16, 0xFF
	OUT		SPDR, R16 ; send first byte so SPIF flag IS SET
	RET

/* SPI_Send: Sends data through SPI
	Params:
		R16 -- byte to send
	Returns:
		R16 -- incoming byte
*/
SPI_Send:
	OUT		SPDR, R16
SPI_Send_Wait:
	SBIS	SPSR, SPIF
	RJMP	SPI_Send_Wait
	RET

