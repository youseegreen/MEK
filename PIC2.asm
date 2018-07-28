;A0:reset  A1:get "play sound flag" from pic3  A2~A7:null 
;B0:intrrupt_pin  ;B1:del | add  ;B2:send flag to pic3  ;B3:null
;B4:update  B5:clock  B6:segSig  B7:conSig
;C0~C7:get morse signal  D0~D7:send morse signal to pic3
		LIST	P=16F1939,F=INHX8M,R=DEC
		include	"p16F1939.inc"
		ORG	0
GOTO	START
		ORG 4
INT		NOP
		BANKSEL	IOCBF		;flag clear
		BCF		IOCBF,0		;flag clear
		BCF		INTCON,IOCIF
		BANKSEL PORTB	;bank0
		BTFSS	PORTB,1		;b1:0消去　1追加	
		GOTO	ERASE1
		GOTO	ADD1

ERASE1	;if(INDEX == 0) then INDEX = LEDNUM
		
		;debug
		MOVLW	H'88'
		MOVWF	PORTD
		;
		;erase this buf[--INDEX]
		MOVLW	H'00'		
		BCF		STATUS,2
		SUBWF	INDEX,W
		BTFSC	STATUS,2
		MOVLW	LED_NUM		;W <= LED_NUM
		BTFSC	STATUS,2
		MOVWF	INDEX		;INDEX <= W
		DECF	INDEX,F		;index--
		
		MOVLW	BUF0
		ADDWF	INDEX,W		
		MOVWF	FSR1
		MOVLW	H'FF'
		MOVWF	INDF1	

		RETFIE  

ADD1	MOVF	PORTC,W
		MOVWF	SIGN
		;debug
		MOVF	SIGN,W
		MOVWF	PORTD
		;
		CLRF	CCNT		;CCNT = A
JUDGE	MOVLW	MORSE		;W <= MORSE
		ADDWF	CCNT,W		;W <= MORSE + CCNT
		BANKSEL EEADRL		;bank3
		MOVWF	EEADRL
		MOVLW	HIGH(MORSE)
		MOVWF	EEADRH
;		BCF		EECON1,CFGS	;select config or flash,data
		BSF		EECON1,EEPGD	;select program memory
		BSF		EECON1,RD	;initiate read
		NOP	;wait
		NOP	;wait
		MOVF	EEDATL,W	;Get Data(MORSE+CCNT)
		BCF		EECON1,EEPGD	;select data memory
		BANKSEL SIGN		;bank0	
		;check W == SIGN
		BCF		STATUS,2	;Zero flag
		SUBWF	SIGN,W		;Data(MORSE+CCNT) , SIGN
		BTFSS	STATUS,2	
		GOTO	SKIP	;Data(MORSE+CCNT) != SIGN
		GOTO	SAVE	;Data(MORSE+CCNT) == SIGN
SKIP	INCF	CCNT,F
		MOVLW	27		;if CCNT == space then return
		BCF		STATUS,2	;Zero flag
		SUBWF	CCNT,W		;CCNT == 27 ?
		BTFSS	STATUS,2	
		GOTO	JUDGE		;CCNT != 27
		RETFIE				;CCNT == 27

;SAVE DATA(SEG + CCNT) to BUF[INDEX]
SAVE	;step 0 save SIGN to SIGBUF[i]
		MOVLW	SIGBUF0
		ADDWF	INDEX,W
		MOVWF	FSR1
		MOVF	SIGN,W
		MOVWF	INDF1
		
		;first set INDF1 to BUF[INDEX]
		MOVLW	BUF0
		ADDWF	INDEX,W
		MOVWF	FSR1		;INDF1 -> BUF[INDEX]	
		INCF	INDEX,F		;INDEX++
		;if(INDEX == LED_NUM) then LED_NUM <= 0
		MOVLW	LED_NUM		
		BCF		STATUS,2
		SUBWF	INDEX,W
		BTFSC	STATUS,2	
		CLRF	INDEX	;INDEX == LED_NUM => INDEX = 0

		;second set DATA(SEG + CCNT) to Wreg
		MOVLW	SEG			;W <= SEG
		ADDWF	CCNT,W		;W <= SEG + CCNT
		BANKSEL EEADRL		;bank5
		MOVWF	EEADRL		;EEADRL <= W
		MOVLW	HIGH(SEG)
		MOVWF	EEADRH
;		BCF		EECON1,CFGS	;select config or flash,data
		BSF		EECON1,EEPGD	;select program memory
		BSF		EECON1,RD	;initiate read
		NOP	;wait
		NOP	;wait
		MOVF	EEDATL,W	;Get Data(SEG+CCNT)
		BCF		EECON1,EEPGD	;select data memory

		;third BUF[INDEX] <= DATA(SEG + CCNT)
		MOVWF	INDF1

		RETFIE

START	;Variable declaration
CONSTANT LED_NUM = 8	;LED_NUMBER
CCNT	EQU	H'20'	;Alphabet Count
SIGN	EQU	H'21'	;get signal from MAIN PIC
LCNT	EQU	H'22'	;Loop CouNT	
INDEX	EQU	H'23'	;index
DLYVAR	EQU	H'25'	;delay variable
TMPSEG 	EQU H'26'	;procedure bit of 7SEG
TMPCON	EQU H'27'	;procedure bit of Control
BITCNT	EQU H'28'	;bitCount
LEDCNT	EQU H'29'	;ledCount
BUF0	EQU	H'30'
BUF1	EQU	H'31'
BUF2	EQU	H'32'
BUF3	EQU	H'33'
BUF4	EQU	H'34'
BUF5	EQU	H'35'
BUF6	EQU	H'36'
BUF7	EQU	H'37'
SIGBUF0	EQU	H'40'
SIGBUF1	EQU	H'41'
SIGBUF2	EQU	H'42'
SIGBUF3	EQU	H'43'
SIGBUF4	EQU	H'44'
SIGBUF5	EQU	H'45'
SIGBUF6	EQU	H'46'
SIGBUF7	EQU	H'47'

		;setting I/O port
		;setting PORTA
		;A0:reset, A1:catch "play sound msg", A2:catch receved frag from buzz
		BANKSEL PORTA
		CLRF	PORTA
		BANKSEL LATA
		CLRF	LATA
		BANKSEL ANSELA
		CLRF	ANSELA	;digital I/O
		BANKSEL TRISA
		MOVLW	H'FF'
		MOVWF	TRISA	;all input
		;B0,1:for intrrupt, B2:send msg to buzz, B3:send add or del to buzz
		;B4~7:graphic  C:morse signal  D:send sig to BUZZER
		;setting PORTB
		BANKSEL PORTB
		CLRF PORTB ;Init PORTB
		BANKSEL	ANSELB
		CLRF ANSELB ;Make RB<7:0> digital
		BANKSEL TRISB
		MOVLW B'00000011' ;Set RB<1:0> as inputs
		MOVWF TRISB ;
		;intrrupt setting
		BANKSEL	IOCBP
		MOVLW H'01'	;B0 Positive Edge
		MOVWF IOCBP
		MOVLW H'00'	;Negative Edge
		MOVWF IOCBN
		BANKSEL	INTCON
		MOVLW B'01001000'
		MOVWF INTCON
		;PORTC and PORTD : all output
		BANKSEL	TRISC
		MOVLW	H'FF'
		MOVWF	TRISC
		CLRF	TRISD
		BANKSEL	PORTC
		CLRF	PORTC
		CLRF	PORTD
		BSF		PORTD,6
		;Buf[i] initialize
		CLRF	INDEX
		MOVLW	H'FF'
		MOVWF	BUF0
		MOVWF	BUF1
		MOVWF	BUF2
		MOVWF	BUF3
		MOVWF	BUF4
		MOVWF	BUF5
		MOVWF	BUF6
		MOVWF	BUF7
		CLRF	SIGBUF0
		CLRF	SIGBUF1
		CLRF	SIGBUF2
		CLRF	SIGBUF3
		CLRF	SIGBUF4
		CLRF	SIGBUF5
		CLRF	SIGBUF6
		CLRF	SIGBUF7
	
		BSF		INTCON,7	;start intrrupt

LOOP	;while(true)
		BTFSC	PORTA,0		
		RESET	
		BTFSC	PORTA,1		;if play botton is pushed,
		CALL	SENDSIG

		;B4:update  B5:clock  B6:segSignal  B7:conSignal
		;prepare for roop
		MOVLW	BUF0
		MOVWF	FSR0
		MOVLW	B'00000001'	;lighting position
		MOVWF	LCNT		;where to light
		MOVLW	LED_NUM		
		MOVWF	LEDCNT

FORNUM	;for(int i = 0;i<LED_NUM;i++)
		;prepare tmpseg, tmpcon
		MOVIW	INDF0++		;W <= BUF[i++]	(FSR0 -> now++)
		MOVWF	TMPSEG		;TMPSEG <= W
		MOVF	LCNT,W		
		MOVWF	TMPCON		;where lighting	 <- is need?
		MOVLW	8
		MOVWF	BITCNT		;bitcnt <= 8
		;first ledCnt is setted ledNum
FORBIT8	;for(bit = 0 ~ 7;bit++)	output TMPCON from MSB
		;controll push
		BTFSS	TMPCON,7	;if(tmpcon,7)?
		BCF		PORTB,7			;tmpcon(7) == Low then reset
		BTFSC	TMPCON,7	
		BSF		PORTB,7			;tmpcon(7) == High then set
		;segment push
		BTFSS	TMPSEG,7	;if(tmpseg,7)?
		BCF		PORTB,6			;tmpseg(7) == Low then reset
		BTFSC	TMPSEG,7	
		BSF		PORTB,6			;tmpseg(7) == High then set

		;clock update
		BSF		PORTB,5	
		BCF		PORTB,5	


		;dont care carry bit
		;rotation controll
		BTFSS	TMPCON,7	;carry bit <= TMPCON,7
		BCF		STATUS,0	;if(Num(7) == 0) then carry bit = 0	
		BTFSC	TMPCON,7
		BSF		STATUS,0	;if(Num(7) == 1) then carry bit = 1		
		RLF		TMPCON,F	;rotation

		;rotation segment
		BTFSS	TMPSEG,7	;carry bit <= TMPCON,7
		BCF		STATUS,0	;if(Num(7) == 0) then carry bit = 0	
		BTFSC	TMPSEG,7
		BSF		STATUS,0	;if(Num(7) == 1) then carry bit = 1		
		RLF		TMPSEG,F	;rotation

		;bitcount--
		DECFSZ	BITCNT,F		
		GOTO	FORBIT8		;if(bitcount > 0) goto roop 

;;;;;;;;end roop;;;;;;;;;;;;;;
		;update shift register
		BSF		PORTB,4		;End updating and output
		BCF		PORTB,4	
		;rotation lighting position
		BTFSS	LCNT,7		;carry bit <= TMPCON,7
		BCF		STATUS,0	;if(Num(7) == 0) then carry bit = 0	
		BTFSC	LCNT,7
		BSF		STATUS,0	;if(Num(7) == 1) then carry bit = 1		
		RLF		LCNT,F		;rotation

		;check end
		DECFSZ	LEDCNT,F		
		GOTO	FORNUM		;next buf
		GOTO	LOOP		;start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SENDSIG	BSF		PORTB,2		;send buzz
		;wait moment and set INDF0
		MOVLW	SIGBUF0
		MOVWF	FSR0
		MOVLW	LED_NUM		
		MOVWF	LEDCNT
		CALL	DLY
		CALL	DLY
		BCF		PORTB,2

FORSIG	;for(int i = 0;i<LEDNUM;i++)
		MOVIW	INDF0++		
		MOVWF	PORTD
		;wait moment
		CALL	DLY
		CALL	DLY
		BSF		PORTB,2	;notice pic3 

		DECFSZ	LEDCNT,F		
		GOTO	SKIPTMP		
		BCF		PORTB,2
		RETURN
SKIPTMP	CALL	DLY
		CALL	DLY
		BCF		PORTB,2
		GOTO	FORSIG

DLY		MOVLW	255
		MOVWF	DLYVAR
DLYLOOP	DECFSZ	DLYVAR,F
		GOTO	DLYLOOP
		RETURN
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
		NOP
;databases    change 27 to Space : - - - -
MORSE	DT		B'00001011',B'11111110',B'11101110',B'00111110'
		DT		B'00000011',B'11101111',B'00111010',B'11111111'
		DT		B'00001111',B'10101011',B'00101110',B'11111011'
		DT		B'00001010',B'00001110',B'00101010',B'11101011'
		DT		B'10111010',B'00111011',B'00111111',B'00000010'
		DT		B'00101111',B'10111111',B'00101011',B'10111110'
		DT		B'10101110',B'11111010',B'10101010',B'00000000'
SEG		DT		B'10000010',B'01100010',B'01110110',B'01010010'
		DT		B'00100110',B'10100110',B'00101010',B'11100010'
		DT		B'11111011',B'01011010',B'10100010',B'01101110'
		DT		B'10001010',B'11110010',B'01110010',B'10000110'
		DT		B'00000110',B'11110110',B'01100011',B'01100110'
		DT		B'01111010',B'01001010',B'01000010',B'11000010'
		DT		B'01000011',B'00011110',B'11111111',B'11111111'

		END