/*
 * strings.inc
 *
 *  Created: 16.2.2012 17:05:37
 *   Author: Ondra
*/ 

.ifndef BINARY
.equ SU_PASS = 'a'
.else
.equ SU_PASS = 0xDA
.endif

.equ TCNTVAL = 0xA0;x80
.equ OCRVAL =  0xE0;xB0

.cseg
.ifndef BINARY
STR_WHO: .db "Hello, I am USB LED controller. Wassup?", 0x0D, 0x0A, 0x00
STR_CMDLINE: .db 0x0D, 0x0A, "Command> ", 0x00
STR_CRLF: .db 0x0D, 0x0A, 0x00
STR_UNKNOWN_COMMAND: .db "Unknown command.", 0x0D, 0x0A, 0x00
STR_MEMTEST: .db "Running extended memory test (0x10FF -> 0xFFFF)... ", 0x0D, 0x0A, 0x00
STR_BANK0: .db " BANK 0: 59.75kB... ", 0x00
STR_BANK1: .db " BANK 1: 59.75kB... ", 0x00
STR_MEMTEST_FAIL: .db "FAILED!", 0x00
STR_MEMTEST_OK: .db "OK!", 0x0D, 0x0A, 0x00
STR_HELLO: .db 0x0D, 0x0A, 0x0D, 0x0A, 0x0D, 0x0A, 0x0D, 0x0A, "================================================================================", 0x0D, 0x0A, "Booting up USB LED Matrix Driver board. Version 1.0.indev.1", 0x0D, 0x0A, "Copyright 2012 Ondrej Moravek.", 0x0D, 0x0A, 0x0D, 0x0A, 0x00
STR_START: .db 0x0D, 0x0A, "Boot finished. Ready to be commanded!", 0x0D, 0x0A, 0x00
STR_POWERON: .db 0x0D, 0x0A, "Reset flags:", 0x00
STR_JTRF: .db 0x0D, 0x0A, " JTAG Reset", 0x00
STR_WDRF: .db 0x0D, 0x0A, " Watchdog Reset", 0x00
STR_BORF: .db 0x0D, 0x0A, " Brown-Out Reset", 0x00
STR_EXTRF: .db 0x0D, 0x0A, " External Reset", 0x00
STR_PORF: .db 0x0D, 0x0A, " Power-On Reset", 0x00
STR_READING_ADDR: .db 0x0D, 0x0A, "Reading this GPU1 addr: ", 0x00
STR_READING_ADDR2: .db 0x0D, 0x0A, "Reading this GPU2 addr: ", 0x00
.endif