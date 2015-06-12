/*
 * game.asm
 *
 *  Created: 8.3.2012 14:46:34
 *   Author: Ondra
 */ 


.dseg
;.org GAME_MEM_START

.cseg

.def LEFT_PADDLE = R14
.def RIGHT_PADDLE = R15
.equ PADDLE_DEF_POS = 1

; paddles move from 4 -- 28, they are 4 pixels high and 1 pixel wide
; colors: paddles: red; ball: green; middle: yellow; score: yellow
; SETUP

GAME_PONG_INIT:
	PUSH	R16
	PUSH	YL
	PUSH	YH
	
	; setup timer... the stuff will be refreshed at least 100 times per second... Use our iface to set it all up
	LDI		R16, (1<<CS12) ;fclk/256
	OUT		TCCR1B, R16
	; we want to have our game run only once per fclk/256, ergo enable only OVF flag. That belongs to TIMER2 part
	LDI		YL, LOW(GAME_OFFSET_TIMER2)
	LDI		YH, HIGH(GAME_OFFSET_TIMER2)
	LDI		R16, LOW(GAME_PONG_TIMER2<<1)
	ST		Y+, R16

	LDI		R16, HIGH(GAME_PONG_TIMER2<<1)
	ST		Y, R16

	LDI		R16, (1<<GAME_IFACE_TIMER2_BIT)
	MOV		GAME_IFACE_CR, R16

	LDI		R16, PADDLE_DEF_POS
	MOV		LEFT_PADDLE, R16
	MOV		RIGHT_PADDLE, R16

	POP		YH
	POP		YL
	POP		R16
	RET

GAME_PONG_TIMER2:
	; game logic!
	PUSH	YL
	PUSH	YH
	PUSH	ZL
	PUSH	ZH
	PUSH	R16
	IN		R16, SREG
	PUSH	R16
	PUSH	R17
	PUSH	R18
	PUSH	R19

	CLR		R18
	LDI		R19, 5
	; load new button info
	RCALL	GAME_IFACE_GET_CONTROLLERS
	RCALL	GAME_IFACE_MEM_RESET ; resets current buffer
	; now "loop" around to draw the paddles. First one: left
	BUFFER_CURRENT_ADDR ; new address is stored in Y.. doesn't take VEN into account
	LDI		R16, 0x80 
	MOV		R17, LEFT_PADDLE
	LSL		R17
	LSL		R17
	LSL		R17
	LSL		R17
	; if carry is not set...
	BRCC	GAME_DRAW_LEFT_PADDLE
	; if carry IS set
	LDI		R18, 0x01
	ADD16	YL, YH, R17, R18
	; should do 32 loops...
GAME_DRAW_LEFT_PADDLE:
	ST		Y, R16
	ADDI16	0x10, 0x00, YL, YH
	MOVW	Y, Z
	DEC		R19
	BREQ	GAME_DRAW_RIGHT_PADDLE_BEGIN
	RJMP	GAME_DRAW_LEFT_PADDLE

GAME_DRAW_RIGHT_PADDLE_BEGIN:
	BUFFER_CURRENT_ADDR
	;LDI		R19, 0x0A
	; for testing purpose only 0x03
	LDI		R19, 0x03
	ADD		YL, R19
	LDI		R19, 5
	LDI		R16, 0x01
	MOV		R17, RIGHT_PADDLE
	LSL		R17
	LSL		R17
	LSL		R17
	LSL		R17
	BRCC	GAME_DRAW_RIGHT_PADDLE
	LDI		R18, 0x01
	ADD16	YL, YH, R17, R18
GAME_DRAW_RIGHT_PADDLE:
	ST		Y, R16
	ADDI16	0x10, 0x00, YL, YH
	MOVW	Y, Z
	DEC		R19
	BREQ	GAME_DRAW_SCORE
	RJMP	GAME_DRAW_RIGHT_PADDLE

GAME_DRAW_SCORE:
; todo

; POP it all back up
	POP		R19
	POP		R18
	POP		R17
	POP		R16
	OUT		SREG, R16
	POP		R16
	POP		ZH
	POP		ZL
	POP		YH
	POP		YL
	RET

.equ GAME_INIT = GAME_PONG_INIT
.equ GAME_TIMER2 = GAME_PONG_TIMER2
