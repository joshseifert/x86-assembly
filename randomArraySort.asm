TITLE Pass by Reference, Indirect Addressing, Random numbers     (P5_seiferjo.asm)

; Author: Josh Seifert					Date Created: 02/16/2015
; Course / Project ID: CS 271-400			Last Modified: 02/27/2015
; Description: This program demonstrates indirect addressing of arrays, 
;	and passing parameters to procedures via the stack. The program
;	requests the user enter a number, and then generates that many
;	pseudo-random numbers in an array. The numbers are displayed, sorted
;	in descending order, then displayed again. The median value is
;	calculated and given to the user.
; Note: In this program, constants are global, variables and strings are 
;	passed as parameters.

INCLUDE Irvine32.inc

;constants

MIN = 10						;Minimum number of random numbers to generate
MAX = 200						;Maximum number of random numbers to generate
LO = 100						;Smallest allowable random number
HI = 999						;Largest allowable random number
NUMCOLUMNS = 10				;Number of columns in each row.

.data

programID		BYTE		"Random integers, sorting, and median. Programmed by Josh Seifert",0dh,0ah,0dh,0ah,0
description	BYTE		"This program calculates and displays random numbers from 100 - 999,",0dh,0ah
			BYTE		"It prints the list of random numbers in the order generated, sorts ",0dh,0ah
			BYTE		"the list in descending order, prints again, and calculates the median.",0dh,0ah,0dh,0ah,0
promptInput	BYTE		"Enter a number from 10 - 200: ",0
rangeError	BYTE		"Sorry, that number is out of range. You may only enter integers from 10 - 200",0dh,0ah,0
space		BYTE		"   ",0
unsortedTitle	BYTE		"Your UNSORTED array of random numbers:",0dh,0ah,0dh,0ah,0
sortedTitle	BYTE		"Your SORTED array of random numbers:",0dh,0ah,0dh,0ah,0
printMedian	BYTE		"The median value is: ",0
goodbye		BYTE		"Thanks for using my program. Goodbye!",0dh,0ah,0

request		DWORD	?				; How many random numbers user wants to display
array		DWORD	MAX	DUP(?)		; Holds randomly generated numbers for display

.code

main PROC

; From Irvine library, uses current time to seed pseudo-random numbers
	call Randomize			

; Introduces the program by giving programmer's name and a brief description of its functionality.
	push OFFSET programID
	push OFFSET description
	call introduction

; Asks for the number of random numbers the user wants to generate. Calls subprocedure to validate.
	push OFFSET request
	push OFFSET promptInput
	push OFFSET rangeError
	call getData

; Generates the pseudo-random numbers, and fills the array.
	push request
	push OFFSET array
	call fillArray

; Prints the unsorted array
	push OFFSET space
	push OFFSET array
	push request
	push OFFSET unsortedTitle
	call displayList

; Sorts the array into descending order. Calls subprocedure to swap values.
	push OFFSET array
	push request
	call sortList

; Calcuates and displays the median of the sorted array.
	push OFFSET printMedian
	push OFFSET array
	push request
	call displayMedian

; Prints the sorted array.
	push OFFSET space
	push OFFSET array
	push request
	push OFFSET sortedTitle
	call displayList

; Says goodbye, thanks the user.
	push OFFSET goodbye
	call farewell

	exit	; exit to operating system

main ENDP

;****************************************************************************
; Description: Gives title of program, name of programmer. Tells user how many
;			random numbers they may calculate, and the range to expect.
; Receives:	programID - string, name of programmer and program title
;			description - string, a description of the program
; Returns: none
; Preconditions: none
; Registers changed: EDX
;****************************************************************************
introduction PROC
	push		EBP
	mov		EBP, ESP

	mov		EDX, [EBP + 12]				; contains programID string
	call		WriteString					; gives program title, name of programmer
	mov		EDX, [EBP + 8]					; contains description string
	call		WriteString					; description of program

	pop		EBP
	ret		8
introduction ENDP

;****************************************************************************
; Description: Prompts for and receives number of random numbers user wants to calculate
; Receives:	request - holds amount of numbers user wants to generate
;			promptInput - string, asks user to enter value for 'request'
;			rangeError - string, tells user their input is invalid
; Returns: request now has a valid quantity of numbers to generate
; Preconditions: none
; Registers changed: EDX, EAX, EDI
;****************************************************************************
getData PROC
	push		EBP							; Save base pointer
	mov		EBP, ESP
	mov		EDI, [EBP + 16]				; address of "request" variable
	mov		EDX, [EBP + 12]				; prompt for input
	call		WriteString					; "Enter a number from 10 - 200: "
	call		ReadInt
	call		validate						; Calls subroutine to ensure number is within valid range
	mov		[EDI], EAX					; Saves valid number in 'request'
	pop		EBP
	ret		12
getData ENDP

;****************************************************************************
; Description: Validates that the user's number is within range. Based on code written
;			for program #4
; Receives: none
; Returns: EAX is between MIN - MAX
; Preconditions: User has entered a number
; Registers changed: EDX, EAX
;****************************************************************************
validate PROC

newInput:
;Compares user input with valid range
	cmp		EAX, MAX						;Checks if user input is greater than 200
	jg		invalidRange
	cmp		EAX, MIN						;Checks if user input is less than 10
	jl		invalidRange
	jmp		validRange					;If input passes both checks, number is valid

invalidRange:
;If data is not within range, issues reminder of valid range, jumps back to let user reenter data.
	mov		EDX, [EBP + 8]					; "Sorry, that number is out of range. You may only enter integers from 10 - 200"
	call		WriteString
	call		ReadInt
	jmp		newInput						; User may reattempt to enter a valid number
	
validRange:
;If data is within range, saves it to memory, returns to main
	ret
validate ENDP

;****************************************************************************
; Description: Fills the array with pseudo-random numbers
; Receives:	request - the amount of numbers the user wants to generate
;			array - the address of the first element in the random number array		
; Returns: Array is filled with random numbers, in unsorted order
; Preconditions: 'request' is within valid range
; Registers changed: EDX, ESI, ECX
;****************************************************************************

fillArray PROC
	push		EBP
	mov		EBP, ESP
	mov		ESI, [EBP + 8]				; Address of array
	mov		ECX, [EBP + 12]			; Sets the loop counter to 'request', the quantity of random numbers user wants to generate

randomLoop:
; Generates random number in the correct range. RandomRange generates a pseudo-random number from [1 - EAX].
; HI - LO + 1 is the width of the range. Random number + LO adjusts to desired range.
	mov		EAX, HI
	sub		EAX, LO
	inc		EAX
	call		RandomRange				; Library function, generates pseudo-random number
	add		EAX, LO					; Adjusts random number to correct range
; Stores the random number in the array, increments the array to the next value.
	mov		[ESI], EAX
	add		ESI, 4
	loop		randomLoop				; ECX = value of 'request'. Loops as many times as user wants random numbers

	pop		EBP
	ret		8
fillArray ENDP

;****************************************************************************
; Description: Prints numbers, 10 per column, three spaces between each number.
; Receives:	space - string of 3 whitespace characters, used for formatting
;			array - address of first element in random number array
;			request - number of elements in the array
;			sorted/unsortedTitle - string, holds the title of the array
; Returns: none
; Preconditions: array is filled with 'request' quantity of pseudorandom numbers
; Registers changed: EDX, ECX, ESI, EBX, EAX
;****************************************************************************

displayList PROC
	push		EBP
	mov		EBP, ESP

	mov		EDX, [EBP + 8]			; The title of the array, stating either sorted or unsorted array.
	call		WriteString

	mov		ECX, [EBP + 12]		; 'request', quantity of random numbers to generate, used as loop counter
	mov		ESI, [EBP + 16]		; Address of first element in random number array
	mov		EBX, 0				; Counts number of elements, to determine when to start a new line
printLoop:
	mov		EAX, [ESI]			; Random number in the array
	call		WriteDec
	mov		EDX, [EBP + 20]		; String of spaces between numbers, to format printout
	call		WriteString
	add		ESI, 4				; Moves pointer to next element in the random array

; Determines if need to start printing on a new line
	inc		EBX
	cmp		EBX, NUMCOLUMNS		; NUMCOLUMNS is global constant 10. If EBX = 10, start new line
	jne		endLoop
	mov		EBX, 0				; If start new line, reset EBX counter
	call		CrLf

endLoop:
	loop		printLoop

	call		CrLf
	call		CrLf
	pop		EBP
	ret		16
displayList ENDP

;****************************************************************************
; Description: Sorts the pseudo-random numbers into descending order. While a heap
;			or merge sort would be a more elegant solution, I struggled implementing it
;			successfully. I reluctantly settled on a bubble sort algorithm. For large values
;			of n, this would be inefficient, but is adequate for an array of max size 200.
; Receives:	array - address of first element in pseudo-random number array
;			request - amount of numbers in the array.
; Returns: array is sorted in descending order
; Preconditions: array is filled with numbers, request is a valid integer
; Registers changed: EAX, ECX
;****************************************************************************
sortList PROC
	push		EBP
	mov		EBP, ESP
	mov		ECX, [EBP + 8]			; 'request', used as the loop counter
	dec		ECX					

outerLoop:
	push		ECX					; Maintain separate counters for inner loop and outer loop
	mov		ESI, [EBP + 12]		; Reset ESI to start of array after every inner loop iteration

innerLoop:
	mov		EAX, [ESI]
	cmp		EAX, [ESI + 4]			; Compare two adjacent elements of the array
	jg		next					; If first is greater than second, no need to switch
	push		[ESI]
	push		[ESI + 4]
	call		exchange				; If first is less than second, elements swapped in subprocedure

next:
	add		ESI, 4				; Increment array pointer, loop to compare next two elements to each other
	loop		innerLoop
	pop		ECX					; ECX value for the outer loop.
	loop		outerLoop

	pop		EBP
	ret		8
sortList ENDP

;****************************************************************************
; Description: Accepts two array values by reference and swaps
; Receives:	[ESI] - @ of first element to be swapped
;			[ESI + 4] - @ of second element to be swapped
; Returns: Elements are correctly sorted
; Preconditions: none
; Registers changed: EAX, EBX
;****************************************************************************

exchange PROC
	push		EBP
	mov		EBP, ESP

	mov		EAX, [EBP + 8]
	mov		EBX, [EBP + 12]
	mov		[ESI], EAX
	mov		[ESI + 4], EBX

	pop		EBP

	ret		8
exchange ENDP

;****************************************************************************
; Description: Calculates and displays the median value in the array, with different
;			calculations depending on if the user requested an even or odd amount of numbers.
; Receives:	printMedian - string, announces value of the median
;			array - first element of the pseudo-random number array
;			request - amount of numbers in the array
; Returns: none
; Preconditions: array is sorted
; Registers changed: EAX, EBX, EDX, EDI
;****************************************************************************
displayMedian PROC
	push		EBP
	mov		EBP, ESP

	mov		EAX, [EBP + 8]			; 'request', quantity of numbers in the array
	mov		EBX, 2
	cdq	
	div		EBX					; Tests if there are an even or odd number of integers in the array
	cmp		EDX, 1				; If there is a remainder here, the number must be odd. Otherwise, even.
	je		odd

;If there are an even number of numbers in the array
	imul		EAX, 4				; Offset in bytes = size of element (DWORD, 4) times position in array
	mov		EDI, EAX				; Save offset in unused register
	mov		ECX, [EBP + 12]		; Address of first element in array
	mov		EAX, [ECX + EDI]		; Starting address + Offset of the median = address of the median
	add		EAX, [ECX + EDI - 4]	; When even number of elements, median is average of 2 middle numbers
	cdq
	div		EBX					; Divide by 2 to get median

;If remainder is greater than half of divisor, round up
	imul		EDX, 2
	cmp		EBX, EDX				; If remainder * 2 > divisor, rounds up
	jg		noInc				; Otherwise, skips incrementation
	inc		EAX

noInc:
	mov		EDX, [EBP + 16]		; "The median value is: "
	call		WriteString
	call		WriteDec				; Median value of the array
	call		CrLf
	call		CrLf
	jmp		endMedian

;If there are an odd number of numbers in the array
odd:
	imul		EAX, 4				; Offset in bytes = size of element (DWORD, 4) times position in array
	mov		ECX, [EBP + 12]		; Starting value of the array
	mov		EAX, [ECX + EAX]		; Starting address + Offset of the median = address of the median
	mov		EDX, [EBP + 16]		; "The median value is: "
	call		WriteString
	call		WriteDec				; Median value of the array
	call		CrLf
	call		CrLf

endMedian:
	pop		EBP
	ret		12
displayMedian ENDP

;****************************************************************************
; Description: Simple procedure saying goodbye to the user. Not required for this
;			program, but it's extra practice passing parameters.
; Receives:	goodbye - string containing farewell message
; Returns: none
; Preconditions: none
; Registers changed: EDX
;****************************************************************************
farewell PROC
	push		EBP
	mov		EBP, ESP
	mov		EDX, [EBP + 8]				;"Thanks for using my program"
	call		WriteString
	pop		EBP
	ret		4
farewell ENDP

END main