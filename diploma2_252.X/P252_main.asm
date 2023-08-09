;     Microcontroller programm for laboratory stand
;   "Improving the reliability of measurement results"
;                       PIC18F252
;
;
;Defining Registers in the quick access bank
time1		equ	00  ;Registers for formation
time2		equ	01  ;time delays
time3		equ	02  ;
mode		equ	03  ;
temp1		equ	04  ;Registers for temporary 
temp2		equ	05  ;data
temp3		equ	06  ;storage
noise1		equ	07  ;Registers for storing
noise2		equ	08  ;results of modeling
noise3		equ	09  ;pseudo-random signal
noise4		equ	0a  ;
noise5		equ	0b  ;
look_sin	equ	0c  ;
look_2		equ	0d  ;
look_TMR1	equ	0e  ;
look_TMR2	equ	0f  ;
look_TMR0	equ	10  ;
temp_tmr1	equ	11  ;
temp_tmr0	equ	12  ;
buff_key	equ	13  ;
old_key		equ	14  ;
temp_key    	equ	15  ;
temp_init_check	equ	16  ;
num_spi		equ	17  ;
data_spi	equ	18  ;
look_spi	equ	19  ;
tmr1_h		equ	1a  ;
tmr1_l		equ	1b  ;
time_l		equ	1c  ;
time_h		equ	1d  ;
mode_sin	equ	1e  ;
look_sin_phase	equ	1f  ;
sinus_change	equ	20  ;
AD_potenc_cycle		equ	21  ;
look_TMR1_16		equ	22  ;
;		equ	23  ;
;check_tim	equ	24  ;
;equ ?? 7f

		
	#include P18F252.INC  ;Connecting include file with functions and regisetrs mapping
	#include ram_252.INC  ;Connecting RAM map
;	__CONFIG _CONFIG1H, _OSCS_OFF_1H & _HS_OSC_1H
;	__CONFIG _CONFIG2H, _WDT_OFF_2H
;	__CONFIG _CONFIG4L, _STVR_OFF_4L & _LVP_OFF_4L & _DEBUG_OFF_4L

;********* PROGRAMM START ************
	org	000000
	goto	start   ;Transition to MC configuration
;************ INTERRUPT VECTOR *********************
	org	000800
	clrwdt
	btfss	PIR1,0
	goto	set_TMR0
	bcf	PIR1,0
	bcf	PIR1,1
	bsf	mode,1
	bsf	mode,2
	;movlw	0x90	    ;????????? ???????????????? ???????? ??????? 
	;movwf	TMR1H	    ;??? ??????????? ??????????? ??????? ????????????
	;Measuring 8 samples for 
	;making 1 sec delay
	decfsz	look_TMR1,1  
	retfie
	btg	PORTC, 6
	bsf	sinus_change,0
	movlw	0x08
	movwf	look_TMR1
	;Measuring 16 samples for 
	;making 2 sec delay
	decfsz	look_TMR1_16,1
	retfie
	bsf	mode,3
	bsf	sinus_change,1
	movlw	0x40		    ;TODO: Broken timer
    	movwf	look_TMR1_16
	;btfss	STATUS,0
	retfie
	;rlncf	PORTC,1
	;retfie

set_TMR0:
	bcf	INTCON,2
	bsf	mode,0
	retfie

;******** Microcontroller configuration ***********
start:
	movlw	0x60	    ;Intterupts form peripheral modules
	movwf	INTCON	    ;and TMR0 are enabled
	movlw	0x80	    ;Interrupt from TMR1 is enabled
	movwf	INTCON2	    ;
	movlw	0x00
	movwf	INTCON3
	movlw	0xff	    ;Group A - inputs
	movwf	TRISA	    ;
	movlw	0xff	    ;Group B - inputs
	movwf	TRISB	    ;
	movlw	0x00	    ;Group C - outputs
	movwf	TRISC	    ;
	;*************Not supported in F252***************
	;movlw	0x00	    ;Group D - outputs  
	;movwf	TRISD	    ;
	;movlw	0x00	    ;Group E - outputs 
	;movwf	TRISE	    ;
	;*************************************************
	movlw	0x01	    
	movwf	PIE1
;	movlw	0x7b
;	movwf	T2CON
	movlw	0x03	    ;TMR0 in 16 bit mode, internal clock signal, 
	movwf	T0CON	    ;using prescaler, coeff of prescaler is 16
	movlw	0x00	    ;B0  ;30
	movwf	T1CON
	movlw	0x00	    ;Prescaler 1, Postscaler 1
	movwf	T2CON	    ;
	movlw	0xFF
	movwf	PR2
	movlw	0xFF
	movwf	CCP1CON
	movlw	0xFF
	movwf	CCP2CON
	movlw	0x00
	movwf	TBLPTRL	    ;Pointer on ROM
	movlw	0x40
	movwf	TBLPTRH
	movlw	0x00
	movwf	TBLPTRU
	movlw	0xFF
	movwf	look_sin
	movlw	0xFF
	movwf   look_sin_phase
	clrf	mode_sin    ;Working mode at a particular time 
	;0x01 = sine shaping with random phase
	;0x02 = sine shaping with random amp
	;0x04 = sending "noise" data to change potentiometer value
	;12.04.2023 add - i don't think its true :)
	movlw	0x08
	movwf	look_TMR1   ;Set 8 cycles for 1 second delay
	movlw	0x40	    ;TODO: Broken timer
	movwf	look_TMR1_16;Set 16 cycles for 2 second delay
	movlw	0x5f	    ;Setting
	movwf	noise1	    ;start
	movlw	0x56	    ;values
	movwf	noise2	    ;a set of registers
	movlw	0xe6	    ;for generating
	movwf	noise3	    ;a pseudo-random signal
	movlw	0x03	    ;
	movwf	noise4	    ;
	movlw	0x00	    ;
	movwf	noise5	    ;    
	movlw	0x06
	movwf   AD_potenc_cycle	
	;movlw	0x90	    ;????????? ???????????????? ???????? ???????
	;movwf	TMR1H	    ;??? ??????????? ??????????? ??????? ????????????
	;movlw	0x01
	;movwf	PORTD
	bsf	mode,0	    ;Flag that starts making pseudo-random signal
	bsf	T0CON,7
	bsf	T1CON,0
	bsf	T2CON,2
	bsf	INTCON,7
	;bsf	PORTC,3
	
	;goto	choice
	
choice:
	clrwdt
	;Selection of different modes
	btfsc	mode, 0
	call	loop_noise	    ;Generating pseudo-random signal (making)
	;btfsc	mode, 1
	;call	loop_sin_amp	    ;Generating sinus with pseudo-random amplitude  (sinus) ;;ready as for 17.05.2023
	btfsc	mode, 2
	call	loop_sin_phase	    ;Generating sinus with pseudo-random phase (sinus) (19.04 - has a bug)
	;btfsc	mode, 3
	;call	loop_AD		    ;Generating signal with pseudo-random amplitude (discrete, "skyscrapers") ;;ready as for 17.05.2023
	nop
	goto	choice
	
;** Subroutine for generating a pseudo-random signal ********
loop_noise:
	bcf	mode,0	    ;Resetting the sign about the need to change the value of a random signal
	movf	noise1,0    ;Loading the lower register of a pseudo-random sequence (PRS) into the accumulator
	andlw	0x80	    ;Masking bits that are not involved in the formation of XOR
	movwf	temp1	    ;Saving result in temporary register
	rlncf	noise1,0    ;Shift of the lower register of the PSP(?) to implement the exclusive OR operation
	andlw	0x80	    ;Masking bits that are not involved in the formation of XOR
	xorwf	temp1,1	    ;Implementation of XOR with the previous value of the lower register of the PSP(?)
	rlcf	temp1,0	    ;
	rlcf	noise1,1    ;Formation
	rlcf	noise2,1    ;of the next value in 
	rlcf	noise3,1    ;PSP
	rlcf	noise4,1    ;
	rlcf	noise5,1    ;
	movf	noise1,0    ;
	;movwf	PORTB	    ;Write one of the PSP registers to port B
	return		    ;Subroutine exit

;** Subroutine for generating a pseudo-random sinus ********
loop_sin_amp:
	btfsc	sinus_change,0
	call	sin_amp_change
	bcf	mode,1 
	tblrd*+		    ;Read the current value of the PWM pulse width from the post-increment ROM
	movf	TABLAT,0    ;Write the value of the PWM pulse width read from the ROM into the accumulator
	movwf	CCPR1L	    ;Write the read value to the PWM pulse width storage register of the CCP1 module
	tblrd*+		    ;Read next ROM data from post-increment to keep polling regular
	decfsz	look_sin,1  ;Check if the sine period is completed
	return		    ;Exit the subroutine
	nop
	movlw	0x00	    ;
	movwf	TBLPTRL	    ;
	movlw	0x40	    ;Initial values of
	movwf	TBLPTRH	    ;addresses to read sine values
	movlw	0x00	    ;in case of formation
	movwf	TBLPTRU	    ;Random sine noise
	movlw	0xFF	    ;Restarting cycle count
	movwf	look_sin    ;of setting the PWM duration values during the formation of the sine period
	return		    ;Exit the subroutine

	
sin_amp_change:
	bcf	sinus_change,0	    ;Resetting the sign about the need to change the value of a random signal
	movf	TBLPTRL,0	    ;Saving ROM point for sinus
	movwf	temp2
	movf	TBLPTRH,0
	movwf	temp3
	
	;;Picking a number in array
	movlw	0x60	    ;High pointer adress in memory 
	movwf	TBLPTRH	    ;Placing pointer on ROM
	bcf	STATUS,0    ;Multiplication by two
	rlcf	noise1,0    ;for ecluding the adress with odd 
	movwf	TBLPTRL	    ;number when radinf value in ROM
	btfsc	STATUS,0    ;
	incf	TBLPTRH,1   ;
	movlw	0x00	    ;
	movwf	TBLPTRU	    ;
	tblrd*+	
	movf	TABLAT,0    ;Writing value from ROM into W register
	movwf	temp1	    ;Writing value from W into "temp1" register (EQU)
	tblrd*+	
	movf	temp1,0
	movwf	data_spi    ;Writing value from temp1 into data_spi register
	movlw	0x00
	movwf	num_spi	    ;Address of potentiometer (in case of 0x00 - it's 1)
	bcf	PORTC, 5
	call	package_spi
	bsf	PORTC, 5
	nop		    ;Delay for SPI
	tblrd*+	
	movf	TABLAT,0    ;Writing value from ROM into W register
	movwf	temp1	    ;Writing value from W into "temp1" register (EQU)
	tblrd*+	
	movf	temp1,0
	movwf	data_spi    ;Writing value from temp1 into data_spi register
	movlw	0x20
	movwf	num_spi	    ;Address of potentiometer (in case of 0x20 - it's 2)
	bcf	PORTC, 5
	call	package_spi
	bsf	PORTC, 5
	nop
	
	;restoring original sinus formation
	movf	temp2,0	    ;
	movwf	TBLPTRL	    ;
	movf	temp3,0	    ;Initial values of
	movwf	TBLPTRH	    ;addresses to read sine values
	movlw	0x00	    ;in case of formation
	movwf	TBLPTRU	    ;Random sine noise
	return		    ;Exit the subroutine
	;;===============================

;** Subroutine for generating a pseudo-random phase ********
loop_sin_phase:
	btfsc	sinus_change,1
	call	sin_phase_change
    	bcf	mode,2	    ;Resetting the sign about the need to change the phase of a random signal
	tblrd*+		    ;Read the current value of the PWM pulse width from the post-increment ROM
	movf	TABLAT,0    ;Write the value of the PWM pulse width read from the ROM into the accumulator
	movwf	CCPR2L	    ;Write the read value to the PWM pulse width storage register of the CCP2 module
	tblrd*+		    ;Read next ROM data from post-increment to keep polling regular
	decfsz	look_sin_phase,1  ;Check if the sine period is completed
	return		    ;Exit the subroutine
	nop
	movlw	0x00	    ;
	movwf	TBLPTRL	    ;
	movlw	0x40	    ;Initial values of
	movwf	TBLPTRH	    ;addresses to read sine values
	movlw	0x00	    ;in case of formation
	movwf	TBLPTRU	    ;Random sine noise
	movlw	0xFF
	movwf   look_sin_phase
	return		    ;Exit the subroutine
	
sin_phase_change:
	bcf	sinus_change,1
	movlw	0x40	    
	movwf	TBLPTRH	    ;Placing pointer on ROM
	bcf	STATUS,0    ;Multiplication by two
	rlcf	noise1,0    ;for ecluding the adress with odd 
	movwf	TBLPTRL	    ;number when reading value in ROM
	btfsc	STATUS,0    ;
	incf	TBLPTRH,1   ;
	movlw	0x00	    ;
	movwf	TBLPTRU	    ;
	return

;************OBSOLETE**************
rerun:
	movlw	0x00
	movwf	TBLPTRL	    ;Placing pointer on ROM
	movlw	0x40
	movwf	TBLPTRH
	movlw	0x00
	movwf	TBLPTRU
	movlw	0xFF	    ;Restarting cycle count
	movwf	look_sin_phase    ;of setting the PWM duration values during the formation of the sine period
	goto	loop_sin_amp
	

;** OBSOLETE ****************
;** Subroutine for AD5206 value potentiometer pointer setup
;loop_AD_setup
;	movlw	0x00
;	movwf	TBLPTRL	    ;Placing pointer on ROM
;	movlw	0x60
;	movwf	TBLPTRH
;	movlw	0x00
;	movwf	TBLPTRU	
;	movlw	0x06
;	movwf	AD_potenc_cycle	
;	goto	loop_1
	
	
;** Subroutine for conection betwween AD5206 and PIC18F252 ******
;** through SPI ************************************************* 
loop_AD:
	bcf	mode,3
	movlw	0x40
	movwf	TBLPTRH	    ;Placing pointer on ROM
	bcf	STATUS,0    ;Multiplication by two
	rlcf	noise1,0    ;for ecluding the adress with odd 
	movwf	TBLPTRL	    ;number when radinf value in ROM
	btfsc	STATUS,0    ;
	incf	TBLPTRH,1   ;
	movlw	0x00
	movwf	TBLPTRU
	tblrd*+	
	movf	TABLAT,0    ;Writing value from ROM into W register
	movwf	temp1	    ;Writing value from W into "temp1" register (EQU)
	tblrd*+	
	movf	temp1,0
	movwf	data_spi    ;Writing value from temp1 into data_spi register
	movlw	0x60	    ;for transmission through SPI
	movwf	num_spi	    ;Value for picking potentiometer in AD5206
	bcf	PORTC, 5
	call	package_spi
	bsf	PORTC, 5
	nop
	nop
	;tblrd*+	
	;movf	TABLAT,0    ;?????? ? ??????????? ?????????? ?? ??? ???????? ??? ?????????????
	;movwf	temp1	    ;?????? ?????????? ???????? ? ??????? ????????
	;tblrd*+	
	;movf	temp1,0
	;movwf	data_spi    ;?????? ???????? ? ?????????????
	;movlw	0x50
	;movwf	num_spi	    ;????? ????????????? (? ?????? ?????? - ?????? 6)
	;bcf	PORTC, 5
	;call	package_spi
	;bsf	PORTC, 5
	;nop
	return
	;movwf	TXREG
	;bsf	PORTD, 0
	
package_spi:
	movlw	0x03
	movwf	look_spi
spi_1:
	rlcf	num_spi, 1
	btfss	STATUS, 0
	goto	trm_0_1
	
	bsf	PORTC, 3
	nop
	bsf	PORTC, 4
	nop
	bcf	PORTC, 4
	decfsz	look_spi, 1
	goto	spi_1	
	goto	spi_2
trm_0_1:
	bcf	PORTC, 3
	nop
	bsf	PORTC, 4
	nop
	bcf	PORTC, 4
	decfsz	look_spi, 1
	goto	spi_1
spi_2:
	movlw	0x08
	movwf	look_spi
spi_3:
	rlcf	data_spi, 1
	btfss	STATUS, 0
	goto	trm_0_2
	
	bsf	PORTC, 3
	nop
	bsf	PORTC, 4
	nop
	bcf	PORTC, 4
	decfsz	look_spi, 1
	goto	spi_3	
	bcf	PORTC, 3
	return
trm_0_2:
	bcf	PORTC, 3
	nop
	bsf	PORTC, 4
	nop
	bcf	PORTC, 4
	decfsz	look_spi, 1
	goto	spi_3
	return
	
	
;10 milliseconds delay
ms10:
	movlw	0x15
	movwf	time2
ms10_2:
	movlw	0xff
	movwf	time1
ms10_1:
;	bsf	PORTC,0
;	bcf	PORTC,0
	decfsz	time1,1
	goto	ms10_1
	decfsz	time2,1
	goto	ms10_2
	retfie
	

;sine value storage area for 2 periods
	org	0x4000
	db	0x007f
	db	0x0082
	db	0x0085
	db	0x0088
	db	0x008c
	db	0x008f
	db	0x0092
	db	0x0095
	db	0x0098
	db	0x009b
	db	0x009e
	db	0x00a1
	db	0x00a4
	db	0x00a7
	db	0x00aa
	db	0x00ad
	db	0x00b0
	db	0x00b3
	db	0x00b6
	db	0x00b9
	db	0x00bb
	db	0x00be
	db	0x00c1
	db	0x00c3
	db	0x00c6
	db	0x00c9
	db	0x00cb
	db	0x00ce
	db	0x00d0
	db	0x00d3
	db	0x00d5
	db	0x00d7
	db	0x00d9
	db	0x00dc
	db	0x00de
	db	0x00e0
	db	0x00e2
	db	0x00e4
	db	0x00e6
	db	0x00e7
	db	0x00e9
	db	0x00eb
	db	0x00ed
	db	0x00ee
	db	0x00f0
	db	0x00f1
	db	0x00f2
	db	0x00f4
	db	0x00f5
	db	0x00f6
	db	0x00f7
	db	0x00f8
	db	0x00f9
	db	0x00fa
	db	0x00fb
	db	0x00fc
	db	0x00fc
	db	0x00fd
	db	0x00fd
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fd
	db	0x00fd
	db	0x00fc
	db	0x00fc
	db	0x00fb
	db	0x00fa
	db	0x00fa
	db	0x00f9
	db	0x00f8
	db	0x00f7
	db	0x00f6
	db	0x00f4
	db	0x00f3
	db	0x00f2
	db	0x00f0
	db	0x00ef
	db	0x00ed
	db	0x00ec
	db	0x00ea
	db	0x00e8
	db	0x00e7
	db	0x00e5
	db	0x00e3
	db	0x00e1
	db	0x00df
	db	0x00dd
	db	0x00db
	db	0x00d8
	db	0x00d6
	db	0x00d4
	db	0x00d1
	db	0x00cf
	db	0x00cd
	db	0x00ca
	db	0x00c8
	db	0x00c5
	db	0x00c2
	db	0x00c0
	db	0x00bd
	db	0x00ba
	db	0x00b7
	db	0x00b4
	db	0x00b2
	db	0x00af
	db	0x00ac
	db	0x00a9
	db	0x00a6
	db	0x00a3
	db	0x00a0
	db	0x009d
	db	0x009a
	db	0x0097
	db	0x0094
	db	0x0090
	db	0x008d
	db	0x008a
	db	0x0087
	db	0x0084
	db	0x0081
	db	0x007e
	db	0x007a
	db	0x0077
	db	0x0074
	db	0x0071
	db	0x006e
	db	0x006b
	db	0x0068
	db	0x0065
	db	0x0062
	db	0x005f
	db	0x005c
	db	0x0059
	db	0x0056
	db	0x0053
	db	0x0050
	db	0x004d
	db	0x004a
	db	0x0047
	db	0x0044
	db	0x0042
	db	0x003f
	db	0x003c
	db	0x0039
	db	0x0037
	db	0x0034
	db	0x0032
	db	0x002f
	db	0x002d
	db	0x002a
	db	0x0028
	db	0x0026
	db	0x0024
	db	0x0021
	db	0x001f
	db	0x001d
	db	0x001b
	db	0x0019
	db	0x0018
	db	0x0016
	db	0x0014
	db	0x0012
	db	0x0011
	db	0x000f
	db	0x000e
	db	0x000c
	db	0x000b
	db	0x000a
	db	0x0008
	db	0x0007
	db	0x0006
	db	0x0005
	db	0x0004
	db	0x0004
	db	0x0003
	db	0x0002
	db	0x0002
	db	0x0001
	db	0x0001
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0001
	db	0x0001
	db	0x0002
	db	0x0002
	db	0x0003
	db	0x0004
	db	0x0005
	db	0x0006
	db	0x0007
	db	0x0008
	db	0x0009
	db	0x000a
	db	0x000b
	db	0x000d
	db	0x000e
	db	0x0010
	db	0x0011
	db	0x0013
	db	0x0015
	db	0x0016
	db	0x0018
	db	0x001a
	db	0x001c
	db	0x001e
	db	0x0020
	db	0x0022
	db	0x0024
	db	0x0027
	db	0x0029
	db	0x002b
	db	0x002e
	db	0x0030
	db	0x0033
	db	0x0035
	db	0x0038
	db	0x003a
	db	0x003d
	db	0x0040
	db	0x0042
	db	0x0045
	db	0x0048
	db	0x004b
	db	0x004e
	db	0x0051
	db	0x0054
	db	0x0056
	db	0x0059
	db	0x005c
	db	0x0060
	db	0x0063
	db	0x0066
	db	0x0069
	db	0x006c
	db	0x006f
	db	0x0072
	db	0x0075
	db	0x0078
	db	0x007b
	db	0x007f
	db	0x0082
	db	0x0085
	db	0x0088
	db	0x008c
	db	0x008f
	db	0x0092
	db	0x0095
	db	0x0098
	db	0x009b
	db	0x009e
	db	0x00a1
	db	0x00a4
	db	0x00a7
	db	0x00aa
	db	0x00ad
	db	0x00b0
	db	0x00b3
	db	0x00b6
	db	0x00b9
	db	0x00bb
	db	0x00be
	db	0x00c1
	db	0x00c3
	db	0x00c6
	db	0x00c9
	db	0x00cb
	db	0x00ce
	db	0x00d0
	db	0x00d3
	db	0x00d5
	db	0x00d7
	db	0x00d9
	db	0x00dc
	db	0x00de
	db	0x00e0
	db	0x00e2
	db	0x00e4
	db	0x00e6
	db	0x00e7
	db	0x00e9
	db	0x00eb
	db	0x00ed
	db	0x00ee
	db	0x00f0
	db	0x00f1
	db	0x00f2
	db	0x00f4
	db	0x00f5
	db	0x00f6
	db	0x00f7
	db	0x00f8
	db	0x00f9
	db	0x00fa
	db	0x00fb
	db	0x00fc
	db	0x00fc
	db	0x00fd
	db	0x00fd
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fd
	db	0x00fd
	db	0x00fc
	db	0x00fc
	db	0x00fb
	db	0x00fa
	db	0x00fa
	db	0x00f9
	db	0x00f8
	db	0x00f7
	db	0x00f6
	db	0x00f4
	db	0x00f3
	db	0x00f2
	db	0x00f0
	db	0x00ef
	db	0x00ed
	db	0x00ec
	db	0x00ea
	db	0x00e8
	db	0x00e7
	db	0x00e5
	db	0x00e3
	db	0x00e1
	db	0x00df
	db	0x00dd
	db	0x00db
	db	0x00d8
	db	0x00d6
	db	0x00d4
	db	0x00d1
	db	0x00cf
	db	0x00cd
	db	0x00ca
	db	0x00c8
	db	0x00c5
	db	0x00c2
	db	0x00c0
	db	0x00bd
	db	0x00ba
	db	0x00b7
	db	0x00b4
	db	0x00b2
	db	0x00af
	db	0x00ac
	db	0x00a9
	db	0x00a6
	db	0x00a3
	db	0x00a0
	db	0x009d
	db	0x009a
	db	0x0097
	db	0x0094
	db	0x0090
	db	0x008d
	db	0x008a
	db	0x0087
	db	0x0084
	db	0x0081
	db	0x007e
	db	0x007a
	db	0x0077
	db	0x0074
	db	0x0071
	db	0x006e
	db	0x006b
	db	0x0068
	db	0x0065
	db	0x0062
	db	0x005f
	db	0x005c
	db	0x0059
	db	0x0056
	db	0x0053
	db	0x0050
	db	0x004d
	db	0x004a
	db	0x0047
	db	0x0044
	db	0x0042
	db	0x003f
	db	0x003c
	db	0x0039
	db	0x0037
	db	0x0034
	db	0x0032
	db	0x002f
	db	0x002d
	db	0x002a
	db	0x0028
	db	0x0026
	db	0x0024
	db	0x0021
	db	0x001f
	db	0x001d
	db	0x001b
	db	0x0019
	db	0x0018
	db	0x0016
	db	0x0014
	db	0x0012
	db	0x0011
	db	0x000f
	db	0x000e
	db	0x000c
	db	0x000b
	db	0x000a
	db	0x0008
	db	0x0007
	db	0x0006
	db	0x0005
	db	0x0004
	db	0x0004
	db	0x0003
	db	0x0002
	db	0x0002
	db	0x0001
	db	0x0001
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0001
	db	0x0001
	db	0x0002
	db	0x0002
	db	0x0003
	db	0x0004
	db	0x0005
	db	0x0006
	db	0x0007
	db	0x0008
	db	0x0009
	db	0x000a
	db	0x000b
	db	0x000d
	db	0x000e
	db	0x0010
	db	0x0011
	db	0x0013
	db	0x0015
	db	0x0016
	db	0x0018
	db	0x001a
	db	0x001c
	db	0x001e
	db	0x0020
	db	0x0022
	db	0x0024
	db	0x0027
	db	0x0029
	db	0x002b
	db	0x002e
	db	0x0030
	db	0x0033
	db	0x0035
	db	0x0038
	db	0x003a
	db	0x003d
	db	0x0040
	db	0x0042
	db	0x0045
	db	0x0048
	db	0x004b
	db	0x004e
	db	0x0051
	db	0x0054
	db	0x0056
	db	0x0059
	db	0x005c
	db	0x0060
	db	0x0063
	db	0x0066
	db	0x0069
	db	0x006c
	db	0x006f
	db	0x0072
	db	0x0075
	db	0x0078
	db	0x007b
	db	0x007f
	db	0x0082
	db	0x0085
	db	0x0088
	db	0x008c
	db	0x008f
	db	0x0092
	db	0x0095
	db	0x0098
	db	0x009b
	db	0x009e
	db	0x00a1
	db	0x00a4
	db	0x00a7
	db	0x00aa
	db	0x00ad
	db	0x00b0
	db	0x00b3
	db	0x00b6
	db	0x00b9
	db	0x00bb
	db	0x00be
	db	0x00c1
	db	0x00c3
	db	0x00c6
	db	0x00c9
	db	0x00cb
	db	0x00ce
	db	0x00d0
	db	0x00d3
	db	0x00d5
	db	0x00d7
	db	0x00d9
	db	0x00dc
	db	0x00de
	db	0x00e0
	db	0x00e2
	db	0x00e4
	db	0x00e6
	db	0x00e7
	db	0x00e9
	db	0x00eb
	db	0x00ed
	db	0x00ee
	db	0x00f0
	db	0x00f1
	db	0x00f2
	db	0x00f4
	db	0x00f5
	db	0x00f6
	db	0x00f7
	db	0x00f8
	db	0x00f9
	db	0x00fa
	db	0x00fb
	db	0x00fc
	db	0x00fc
	db	0x00fd
	db	0x00fd
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fe
	db	0x00fd
	db	0x00fd
	db	0x00fc
	db	0x00fc
	db	0x00fb
	db	0x00fa
	db	0x00fa
	db	0x00f9
	db	0x00f8
	db	0x00f7
	db	0x00f6
	db	0x00f4
	db	0x00f3
	db	0x00f2
	db	0x00f0
	db	0x00ef
	db	0x00ed
	db	0x00ec
	db	0x00ea
	db	0x00e8
	db	0x00e7
	db	0x00e5
	db	0x00e3
	db	0x00e1
	db	0x00df
	db	0x00dd
	db	0x00db
	db	0x00d8
	db	0x00d6
	db	0x00d4
	db	0x00d1
	db	0x00cf
	db	0x00cd
	db	0x00ca
	db	0x00c8
	db	0x00c5
	db	0x00c2
	db	0x00c0
	db	0x00bd
	db	0x00ba
	db	0x00b7
	db	0x00b4
	db	0x00b2
	db	0x00af
	db	0x00ac
	db	0x00a9
	db	0x00a6
	db	0x00a3
	db	0x00a0
	db	0x009d
	db	0x009a
	db	0x0097
	db	0x0094
	db	0x0090
	db	0x008d
	db	0x008a
	db	0x0087
	db	0x0084
	db	0x0081
	db	0x007e
	db	0x007a
	db	0x0077
	db	0x0074
	db	0x0071
	db	0x006e
	db	0x006b
	db	0x0068
	db	0x0065
	db	0x0062
	db	0x005f
	db	0x005c
	db	0x0059
	db	0x0056
	db	0x0053
	db	0x0050
	db	0x004d
	db	0x004a
	db	0x0047
	db	0x0044
	db	0x0042
	db	0x003f
	db	0x003c
	db	0x0039
	db	0x0037
	db	0x0034
	db	0x0032
	db	0x002f
	db	0x002d
	db	0x002a
	db	0x0028
	db	0x0026
	db	0x0024
	db	0x0021
	db	0x001f
	db	0x001d
	db	0x001b
	db	0x0019
	db	0x0018
	db	0x0016
	db	0x0014
	db	0x0012
	db	0x0011
	db	0x000f
	db	0x000e
	db	0x000c
	db	0x000b
	db	0x000a
	db	0x0008
	db	0x0007
	db	0x0006
	db	0x0005
	db	0x0004
	db	0x0004
	db	0x0003
	db	0x0002
	db	0x0002
	db	0x0001
	db	0x0001
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0000
	db	0x0001
	db	0x0001
	db	0x0002
	db	0x0002
	db	0x0003
	db	0x0004
	db	0x0005
	db	0x0006
	db	0x0007
	db	0x0008
	db	0x0009
	db	0x000a
	db	0x000b
	db	0x000d
	db	0x000e
	db	0x0010
	db	0x0011
	db	0x0013
	db	0x0015
	db	0x0016
	db	0x0018
	db	0x001a
	db	0x001c
	db	0x001e
	db	0x0020
	db	0x0022
	db	0x0024
	db	0x0027
	db	0x0029
	db	0x002b
	db	0x002e
	db	0x0030
	db	0x0033
	db	0x0035
	db	0x0038
	db	0x003a
	db	0x003d
	db	0x0040
	db	0x0042
	db	0x0045
	db	0x0048
	db	0x004b
	db	0x004e
	db	0x0051
	db	0x0054
	db	0x0056
	db	0x0059
	db	0x005c
	db	0x0060
	db	0x0063
	db	0x0066
	db	0x0069
	db	0x006c
	db	0x006f
	db	0x0072
	db	0x0075
	db	0x0078
	db	0x007b
	

;Storage area for potentiometer	
	org	0x6000	
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x004F
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x004A
	db	0x005F
	db	0x0070
	db	0x0072
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0070
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x004C
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x004F
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x004A
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0049
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x004A
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x004B
	db	0x004A
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x004A
	db	0x004B
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x0048
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0049
	db	0x004C
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x004A
	db	0x0049
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	db	0x0070
	db	0x0068
	db	0x006F
	db	0x006A
	db	0x0062
	db	0x0071
	db	0x0067
	db	0x0060
	db	0x005F
	db	0x0063
	db	0x006C
	db	0x0061
	db	0x006D
	db	0x005E
	
	end
