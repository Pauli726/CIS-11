; CIS 11 TEST SCORE CALCULATOR 
;Alicia Medrano Escobar, Team member
;Alberto Garcia, Team member
;Aaron Pauli, Team member

.ORIG x3000         			; Program starts at memory address x3000
        BR MAIN      			; Jump to MAIN routine

STACK_TOP .FILL x4000 			; Initial stack pointer location
NL        .FILL x000A 			; Newline character
SP        .FILL x0020 			; Space character
WELCOME   .STRINGZ "Enter 5 scores:" 	; Welcome message
PROMPT    .STRINGZ "Score: "         	; Prompt for each score

GRADES    .BLKW #5   			; Reserve space for 5 scores
COUNT     .BLKW #1   			; Counter for number of inputs left
PTR       .BLKW #1   			; Pointer to current GRADES index
MAXS      .BLKW #1   			; Stores maximum score
MINS      .BLKW #1   			; Stores minimum score
SUMS      .BLKW #1   			; Stores sum of all scores
AVGS      .BLKW #1   			; Stores average score

MAIN
        LD R6, STACK_TOP 		; Initialize stack pointer R6

        LEA R0, WELCOME  		; Load address of welcome message
        PUTS             		; Print welcome message
        LD R0, NL        		; Load newline
        OUT              		; Print newline

        AND R0, R0, #0   		; Clear R0
        ADD R0, R0, #5   		; Set COUNT = 5
        ST R0, COUNT

        LEA R0, GRADES  		; Load base address of GRADES array
        ST R0, PTR       		; Store pointer

INPUT_LOOP
        LEA R0, PROMPT   		; Print "Score: "
        PUTS

        JSR GET_SCORE    		; Read a 2-digit score into R3

        LD R4, PTR       		; Load pointer to GRADES array
        STR R3, R4, #0   		; Store score into GRADES[i]

        LD R0, SP        		; Print a space
        OUT

        JSR GET_LETTER   		; Convert score to letter grade
        JSR POP          		; Print the letter grade

        LD R0, NL        		; Print newline
        OUT

        LD R4, PTR       		; Increment pointer to next GRADES slot
        ADD R4, R4, #1
        ST R4, PTR

        LD R0, COUNT     		; Decrement COUNT
        ADD R0, R0, #-1
        ST R0, COUNT
        BRp INPUT_LOOP   		; Loop until 5 scores entered

        JSR CALC_STATS   		; Compute min, max, avg
        JSR RESTART      		; Ask user if they want to restart
        HALT             		; End program

; ---------------- GET_SCORE ----------------
; Reads two digits, validates them, converts to numeric value in R3

GET_SCORE
        ST R7, GS7       		; Save registers
        ST R1, GS1
        ST R2, GS2

        GETC             		; Read first digit
        JSR CHECK_DIGIT  		; Validate digit
        OUT              		; Echo digit

        LD R1, GS_NEGZERO 		; Convert ASCII to number
        ADD R1, R0, R1

        AND R3, R3, #0   		; R3 = 0 (score accumulator)
        AND R2, R2, #0   		; R2 = 10 (multiplier)
        ADD R2, R2, #10

GS_MULT
        ADD R3, R3, R1   		; Multiply first digit by 10
        ADD R2, R2, #-1
        BRp GS_MULT

        GETC             		; Read second digit
        JSR CHECK_DIGIT  		; Validate digit
        OUT              		; Echo digit

        LD R1, GS_NEGZERO 		; Convert ASCII to number
        ADD R0, R0, R1
        ADD R3, R3, R0   		; Add second digit

        LD R1, GS1       		; Restore registers
        LD R2, GS2
        LD R7, GS7
        RET

GS7 .BLKW #1
GS1 .BLKW #1
GS2 .BLKW #1
GS_NEGZERO .FILL xFFD0 ; -48 (ASCII '0')

; ---------------- CHECK_DIGIT ----------------
; Validates ASCII input is between '0' and '9'

CHECK_DIGIT
        ST R1, CD1
        ST R2, CD2

        LD R1, CD_NEGZERO 		; R0 - '0'
        ADD R2, R0, R1
        BRn BAD_INPUT     		; If < 0, invalid

        LD R1, CD_NEGNINE 		; R0 - '9'
        ADD R2, R0, R1
        BRp BAD_INPUT     		; If > 9, invalid

        LD R1, CD1        		; Restore
        LD R2, CD2
        RET

; ---------------- ERROR HANDLING ----------------

BAD_INPUT
        LEA R0, BADMSG    		; Print error message
        PUTS
        LD R7, STARTADDR  		; Restart program
        JMP R7

CD1 .BLKW #1
CD2 .BLKW #1
CD_NEGZERO .FILL xFFD0
CD_NEGNINE .FILL xFFC7
BADMSG .STRINGZ " Invalid input. Restarting."
STARTADDR .FILL x3000

; ---------------- GET_LETTER ----------------
; Converts numeric score in R3 to letter grade

GET_LETTER
        ST R7, GL7
        ST R1, GL1
        ST R2, GL2

        LD R1, N90
        ADD R2, R3, R1
        BRzp G_A          		; Score >= 90 ? A

        LD R1, N80
        ADD R2, R3, R1
        BRzp G_B          		; Score >= 80 ? B

        LD R1, N70
        ADD R2, R3, R1
        BRzp G_C          		; Score >= 70 ? C

        LD R1, N60
        ADD R2, R3, R1
        BRzp G_D          		; Score >= 60 ? D

        LD R0, LF         		; Else unknown is F
        BRnzp SAVE_LETTER

G_A     LD R0, LA         		; Load ASCII 'A'
        BRnzp SAVE_LETTER
G_B     LD R0, LB
        BRnzp SAVE_LETTER
G_C     LD R0, LC
        BRnzp SAVE_LETTER
G_D     LD R0, LDVAL

SAVE_LETTER
        JSR PUSH          		; Push letter onto stack
        LD R1, GL1       		; Restore registers
        LD R2, GL2
        LD R7, GL7
        RET

GL7 .BLKW #1
GL1 .BLKW #1
GL2 .BLKW #1
N90 .FILL #-90
N80 .FILL #-80
N70 .FILL #-70
N60 .FILL #-60
LA .FILL x0041 ; 'A'
LB .FILL x0042 ; 'B'
LC .FILL x0043 ; 'C'
LDVAL .FILL x0044 ; 'D'
LF .FILL x0046 ; 'F'

; ---------------- STACK OPS ----------------

PUSH
        ADD R6, R6, #-1 		; Move stack pointer down
        STR R0, R6, #0  		; Store value
        RET

POP
        ST R7, POP7
        LDR R0, R6, #0  		; Load top of stack
        OUT             		; Print it
        ADD R6, R6, #1  		; Pop
        LD R7, POP7
        RET

POP7 .BLKW #1

; ---------------- CALC_STATS ----------------
; Computes MIN, MAX, SUM, AVG

CALC_STATS
        ST R7, CS7
        ST R6, CS6

        LEA R4, GRADES   		; R4 = pointer to GRADES
        LDR R1, R4, #0   		; R1 = max
        LDR R2, R4, #0   		; R2 = min
        AND R3, R3, #0   		; R3 = sum = 0

        AND R5, R5, #0   		; R5 = loop counter
        ADD R5, R5, #5

STAT_LOOP
        LDR R0, R4, #0   		; Load next score
        ADD R3, R3, R0  		; Add to sum

        NOT R6, R1       		; Compare for max
        ADD R6, R6, #1
        ADD R6, R0, R6
        BRp SET_MAX

CHECK_MIN
        NOT R6, R2       		; Compare for min
        ADD R6, R6, #1
        ADD R6, R0, R6
        BRn SET_MIN

NEXT_STAT
        ADD R4, R4, #1   		; Move to next score
        ADD R5, R5, #-1
        BRp STAT_LOOP
        BRnzp SHOW_STATS

SET_MAX
        ADD R1, R0, #0   		; Update max
        BRnzp CHECK_MIN

SET_MIN
        ADD R2, R0, #0   		; Update min
        BRnzp NEXT_STAT

SHOW_STATS
        ST R1, MAXS        		; Store the maximum score (in R1) into memory MAXS
        ST R2, MINS          		; Store the minimum score (in R2) into memory MINS
        ST R3, SUMS          		; Store the total sum of scores (in R3) into SUMS

        ; Print MAX
        LEA R0, MAXMSG       		; Load address of "MAX " message into R0
        PUTS                 		; Print "MAX "
        LD R3, MAXS          		; Load the maximum score into R3
        JSR PRINT_NUM        		; Print the numeric value of the max score
        LD R0, CS_SP         		; Load space character
        OUT                 		; Print space
        LD R3, MAXS          		; Load max score again for letter conversion
        JSR GET_LETTER       		; Convert numeric score ? letter grade (pushes letter on stack)
        JSR POP              		; POP prints the letter grade from the stack
        LD R0, CS_NL         		; Load newline character
        OUT                  		; Print newline

        ; Print MIN
        LEA R0, MINMSG       		; Load address of "MIN " message
        PUTS                 		; Print "MIN "
        LD R3, MINS          		; Load minimum score into R3
        JSR PRINT_NUM        		; Print the numeric value of the min score
        LD R0, CS_SP         		; Load space character
        OUT                  		; Print space
        LD R3, MINS          		; Load min score again for letter conversion
        JSR GET_LETTER       		; Convert numeric score ? letter grade
        JSR POP              		; Print the letter grade
        LD R0, CS_NL         		; Load newline
        OUT                  		; Print newline

        ; Compute AVG = SUM / 5
        LD R4, SUMS          		; Load SUM into R4 (working register)
        AND R5, R5, #0       		; Clear R5 (this will count how many times we subtract 5)

AVG_LOOP
        ADD R4, R4, #-5      		; Subtract 5 from SUM
        BRn AVG_DONE         		; If result < 0, stop (division complete)
        ADD R5, R5, #1       		; Increment average counter
        BRnzp AVG_LOOP       		; Repeat until SUM < 0

AVG_DONE
        ST R5, AVGS          		; Store computed average into AVGS

        ; Print AVG
        LEA R0, AVGMSG      		; Load address of "AVG " message
        PUTS                 		; Print "AVG "
        LD R3, AVGS          		; Load average score into R3
        JSR PRINT_NUM        		; Print the numeric average
        LD R0, CS_SP         		; Load space character
        OUT                  		; Print space
        LD R3, AVGS          		; Load average again for letter conversion
        JSR GET_LETTER       		; Convert numeric score ? letter grade
        JSR POP              		; Print the letter grade
        LD R0, CS_NL         		; Load newline
        OUT                  		; Print newline

        LD R6, CS6           		; Restore saved R6 (stack pointer)
        LD R7, CS7           		; Restore saved R7 (return address)
        RET                  		; Return to caller

CS7 .BLKW #1                 		; Storage for saved R7
CS6 .BLKW #1                 		; Storage for saved R6
CS_NL .FILL x000A            		; Newline character
CS_SP .FILL x0020            		; Space character
MAXMSG .STRINGZ "MAX "       		; Label for max score
MINMSG .STRINGZ "MIN "       		; Label for min score
AVGMSG .STRINGZ "AVG "      		; Label for average score


; ---------------- PRINT_NUM ----------------
; Prints a 2-digit number stored in R3

PRINT_NUM
        ST R7, PN7
        ST R1, PN1
        ST R4, PN4
        ST R5, PN5

        AND R1, R1, #0   		; Tens digit
        ADD R4, R3, #0  		; Copy number

DIV10
        ADD R4, R4, #-10
        BRn DIV_DONE
        ADD R1, R1, #1
        BRnzp DIV10

DIV_DONE
        ADD R4, R4, #10  		; R4 = ones digit
        LD R5, PN_ZERO   		; ASCII '0'

        ADD R0, R1, R5   		; Print tens
        OUT
        ADD R0, R4, R5   		; Print ones
        OUT

        LD R1, PN1
        LD R4, PN4
        LD R5, PN5
        LD R7, PN7
        RET

PN7 .BLKW #1
PN1 .BLKW #1
PN4 .BLKW #1
PN5 .BLKW #1
PN_ZERO .FILL x0030 ; ASCII '0'

; ---------------- RESTART ----------------

RESTART
        ST R7, RE7

        LEA R0, RMSG     		; Print "Restart? Y/N"
        PUTS

        GETC             		; Read user input
        OUT              		; Echo input
        ST R0, USERANS

        LD R0, RNL       		; Print newline
        OUT

        LD R0, USERANS   		; Compare with 'y'
        LD R1, Ry
        ADD R2, R0, R1
        BRz AGAIN

        LD R7, RE7       		; Otherwise return
        RET

AGAIN
        LD R7, RSTART   		; Jump to program start
        JMP R7

RE7 .BLKW #1
USERANS .BLKW #1

RMSG .STRINGZ " Restart? y/n "
RNL .FILL x000A
Ry .FILL xFF87 ; 'y'
RSTART .FILL x3000

.END