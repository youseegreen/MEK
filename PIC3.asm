;A0:ton A1:tuu A2:reset A3:play sound A4:receive flag from pic2 
;A5~A7:null B0:null B1:send flag to pic2 B2:send flag to pic1
;B3~B7:null  C0~C7:receive morse signal  D2:buzz  D0,D1,D3~D7:null
		LIST	P=16F1939,F=INHX8M,R=DEC
		include	"p16F1939.inc"
		ORG	0
		GOTO	START

		ORG	4
INT		BCF		PIR1,2

		MOVLW	B'00001100'
		XORWF	PORTD,F		;sound buzzer

		INCF	CNTL,F		
		MOVF	CNTL,W
		;check cnt_Low , threshold_Low
		BCF		STATUS,2
		SUBWF	THRL,W
		BTFSS	STATUS,2	
		RETFIE	;if(CNTL != THRL) then return
		CLRF	CNTL

		INCF	CNTH,F		
		MOVF	CNTH,W
		;check cnt_High , threshold_High
		BCF		STATUS,2
		SUBWF	THRH,W
		BTFSS	STATUS,2	
		RETFIE	;if(CNTH != THRH) then return
		CLRF	CNTH

		;disable intrrupt
		BANKSEL	PIE1
		BCF		PIE1,2
		BANKSEL	PORTD
		CLRF	PORTD	
		RETFIE

START	
CONSTANT LED_NUM = 8	;LED_NUMBER
CNTH	EQU		H'20'
CNTL	EQU		H'21'
THRH	EQU		H'22'
THRL	EQU		H'23'
DLYH	EQU		H'24'
DLYL	EQU		H'25'
BITCNT  EQU		H'26'	;bit count for play sound
LEDCNT	EQU		H'27'	;led count for play sound
SIGN	EQU		H'28'	;morse sign 
PLYNUM	EQU		H'29'	;play number (space not sound)
BUF0	EQU		H'30'
BUF1	EQU		H'31'
BUF2	EQU		H'32'
BUF3	EQU		H'33'
BUF4	EQU		H'34'
BUF5	EQU		H'35'
BUF6	EQU		H'36'
BUF7	EQU		H'37'

		;prepare for ccp intrrupt
		BSF		INTCON,6
		BSF		INTCON,7
		BANKSEL T1CON	;bank0
		MOVLW	B'00110001'
		MOVWF	T1CON
		;set special event trigger
		BANKSEL CCP1CON	;bank6
		MOVLW	B'00001011'
		MOVWF	CCP1CON	
		;setting freqency

		;setting I/O port
		;setting PORTA
		BANKSEL PORTA	;bank0
		CLRF	PORTA
		BANKSEL LATA
		CLRF	LATA
		BANKSEL ANSELA
		CLRF	ANSELA	;digital I/O
		BANKSEL TRISA	;bank1
		MOVLW	H'FF'
		MOVWF	TRISA	;portA A0~A7:input
		;setting PORTB
		BANKSEL PORTB
		CLRF PORTB ;Init PORTB
		BANKSEL	ANSELB
		CLRF ANSELB ;Make RB<7:0> digital
		BANKSEL TRISB
		MOVLW H'00' ;Set RB<7:0> as outputs
		MOVWF TRISB ;
		;PORTC and PORTD
		MOVLW	H'FF'
		MOVWF	TRISC	;all input
		CLRF	TRISD	;all output
		BANKSEL	PORTC
		CLRF	PORTC
		CLRF	PORTD
	
		;initialize variable
		CLRF	BUF0
		CLRF	BUF1
		CLRF	BUF2
		CLRF	BUF3
		CLRF	BUF4
		CLRF	BUF5
		CLRF	BUF6
		CLRF	BUF7												
		CLRF	CNTH
		CLRF	CNTL


LOOP	CALL	DLY		;for chattering
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY

WAIT	BTFSS	PORTA,0
		BTFSC	PORTA,0
		GOTO	TON_L	
		BTFSS	PORTA,1
		BTFSC	PORTA,1
		GOTO	TUU_L	
		BTFSS	PORTA,2
		BTFSC	PORTA,2
		RESET
		BTFSS	PORTA,3
		BTFSC	PORTA,3
		GOTO	PLAY
		GOTO	WAIT

TON_C	NOP
		BANKSEL	PIE1	;bank1
		BCF		PIE1,2		;disable interrupt
		BANKSEL	CCPR1H	;bank6
		MOVLW	H'02'		;set freqency
		MOVWF	CCPR1H
		MOVLW	H'C6'
		MOVWF	CCPR1L
		BANKSEL	PORTA	;bank0
		MOVLW	1			;set time
		MOVWF	THRH
		MOVLW	150
		MOVWF	THRL
		CLRF	CNTH
		CLRF	CNTL
		BANKSEL	PIE1	;bank1
		BSF		PIE1,2		;able interrupt
		BANKSEL PORTA	;bank0
		RETURN
TON_L	CALL	TON_C
		GOTO	LOOP

TUU_C	NOP
		BANKSEL	PIE1	;bank1
		BCF		PIE1,2		;disable interrupt
		BANKSEL	CCPR1H	;bank6
		MOVLW	H'02'		;set freqency
		MOVWF	CCPR1H
		MOVLW	H'14'
		MOVWF	CCPR1L
		BANKSEL	PORTA	;bank0
		MOVLW	5			;set time
		MOVWF	THRH
		MOVLW	100
		MOVWF	THRL
		CLRF	CNTH
		CLRF	CNTL
		BANKSEL	PIE1	;bank1
		BSF		PIE1,2		;able interrupt
		BANKSEL PORTA	;bank0
		RETURN
TUU_L	CALL	TUU_C
		GOTO	LOOP

PLAY	NOP
		BANKSEL	PIE1	;bank1
		BCF		PIE1,2		;disable interrupt

		BANKSEL	PORTB
		BSF		PORTB,2	;notice PIC1

		BSF		PORTD,1
		CALL	GETSIG	;get signal from pic2
		BCF		PORTD,0


		;if sign == space then sign <= 00000000
		CLRF	LEDCNT
ISSPACE	;for(i = 0;i < LED_NUM;i++)
		MOVLW	BUF0
		ADDWF	LEDCNT,W	;buf[i]
		MOVWF	FSR0
		
		MOVLW	B'10101010'	;space
		BCF		STATUS,2
		SUBWF	INDF0,W
		BTFSC	STATUS,2
		CLRF	INDF0		;if(buf[i] == space) then buf[i]=0
		;goto next buf
		INCF	LEDCNT,F
		MOVLW	LED_NUM
		BCF		STATUS,2
		SUBWF	LEDCNT,W
		BTFSS	STATUS,2
		GOTO	ISSPACE

		;how many sign play
		MOVLW	BUF7		;maybe already setted
		MOVWF	FSR0
		MOVLW	LED_NUM
		MOVWF	PLYNUM
		MOVWF	LEDCNT
HOWMANY	MOVIW	INDF0--		;W <= BUF[i--]	(FSR0 -> now--)
		MOVWF	SIGN
		MOVLW	H'00'
		BCF		STATUS,2
		SUBWF	SIGN,W
		BTFSC	STATUS,2
		DECF	PLYNUM,F
		DECFSZ	LEDCNT,F
		GOTO	HOWMANY
		
		MOVLW	H'00'
		BCF		STATUS,2
		SUBWF	PLYNUM,W
		BTFSC	STATUS,2
		BCF		PORTB,2
		BTFSC	STATUS,2
		RETURN

		CALL	W_THREE
		;play sound
		MOVLW	BUF0
		MOVWF	FSR0
		MOVF	PLYNUM,W		
		MOVWF	LEDCNT		;ledCount set
	
FORNUM	;for(n = 0; n < LED_NUM; n++)
		MOVIW	INDF0++		;W <= BUF[i++]	(FSR0 -> now++)
		MOVWF	SIGN
		MOVLW	4
		MOVWF	BITCNT		;bitCount set


FORSIG	;for(sign = 1 ~ 4)
		BTFSS	SIGN,1	;if sig not (ton | tuu)
		GOTO 	NEXT	;then goto next buf

		BTFSS	SIGN,0		;if sign[0] == 0
		CALL	TUU_C		;then call TON
		BTFSC	SIGN,0
		CALL	TON_C		;else call TUU

		;wait until PIE1,2->false
W8		BTFSC	PIE1,2
		GOTO	W8
		CALL	W_ONE	;wait second

		;rotation	'abcdefgh' -> 'ghabcdef'
		BTFSS	SIGN,0		;carry bit <= NUM,7
		BCF		STATUS,0	;if(Num(0) == 0) then carry bit = 0	
		BTFSC	SIGN,0
		BSF		STATUS,0	;if(Num(0) == 1) then carry bit = 1		
		RRF		SIGN,F
		;rotation	
		BTFSS	SIGN,0		;carry bit <= NUM,7
		BCF		STATUS,0	;if(Num(0) == 0) then carry bit = 0	
		BTFSC	SIGN,0
		BSF		STATUS,0	;if(Num(0) == 1) then carry bit = 1		
		RRF		SIGN,F


		;if all bit checked then go to next buf
		DECFSZ	BITCNT,F		
		GOTO	FORSIG		;next bit

NEXT	CALL	W_THREE	;wait 3 seconds

		DECFSZ	LEDCNT,F		
		GOTO	FORNUM		;next buf

		;if all buf played then goto LOOP
		BCF		PORTB,2	;notice pic1
		GOTO	LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;get signal from GRA_PIC
GETSIG	;set INDF0
		MOVLW	BUF0
		MOVWF	FSR0
		MOVLW	LED_NUM		
		MOVWF	LEDCNT
		BSF		PORTB,1	;notice pic1

;wait until pic2 send msg
UNT1	BTFSS	PORTA,4	
		GOTO	UNT1
		BCF		PORTB,1
;wait until pic2 send reset msg
UNT2	BTFSC	PORTA,4
		GOTO	UNT2


LOOPBUF	;for(int i = 0;i<LED_NUM;i++)
GRA_H	BTFSS	PORTA,4
		GOTO	GRA_H
		MOVF	PORTC,W	;get sign
		MOVWI	INDF0++	;set sign in buf[i]
		DECFSZ	LEDCNT,F
		GOTO	GRA_L
		RETURN
GRA_L	

		BTFSC	PORTA,4
		GOTO	GRA_L
		GOTO	LOOPBUF


DLY		MOVLW	255
		MOVWF	DLYH
DLYLP2	MOVLW	255
		MOVWF	DLYL
DLYLP1	DECFSZ	DLYL,F
		GOTO	DLYLP1
		DECFSZ	DLYH,F
		GOTO	DLYLP2
		RETURN	
W_ONE	CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		RETURN
W_THREE	CALL	W_ONE
		CALL	W_ONE
		RETURN
		END
	