;A0;ton A1:tuu A2:del A3:play sound flag from pic3  
;A4:reset A5~A7:null  B0~B7:null C0:send flag gra_pic  
;C1:send gra_pic add | del  D0~D7:send gra_pic morse signal
		LIST	P=16F1939,F=INHX8M,R=DEC
		include	"p16F1939.inc"
		ORG	0
		GOTO MAIN

		ORG 4	;intrrupt  ccp
INT		BCF		PIR1,2	;flag clear
		INCF	TMCNT,F
		;check TMCNT==50
		BCF		STATUS,2	;Zero flag
		MOVLW	45
		SUBWF	TMCNT,W
		BTFSS	STATUS,2	
		RETFIE	;TMCNT!=50
		;TMCNT==50

		;check PORTD == 0
		BCF		STATUS,2	;Zero flag
		MOVLW	B'00000000'
		SUBWF	CHARA,W
		BTFSC	STATUS,2	
		RETFIE	;PORTD!=0
		CALL	OUTPUT	;PORTD==0
		RETFIE


MAIN	
CNT		EQU		H'20'
DLYH	EQU		H'21'
DLYL	EQU		H'22'
NUM		EQU		H'23'
CHARA	EQU		H'24'
TMCNT	EQU		H'25'
;W_TEMP	EQU		H'26'
;ST_TEMP EQU		H'27'

		;prepare for ccp intrrupt
		BSF		INTCON,6
		BANKSEL PIE1
		BSF		PIE1,2
		BANKSEL T1CON
		MOVLW	B'00110001'
		MOVWF	T1CON
		;set special event trigger
		BANKSEL CCP1CON
		MOVLW	B'00001011'
		MOVWF	CCP1CON	
		;setting freqency
		MOVLW	H'3D'	
		MOVWF	CCPR1H
		MOVLW	H'FF'
		MOVWF	CCPR1L
	
		;setting I/O port
		;setting PORTA
		BANKSEL PORTA
		CLRF	PORTA
		BANKSEL LATA
		CLRF	LATA
		BANKSEL ANSELA
		CLRF	ANSELA	;digital I/O
		BANKSEL TRISA
		MOVLW	H'FF'
		MOVWF	TRISA	;all input
		;PORTC and PORTD : all output
		CLRF	TRISC	;all output
		CLRF	TRISD	;all output
		BANKSEL	PORTC
		CLRF	PORTC
		CLRF	PORTD

		;initialize variable
		MOVLW	B'00000011'
		MOVWF	NUM
		CLRF	TMCNT
		CLRF	CHARA

		;start ccp intrrupt
		BSF		INTCON,7

LOOP	CALL	DLY		;for chattering
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		CALL	DLY
		BSF		PORTC,1
		
WAIT	BTFSS	PORTA,4	
		BTFSC	PORTA,4
		RESET
		BTFSS	PORTA,3	
		BTFSC	PORTA,3
		GOTO	PLAY	;play sound
		BTFSS	PORTA,0
		BTFSC	PORTA,0
		GOTO	TON	
		BTFSS	PORTA,1
		BTFSC	PORTA,1
		GOTO	TUU	
		BTFSS	PORTA,2
		BTFSC	PORTA,2
		GOTO	DELETE
		GOTO	WAIT
	
TON		CLRF	TMCNT	;reset TMCNT
		MOVLW	B'11111111'
		CALL	ISPERIOD
		GOTO	LOOP

TUU		CLRF	TMCNT	
		MOVLW	B'10101010'
		CALL	ISPERIOD
		GOTO	LOOP

ISPERIOD	
		ANDWF	NUM,W	
		IORWF	CHARA,F
		MOVF	CHARA,W
		MOVWF	PORTD
		;shift
		BTFSS	NUM,7		;carry bit <= NUM,7
		BCF		STATUS,0	;if(Num(7) == 0) then carry bit = 0	
		BTFSC	NUM,7
		BSF		STATUS,0	;if(Num(7) == 1) then carry bit = 1		
		RLF		NUM,F
		;shift
		BTFSS	NUM,7		;carry bit NUM,7
		BCF		STATUS,0	;if(Num(7) == 0) then carry bit = 0	
		BTFSC	NUM,7
		BSF		STATUS,0	;if(Num(7) == 1) then carry bit = 1		
		RLF		NUM,F
			
		;check
		MOVLW	B'00000011'
		;check NUM == 3
		BCF		STATUS,2	;Zero flag
		MOVLW	3
		SUBWF	NUM,W
		BTFSS	STATUS,2	
		RETURN	;NUM!=3
		CALL	OUTPUT	;NUM==3
		RETURN

OUTPUT	BSF		PORTC,1		;notice GRA PIC
		CALL	DLY
		
		MOVLW	B'00000011'
		MOVWF	NUM
		CLRF	CHARA
		BSF		PORTC,0	
		CALL	DLY
		BCF		PORTC,0		;stop sending
		CLRF	PORTD
		CLRF	TMCNT
		RETURN

DELETE	BCF		PORTC,1		;notice GRA PIC
		MOVLW	B'00000011'
		MOVWF	NUM
		CLRF	PORTD
		CLRF	CHARA
		BSF		PORTC,0	
		CALL	DLY
		BCF		PORTC,0	
		CLRF	TMCNT
		GOTO	LOOP	

PLAY	MOVLW	B'00000011'
		CLRF	TMCNT
		MOVWF	NUM
		CLRF	PORTD
		CLRF	CHARA
		GOTO	LOOP



DLY		MOVLW	255
		MOVWF	DLYH
DLYLP2	MOVLW	255
		MOVWF	DLYL
DLYLP1	DECFSZ	DLYL,F
		GOTO	DLYLP1
		DECFSZ	DLYH,F
		GOTO	DLYLP2
		RETURN
		END


