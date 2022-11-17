#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_New_Line, LCD_Clear_Screen,LCD_To_Start
extrn	Keypad_Setup, Key_Row_Detect, Key_Col_Detect, Key_Press
	
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
key_vals:   ds 1
row_vals:   ds 1
col_vals:   ds 1
initial_table_ptr:  ds 1
key_select: ds 1
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
Key_Pad_Letters_Array:    ds 0x88 ; reserve 128 bytes for message data

psect data
Key_Pad_Letters:
       db	' ','1','2','3','F','4','5','6','E','7','8','9','D','A', '0', 'B','C'
       Key_Pad_Letters_l   EQU	17	; length of data
       align	2
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup UART
	call	Keypad_Setup
	
	movlw   0x00
	movwf   TRISD
	movlw   0x00
	movwf   TRISH
	goto	start

	
start: 	
    	lfsr	0, Key_Pad_Letters_Array	; Load FSR0 with address in RAM	
	movlw	low highword(Key_Pad_Letters)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(Key_Pad_Letters)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(Key_Pad_Letters)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	nop
	movlw	Key_Pad_Letters_l	; bytes to read
	movwf 	counter, A
loop2: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0
	decfsz	counter, A		; count down to zero
	bra	loop2		; keep going until finished



loop: 	
	;call LCD_Clear_Screen
	movlw	0xff
	movwf	delay_count
	movlw	0xff
	movwf	delay_count
	movlw	0xff
	movwf	delay_count
	call delay
	
	call Key_Press
	
	movwf	key_vals
	
	comf	key_vals, 0, 0
	
	andlw	0xF0
	movwf	row_vals
	rrncf	row_vals, 1, 0
	rrncf	row_vals, 1, 0
	rrncf	row_vals, 1, 0
	rrncf	row_vals, 0, 0
	movwf	row_vals
	movf	row_vals, A
	movff	row_vals, PORTD
	nop
	;GET COLS
	
	comf	key_vals, 0, 0
	andlw	0x0F
	movwf	col_vals, A
	movff	col_vals, PORTH
	nop
	
	
	
	
	movlw 0xff
	cpfseq	key_vals
	    call write_LCD
	
	movlw 0x00
	movwf	key_vals
	
	bra loop
	

	
goto	$		; goto current line in code

	; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return
write_LCD:	
    call	LCD_Clear_Screen
    
    
    lfsr	2, Key_Pad_Letters_Array
    nop
    movlw	0x00
    addwf	POSTINC2, f, A
    movlw   0x01
    cpfsgt  row_vals
    bra skip_row_loop
    
    row_loop:
	rrcf	row_vals, 1, 0
	movlw	0x00
	addwf	POSTINC2, f, A
	movlw	0x00
	addwf	POSTINC2, f, A
	movlw	0x00
	addwf	POSTINC2, f, A
	movlw	0x00
	addwf	POSTINC2, f, A
	movlw   0x01
	cpfseq	row_vals
	bra row_loop

    skip_row_loop:
    movlw   0x01
    cpfsgt  col_vals
    bra skip_col_loop
    
    col_loop:
	rrcf	col_vals, 1, 0
	movlw	0x00
	addwf	POSTINC2, f, A
	movlw	0x01
	cpfseq	col_vals
	bra col_loop
	
    skip_col_loop:
    
    ;key_loop:
	;movlw	0x00
	;addwf	POSTINC2, f, A
	;decfsz	key_select, A		; count down to zero
	;bra	key_loop		; keep going until finished
    
    
    movlw	0x01
    call	LCD_Write_Message
    nop
    ;call	LCD_To_Start
    return
	end	rst
