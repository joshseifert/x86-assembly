TITLE Macros and Low Level I/O. Program #6B     (P6_seiferjo.asm)

; Author: Josh Seifert					Date Created: 03/02/2015
; Course / Project ID: CS 271-400			Last Modified: 03/14/2015
; Description: This program demonstrates low level I/O procedures and Recursion.
;	It quizzes the user on combinatorics problems. The program generates and 
;	displays a random n [3, 12] and r[1, n], and asks the user for the number
;	of combinations. It calculates the correct number recursively, and reports
;	whether the user was correct.
;	The program and reads the keyboard input as a string and converts it to a 
;	number before performing data validation. Printed strings are displayed via
;	programmer-defined macros.

INCLUDE Irvine32.inc

;constants

ASCII_ZERO = 48		; Value of character '0' in ASCII table
ASCII_NINE = 57		; Value of character '9' in ASCII table
N_MIN = 3
N_MAX = 12
R_MIN = 1

displayString MACRO		buffer
	push		EDX
	mov		EDX, OFFSET buffer
	call		WriteString
	pop		EDX
ENDM

.data

programID		BYTE		"Low-Level I/O, Macros, and Recursion. Programmed by Josh Seifert",0dh,0ah,0dh,0ah,0
description	BYTE		"This program quizzes the user on their knowledge of combinatorics.",0dh,0ah
			BYTE		"It prints randomly generated values for 'n' and 'r', and asks the user ",0dh,0ah
			BYTE		"to calculate the number of possible combinations.",0dh,0ah,0dh,0ah,0
prompt1		BYTE		"How many ways can you choose ",0
prompt2		BYTE		" element(s) from a set of size ",0
prompt3		BYTE		"?",0dh,0ah,0
promptInput	BYTE		"Enter a number: ",0
rangeError	BYTE		"Sorry, that is not a valid number. Please enter integers only.",0dh,0ah,0
result1		BYTE		"I calculated ",0
result2		BYTE		" combinations of numbers.",0dh,0ah,0
resultRight	BYTE		"Congratulations, you got it right!",0dh,0ah,0dh,0ah,0
resultWrong	BYTE		"Sorry, you miscalculated this time...",0dh,0ah,0dh,0ah,0
promptAgain	BYTE		"Would you like to try again? Enter 'y' for yes, or any other key to quit: ",0dh,0ah,0dh,0ah,0
goodbye		BYTE		"Thanks for using my program. Goodbye!",0dh,0ah,0

n			DWORD	?			; Number of elements in the set, [3 - 12], random
r			DWORD	?			; Number of elements selected from the set, [1 - n], random
stringGuess	BYTE		10 DUP(?)		; User input is read in a string
answer		DWORD	?			; stringGuess is converted to an int, and stored here
result		DWORD	?			; Correct number of possible combinations, calculated by program


.code

main PROC

; From Irvine library, uses current time to seed pseudo-random numbers
	call Randomize			

; Introduces the program by giving programmer's name and a brief description of its functionality.
	call introduction

startQuestion:
; Randomizes n and r, displays problem to the user
	push OFFSET n
	push OFFSET r
	call showProblem

; Prompts for, receives, validates user's guess
	push OFFSET stringGuess
	push OFFSET answer
	call getData

; Calculates the correct number of combinations
	push		n
	push		r
	push		OFFSET result
	call		combinations

; Shows results of program calculation, tells user if they were correct
	push		n
	push		r
	push		answer
	push		result
	call		showResults

; Asks user if they want to try again:
	displayString	promptAgain
	mov		EAX, 0
	call		ReadChar
	cmp		AL, 'y'
	je		startQuestion
	cmp		AL, 'Y'
	je		startQuestion

; Says goodbye, thanks the user
	call farewell

quit:
	exit	; exit to operating system

main ENDP

;****************************************************************************
; Description: Gives title of program, name of programmer. Describes 
;	functionality of the program
; Receives: none
; Returns: none
; Preconditions: none
; Registers changed: EDX
;****************************************************************************
introduction PROC
	push		EBP
	mov		EBP, ESP

	displayString programID			; gives program title, name of programmer
	displayString description		; description of program

	pop		EBP
	ret
introduction ENDP

;****************************************************************************
; Description: Generates pseudo-random values for n[3-12] and r[1-n], and
;	displays those values to the user
; Receives: n (address), r (address)
; Returns: n and r have integer values
; Preconditions: none
; Registers changed: EAX, EBX, ECX, EDX
;****************************************************************************
showProblem PROC
	push		EBP
	mov		EBP, ESP

; Creates random value for n
	mov		EAX, N_MAX		; 12
	sub		EAX, N_MIN		; 12 - 3 = 9
	inc		EAX				; 10
	call		RandomRange		; [0 - 9]
	add		EAX, N_MIN		; [3 - 12]

; Save n
	mov		EBX, [EBP + 12]	; @n
	mov		[EBX], EAX

; Creates random value for r
	sub		EAX, R_MIN		; n - 1
	inc		EAX				; (n - 1) + 1, last 2 steps obviously unncessary in this case, but following standard protocol for RandomRange
	call		RandomRange		; [0 - (n - 1)]
	add		EAX, R_MIN		; [1 - n]

; Save r
	mov		ECX, [EBP + 8]		; @r
	mov		[ECX], EAX

; Prints question for user
	displayString	prompt1		; "How many ways to create"
	mov		EAX, [ECX]		; r
	call		WriteDec
	displayString	prompt2		; "combinations from"
	mov		EAX, [EBX]		; n
	call		WriteDec
	displayString	prompt3		; "elements?"

	pop		EBP
	ret
showProblem ENDP

;****************************************************************************
; Description: Prompts user for guess, reads value from keyboard and validates
;	that it is a number
; Receives: intGuess (address), 'stringGuess(address)'
; Returns: 'intGuess' contains integer value
; Preconditions: none
; Registers changed: EAX, EBX, ECX, EDX, EDI
;****************************************************************************

getData PROC
	push		EBP
	mov		EBP, ESP

enterNumber:
	displayString	promptInput
	mov		EDX, [EBP + 12]	; String variable holds user's guess

	mov		ECX, 10			; Assume user's guess fits in 32 bits, or 10 decimal digits
	call		ReadString

	mov		ECX, EAX			; ReadString puts number of characters entered by user in EAX. Used as loop counter
	mov		ESI, [EBP + 12]	; Set pointer to first char in string
	mov		EDI, 0
	cld

nextChar:
	mov		EAX, 0			; Clear it to accept next char
	lodsb					; Loads byte at ESI into AL, increments ESI. EAX is clear, so AL = EAX

	cmp		EAX, ASCII_ZERO	; If character is less than numeric equivalent of '0' ASCII char
	jb		outOfRange
	cmp		EAX, ASCII_NINE	; If character is greater than numeric equivalent of '9' ASCII char
	ja		outOfRange

	sub		EAX, ASCII_ZERO	; Subtracts 48 to convert string value to int value
	push		ECX				; Save ECX, used here as inner loop
	cmp		ECX, 1			
	je		skipMult			; If ECX = 1, single digits column, do not multiply by 10
	dec		ECX					

multTen:
	mov		EBX, 10			; Makes hundreds place digit * 100, tens place digit * 10 ...
	mul		EBX
	loop		multTen

skipMult:
	add		EDI, EAX			; Running total of values

	pop		ECX
	loop		nextChar			; Read next digit from user string
	jmp		inRange			; If every number successfully read (no invalid characters, return int)

outOfRange:
	displayString	rangeError	; "Integer values only"
	jmp			enterNumber

inRange:
	mov		EBX, [EBP+8]		; @answer
	mov		[EBX], EDI

	pop		EBP
	ret		8
getData ENDP

;****************************************************************************
; Description: Calculates the values for n!, r!, and the total combinations, 
;	solving factorials by calling itself recursively
; Receives: n, r, result(address)
; Returns: 'result' stores the correct number of combinations
; Preconditions: none
; Registers changed: EAX, EBX, EDX
;****************************************************************************

combinations PROC
	push		EBP
	mov		EBP, ESP

; Calculate n!
	mov		EAX, [EBP + 16]	; n
	push		EAX
	call		factorial
	push		EAX				; Save n! on stack

; Calculate r!
	mov		EAX, [EBP + 12]	; r
	push		EAX
	call		factorial
	push		EAX				; Save r! on stack

; Calculate (n - r)!
	mov		EAX, [EBP + 16]	; n
	sub		EAX, [EBP + 12]	; n - r
	push		EAX	
	call		factorial
	push		EAX				; Save (n - r)! on stack

; Calculate combinations
	pop		EAX				; (n - r)!
	pop		EDX				; r!
	mul		EDX				; EAX = r!(n - r)!
	cdq
	mov		EBX, EAX
	pop		EAX				; n!
	div		EBX				; EAX = n! / (r!(n - r)!), the desired result
	mov		EBX, [EBP + 8]		; @result
	mov		[EBX], EAX		; Store answer in 'result'

	pop		EBP
	ret		12
combinations ENDP

;****************************************************************************
; Description: Recursive procedure, calculates factorials
; Receives: Integer value
; Returns: Factorial of that integer
; Preconditions: none
; Registers changed: EAX, EBX, EDX
;****************************************************************************

factorial	PROC
	push		EBP
	mov		EBP, ESP

	mov		EAX, [EBP + 8]		; n
	cmp		EAX, 0
	ja		computeFactorial	; while n != 0
	mov		EAX, 1			; 0! = 1
	jmp		endFactorial

computeFactorial:
	dec		EAX
	push		EAX				; Stack holds n, n-1, n-2 ...
	call		factorial	
	mov		EBX, [EBP + 8]
	mul		EBX

endFactorial:
	pop		EBP
	ret		4	
factorial	ENDP

;****************************************************************************
; Description: Displays the calculated number, tells the user if they were correct.
; Receives: n (value), r(value), answer(value), result(value)
; Returns: none
; Preconditions: none
; Registers changed: EAX, EDX
;****************************************************************************

showResults PROC
	push		EBP
	mov		EBP, ESP

; Says how many combinations the program calculated
	displayString	result1			; "I calculated "
	mov		EAX, [EBP + 8]			; result
	call		WriteDec
	displayString	result2			; " possible combinations"

; Compares user's answer to correct answer
	cmp		EAX, [EBP + 12]		; user's answer
	jne		wrongGuess
	displayString	resultRight		; If user calculated correctly
	jmp		endResults

wrongGuess:
	displayString	resultWrong		; If user calculated incorrectly

endResults:

	pop		EBP
	ret		20
showResults ENDP


;****************************************************************************
; Description: Simple procedure saying goodbye to the user.
; Receives: none
; Returns: none
; Preconditions: none
; Registers changed: EDX
;****************************************************************************
farewell PROC
	push		EBP
	mov		EBP, ESP

	displayString goodbye				;"Thanks for using my program"

	pop		EBP
	ret	
farewell ENDP

END main