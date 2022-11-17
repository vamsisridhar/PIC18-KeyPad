#include <xc.inc>
    
global Keypad_Setup, Key_Row_Detect, Key_Col_Detect, Key_Press
    
psect	udata_acs
row_vals:    ds 1
col_vals:    ds 1  
delay_count:ds 1    ; reserve one byte for counter in the delay routine
    
psect keypad_code,class = CODE

Keypad_Setup:
    movlb 15
    bsf REPU
    movlb 0
    clrf LATE, A
    
    
    return

Key_Row_Detect:
    movlw 0x0F
    movwf TRISE, A
    movf  PORTE, W
    movwf   row_vals    
    return
    
Key_Col_Detect:
    movlw 0xF0
    movwf TRISE, A
    movf  PORTE, W
    movwf   col_vals
    return

Keypad_delay:	decfsz	delay_count, A	; decrement until zero
	bra	Keypad_delay
	return

Key_Press:
    	call Key_Row_Detect
	movlw	0xff
	call Keypad_delay
	movlw	0xff
	call Keypad_delay
	call Key_Col_Detect
	movlw	0xff
	call Keypad_delay
	movlw	0xff
	

	movf	row_vals, W
	addwf	col_vals, W
	return
	
	