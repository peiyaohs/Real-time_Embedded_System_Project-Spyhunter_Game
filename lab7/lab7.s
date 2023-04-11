	AREA interrupts, CODE, READWRITE
	EXPORT lab7
	EXPORT FIQ_Handler
	EXTERN DISPLAY_DIGIT
	EXTERN OUTPUT_STRING
	EXTERN READ_CHARACTER
	EXTERN unsigned_div_and_mod
	EXTERN RGB_LED
	EXTERN LEDS

U0IIR EQU 0xE000C008 ; UART0 Interrupt Identification Register
U0IER EQU 0xE000C004 ; UART0 Interrupt Enable Register
T0TC EQU 0xE0004008 ; Timer 0 Counter Register
T0TCR EQU 0xE0004004 ; Timer 0 Time Control Register
T1TCR EQU 0xE0008004 ; Timer 1 Time Control Register
T0IR EQU 0xE0004000	; Timer 0 Interrupt Register
T0MCR EQU 0xE0004014 ; Timer 0 Match Control Register
MR1 EQU 0xE000401C ; Match Registor 1

prompt_upper_bound_line =     12, "@@@@@@@@@@@@@@@@@@@@@@@" ; 0x40000000
prompt_line_1 =           13, 10, "@W | | | | | | | | | W@" ; 0x40000018
prompt_line_2 =           13, 10, "@W | | | |V| | | | | W@" ; 0x40000031
prompt_line_3 =           13, 10, "@W | |B| |V| |S| | | W@" ; 0x4000004A
prompt_line_4 =           13, 10, "@W | |B| | | |S| | | W@" ; 0x40000063
prompt_line_5 =           13, 10, "@W | | | | | |S| | | W@" ; 0x4000007C
prompt_line_6 =           13, 10, "@W | | |V| | | | | | W@" ; 0x40000095
prompt_line_7 =           13, 10, "@W | | |V| | | | | | W@" ; 0x400000AE
prompt_line_8 =           13, 10, "@W | | | | |M| | | | W@" ; 0x400000C7
prompt_line_9 =           13, 10, "@W | | | | | | | | | W@" ; 0x400000E0
prompt_line_10 =          13, 10, "@W | | | | | | | | | W@" ; 0x400000F9
prompt_line_11 =          13, 10, "@W | | | | | | | | | W@" ; 0x40000112
prompt_line_12 =          13, 10, "@W | | | | | | | | | W@" ; 0x4000012B
prompt_line_13 =          13, 10, "@W | | | |*| | | | | W@" ; 0x40000144
prompt_line_14 =          13, 10, "@W | | | | | | | | | W@" ; 0x4000015D
prompt_line_15 =          13, 10, "@W | | | |*| | | | | W@" ; 0x40000176
prompt_line_16 =          13, 10, "@W | | | |C| | | | | W@" ; 0x4000018F
prompt_lower_bound_line = 13, 10, "@@@@@@@@@@@@@@@@@@@@@@@" ; 0x400001A8
prompt_score_line =       13, 10, "       Score:0000      ", 0 ; 0x400001C1, number start at 0x400001D0 (MSB) to 0x400001D3 (LSB)
last_line = 			  13, 10, "@W | | | | | | | | | W@", 0 ; 0x400001DB
prompt_intro = 13, 10, "Welcome to Spy Hunter", 0
prompt_instr = 13, 10, "Press g to start the game", 13, 10, "Press q to quit the program", 13, 10, "Press wasd to move X", 13, 10, "Press space to fire bullet",0
prompt_game_start_instr = 13, 10, "Press button to pause", 13, 10, "Press q to quit the program", 13, 10, "Press wasd to move X", 13, 10, "Press space to fire bullet", 0
prompt_game_restart_instr = 13, 10, "Press r to resume the game", 0
prompt_end = 13, 10, "Thank you for playing", 0
bullet_address_1 = 0,0,0,0 ; 0x40000314 
bullet_address_2 = 0,0,0,0 ; 0x40000318
prompt_restart_lost_life = 13, 10, "Press g to start the game with another live", 0
prompt_restart_no_life = 13, 10, "GAME OVER. Press y to restart the game or q to end spy hunter", 0
prompt_spam_on_top = 13, 10, "ENEMY SPAM ON TOP OFF YOU!", 0
column_locations = 0, 0, 3, 0, 0 ; 400003A7
 
    ALIGN

lab7	 	
	STMFD sp!, {lr}
	BL interrupt_init ; initialize interrupt
; --------------------------------------------------------------- lab7
RESTART
	; start with 4 lives left
	MOV r0, #15
	BL LEDS
	; start with level 0
	MOV r0, #0
	BL DISPLAY_DIGIT
	; instead of keep tracting the cursor locations we keep track in memory
	; RGB LED to white
	MOV r0, #6
	BL RGB_LED
	; prompt interface
	MOV r5, #0 ; set r5 to tell the program at game-not-started state
	; set RGB LED to white
	LDR r4, =prompt_upper_bound_line ; prompt from the start of the bound line
	BL OUTPUT_STRING
	LDR r4, =prompt_intro ; prompt intro
	BL OUTPUT_STRING
	LDR r4, =prompt_instr ; prompt instructions
	BL OUTPUT_STRING
	B LOOP
LOOP
	; set for restart
	CMP r5, #0xFE ; the value to restart
	BEQ RESTART
	; set for quit program
	CMP r5, #0xFF ; the value to quit
	BEQ EXIT_LOOP
	B LOOP
EXIT_LOOP
	; RGB LED to red
	MOV r0, #1
	BL RGB_LED
	LDR r4, =prompt_end ; prompt end
	BL OUTPUT_STRING
	; stop timer 1
	LDR r0, =0xE0008004
	LDR r1, [r0]
	BIC r1, r1, #1 ; set bit-0 to 1 if want to start the timer
	STR r1, [r0]
	; stop timer 0
	LDR r0, =0xE0004004
	LDR r1, [r0]
	BIC r1, r1, #1 ; set bit-0 to 1 if want to start the timer
	STR r1, [r0]

	LDMFD sp!,{lr}
	BX lr
; --------------------------------------------------------------- interrupt initialize
interrupt_init       
		STMFD SP!, {r0-r1, lr}   ; Save registers 
		
		; Push button setup		 
		LDR r0, =0xE002C000
		LDR r1, [r0]
		ORR r1, r1, #0x20000000
		BIC r1, r1, #0x10000000
		STR r1, [r0]  ; PINSEL0 bits 29:28 = 10
		
		; uart0 setup
		LDR r0, =0xE000C004
		LDR r1, [r0]
		ORR r1, r1, #1 ; bit-0 enable interrupt
		STR r1, [r0]
		
		; set bit-4 to reset T0TC when T0MR0 = T0TC
		; set bit-5 to stop T0TC when T0MR0 = T0TC		
		; set for every 1 sec to start interrupt (level 0 speed)
		; timer 0 setup
		LDR r0, =0xE0004014
		LDR r1, [r0]
		ORR r1, r1, #0x18 ; set bit-3, bit-4 (MR1I, MR1R) to 1
		STR r1, [r0] ; create interrupt when T0MR1 = T0TC or T0MR0 = T0TC				   not working
		; store 0.5 sec in 0xE000401C (18.432MHz is 1 sec, 9.216MHz is 0.5 sec)
		LDR r0, =0xE000401C ; MR1
		LDR r1, =0x8CA000 ; value for half sec (18.432M) 0x1194000 value for a sec (18.432M)
		STR r1, [r0]
		; stop timer
		LDR r0, =0xE0004004
		LDR r1, [r0]
		BIC r1, r1, #1 ; set bit-0 to 1 if want to start the timer
		STR r1, [r0]
		
		; timer 1 setup (start running timer 1 for random number generator)
		; start timer 1
		LDR r0, =0xE0008004
		LDR r1, [r0]
		ORR r1, r1, #1 ; set bit-0 to 1 if want to start the timer
		STR r1, [r0]
		
		; Classify sources as IRQ or FIQ (we use FIQ only)
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0xC]
		ORR r1, r1, #0x8000 ; External Interrupt 1
		ORR r1, r1, #0x40 ; UART Interrupt 1
		ORR r1, r1, #0x10 ; Timer 0 Interrupt
		STR r1, [r0, #0xC]

		; Enable Interrupts
		LDR r0, =0xFFFFF000
		LDR r1, [r0, #0x10] 
		ORR r1, r1, #0x8000 ; External Interrupt 1
		ORR r1, r1, #0x40 ; UART Interrupt 1
		ORR r1, r1, #0x10 ; Timer 0 Interrupt
		STR r1, [r0, #0x10]

		; External Interrupt 1 setup for edge sensitive
		LDR r0, =0xE01FC148
		LDR r1, [r0]
		ORR r1, r1, #2  ; EINT1 = Edge Sensitive
		STR r1, [r0]

		; Enable FIQ's, Disable IRQ's
		MRS r0, CPSR
		BIC r0, r0, #0x40
		ORR r0, r0, #0x80
		MSR CPSR_c, r0

		LDMFD SP!, {r0-r1, lr} ; Restore registers
		BX lr             	   ; Return
; --------------------------------------------------------------- CLEAR_BOARD
CLEAR_BOARD
		STMFD sp!, {lr, r0-r4}
		; start clearing board from 0x4000001C to 0x400001A5
		; increment 2 for every column (10 times) (this loop is inside increment-7 loop)
		; increment 7 for every row	(16 times)
		LDR r4, =0x4000001C ; the first space at prompt_line_1
		MOV r2, #0x20 ; space
		MOV r1, #0 ; i th column
		MOV r0, #0 ; j th row
LOOP_CLEAR_BOARD_ROW
		CMP r0, #16
		BEQ EXIT_CLEAR_BOARD
LOOP_CLEAR_BOARD_COLUMN		
		CMP r1, #10
		BEQ EXIT_LOOP_CLEAR_BOARD_COLUMN
		STRB r2, [r4], #2
		ADD r1, r1, #1
		B LOOP_CLEAR_BOARD_COLUMN	
EXIT_LOOP_CLEAR_BOARD_COLUMN
		ADD r4, r4, #5
		MOV r1, #0
		ADD r0, r0, #1
		B LOOP_CLEAR_BOARD_ROW
EXIT_CLEAR_BOARD

		LDMFD SP!, {lr, r0-r4}
		BX lr
; --------------------------------------------------------------- CHECK_SPAM_TOP_USER
CHECK_SPAM_TOP_USER
		STMFD sp!, {lr, r0-r4}
		; take r2 as case number, r0 is enemy type, r1 is column
		; check 5 or other cases
		; 		if is case 5, exit CHECK_SPAM_TOP_USER
		; check enemy type
		;		if is M, 		check if is case 2
		;								if yes, lost life, prompt_spam_on_top
		;		if is V, B2, 	check if is case 2 or case 3
		;								if is case 2, lost life, prompt_spam_on_top (add V or B2 at 0x40000035 + column)
		;								if is case 3, lost life, prompt_spam_on_top (add V or B2 at 0x4000001C + column) 
		;		if is S, 		check if is case 2, case3 or case 4
		;								if is case 2, lost life, prompt_spam_on_top (add V or B2 at 0x40000035 + column and 0x4000004E + column)
		;								if is case 3, lost life, prompt_spam_on_top (add V or B2 at 0x4000001C + column and 0x4000004E + column)
		;								if is case 4, lost life, prompt_spam_on_top (add V or B2 at 0x4000001C + column and 0x40000035 + column)
		CMP r2, #5
		BEQ END_CHECK_SPAM_TOP_USER
		; enemy type
		CMP r0, #0 ; M
		BEQ CHECK_SPAM_TOP_USER_TYPE_0
		CMP r0, #1 ; V
		BEQ CHECK_SPAM_TOP_USER_TYPE_1
		CMP r0, #2 ; S
		BEQ CHECK_SPAM_TOP_USER_TYPE_2
		CMP r0, #3 ; B
		BEQ CHECK_SPAM_TOP_USER_TYPE_3
		; check 1 enemy cursor type
CHECK_SPAM_TOP_USER_TYPE_0 
		CMP r2, #2
		BEQ CHECK_SPAM_TOP_USER_TYPE_0_CASE_2
		; add enemy cursor at 0x4000001C + column
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x4D
		STRB r0, [r4]
		B END_CHECK_SPAM_TOP_USER
CHECK_SPAM_TOP_USER_TYPE_0_CASE_2 ; check case 2
		BL LOST_LIFE
		; prompt
		LDR r4, =prompt_spam_on_top
		BL OUTPUT_STRING
		B END_CHECK_SPAM_TOP_USER
		; check 2 enemy cursors type
CHECK_SPAM_TOP_USER_TYPE_1 
		CMP r2, #2
		BEQ CHECK_SPAM_TOP_USER_TYPE_1_CASE_2
		CMP r2, #3
		BEQ CHECK_SPAM_TOP_USER_TYPE_1_CASE_3
		; add enemy cursor at 0x4000001C + column
		; add enemy cursor at 0x40000035 + column
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x56
		STRB r0, [r4]
		LDR r4, =0x40000035
		ADD r4, r4, r1
		STRB r0, [r4]
		B END_CHECK_SPAM_TOP_USER
CHECK_SPAM_TOP_USER_TYPE_1_CASE_2 ; check case 2
		BL LOST_LIFE
		; add enemy cursor at 0x40000035 + column
		LDR r4, =0x40000035
		ADD r4, r4, r1
		MOV r0, #0x56
		STRB r0, [r4]
		; prompt
		LDR r4, =prompt_spam_on_top
		BL OUTPUT_STRING
		B END_CHECK_SPAM_TOP_USER
CHECK_SPAM_TOP_USER_TYPE_1_CASE_3 ; check case 3
		BL LOST_LIFE
		; add enemy cursor at 0x4000001C + column
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x56
		STRB r0, [r4]
		; prompt
		LDR r4, =prompt_spam_on_top
		BL OUTPUT_STRING
		B END_CHECK_SPAM_TOP_USER
		; check 3 enemy cursors type
CHECK_SPAM_TOP_USER_TYPE_2 
		CMP r2, #2
		BEQ CHECK_SPAM_TOP_USER_TYPE_2_CASE_2
		CMP r2, #3
		BEQ CHECK_SPAM_TOP_USER_TYPE_2_CASE_3
		CMP r2, #4
		BEQ CHECK_SPAM_TOP_USER_TYPE_2_CASE_4
		; add enemy cursor at 0x4000001C + column
		; add enemy cursor at 0x40000035 + column
		; add enemy cursor at 0x4000004E + column
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x53
		STRB r0, [r4]
		LDR r4, =0x40000035
		ADD r4, r4, r1
		STRB r0, [r4]
		LDR r4, =0x4000004E
		ADD r4, r4, r1
		STRB r0, [r4]
		B END_CHECK_SPAM_TOP_USER
CHECK_SPAM_TOP_USER_TYPE_2_CASE_2 ; check case 2
		BL LOST_LIFE
		; add enemy cursor at 0x40000035 + column
		; add enemy cursor at 0x4000004E + column
		LDR r4, =0x40000035
		ADD r4, r4, r1
		MOV r0, #0x53
		STRB r0, [r4]
		LDR r4, =0x4000004E
		ADD r4, r4, r1
		STRB r0, [r4]
		; prompt
		LDR r4, =prompt_spam_on_top
		BL OUTPUT_STRING
		B END_CHECK_SPAM_TOP_USER
CHECK_SPAM_TOP_USER_TYPE_2_CASE_3 ; check case 3
		BL LOST_LIFE
		; add enemy cursor at 0x4000001C + column
		; add enemy cursor at 0x4000004E + column
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x53
		STRB r0, [r4]
		LDR r4, =0x4000004E
		ADD r4, r4, r1
		STRB r0, [r4]
		; prompt
		LDR r4, =prompt_spam_on_top
		BL OUTPUT_STRING
		B END_CHECK_SPAM_TOP_USER
CHECK_SPAM_TOP_USER_TYPE_2_CASE_4 ; check case 4
		BL LOST_LIFE
		; add enemy cursor at 0x4000001C + column
		; add enemy cursor at 0x40000035 + column
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x53
		STRB r0, [r4]
		LDR r4, =0x40000035
		ADD r4, r4, r1
		STRB r0, [r4]
		; prompt
		LDR r4, =prompt_spam_on_top
		BL OUTPUT_STRING
		B END_CHECK_SPAM_TOP_USER
		; check 2 enemy cursors type
CHECK_SPAM_TOP_USER_TYPE_3 
		CMP r2, #2
		BEQ CHECK_SPAM_TOP_USER_TYPE_3_CASE_2
		CMP r2, #3
		BEQ CHECK_SPAM_TOP_USER_TYPE_3_CASE_3
		; add enemy cursor at 0x4000001C + column
		; add enemy cursor at 0x40000035 + column
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x42
		STRB r0, [r4]
		LDR r4, =0x40000035
		ADD r4, r4, r1
		STRB r0, [r4]
		B END_CHECK_SPAM_TOP_USER
CHECK_SPAM_TOP_USER_TYPE_3_CASE_2 ; check case 2
		BL LOST_LIFE
		; add enemy cursor at 0x40000035 + column
		LDR r4, =0x40000035
		ADD r4, r4, r1
		MOV r0, #0x42
		STRB r0, [r4]
		; prompt
		LDR r4, =prompt_spam_on_top
		BL OUTPUT_STRING
		B END_CHECK_SPAM_TOP_USER
CHECK_SPAM_TOP_USER_TYPE_3_CASE_3 ; check case 3
		BL LOST_LIFE
		; add enemy cursor at 0x4000001C + column
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x42
		STRB r0, [r4]
		; prompt
		LDR r4, =prompt_spam_on_top
		BL OUTPUT_STRING
		B END_CHECK_SPAM_TOP_USER
END_CHECK_SPAM_TOP_USER

		LDMFD SP!, {lr, r0-r4}
		BX lr
; --------------------------------------------------------------- CHECK_4_LINES
CHECK_4_LINES
		STMFD sp!, {lr, r0-r1,r3-r4}
		; takes in address 0x4000001C + column (random number column)
		; takes in r1 as random column
		; check this location is M, V, S, B2 or not
		;		if yes, return 1, exit iteration
		;		if is C, return 2 for location at 0x4000001C + column
		;				 return 3 for location at 0x40000035 + column
		; 				 return 4 for location at 0x4000004E + column
		; 				 return 5 for location at 0x40000067 + column
		;		if is space, return 0 and back to iteration
		; iterate from 0x4000001C + column --> 0x40000035 + column --> 0x4000004E + column --> 0x40000067 + column
		LDR r2, =0x4000001C ; for later determine user cases
		MOV r0, #0 ; iteration
		LDR r4, =0x4000001C
		ADD r4, r4, r1
LOOP_CHECK_4_LINES
		CMP r0, #4
		BEQ CHECK_4_LINES_CASE_0
		LDRB r3, [r4]
		CMP r3, #0x4D
		BEQ CHECK_4_LINES_CASE_1
		CMP r3, #0x56
		BEQ CHECK_4_LINES_CASE_1
		CMP r3, #0x53
		BEQ CHECK_4_LINES_CASE_1
		CMP r3, #0x42
		BEQ CHECK_4_LINES_CASE_1
		CMP r3, #0x43
		BEQ CHECK_4_LINES_USER_CASE
		B END_CHECK_4_LINES_USER_CASE
CHECK_4_LINES_USER_CASE
		SUB r1, r4, r2
		CMP r1, #25
		BLT CHECK_4_LINES_CASE_2
		CMP r1, #50
		BLT CHECK_4_LINES_CASE_3
		CMP r1, #75
		BLT CHECK_4_LINES_CASE_4
		CMP r1, #100
		BLT CHECK_4_LINES_CASE_5
END_CHECK_4_LINES_USER_CASE
		; case 0, iterate address
		ADD r0, r0, #1
		ADD r4, r4, #25
		B LOOP_CHECK_4_LINES
CHECK_4_LINES_CASE_0
		MOV r2, #0
		B END_CHECK_4_LINES
CHECK_4_LINES_CASE_1
		MOV r2, #1
		B END_CHECK_4_LINES
CHECK_4_LINES_CASE_2
		MOV r2, #2
		B END_CHECK_4_LINES
CHECK_4_LINES_CASE_3
		MOV r2, #3
		B END_CHECK_4_LINES
CHECK_4_LINES_CASE_4
		MOV r2, #4
		B END_CHECK_4_LINES
CHECK_4_LINES_CASE_5
		MOV r2, #5
END_CHECK_4_LINES
		
		LDMFD SP!, {lr, r0-r1,r3-r4}
		BX lr
; --------------------------------------------------------------- SPAM_ENEMY
SPAM_ENEMY
		STMFD sp!, {lr, r4}
		; we want to spam in enemy to board using random generator
		; use 4 row (at least a space between enemy cursors)
		; check that 4 rows dont have other enemy cursors (except user cursor)
		; 		if it overlap, dont generate enemy
		; check if it spam on top of user cursor
		; 		if is on top, then lost life and show other cursors	that is not overlap
		;		lost life
		; Note: r3 is the random value from RANDOM COLUMN, RANDOM ROW	and RANDOM ENEMY_TYPE
		; 40000018 (1st space at 4000001c, last space at 4000002E)
		; 40000031 (1st space at 40000035, last space at 40000047)
		; 4000004A (1st space at 4000004E, last space at 40000060)
		; 40000063 (1st space at 40000067, last space at 40000079)
		; 											takes in the random type (r0) and random column (r1)
		; check (A,B,C,D, + column) location dont have (M,V,S,B2)
		; 		if there is a branch to DONT SPAM (case 1), branch to end spam
		; 		if there is user, bl check-spam-top-user at A,B,C (case 2~5), branch to end spam
		; check random type (M=0, V=1, S=2, B=3) (case 0)
		;		if is 0, add M at A + column
		;		if is 1, add V at A,B + column
		;		if is 2, add S at A, B, C + column
		;		if is 3, add B at A, B + column  
		BL CHECK_4_LINES ; output cases is r2
		CMP r2, #0
		BEQ	SPAM_ENEMY_SPAM_IN
		CMP r2, #1
		BEQ END_SPAM_ENEMY
		; others is SPAM_ENEMY_SPAM_TOP_USER
		BL CHECK_SPAM_TOP_USER
		B END_SPAM_ENEMY
SPAM_ENEMY_SPAM_IN
		; check enemy type
		CMP r0, #0
		BEQ SPAM_ENEMY_M
		CMP r0, #1
		BEQ SPAM_ENEMY_V
		CMP r0, #2
		BEQ SPAM_ENEMY_S
		CMP r0, #3
		BEQ SPAM_ENEMY_B
SPAM_ENEMY_M
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x4D
		STRB r0, [r4]
		B END_SPAM_ENEMY
SPAM_ENEMY_V
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x56
		STRB r0, [r4]
		LDR r4, =0x40000035
		ADD r4, r4, r1
		STRB r0, [r4]
		B END_SPAM_ENEMY
SPAM_ENEMY_S
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x53
		STRB r0, [r4]
		LDR r4, =0x40000035
		ADD r4, r4, r1
		STRB r0, [r4]
		LDR r4, =0x4000004E
		ADD r4, r4, r1
		STRB r0, [r4]
		B END_SPAM_ENEMY
SPAM_ENEMY_B
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r0, #0x42
		STRB r0, [r4]
		LDR r4, =0x40000035
		ADD r4, r4, r1
		STRB r0, [r4]
END_SPAM_ENEMY
		
		LDMFD SP!, {lr, r4}
		BX lr
; --------------------------------------------------------------- CHECK_COLUMN_LOCATIONS
CHECK_COLUMN_LOCATIONS
		STMFD sp!, {lr, r2-r4}
		; check r1 is not in column location
		LDR r4, =column_locations
		MOV r2, #0
LOOP_CHECK_COLUMN_LOCATIONS
		CMP r2, #5
		BEQ EXIT_LOOP_CHECK_COLUMN_LOCATIONS
		LDRB r3, [r4], #1
		CMP r1, r3
		BEQ ASK_RERADOM
		ADD r2, r2, #1
		B LOOP_CHECK_COLUMN_LOCATIONS
ASK_RERADOM
		MOV r1, #10 ; ask to randomize
EXIT_LOOP_CHECK_COLUMN_LOCATIONS
		
		LDMFD SP!, {lr, r2-r4}
		BX lr
; --------------------------------------------------------------- SPAM_ENEMY_START*
SPAM_ENEMY_START
		STMFD sp!, {lr, r0-r8}
		; this mthod is called in user input 'g'
		; spam 5 enemy to board using random generator
		; we dont check where user cursor is
		; we dont spam enemy at same column
		; Note: r3 is the random value from RANDOM COLUMN, RANDOM ROW and RANDOM ENEMY_TYPE
		; takes in random type (r0), random column (r1), random row (r2)
		; iterate 5 times to generate 5 enemy
		; check r1 is not in stored value (5 values)
		;		if yes regenerate again, dont increment
		; store r1, check emeny type (column_locations)
		; 		if is B2	add	2 B start from 0x4000001C + r1 + (r2*#25)
		; 		if is V		add	2 V	start from 0x4000001C + r1 + (r2*#25)
		; 		if is M		add	1 M	start from 0x4000001C + r1 + (r2*#25)
		; 		if is S		add	3 S	start from 0x4000001C + r1 + (r2*#25)
		; increment
		; call random column, back to iteration
		MOV r8, #0
GENERATE_5_ENEMY
		; store r1
		LDR r4, =column_locations
		ADD r4, r4, r8
		STRB r1, [r4]
		; generate 5
		CMP r8, #5
		BEQ EXIT_GENERATE_5_ENEMY
		; generate enemy
		CMP r0, #0
		BEQ GENERATE_M
		CMP r0, #1
		BEQ GENERATE_V
		CMP r0, #2
		BEQ GENERATE_S
		CMP r0, #3
		BEQ GENERATE_B
GENERATE_M
		; add 1 M start from 0x4000001C + r1 + (r2*#25)
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r6, #25
		MUL r2, r6, r2
		ADD r4, r4, r2
		; place cursor
		MOV r7, #0x4D
		STRB r7, [r4]
		B END_GENERATE
GENERATE_V
		; add 2 V start from 0x4000001C + r1 + (r2*#25)
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r6, #25
		MUL r2, r6, r2
		ADD r4, r4, r2
		; place cursor
		MOV r7, #0x56
		STRB r7, [r4], #25
		STRB r7, [r4]
		B END_GENERATE
GENERATE_S
		; add 3 S start from 0x4000001C + r1 + (r2*#25)
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r6, #25
		MUL r2, r6, r2
		ADD r4, r4, r2
		; place cursor
		MOV r7, #0x53
		STRB r7, [r4], #25
		STRB r7, [r4], #25
		STRB r7, [r4]
		B END_GENERATE
GENERATE_B
		; add 2 B start from 0x4000001C + r1 + (r2*#25)
		LDR r4, =0x4000001C
		ADD r4, r4, r1
		MOV r6, #25
		MUL r2, r6, r2
		ADD r4, r4, r2
		; place cursor
		MOV r7, #0x42
		STRB r7, [r4], #25
		STRB r7, [r4]
END_GENERATE
		; rerandomize: random type (r0), random column (r1), random row (r2)
RERANDOM
		BL RANDOM_ROW
		MOV r6, r3
		BL RANDOM_COLUMN
		MOV r7, r3
		BL RANDOM_ENEMY_TYPE
		MOV r0, r3
		MOV r1, r7
		MOV r2, r6
		; check r1 is not in column_locations
		BL CHECK_COLUMN_LOCATIONS
		CMP r1, #10
		BEQ RERANDOM
		; increment
		ADD r8, r8, #1
		B GENERATE_5_ENEMY
EXIT_GENERATE_5_ENEMY

		LDMFD SP!, {lr, r0-r8}
		BX lr
; --------------------------------------------------------------- RANDOM COLUMN
RANDOM_COLUMN
		STMFD sp!, {lr}
		; get value from T1TC
		; use division mod, set divisor to # of rows and then get remainder
		LDR r1, =0xE0008008
		LDR r0, [r1]
		LDR r2, =0xFFFF
		AND r0, r0, r2
		MOV r1, #10 ; number of rows
		BL unsigned_div_and_mod
		; remainder is r3 (output r3)
		; convert to board addresses
		LSL r3, r3, #1 ; multiply by 2
		
		LDMFD SP!, {lr}
		BX lr
; --------------------------------------------------------------- RANDOM ROW
RANDOM_ROW
		STMFD sp!, {lr}
		; get value from T1TC
		; use division mod, set divisor to # of rows and then get remainder
		LDR r1, =0xE0008008
		LDR r0, [r1]
		LDR r2, =0xFFFF
		AND r0, r0, r2
		; 14-3 = 11 is top of user cursor, 11-2 = 9 is at least 2 space above user cursor
		MOV r1, #9 ; number of rows
		BL unsigned_div_and_mod
		; remainder is r3 (output r3)
		
		LDMFD SP!, {lr}
		BX lr
; --------------------------------------------------------------- RANDOM ENEMY_TYPE
RANDOM_ENEMY_TYPE
		STMFD sp!, {lr}
		; get value from T1TC
		; use division mod, set divisor to # of rows and then get remainder
		LDR r1, =0xE0008008
		LDR r0, [r1]
		LDR r2, =0xFFFF
		AND r0, r0, r2
		MOV r1, #4 ; number of enemy types (M, V, S, B2)
		BL unsigned_div_and_mod
		; remainder is r3 (output r3)
		
		LDMFD SP!, {lr}
		BX lr
; --------------------------------------------------------------- LOST_LIFE
LOST_LIFE
		STMFD sp!, {lr, r1,r4}
		; read the number of lives on the board (or memory)
		; check if 0 life left
		; if yes then turn RGB to red, pause, lost life prompt, ask for restart game (if restart game then reset score, reset level)
		; if no then turn RGB to red, pause, lost life prompt, ask for resume game (dont reset score, level)
		BL READ_LIFE
		CMP r0, #15
		BEQ THREE_LIVES
		CMP r0, #7
		BEQ TWO_LIVES
		CMP r0, #3
		BEQ ONE_LIFE
		CMP r0, #1
		BEQ NO_LIFE
		CMP r0, #0
		BEQ END_GAME
THREE_LIVES
		; change to 3 lives and update board
		MOV r0, #7
		BL LEDS
		BL BOARD_CHANGE_LOST_LIFE
		B END_LOST_LIFE
TWO_LIVES
		; change to 2 lives and update board
		MOV r0, #3
		BL LEDS
		BL BOARD_CHANGE_LOST_LIFE
		B END_LOST_LIFE
ONE_LIFE
		; change to 1 lives and update board
		MOV r0, #1
		BL LEDS
		BL BOARD_CHANGE_LOST_LIFE
		B END_LOST_LIFE
NO_LIFE
		; change to 0 lives and update board
		MOV r0, #0
		BL LEDS
		BL BOARD_CHANGE_LOST_LIFE
		B END_LOST_LIFE
END_GAME
		; stop timer
		LDR r0, =0xE0004004
		LDR r1, [r0]
		BIC r1, r1, #1 ; set bit-0 to 1 if want to start the timer
		STR r1, [r0]
		; RGB LED to red
		MOV r0, #1
		BL RGB_LED
		; ask if want to start the game again
		LDR r4, =prompt_restart_no_life
		BL OUTPUT_STRING
		; reset game to reset score and reset life using user interrupt
END_LOST_LIFE
		MOV r0, #1 ; to indecate lost life		

		LDMFD SP!, {lr, r1,r4}
		BX lr
; --------------------------------------------------------------- BOARD_CHANGE_LOST_LIFE
BOARD_CHANGE_LOST_LIFE
		STMFD sp!, {lr, r0-r1}
		; turn RGB to red, pause, ask for restart game (dont reset score or reset level)
		; stop timer
		LDR r0, =0xE0004004
		LDR r1, [r0]
		BIC r1, r1, #1 ; set bit-0 to 1 if want to start the timer
		STR r1, [r0]
		; RGB LED to red
		MOV r0, #1
		BL RGB_LED
		; ask for restart game
		LDR r4, =prompt_restart_lost_life
		BL OUTPUT_STRING
		
		LDMFD SP!, {lr, r0-r1}
		BX lr
; --------------------------------------------------------------- READ_LIFE
READ_LIFE
		STMFD sp!, {lr, r1-r4}
		; read the number of lives on the board and put in r0
		LDR r1, =0xE0028014 ; IO1SET for LED
		LDR r0, [r1] ; value
		LSR r0, #16 ; shift the values from bit-16 to bit-0
		AND r0, r0, #0xF ; keep first 4 bits
		; reverse the order in r0
		BL REVERSE_INVERSE_BYTE
		
		LDMFD SP!, {lr, r1-r4}
		BX lr
; --------------------------------------------------------------- REVERSE_INVERSE_BYTE
REVERSE_INVERSE_BYTE
		STMFD sp!, {lr, r1-r3}
		; port 1 pin 16 to 19 (maximum of 16 numbers, 0 to 15)
		; pin 16 is MSB, pin 19 is LSB (reverse the order)
		; turn on is 0; turn off is 1 (invert the bits)
		; reverse the order of bits in r0
		MOV r1, #0 ; reset r1
		MOV r2, #0 ; initialize count
LOOP_REVERSE_INVERSE_BYTE
		CMP r2, #4
		BEQ END_LOOP_REVERSE_INVERSE_BYTE
		AND r3, r0, #1 ; get the first bit
		CMP r3, #1 ; check the first bit is 1 or not
		BEQ LSL_0_REVERSE_INVERSE_BYTE 
		LSL r1, #1 ; left shift 1
		ADD r1, r1, #1
		LSR r0, r0, #1 ; increment (next bit)
		ADD r2, r2, #1 ; increment count
		B LOOP_REVERSE_INVERSE_BYTE
LSL_0_REVERSE_INVERSE_BYTE ; left shift 0
		LSL r1, #1
		LSR r0, r0, #1 ; increment (next bit)
		ADD r2, r2, #1 ; increment count
		B LOOP_REVERSE_INVERSE_BYTE
END_LOOP_REVERSE_INVERSE_BYTE
		MOV r0, r1
		
		LDMFD SP!, {lr, r1-r3}
		BX lr
; --------------------------------------------------------------- SHIFT_CHARACTER
SHIFT_CHARACTER
		STMFD sp!, {lr, r0-r1}
		; r4 is the address we want to load
		; r6 is the address we want to store
		MOV r1, #22 ; offset (22 is at the last space in the line) (25 characters in each line)
SHIFT_LOOP
		CMP r1, #3 ; offset (3 is at the left-side W)
		BEQ	END_SHIFT_LOOP
		LDRB r0, [r4, r1] ; load byte into r0
		STRB r0, [r6, r1] ; store r0 at the next line
		SUB r1, r1, #1 ; decrement
		B SHIFT_LOOP
END_SHIFT_LOOP

		LDMFD SP!, {lr, r0-r1}
		BX lr
; --------------------------------------------------------------- SHIFT_LINE
SHIFT_LINE
		STMFD sp!, {lr, r1,r4,r6}
		; move car cursor above
		; shift address	from bottom to top (0x4000018F to 0x40000018)
		LDR r4, =prompt_line_16
		LDR r6, =last_line
		BL SHIFT_CHARACTER
		LDR r4, =prompt_line_15
		LDR r6, =prompt_line_16
		LDR r1, =prompt_upper_bound_line ; bound
LOOP_SHIFT_LINE
		CMP r4, r1
		BLT EXIT_LOOP_SHIFT_LINE
		BL SHIFT_CHARACTER
		MOV r6, r4 ; prompt_line_15 in r6
		SUB r4, r4, #25 ; prompt_line_14 in r4
		B LOOP_SHIFT_LINE
EXIT_LOOP_SHIFT_LINE
		; clear prompt_line_1 at after all others is shifted
		MOV r6, #0
		LDR r4, =0x4000001C
CLEAR_LINE_1
		CMP r6, #10
		BEQ EXIT_CLEAR_LINE_1
		MOV r1, #0x20 ; space
		STRB r1, [r4], #2
		ADD r6, r6, #1
		B CLEAR_LINE_1
EXIT_CLEAR_LINE_1

		LDMFD SP!, {lr, r1,r4,r6}
		BX lr
; --------------------------------------------------------------- REPROMPT
REPROMPT
		STMFD sp!, {lr, r4}
		; prompt interface
		LDR r4, =prompt_upper_bound_line ; prompt from the start of the bound line
		BL OUTPUT_STRING
		LDR r4, =prompt_game_start_instr ; prompt game starting instructions
		BL OUTPUT_STRING

		LDMFD SP!, {lr, r4}
		BX lr
; --------------------------------------------------------------- CHECK SCORE LEVEL
CHECK_SCORE_LEVEL
		STMFD sp!, {lr, r0-r4}
		; check the points if needed to increase level
		; level increase then the MR1 value - 0.1 sec (except bullet), bullet is (MR1 - 0.1 sec)/2
		; up to 6, so the game can be 0.4 sec per refresh (except bullet), bullet is 0.4/2 = 0.2 sec (we can lower the bound level)
		;       read the score
		BL READ_SCORE
		; use division to check level
		MOV r1, #500
		BL unsigned_div_and_mod ; r2 is level
		CMP r2, #9 ; level cant be greater than 9
		BGT DONT_CHANGE_LEVEL
		; use 7-seg to display level
		MOV r0, r2
		BL DISPLAY_DIGIT
		; calculate the speed
		LDR r0, =0xE000401C ; MR1
		LDR r1, =0x8CA000 ; value for half sec (9.216M), 0x1194000 value for a sec (18.432M)
		LDR r3, =0xE1000 ; 0xE1000 is 0.05 sec, 0x1C2000 is 0.1 sec
		MUL r2, r3, r2 ; 0.05*Level
		SUB r1, r1, r2 ; 0.5 - 0.05*Level
		STR r1, [r0]
DONT_CHANGE_LEVEL
		
		LDMFD SP!, {lr, r0-r4}
		BX lr
; --------------------------------------------------------------- INCREMENT SCORE		
INCREMENT_SCORE
		STMFD sp!, {lr, r1-r7}
		; r0 pass in the number need to add
		MOV r1, r0
		BL READ_SCORE
		ADD r0, r0, r1
		BL WRITE_SCORE
		
		LDMFD SP!, {lr, r1-r7}
		BX lr
; --------------------------------------------------------------- WRITE SCORE		
WRITE_SCORE
		STMFD sp!, {lr, r1-r7}
		; load prompt_score_line in r4 and modify memory to store the value r0 (dividend)
		; number start at 0x400001D0 (MSB)
		LDR r4, =0x400001D0
		MOV r5, #0 ; bound (offset)
		MOV r6, #3 ; 10-counter (divisor)
		MOV r7, #10 ; 10
WRITE_ADDRESS
		; compute divisor
		MOV r1, #1 ; initialize
		MOV r8, r6 ; dont change 10-counter untill is write
COMPUTE_10
		CMP r8, #0
		BLE EXIT_COMPUTE_10
		MUL r1, r7, r1 ; multiply by 10
		SUB r8, r8, #1 ; decrement
		B COMPUTE_10
EXIT_COMPUTE_10
		; compute character
		CMP r5, #4
		BEQ EXIT_WRITE_ADDRESS
		BL unsigned_div_and_mod
		; r2 quotient, r3 remainder
		ADD r2, r2, #0x30 ; convert to character
		STRB r2, [r4, r5] ; write into address
		MOV r0, r3 ; move remainder into dividend
		ADD r5, r5, #1 ; increment offset
		SUB r6, r6, #1 ; decrement 10-counter
		B WRITE_ADDRESS
EXIT_WRITE_ADDRESS

		LDMFD SP!, {lr, r1-r7}
		BX lr
; --------------------------------------------------------------- READ SCORE		
READ_SCORE
		STMFD sp!, {lr, r1-r4}
		; load prompt_score_line in r4 to read the values in into r0
		; number start at 0x400001D0 (MSB)
		LDR r4, =0x400001CF
		MOV r0, #0 ; initialize
		MOV r1, #4 ; bound
		MOV r2, #1 ; 10-counter
COMPUTE
		CMP r1, #0
		BEQ EXIT_COMPUTE
		LDRB r3, [r4, r1] ; load character into r0
		SUB r3, r3, #0x30 ; convert to integer
		MUL r3, r2, r3 ; multiply by 10-counter
		ADD r0, r0, r3 ; add to result
		; increment r2 by 10
		MOV r3, #10
		MUL r2, r3, r2
		; decrement
		SUB r1, r1, #1
		B COMPUTE
EXIT_COMPUTE

		LDMFD SP!, {lr, r1-r4}
		BX lr
; --------------------------------------------------------------- CHECK_LAST_LINE
CHECK_LAST_LINE
		STMFD sp!, {lr, r0,r4}
		; takes in r4 as address (but dont modify it) then check the character in it
		; add points, check if char M, V, S, B in there
		; read score then add the values, write score last
		LDR r4, =last_line
CHECK_LAST_LINE_LOOP
		LDRB r0, [r4], #1
		CMP r0, #0 ; NULL terminate string
		BEQ EXIT_CHECK_LAST_LINE_LOOP
		; check M, V, S, B in there
		CMP r0, #0x4D
		BEQ LAST_LINE_ADD_SCORE
		CMP r0, #0x56
		BEQ LAST_LINE_ADD_SCORE
		CMP r0, #0x53
		BEQ LAST_LINE_ADD_SCORE
		CMP r0, #0x42
		BEQ LAST_LINE_ADD_SCORE
		B END_CHECK_LAST_LINE_CURSOR
LAST_LINE_ADD_SCORE
		MOV r0, #10 ; add 10 points
		BL INCREMENT_SCORE
END_CHECK_LAST_LINE_CURSOR		
		B CHECK_LAST_LINE_LOOP
EXIT_CHECK_LAST_LINE_LOOP
		
		LDMFD SP!, {lr, r0,r4}
		BX lr
; --------------------------------------------------------------- CHECK_MOVE_BULLET_HIT
MOVE_BULLET
		STMFD sp!, {lr, r0,r4}
		; move the bullet
		BL SEARCH_BULLET_CURSOR
		; check if bullet hits the M, V, S (no B) and move the bullet or add points
		CMP r1, #1
		BEQ CHECK_address_1
		CMP r1, #2
		BEQ CHECK_BOTH
		B CHECK_NONE
CHECK_address_1
		LDR r4, =bullet_address_1
		BL CHECK_MOVE_BULLET_HIT
		B CHECK_NONE
CHECK_BOTH
		LDR r4, =bullet_address_1
		BL CHECK_MOVE_BULLET_HIT
		LDR r4, =bullet_address_2
		BL CHECK_MOVE_BULLET_HIT
CHECK_NONE
		
		LDMFD SP!, {lr, r0,r4}
		BX lr
; --------------------------------------------------------------- CHECK_MOVE_BULLET_HIT
CHECK_MOVE_BULLET_HIT
		STMFD sp!, {lr, r0,r4,r6}
		; takes in r4 as address (but dont modify it) then check the character above
		; add points, check if bullet hits the M, V, S (no B)
		; if it hit bullet proof then the bullet disappear
		; move bullet upward
		LDR r6, [r4]
		; check if hit enemy car
		LDRB r0, [r6, #-0x19] ; the character at the top (separate by 19 characters in between), store in r0
		CMP r0, #0x20 ; see if this character is a space or not
		BEQ MOVE_BULLET_UP
		; if the charcter is not a space, then add 50 points if only hits enemy car (M,V,S only)
		; change the enemy cursor to space
		; if it destory the car then add 25 points more
		; spame in first 4 lines before we start putting into board (4th line is a space)
		CMP r0, #0x4D
		BEQ BULLET_HIT_ENEMY
		CMP r0, #0x56
		BEQ BULLET_HIT_ENEMY
		CMP r0, #0x53
		BEQ BULLET_HIT_ENEMY
		CMP r0, #0x42 ; bullet proof case
		BEQ BULLET_HIT_ENEMY_BULLET_PROOF
		CMP r0, #0x40 ; top bound of the board
		BEQ BULLET_HIT_ENEMY_BULLET_PROOF
		CMP r0, #0x43 ; if hits user cursor case
		BEQ BULLET_HIT_USER
		B END_BULLET_UP
BULLET_HIT_USER
		; bullet disappear
		MOV r0, #0x20
		STRB r0, [r6]
		; clear the bullet_address
		MOV r0, #0
		STRB r0, [r4]
		B END_BULLET_UP
BULLET_HIT_ENEMY_BULLET_PROOF
		; clear the bullet
		MOV r0, #0x20
		STRB r0, [r6]
		; clear bullet_address
		MOV r0, #0
		STRB r0, [r4]
		B END_BULLET_UP
BULLET_HIT_ENEMY
		; clear bullet addresses
		MOV r1, #0
		STR r1, [r4]
		; reset r0 for later add score
		BL READ_SCORE 
		ADD r0, r0, #10 ; add 50 to r0 ------------------------------------------ change to 10
		; erase the bullet
		MOV r1, #0x20 ; space
		STRB r1, [r6]
		; erase the enemy cursor
		STRB r1, [r6, #-0x19]
		; check if this enemy cursor is the last character
		LDRB r1, [r6, #-0x32] ; the character at the top (separate by 19 characters in between), store in r0
		CMP r1, #0x20 ; if is, then add another 25 points
		BEQ BULLET_HIT_ADD_25_MORE
		B BULLET_HIT_ADD
BULLET_HIT_ADD_25_MORE
		ADD r0, r0, #5 ; --------------------------------------------------------- change to 5
BULLET_HIT_ADD
		BL WRITE_SCORE
		B END_BULLET_UP
MOVE_BULLET_UP
		; move the user car cursor to the top
		MOV r0, #0x20 ; store the space into the location before * moves
		STRB r0, [r6]
		MOV r0, #0x2A ; store char * to the top of the orginal location, then update the address for maybe later use
		STRB r0, [r6, #-0x19]!
		STR r6, [r4]
END_BULLET_UP
		
		LDMFD SP!, {lr, r0,r4,r6}
		BX lr
; --------------------------------------------------------------- Search 2 bullets cursor
SEARCH_BULLET_CURSOR
		STMFD sp!, {lr, r2-r4}
		; load prompt_upper_bound_line in r4, and store bullet address at bullet_address_1 (0x40000314) and bullet_address_2 (0x40000319)
		; search for at most 2 addresses
		LDR r4, =prompt_upper_bound_line
		MOV r1, #0 ; bound (offset)
		LDR r2, =bullet_address_1
FIND_BULLETS
		CMP r1, #2
		BEQ END_FIND_BULLETS
FIND_BULLET_CURSOR
		LDRB r0, [r4, #1]!
		CMP r0, #0x2A ; find *
		BEQ EXIT_FIND_BULLET_CURSOR
		; the case for not finding any * 
		LDR r0, =prompt_line_16
		CMP r4, r0
		BEQ END_FIND_BULLETS
		B FIND_BULLET_CURSOR
EXIT_FIND_BULLET_CURSOR
		; found then store location into bullet address
		MOV r3, #4
		MUL r3, r1, r3
		STR r4, [r2, r3]
		ADD r1, r1, #1 ; increment
		ADD r4, r4, #1 ; skip * and find the next *
		B FIND_BULLETS
END_FIND_BULLETS

		LDMFD SP!, {lr, r2-r4}
		BX lr
; --------------------------------------------------------------- MOVE_USER_LEFT
MOVE_USER_LEFT
		STMFD sp!, {lr, r4}
		; search C (user cursor)
		BL SEARCH_USER_CURSOR
		; move cursor
		; check if hit a wall or enemy car
		LDRB r0, [r4, #-2] ; the character at the left ('|' separate in between), store in r0
		CMP r0, #0x20 ; see if this character is a space if not
		BEQ MOVE_LEFT
		; if the charcter is not a space, then lost a life (LED) and restart the game at the same level but not score
		; make sure is not a bullet or @
		CMP r0, #0x2A
		BEQ END_LOST_LIFE_MOVE_USER_LEFT
		CMP r0, #0x40
		BEQ END_LOST_LIFE_MOVE_USER_LEFT
		; call lost_life
		BL LOST_LIFE
		B END_LEFT
END_LOST_LIFE_MOVE_USER_LEFT
		; check if left is W
		LDRB r0, [r4, #-1] ; the character at the left ('|' separate in between), store in r0
		CMP r0, #0x57
		BNE NOT_OFF_ROAD_LEFT
		; call lost_life
		BL LOST_LIFE
NOT_OFF_ROAD_LEFT
		B END_LEFT
MOVE_LEFT
		; move the user car cursor to the left
		MOV r0, #0x20 ; store the space into the location before C moves
		STRB r0, [r4]
		MOV r0, #0x43 ; store char C to the left of the orginal location, then update the address for maybe later use
		STRB r0, [r4, #-2]!
END_LEFT
		
		LDMFD SP!, {lr, r4}
		BX lr
; --------------------------------------------------------------- MOVE_USER_RIGHT
MOVE_USER_RIGHT
		STMFD sp!, {lr, r4}
		; search C (user cursor)
		BL SEARCH_USER_CURSOR
		; move cursor
		; check if hit a wall or enemy car
		LDRB r0, [r4, #2] ; the character at the right ('|' separate in between), store in r0
		CMP r0, #0x20 ; see if this character is a space if not
		BEQ MOVE_RIGHT
		; if the charcter is not a space, then lost a life (LED) and restart the game at the same level but not score
		; make sure is not a bullet	or @
		CMP r0, #0x2A
		BEQ END_LOST_LIFE_MOVE_USER_RIGHT
		CMP r0, #0x40
		BEQ END_LOST_LIFE_MOVE_USER_RIGHT
		; call lost_life
		BL LOST_LIFE
		B END_RIGHT
END_LOST_LIFE_MOVE_USER_RIGHT
		; check if right is W
		LDRB r0, [r4, #1] ; the character at the left ('|' separate in between), store in r0
		CMP r0, #0x57
		BNE NOT_OFF_ROAD_RIGHT
		; call lost_life
		BL LOST_LIFE
NOT_OFF_ROAD_RIGHT
		B END_RIGHT
MOVE_RIGHT
		; move the user car cursor to the left
		MOV r0, #0x20 ; store the space into the location before C moves
		STRB r0, [r4]
		MOV r0, #0x43 ; store char C to the left of the orginal location, then update the address for maybe later use
		STRB r0, [r4, #2]!
END_RIGHT
		
		LDMFD SP!, {lr, r4}
		BX lr
; --------------------------------------------------------------- MOVE_USER_DOWN
MOVE_USER_DOWN
		STMFD sp!, {lr, r4}
		; search C (user cursor)
		BL SEARCH_USER_CURSOR
		; move cursor
		; check if hit a wall or enemy car
		LDRB r0, [r4, #0x19] ; the character at the top (separate by 19 characters in between), store in r0
		CMP r0, #0x20 ; see if this character is a space if not
		BEQ MOVE_DOWN
		; if the charcter is not a space, then lost a life (LED) and restart the game at the same level if only hits an enemy car
		; make sure is not a bullet	or @
		CMP r0, #0x2A
		BEQ END_LOST_LIFE_MOVE_USER_DOWN
		CMP r0, #0x40
		BEQ END_LOST_LIFE_MOVE_USER_DOWN
		; call lost_life
		BL LOST_LIFE
		B END_DOWN
END_LOST_LIFE_MOVE_USER_DOWN
		B END_DOWN
MOVE_DOWN
		; move the user car cursor to the left
		MOV r0, #0x20 ; store the space into the location before C moves
		STRB r0, [r4]
		MOV r0, #0x43 ; store char C to the left of the orginal location, then update the address for maybe later use
		STRB r0, [r4, #0x19]!
END_DOWN
		
		LDMFD SP!, {lr, r4}
		BX lr
; --------------------------------------------------------------- MOVE_USER_UP
MOVE_USER_UP
		STMFD sp!, {lr, r4}
		; search C (user cursor)
		BL SEARCH_USER_CURSOR
		; move cursor
		; check if hit a wall or enemy car
		LDRB r0, [r4, #-0x19] ; the character at the top (separate by 19 characters in between), store in r0
		CMP r0, #0x20 ; see if this character is a space if not
		BEQ MOVE_UP
		; if the charcter is not a space, then lost a life (LED) and restart the game at the same level if only hits an enemy car
		; make sure is not a bullet	or @
		CMP r0, #0x2A
		BEQ END_LOST_LIFE_MOVE_USER_UP
		CMP r0, #0x40
		BEQ END_LOST_LIFE_MOVE_USER_UP
		; call lost_life
		BL LOST_LIFE
		B END_UP
END_LOST_LIFE_MOVE_USER_UP
		B END_UP
MOVE_UP
		; move the user car cursor to the left
		MOV r0, #0x20 ; store the space into the location before C moves
		STRB r0, [r4]
		MOV r0, #0x43 ; store char C to the left of the orginal location, then update the address for maybe later use
		STRB r0, [r4, #-0x19]!
END_UP
		
		LDMFD SP!, {lr, r4}
		BX lr
; --------------------------------------------------------------- Search user cursor
SEARCH_USER_CURSOR
		STMFD sp!, {lr}
		; load prompt_upper_bound_line in r4, and return user cursor at r4 (address)
		LDR r4, =prompt_line_1
FIND_USER_CURSOR
		LDRB r0, [r4, #1]!
		CMP r0, #0x43 ; find C
		BEQ EXIT_FIND_USER_CURSOR
		B FIND_USER_CURSOR
EXIT_FIND_USER_CURSOR

		LDMFD SP!, {lr}
		BX lr
; --------------------------------------------------------------- FIQ
FIQ_Handler
		; set r5 as global variable for bound
		STMFD SP!, {r0-r4,r8-r12, lr}   ; Save registers
; Check for EINT1 interrupt
EINT1			
		LDR r0, =0xE01FC140
		LDR r1, [r0]
		TST r1, #2 ; bit-1 is 0 means no interrupt
		BEQ FIQ_Exit
		STMFD SP!, {r0-r4,r8-r12, lr}   ; Save registers 
		; Push button EINT1 Handling Code
		; RGB LED to blue
		MOV r0, #2
		BL RGB_LED
		; stop timer
		LDR r0, =0xE0004004
		LDR r1, [r0]
		AND r1, r1, #0 ; set bit-0 to 0 to stop the timer
		STR r1, [r0]
		; prompt resume game instructions
		LDR r4, =prompt_game_restart_instr
		BL OUTPUT_STRING
		; End My code
		LDMFD SP!, {r0-r4,r8-r12, lr}   ; Restore registers
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
FIQ_Exit

; check for timer interrupt
; timer code starts here
; shift the lines in memory
; redraw the text every time for object coming down
; change memory only
TIMER_MR1
		LDR r0, =0xE0004000
		LDR r1, [r0]
		TST r1, #2 ; bit-1 is 0 means no interrupt (MR1)
		BEQ TIMER_MR1_Exit
		STMFD SP!, {r0-r4,r8-r12, lr}   ; Save registers 
		; timer Handling Code
		; timer interrupt for bullet set the timer as 0.5 sec (MR1 value divide by 2) 
		; let r5 changing 0 and 1 back and forth so we can move other cursors every 1 sec
		; here we have to check the bullets first before we start the shifting
		BL MOVE_BULLET
		; check if we need to move other cursors
		CMP r5, #1
		BEQ SHIFT_BOARD
		B MOVE_BULLET_ONLY
SHIFT_BOARD
		; move bullet again
		BL MOVE_BULLET
		; move character upward 1 line (UP-code from user)
		BL MOVE_USER_UP
		CMP r0, #1 ; if is 1, then is lost life case
		BEQ END_TIME_INTERRUPT
		; shift all the lines by one line expect the boundary
		BL SHIFT_LINE
		; spam enemy when every time board shifts
		BL RANDOM_ENEMY_TYPE
		MOV r7, r3 ; store r3 at r7
		BL RANDOM_COLUMN
		MOV r1, r3
		MOV r0, r7
		BL SPAM_ENEMY
		; check last line for enemy cursors
		BL CHECK_LAST_LINE
		; set r5 to 1 so next time timer-interrupt happen will not move cursors
		MOV r5, #0 
		B CHECK_POINT_LEVEL
MOVE_BULLET_ONLY
		; set r5 to 1 so next time timer-interrupt happen will not move cursors
		MOV r5, #1 
CHECK_POINT_LEVEL
		; check the points if needed to increase level
		BL CHECK_SCORE_LEVEL
END_HIT_ENEMY
		; make sure it stays green
		MOV r0, #3
		BL RGB_LED
		; set to reprompt
		BL REPROMPT
		; End My code
END_TIME_INTERRUPT
		LDMFD SP!, {r0-r4,r8-r12, lr}   ; Restore registers
		ORR r1, r1, #2		; Clear Interrupt
		STR r1, [r0]
TIMER_MR1_Exit

; check for user input interrupt
USER
		LDR r0, =0xE000C008
		LDR r1, [r0]
		AND r1, r1, #1 ; get bit-0
		CMP r1, #1 ; 0 if there's interrupt pending
		BEQ USER_EXIT
		STMFD SP!, {r0-r4,r8-r12, lr}   ; Save register
		; user input
		BL READ_CHARACTER ; user input is store at r0
		CMP r0, #0x71 ; quit program
		BEQ QUIT; if is q
		CMP r0, #0x79 ; restart program
		BEQ RESTART_GAME; if is y
		CMP r0, #0x67 ; compare g to start the game and generate enemy
		BEQ START_TIMER_GENERATE_ENEMY ; if is g
		CMP r0, #0x72 ; compare r to resume the game
		BEQ START_TIMER ; if is r
		; check for move cursor X up, down, right or left (w: up, s: down, a: left, d: right)
		CMP r0, #0x61; compare w,a,s,d
		BEQ LEFT; if is a
		CMP r0, #0x64; compare w,a,s,d
		BEQ RIGHT; if is d
		CMP r0, #0x77; compare w,a,s,d
		BEQ UP; if is w
		CMP r0, #0x73; compare w,a,s,d
		BEQ DOWN; if is s
		CMP r0, #0x20; compare space
		BEQ FIRE; if is space then fire bullet
		B FIN_CMP
		
		; code for user input 'g' handle
START_TIMER_GENERATE_ENEMY
		; clear user previous user cursor location
		BL CLEAR_BOARD
		; generate enemy
		BL RANDOM_ROW
		MOV r6, r3
		BL RANDOM_COLUMN
		MOV r7, r3
		BL RANDOM_ENEMY_TYPE
		MOV r0, r3
		MOV r1, r7
		MOV r2, r6
		BL SPAM_ENEMY_START
		; set user cursor at initial location
		LDR r4, =0x4000019B ; initial location for user cursor
		MOV r0, #0x43
		STRB r0, [r4]
		; RGB LED to green
		MOV r0, #3
		BL RGB_LED
		; start timer
		LDR r0, =0xE0004004
		LDR r1, [r0]
		ORR r1, r1, #0x1 ; set bit-0 to 1 to start the timer
		STR r1, [r0]
		; reprompt the enemy out
		BL REPROMPT
		B FIN_CMP
		
RESTART_GAME ; code for user input 'y' handle
		; reset level and time, reset score, reset lives
		MOV r0, #0
		BL DISPLAY_DIGIT
		; store 0.5 sec in 0xE000401C (18.432MHz is 1 sec, 9.216MHz is 0.5 sec)
		LDR r0, =0xE000401C ; MR1
		LDR r1, =0x8CA000 ; value for half sec (18.432M) 0x1194000 value for a sec (18.432M)
		STR r1, [r0]
		MOV r0, #0
		BL WRITE_SCORE
		MOV r0, #15		
		BL LEDS
		MOV r5, #0xFE
		B FIN_CMP
		
FIRE    ; code for user input space handle
		
		; search for * cursor (can only have 2 bullet at the same board)
		BL SEARCH_BULLET_CURSOR
		CMP r1, #2
		BGE EXIT_FIRE
		; search for car cursor
		BL SEARCH_USER_CURSOR
		; check top of C
		SUB r4, r4, #25
		LDRB r0, [r4]
		CMP r0, #0x4D ; if is M, V, S, then add score
		BEQ ADD_SCORE
		CMP r0, #0x56 ; if is M, V, S, then add score
		BEQ ADD_SCORE
		CMP r0, #0x53 ; if is M, V, S, then add score
		BEQ ADD_SCORE
		CMP r0, #0x42 ;	if is B, then do nothing
		BEQ EXIT_FIRE
		CMP r0, #0x20 ;	if is space, then put *
		BEQ ADD_BULLET_CURSOR
		B FIN_FIRE
ADD_SCORE
		BL READ_SCORE
		ADD r0, r0, #50
		BL WRITE_SCORE
		; clear the enemy cursor
		MOV r0, #0x20 
		STRB r0, [r4]
		B FIN_FIRE
ADD_BULLET_CURSOR
		MOV r0, #0x2A
		STRB r0, [r4]
		B FIN_FIRE
FIN_FIRE
		BL CHECK_SCORE_LEVEL ; check the points if needed to increase level
		BL REPROMPT ; reprompt
EXIT_FIRE
		B FIN_CMP
		
START_TIMER ; code for user input 'r' handle
		; RGB LED to green
		MOV r0, #3
		BL RGB_LED
		LDR r0, =0xE0004004
		LDR r1, [r0]
		ORR r1, r1, #0x1 ; set bit-0 to 1 to start the timer
		STR r1, [r0]
		B FIN_CMP
		
LEFT	; code for user input 'a' handle
		BL MOVE_USER_LEFT
		CMP r0, #1 ; if is 1, then is lost life case
		BEQ FIN_CMP

		BL REPROMPT ; reprompt
		B FIN_CMP
		
RIGHT	; code for user input 'd' handle
		BL MOVE_USER_RIGHT
		CMP r0, #1 ; if is 1, then is lost life case
		BEQ FIN_CMP
		BL REPROMPT ; reprompt
		B FIN_CMP
			
UP		; code for user input 'w' handle (user can go up to prompt_line_4)
		BL MOVE_USER_UP
		CMP r0, #1 ; if is 1, then is lost life case
		BEQ FIN_CMP
		BL REPROMPT ; reprompt
		B FIN_CMP
		
DOWN    ; code for user input 's' handle
		BL MOVE_USER_DOWN
		CMP r0, #1 ; if is 1, then is lost life case
		BEQ FIN_CMP
		BL REPROMPT ; reprompt
		B FIN_CMP

QUIT	; set r5 to 0xFF to quit program
		MOV r5, #0xFF ; end-game state
		B FIN_CMP
FIN_CMP
		LDMFD SP!, {r0-r4,r8-r12, lr}   ; Restore registers
USER_EXIT

		LDMFD SP!, {r0-r4,r8-r12, lr}
		SUBS pc, lr, #4
	END