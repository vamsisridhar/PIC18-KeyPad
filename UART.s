#include <xc.inc>
    
global  UART_Setup, UART_Transmit_Message,UART_New_Line

psect	udata_acs   ; reserve data space in access ram
UART_counter: ds    1	    ; reserve 1 byte for variable UART_counter
New_Line_counter:    ds 1
    
psect	udata_bank3 ; reserve data anywhere in RAM (here at 0x400)
New_Line_Array:    ds 0x80 ; reserve 128 bytes for message data
    
psect	data
New_Line:
	db	' ',0x0a
					; message, plus carriage return
	New_Line_1   EQU	2	; length of data
	align	2
    
psect	uart_code,class=CODE
UART_Setup:
    bsf	    SPEN	; enable
    bcf	    SYNC	; synchronous
    bcf	    BRGH	; slow speed
    bsf	    TXEN	; enable transmit
    bcf	    BRG16	; 8-bit generator only
    movlw   103		; gives 9600 Baud rate (actually 9615)
    movwf   SPBRG1, A	; set baud rate
    bsf	    TRISC, PORTC_TX1_POSN, A	; TX1 pin is output on RC6 pin
					; must set TRISC6 to 1
    return

UART_Transmit_Message:	    ; Message stored at FSR2, length stored in W
    movwf   UART_counter, A
UART_Loop_message:
    movf    POSTINC2, W, A
    call    UART_Transmit_Byte
    decfsz  UART_counter, A
    bra	    UART_Loop_message
    return

UART_Transmit_Byte:	    ; Transmits byte stored in W
    btfss   TX1IF	    ; TX1IF is set when TXREG1 is empty
    bra	    UART_Transmit_Byte
    movwf   TXREG1, A
    return

UART_New_Line:
    	movlw	New_Line_1	; bytes to read
	movwf 	New_Line_counter, A
    	lfsr	0, New_Line_Array
	movlw	low highword(New_Line)
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(New_Line)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(New_Line)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
New_Line_loop:
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0
	decfsz	New_Line_counter, A		; count down to zero
	bra	New_Line_loop		; keep going until finished
	movlw	New_Line_1	; output message to UART
	lfsr	2, New_Line_Array
	call	UART_Transmit_Message