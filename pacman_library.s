;=========================
; pacman_library.s
;=======================

    .text

    .global uart_init
    .global output_character
    .global output_string
    .global simple_read_character
    .global read_string
    .global illuminate_RGB_LED
    .global illuminate_LED

; Register offsets
PUR     .equ 0x510
DIR     .equ 0x400
DEN     .equ 0x51C
DATA    .equ 0x3FC
U0FR    .equ 0x18

;=============================================================================
; uart_init - Initialize UART0 at 115200 baud, 16 MHz clock
;=============================================================================
uart_init:
    PUSH {r4-r12, lr}

    ; Point r1 at SYSCTL base
    MOV  r1, #0xE000
    MOVT r1, #0x400F                ; SYSCTL = 0x400FE000

    ; Enable UART0 clock (RCGCUART bit 0)
    LDR  r0, [r1, #0x618]
    ORR  r0, r0, #0x01
    STR  r0, [r1, #0x618]

    ; Wait for UART0 ready
UARTpower:
    LDR  r0, [r1, #0xA18]           ; PRUART
    AND  r0, r0, #0x01
    CMP  r0, #0x01
    BNE  UARTpower

    ; Enable GPIOA clock (RCGCGPIO bit 0) - READ-MODIFY-WRITE
    LDR  r0, [r1, #0x608]           ; read RCGCGPIO
    ORR  r0, r0, #0x01              ; set bit 0 (Port A only)
    STR  r0, [r1, #0x608]           ; write back

    ; Wait for GPIOA ready
GPIOApower:
    LDR  r0, [r1, #0xA08]           ; PRGPIO
    AND  r0, r0, #0x01
    CMP  r0, #0x01
    BNE  GPIOApower

    ; Disable UART0 before configuring
    MOV  r1, #0xC000
    MOVT r1, #0x4000                ; UART0 = 0x4000C000
    MOV  r0, #0
    STR  r0, [r1, #0x30]            ; UARTCTL = 0

    ; Baud rate: 115200 at 16MHz - IBRD=8, FBRD=44
    MOV  r0, #8
    STR  r0, [r1, #0x24]            ; IBRD
    MOV  r0, #44
    STR  r0, [r1, #0x28]            ; FBRD

    ; Use system clock
    MOV  r0, #0
    STR  r0, [r1, #0xFC8]           ; UARTCC

    ; 8-bit word, no parity, 1 stop bit, FIFOs enabled
    MOV  r0, #0x70
    STR  r0, [r1, #0x2C]            ; LCRH (0x70 = 8N1 + FIFO enable)

    ; Enable UART: UARTEN + TXE + RXE
    MOV  r0, #0x301
    STR  r0, [r1, #0x30]            ; UARTCTL

    ; Configure GPIOA PA0/PA1 as UART pins
    MOV  r1, #0x4000
    MOVT r1, #0x4000                ; GPIOA = 0x40004000

    ; Digital enable PA0, PA1
    LDR  r0, [r1, #DEN]
    ORR  r0, r0, #0x03
    STR  r0, [r1, #DEN]

    ; Alternate function select PA0, PA1
    LDR  r0, [r1, #0x420]
    ORR  r0, r0, #0x03
    STR  r0, [r1, #0x420]

    ; Port control: PA0=U0RX(1), PA1=U0TX(1)
    LDR  r0, [r1, #0x52C]
    BIC  r0, r0, #0xFF              ; clear PA0 and PA1 fields (low byte)
    ORR  r0, r0, #0x11              ; PA0=1, PA1=1 (UART function)
    STR  r0, [r1, #0x52C]

    POP  {r4-r12, lr}
    MOV  pc, lr

;=============================================================================
; output_character - send r0 via UART0 TX (polling)
;=============================================================================
output_character:
    PUSH {r4-r12, lr}

    MOV  r1, #0xC000
    MOVT r1, #0x4000                ; UART0 base

tFlag:
    LDR  r3, [r1, #U0FR]
    AND  r3, r3, #0x20              ; TXFF bit 5
    CMP  r3, #0
    BNE  tFlag                      ; spin while TX FIFO full

    STRB r0, [r1]                   ; write to UARTDR

    POP  {r4-r12, lr}
    MOV  pc, lr

;=============================================================================
; output_string - send null-terminated string at r0
;=============================================================================
output_string:
    PUSH {r4-r12, lr}

    MOV  r4, r0
    MOV  r5, #0

writeLoop:
    LDRB r0, [r4, r5]
    CMP  r0, #0x00
    BEQ  writeFin
    BL   output_character
    ADD  r5, r5, #1
    B    writeLoop

writeFin:
    POP  {r4-r12, lr}
    MOV  pc, lr

;=============================================================================
; simple_read_character - read one byte from UART0 DR
;=============================================================================
simple_read_character:
    PUSH {r4-r12, lr}

    MOV  r1, #0xC000
    MOVT r1, #0x4000

    LDRB r0, [r1]                   ; read UARTDR (low byte)

    POP  {r4-r12, lr}
    MOV  pc, lr

;=============================================================================
; read_string - read until Enter, echo chars, store in buffer at r0
;=============================================================================
read_string:
    PUSH {r4-r12, lr}

    MOV  r4, r0
    MOV  r5, #0
    MOV  r6, #31

readLoop:
    BL   simple_read_character
    CMP  r0, #0x0D
    BEQ  readFin
    BL   output_character
    CMP  r0, #0x2C
    BEQ  readLoop
    CMP  r5, r6
    BGE  readLoop
    STRB r0, [r4, r5]
    ADD  r5, r5, #1
    B    readLoop

readFin:
    MOV  r0, #0
    STRB r0, [r4, r5]
    POP  {r4-r12, lr}
    MOV  pc, lr

;=============================================================================
; illuminate_RGB_LED - r0 = bitmask for PF1-PF3 (0x02=red 0x04=blue 0x08=green)
;=============================================================================
illuminate_RGB_LED:
    PUSH {r4-r12, lr}

    MOV  r4, #0x5000
    MOVT r4, #0x4002                ; Port F base

    LDR  r5, [r4, #DATA]
    BIC  r5, r5, #0x0E              ; clear PF1-PF3
    ORR  r5, r5, r0                 ; set new color
    STR  r5, [r4, #DATA]

    POP  {r4-r12, lr}
    MOV  pc, lr

;============================================================
; illuminate_LED
; Turns a specific LED on the Alice EduBase board
;
; Input : r0 = led #
;       LED0: 0x01
;       LED1: 0x02
;       LED2: 0x04
;       LED3: 0x08
; ----------------------------------
;		0x00: NONE
; 		0x01: LED0
; 		0x02: LED1
; 		0x03: LED0, LED1
; 		0x04: LED2
; 		0x05: LED0, LED2
; 		0x06: LED1, LED2
; 		0x07: LED0, LED1, LED2
; 		0x08: LED3
; 		0x09: LED0, LED3
; 		0x0A: LED1, LED3
; 		0x0B: LED0, LED1, LED3
; 		0x0C: LED2, LED3
; 		0x0D: LED0, LED2, LED3
; 		0x0E: LED1, LED2, LED3
; 		0x0F: LED0, LED1, LED2, LED3
;============================================================
illuminate_LED:
	PUSH {r4-r12,lr}		; Spill registers to stack

	MOV  r4, #0x5000
	MOVT r4, #0x4000 		;PORT B base address 0x40005000

	AND  r0, r0, #0x0F		; Keeps only PB0-PB3 bits

    LDR  r5, [r4, #DATA]     	; GPIODATA
    BIC  r5, r5, #0x0F             	; clear PB0-3
	ORR  r5, r5, r0          	; set PB0-PB3 to pattern
	STR  r5, [r4, #DATA]     	;GPIODATA for Port B

	POP {r4-r12,lr}  		; Restore registers from stack
	MOV pc, lr



    .end
