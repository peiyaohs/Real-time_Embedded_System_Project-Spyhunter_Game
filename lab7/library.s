	AREA	lib, CODE, READWRITE
	EXPORT pin_connect_block_setup_for_uart0
	EXPORT UART_INIT
	EXPORT READ_CHARACTER
	EXPORT OUTPUT_CHARACTER
	EXPORT OUTPUT_STRING
	EXPORT READ_STRING
	EXPORT DIGITS_SET
	EXPORT DISPLAY_DIGIT
	EXPORT READ_PUSH_BTNS
	EXPORT LEDS
	EXPORT RGB_LED
	EXPORT unsigned_div_and_mod

U0LSR EQU 0xE000C014 ; UART0 Line Status Register
U0RBR EQU 0xE000C000 ; UART0 recieve
U0THR EQU 0xE000C000 ; UART0 transmit
IO0DIR EQU 0xE0028008 ; PORT0 direction register
IO1DIR EQU 0xE0028018 ; PORT1 direction register
IO0SET EQU 0xE0028004 ; PORT0 output set register
IO1SET EQU 0xE0028014 ; PORT1 output set register
IO0CLR EQU 0xE002800C ; PORT0 output clear register
IO1CLR EQU 0xE002801C ; PORT1 output clear register
IO0PIN EQU 0xE0028000 ; PORT0 port pin value register
IO1PIN EQU 0xE0028010 ; PORT1 port pin value register

DIGITS_SET
	DCD 0x00001F80 ;0
	DCD 0x00000300 ;1
	DCD 0x00002D80 ;2
	DCD 0x00002780 ;3
	DCD 0x00003300 ;4
	DCD 0x00003680 ;5
	DCD 0x00003E80 ;6
	DCD 0x00000380 ;7
	DCD 0x00003F80 ;8
	DCD 0x00003780 ;9
	DCD 0x00003B80 ;A
	DCD 0x00003E00 ;b
	DCD 0x00001C80 ;C
	DCD 0x00002F00 ;d
	DCD 0x00003C80 ;E
	DCD 0x00003880 ;F
		ALIGN

;-------------------------------------------------READ_PUSH_BTNS------------------------------------------------------------
READ_PUSH_BTNS
	STMFD SP!,{lr,r4-r6}
	; output r0 is the pushed button values convert into integer from binary then display on to putty
	; pin 20 is MSB, pin 23 LSB (maximum of 16 numbers, 0 to 15)
	; the button pushed is 0; not pressed is 1
	MOV r0, #0 ; reset r0
	LDR r1, =IO1PIN ; address for data botton pushed
	LDR r5, =IO1DIR ; set up IO1DIR
	MOV r6, #0x00000000  ; we want all the pins (20 to 23) to be input (set to 0) 
	STR r6, [r5] ; set the input
	LDR r0, [r1] ; store information into r0
	LSR r0, r0, #20 ; get to bit-20
	AND r0, #0xF ; we just want the last 4 bit
	; reverse the values
	MOV r3, #0 ; reset r3
	MOV r4, #0 ; initialize count
LOOP_BTN
	ADD r4, r4, #1 ; increment count
	AND r2, r0, #1 ; get the first bit
	CMP r2, #1 ; check the first bit is 1 or not
	BEQ LSL_0 
	LSL r3, #1 ; left shift 1
	ADD r3, r3, #1
	B END_LSL
LSL_0 ; left shift 0
	LSL r3, #1
END_LSL
	LSR r0, r0, #1 ; increment (next bit)
	CMP r4, #4 ; count (4 times)
	BNE LOOP_BTN
	MOV r0, r3 ; output the value into r0

	LDMFD sp!, {lr,r4-r6}
	BX lr
;-------------------------------------------------LEDS----------------------------------------------------------------------
LEDS
	STMFD SP!,{lr,r4-r6}
	; input r0 value use 4 LEDS to display the value in binary
	; port 1 pin 16 to 19 (maximum of 16 numbers, 0 to 15)
	; pin 16 is MSB, pin 19 is LSB (reverse the order)
	; turn on is 0; turn off is 1
	LDR r5, =IO1CLR ; set up IO1CLR
	LDR r6, [r5]
	ORR r6, r6, #0xF0000 ; we want all the pins (16 to 19) to be output (set to 1) 
	STR r6, [r5]
	LDR r1, =IO1SET
	LDR r5, =IO1DIR ; set up IO1DIR
	LDR r6, [r5]
	ORR r6, r6, #0xF0000 ; we want all the pins (16 to 19) to be output (set to 1) 
	STR r6, [r5] ; set the output
	; reverse the order in r0
	MOV r3, #0 ; reset r3
	MOV r4, #0 ; initialize count
LOOP_LED
	ADD r4, r4, #1 ; increment count
	AND r2, r0, #1 ; get the first bit
	CMP r2, #1 ; check the first bit is 1 or not
	BEQ LSL_0_LED 
	LSL r3, #1 ; left shift 1
	ADD r3, r3, #1
	B END_LSL_LED
LSL_0_LED ; left shift 0
	LSL r3, #1
END_LSL_LED
	LSR r0, r0, #1 ; increment (next bit)
	CMP r4, #4 ; count (4 times)
	BNE LOOP_LED
	LSL r3, #16 ; shift the values to bit-16

	STR r3, [r1] ; store the information in address r1 
	
	LDMFD sp!, {lr,r4-r6}
	BX lr
;-------------------------------------------------RGB_LED-------------------------------------------------------------------
RGB_LED
	STMFD SP!,{lr, r4-r6}
	; set the pin 17 18 21 in IO0SET to 1 to turn on the color
	; set the pin 17 18 21 in IO0CLR to 1 to turn off the color
	; 0 will not effect anything
	; r0 is input color
	; red: SET= 17, CLR= 18 and 21
	; blue: SET= 18, CLR= 17 and 21
	; green: SET= 21, CLR= 17 and 18 
	; purple: SET= 17 and 18 (red and blue), CLR= 21
	; yellow: SET= 17 and 21 (red and green), CLR= 18
	; purple: SET= 17 and 18 (red and blue), CLR= 21
	; white: SET= 17, 18 and 21, NO CLR
	LDR r5, =IO0DIR ; set up IO1DIR
	LDR r6, [r5]
	ORR r6, r6, #0x260000  ; we want all the pins (17 18 21) to be output (set to 1) 
	STR r6, [r5] ; set the output
	LDR r1, =IO0SET ; address for turn off
	LDR r2, =IO0CLR ; address for turn on
	LDR r6, [r2]
	ORR r6, r6, #0x260000
	STR r6, [r2] ; turn on everything
	CMP r0, #1 ; red
	BEQ RED
	CMP r0, #2 ; blue
	BEQ BLUE
	CMP r0, #3 ; green
	BEQ GREEN
	CMP r0, #4 ; purple
	BEQ PURPLE
	CMP r0, #5 ; yellow
	BEQ YELLOW
	CMP r0, #6 ; white
	BEQ WHITE
	B ELSE_CLOSE
RED
	LDR r4, [r1]
	ORR r4, r4, #0x240000 ; close blue and green, keep red (pin 17)
	STR r4, [r1] ; display red
	B END_LED
BLUE
	LDR r4, [r1]
	ORR r4, r4, #0x220000 ; close red and green, keep blue (pin 18)
	STR r4, [r1] ; display blue
	B END_LED
GREEN
	MOV r4, #0x60000 ; close red and blue, keep green (pin 21)
	STR r4, [r1] ; display green
	B END_LED
PURPLE
	LDR r4, [r1]
	ORR r4, r4, #0x200000 ; close green, keep red and blue (pin 17 and 18)
	STR r4, [r1] ; display purple
	B END_LED
YELLOW
	MOV r4, #0x40000 ; close blue, keep red and green (pin 17 and 21)
	STR r4, [r1] ; display yellow
	B END_LED
WHITE
	LDR r4, [r1]
	ORR r4, r4, #0x000000 ; keep all colors (pin 17, 18 and 21)
	STR r4, [r1] ; display white
	; no need to close
	B END_LED
ELSE_CLOSE
	LDR r4, [r1]
	ORR r4, r4, #0x260000 ; close all colors (pin 17, 18 and 21)
	STR r4, [r1] ; display no color
END_LED
	
	LDMFD sp!, {lr, r4-r6}
	BX lr
;-------------------------------------------------DISPLAY_DIGIT-------------------------------------------------------------
DISPLAY_DIGIT
	STMFD SP!,{lr,r2-r6}
	; read input value from r0 (number value), port 0 pin 7 to 13
	; display it on board
	; store nothing after finish displaying
	LDR r2, =IO0CLR	; clear the port
	LDR r6, [r2]
	ORR r6, r6, #0x00003F80  ; we want to clear all the pins (7 to 13, set to 1) 
	STR r6, [r2]
	LDR r1, =IO0SET ; address for display
	LDR r4, =DIGITS_SET ; start address of digit sets
	LDR r5, =IO0DIR ; set up IO0DIR
	LDR r6, [r5]
	ORR r6, r6, #0x00003F80  ; we want all the pins (7 to 13) to be output (set to 1) 
	STR r6, [r5] ; set the output
	; treat r0 as offset to get the correct display digit
	MOV r5, #4
	MUL r0, r5, r0
	LDR r4, [r4, r0] ; Load IOSET pattern for digit in r0
	STR r4, [r1] ; Display (IOSET)

	LDMFD sp!, {lr,r2-r6}
	BX lr
;-------------------------------------------------UART_INIT-----------------------------------------------------------------
UART_INIT
	STMFD SP!,{lr}
	MOV r3,#131
	LDR r2, =0xE000C00C
	STRB r3,[r2]
	
	MOV r3,#1 ; 120... 1 if we used 1152000 in putty (lag out?)
	LDR r4, =0xE000C000
	STRB r3,[r4]
	
	MOV r3,#0 ; 0
	LDR r5, =0xE000C004
	STRB r3,[r5]
	
	MOV r3,#3
	LDR r6,=0xE000C00C
	STRB r3,[r6]
	
	LDMFD sp!, {lr}
	BX lr

;-------------------------------------------------READ CHARACTER------------------------------------------------------------
READ_CHARACTER
	STMFD SP!,{lr}
	LDR r1, =U0RBR               ; load address into r1
	LDR r3, =U0LSR               ; load address into r3
READ
	LDRB r2, [r3]                ; load content into r2
	AND r2, r2, #1               ; get RDR by AND with 0000 0001
	CMP r2, #0                   ; test RDR in status register
	BEQ READ                     ; if 0 then back to READ
	LDRB r0, [r1]                ; read byte
	
	LDMFD sp!, {lr}
	BX lr 

;-------------------------------------------------OUTPUT CHARACTER----------------------------------------------------------
OUTPUT_CHARACTER
	STMFD SP!,{lr}
	LDR r1, =U0THR               ; load address into r1
	LDR r3, =U0LSR               ; load address into r3
TRANS
	LDRB r2, [r3]                ; load content into r2
	AND r2, r2, #0x20            ; get THRE by AND with 0010 0000
	CMP r2, #0                   ; test THRE in status register
	BEQ TRANS                    ; if 0 then back to TRANS
	CMP r0, #0                   ; check if the content in NULL
	BEQ JUMP                     ; if yes then jump out of store byte
	STRB r0, [r1]                ; store byte
JUMP
	
	LDMFD sp!, {lr}
	BX lr

;-------------------------------------------------OUTPUT STRING-------------------------------------------------------------
OUTPUT_STRING
	STMFD SP!,{lr,r4}
	; r4 stores the address of the contant
	MOV r1, r0
PROCESS_OUTPUT
	LDRB r0, [r4], #1            ; load the first character then add 1 to the address
	CMP r0, #0                   ; string terminate by null --> ASCII 0
	BEQ EXIT_OUTPUT
	BL OUTPUT_CHARACTER
	B PROCESS_OUTPUT
EXIT_OUTPUT

	LDMFD sp!, {lr,r4}
	BX lr
 
;-------------------------------------------------READ STRING---------------------------------------------------------------
READ_STRING
	; integers value of input
	; store value to r4
	STMFD SP!,{lr,r4}
PROCESS_READ
	BL READ_CHARACTER
	CMP r0, #13
	BEQ EXIT_READ
	BL OUTPUT_CHARACTER
	STRB r0, [r4], #1
    B PROCESS_READ
EXIT_READ
	MOV r0, #0
	STRB r0, [r4], #1

	LDMFD sp!, {lr,r4}
	BX lr
	
;-------------------------------------------------unsigned_div_and_mod---------------------------------------------------------------
		; r0 dividend
        ; r1 divisor
        ; r2 quotient
        ; r3 remainder
unsigned_div_and_mod
	STMFD sp!, {lr, r4-r12}
    ; Your code for the signed division/mod routine goes here.
    ; The dividend is passed in r0 and the divisor in r1.
    ; The quotient is returned in r0 and the remainder in r1.
    MOV r4, #15 ; initialize counter to 15
    MOV r2, #0 ; initialize quotient to 0
    MOV r3, r0 ; initialize remainder to dividend
    MOV r1, r1, LSL #15; left shift divisior by 15 bits

LOOP
    SUB r3, r3, r1; start of the loop
    ; remainder less than 0 or not
TEST
    CMP r3, #0
    BLT THEN ; if remainder less than 0 go to THEN
    B GREATER ; if not go to DONE
THEN
    ADD r3, r3, r1 ; remainder + divisor
    MOV r2, r2, LSL #1 ; left shift quotient by 0
    B DONE ; finish then statement move to DONE
GREATER
    ; left shift quotient by 1
    MOV r2, r2, LSL #1 ; left shift quotient by 0
    ADD r2, r2, #1 ; add one
DONE
    MOV r1, r1, LSR #1 ; right shift divisor by 1 bit
    CMP     r4, #0 ; compare counter is greater than 0
    SUB r4, r4, #1 ; decrement counter
    BGT LOOP ; back to loop

    LDMFD sp!, {lr, r4-r12}
    BX lr

;-------------------------------------------------PIN CONNECT---------------------------------------------------------------
pin_connect_block_setup_for_uart0
	STMFD SP!, {r0, r1, lr}
	LDR r0, =0xE002C000  ; PINSEL0
	LDR r1, [r0]
	ORR r1, r1, #5
	BIC r1, r1, #0xA
	STR r1, [r0]
	LDMFD sp!, {r0, r1, lr}
	BX lr

	END