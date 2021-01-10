ddrb = $6002 
ddra = $6003
portb = $6000
porta = $6001

; ACIA chip registers

acia_data = $5000 ; data register
acia_stat = $5001 ; status register ; on write we reset the ACIA
acia_comm = $5002 ; command register
acia_ctrl = $5003 ; control register

	; PORTA 0-2 : E - R/WB - RS
	; PORTB 0-7 : LCD data bus  in order 

 ; PAGE ZERO VARIABLES 

serial_string_send_low = $05
serial_string_send_high = $06

; Constants

CR = $0D ; carriage return
ESC = $1B
PROMPT = "$" ; prompt character

; Monitor  variables 

line_buffer = $200 ; starts at $200 and spans till $27F ; 127 characters like the original wozmon
serial_buffer = $300 ; from $300 to $3ff 
L = $28 ; hex value parsing low 
H = $29  ; hex value parsing high 
XAML = $24 ; last opened location low 
XAMH = $25 ; last opened location high
MODE = $23  ; MODE
YSAV = $22 ; last Y index we had
STL = $20 ; store address low 
STH = $21 ; store address high
ACIA_ERROR = $2A ; check this for serial errors
ACIA_NUMBER = $2B
q_front = $2C ; front of serial queue
q_back = $2D ; back of serial queue

	.org $8000

	sei 
init:	
	; set up VIA ports
	lda #$ff
	sta ddrb
	lda #$07
	sta ddra

	cld

	ldx #$ff 
	txs ; initialize stack pointer 

	; write things to zero page 

	; set up the circular queue back and front variables for the serial buffer 
	lda #0
	sta q_back
	sta q_front

	; initialise LCD 

	jsr krnl_init_lcd 

	; now write hello world string
	
	lda #'O'
	jsr krnl_write_lcd_charac
	lda #'K'
	jsr krnl_write_lcd_charac
	
	;ACIA init code
	
	sta acia_stat ; soft reset
	lda #$09
	sta acia_comm

	lda #$1F ; full speed at 19200 baud 
	sta acia_ctrl ;
	clc

; send greeting string over serial 

	lda #$00
	sta serial_string_send_low
	lda #$B0
	sta serial_string_send_high
	jsr krnl_send_string_serial ; print the greeting string over serial 

ram_test: ; test if ram from 0x0000-0x3FFF is available 
			; stack is empty at this point so we shouldn't worry about anything

	lda #$55
	sta $00
	sta $01

	lda $00 
	cmp #$55 ; test 
	bne ram_test_error
	lda $01
	cmp #$55 ; test 
	bne ram_test_error

	; now we are sure we can use this location to store our address counter to test the rest

	lda #02
	sta $00
	lda #00
	sta $01

	lda #$55
	ldy #00

ram_cont:

	sta ($00),Y
	lda ($00),Y

	cmp #$55 ; test
	bne ram_test_error

	; we need a 16 bit counter 

	ldx $00 ; load lower byte of address ( counter )
	cpx #$ff
	beq adjust_address
	inc $00 ; increment address
	jmp _cont

adjust_address :

	inc $01 ; increment upper byte 
	ldx #00
	stx $00  ; reset lower byte

_cont:

	; check is we reached the upper boundary yet, when A14 is high 
	ldx $01 ; upper byte of address
	cpx #$40 ; test for A14

	bne ram_cont

	jmp ram_test_success


ram_test_error:

	lda #(ram_error_message & 0xFF) ; lower byte first
	sta serial_string_send_low
	lda #(ram_error_message >> 8 ) ; higher byte first 
	sta serial_string_send_high

	jsr krnl_send_string_serial ; send error message over serial 

	jmp * ; stay here if error 

ram_test_success:

	lda #(ram_ok_message & 0xFF )
	sta serial_string_send_low
	lda #(ram_error_message >> 8 )
	sta serial_string_send_high

	jsr krnl_send_string_serial ; send ok message over serial

	cli ; enable interrupts
 
; ********************************************************* init done falls through to augustiner monitor :) 
	ldy #-2 
 ; CURRENT MONITOR PROGRAM
augustiner: ; for now takes arguments in accumulator
    
notcr:

	cmp #ESC ; is it the escape key ? 
	beq getline  

	iny
	bpl getchar ; auto esc if line longer than 127 characters

getline:
	lda #$0A
	jsr krnl_send_chr_serial
	lda #CR
	jsr krnl_send_chr_serial

escape:
	lda #PROMPT
	jsr krnl_send_chr_serial 

	ldy #0 ; reset y

getchar:
	jsr krnl_rx_serial ; wait for character
	sta line_buffer,Y
	jsr krnl_send_chr_serial ; echo to serial
	
	cmp #CR
	bne notcr

	;falls through if CR since we have a line 

; parse the line since we have it

	ldy #-1 ; reset index , -1 since we will pass through iny 
	lda #0 ; set default mode to single listing  
	tax 

setmode:

	sta MODE 


skip:
	iny

next_token:
	lda line_buffer,Y
	cmp #" " ;  skip spaces 
	beq skip
	cmp #CR 
	beq getline ; done restart 
	cmp #"." ; block listing mode
	beq setmode ;set mode
	cmp #":" ; set STOR mode 
	beq setmode 
	cmp #"S" ; check for load from serial mode 
	beq setmode
	cmp #"R" ; check for run mode 
	bne notrun ; run program from last location XAML
	jmp run 
notrun:
	stx L ; x = 0 
	stx H
	sty YSAV ; save Y index for later 

nexthex:

	lda line_buffer,Y ; get next ascii byte
	eor #$30 ; 0-9 : $30-$39 
	cmp #10 ; check if within range 0-9
	bcc parse ;ok we are done
	; if not check if it is within A-F

	adc #$88 ; map letter from "A"-"F" to $FA-FF
	; we need the $F before the first digit since it will be shifted out 
	cmp #$FA
	bcs parse 
	; try to map "a" - "f" to $FA-$FF and check again 

	adc #$20 ; $20 difference between A and a 
	cmp #$FA
	bcc not_hex
	
parse:

	; shift nibble to MSD , since we want to use C bit thereafter 
	asl
	asl
	asl
	asl

shift_store: ; shift hex nibble into L and H locations 

	ldx #4 ;  we will shift 4 times

shift_again:
	asl ; MSB to carry
	rol L ; shift MSB into both L and H combined 
	rol H 
	dex
	bne shift_again
	iny ; increment index to a possible next hex digit 
	bne nexthex

not_hex:

	; check if we have at least one hex digit 
	cpy YSAV
	beq getline ; no restart 

	lda MODE
	cmp #"." ; multiple listing mode
	beq xamnext
	cmp #"S" ; load from serial mode 
	bne not_serial
	jmp load_serial
not_serial:
	cmp #":" ; check if STOR mode
	bne  notstormode

stormode: ; ************* STORMODE 

	lda L
	sta (STL,X)
	inc STL
	bne next_token
	inc STH
hello:
	jmp next_token
	
	; fall through to print address and data 
notstormode:

	ldx #2
setadr:

	lda L-1,X
	sta STL-1,X
	sta XAML-1,X
	dex
	bne setadr

nxtprnt:
	bne prdata ; used for branch after MOD8 to print new line 
	lda #$0A ; new line feed 
	jsr krnl_send_chr_serial
	lda #CR
	jsr krnl_send_chr_serial

	lda XAMH
	jsr krnl_print_hex
	lda XAML
	jsr krnl_print_hex
	lda #":"
	jsr krnl_send_chr_serial
	
prdata:
	lda #" "
	jsr krnl_send_chr_serial
	lda (XAML,X)
	jsr krnl_print_hex

xamnext:

	stx MODE ; x = 0 dunno why 
	; now check if (XAMH;XAML) still < (L;H) 
	lda XAML ; 
	cmp L
	lda XAMH
	sbc H
	bcs hello  ; we are not less , done ! , continue line parsing 

	inc XAML ; increment index of address 
	bne mod8 ; no carry from incrementing XAML
	inc XAMH 

mod8:
	lda XAML
	and #$07 ; if 0 then we have x % 8 == 0 
	bpl nxtprnt ; always taken 

; *******************************

run : jmp (XAML) 

; **********************************
; load bytes from serial, place them at address XAMH;XAML and load (H;L) bytes

load_serial:

	ldx #0

load_next_byte:
	cpx L
	bne not_done
	cpX H
	beq load_done
not_done:
	jsr krnl_rx_serial ; wait for byte
	bit ACIA_ERROR ; check for errors 
	bmi acia_error
	sta (XAML,X) ; store

	jsr krnl_print_hex
	lda #" "
	jsr krnl_send_chr_serial

	; decrement counter 
	dec L 
	bpl dec_ok ; no borrow 
	dec H 
dec_ok:
	; increment XAML
	inc XAML 
	bne load_next_byte; no carry 
	inc XAMH
	bne load_next_byte ; always taken 
load_done:

	jmp next_token ; goto to monitor 

acia_error:

	lda #(acia_error_message & 0xFF) ; lower byte first
	sta serial_string_send_low
	lda #(acia_error_message >> 8 ) ; higher byte first 
	sta serial_string_send_high

	jsr krnl_send_string_serial ; send error message over serial 

	jmp next_token
;***********************************************************	
;*                                                         *
;*                KERNEL_FUNCTIONS                         *
;*                                                         *
;***********************************************************


krnl_print_hex: ; print the hex value that is in the accumulator

	pha
	pha

	lsr 
	lsr
	lsr
	lsr
	
	jsr krnl_convert_nibble_hex ; convert higher nibble first 
	jsr krnl_send_chr_serial

	pla

	jsr krnl_convert_nibble_hex
	jsr krnl_send_chr_serial

	pla

	rts


krnl_print_lcd_hex: ; print the hex value that is in accumulator

	pha
	pha

	lsr 
	lsr
	lsr
	lsr
	
	jsr krnl_convert_nibble_hex ; convert higher nibble first 
	jsr krnl_write_lcd_charac

	pla

	jsr krnl_convert_nibble_hex
	jsr krnl_write_lcd_charac

	pla

	rts

krnl_convert_nibble_hex ; converts the lower nibble in A to hex

	and #$0f 
	ora #"0" ; add "0"
	cmp #"9"+1 ; check if we are passed "0"-"9"
	bcc	krnl_convert_done
	adc #6 ; put the character in the "A"-"F" offset

krnl_convert_done:

	rts

krnl_send_string_serial: ; expects the string location to be null terminated and the location in the variable defined above 
							; string is limited to 127 characters 
	pha
	phy

	ldy #0

cont_sending:	

	lda (serial_string_send_low),Y
	cmp #00
	beq string_sending_done
	jsr krnl_send_chr_serial

	iny
	jmp cont_sending

string_sending_done:

	
	ply
	pla

	rts

krnl_send_chr_serial: ; expects input argument in accumulator

	sta acia_data
	jsr krnl_tx_byte_delay

	rts

	;***************************************************************************************

krnl_rx_serial: ; this routine reads from the queue, and waits for the data if none is available 

	phx
	ldx q_front
wait:
	cpx q_back ; check if back != front 
	beq wait ; data is available in the queue

	lda serial_buffer,X
	inx 					; increment front buffer and store back 
	stx q_front
	
	plx
	rts
	;***********************************************************************************

krnl_tx_byte_delay:

    phx
	ldx #$80 ; TODO: calculate exact value we need

cnt:
	dex
	bne cnt
	plx

	rts

krnl_init_lcd:
	
	lda #$00
	sta porta ; E set to 0 
	jsr delay ; wait for > 30 ms
	lda #$30
	jsr krnl_send_lcd_instr
	jsr delay
	jsr krnl_send_lcd_instr
	jsr delay
	jsr krnl_send_lcd_instr
	jsr delay
	
	lda #$38
	jsr krnl_send_lcd_instr
	lda #$10
	jsr krnl_send_lcd_instr
	lda #$0C
	jsr krnl_send_lcd_instr
	lda #$06
	jsr krnl_send_lcd_instr

	lda #$01
	jsr krnl_send_lcd_instr ; clear display 

	;set dram address

	lda #$80
	jsr krnl_send_lcd_instr

	rts


delay:	; used by lcd init 

	phx
	phy

	ldy #$80
loop3:

	ldx #$ff
loop2:	dex
	bne loop2

	dey 
	bne loop3

	; restore the 3 registers

    ply
    plx
	
	rts

fast_delay: ; used for sending lcd characters pulse width >= 300ns 
	pha

	lda #200
dec_more:
	dec ; 2 cycles 
	bne dec_more ; 3 cycles on average 

	pla
	rts

krnl_send_lcd_instr:	
	
	sta portb
	ldx #$01 ; instruction - write - E = 1
	stx porta
	jsr delay
	ldx #$00
	stx porta 

	rts

krnl_write_lcd_charac:
	
	pha
	phx

	sta portb
	ldx #$05 ; data - write - E = 1
	stx porta
	jsr fast_delay
	ldx #$04 ; R/S still high
	stx porta

    plx
    pla

	rts

acia_routine: ; reads into line_buffer stored at $300 goes upto $3ff 

	pha
	phx
	ldx q_back
	lda acia_stat ; just to clear
	lda acia_data

	; store the data in the circular queue
	; store at back and increment back then pray for no buffer overflow 
	; back points to an empty location

	sta serial_buffer,X
	inx  ; increment back pointer and store it back 
	stx q_back

	plx
	pla
	rti

	.org $b000

	; **************************************
	; PROGRAM STRINGS

serial_greeting: db "Welcome to the Robz6502 SBC project" , $A , $D , $00 
ram_ok_message: db "memory: 0x000-0x3FFF OK..." , $A , $D, $00 
ram_error_message : db "RAM TEST ERROR: could not R/W from RAM" , $A , $D , $00
monitor_help_message : db "Augustiner Monitor Program:" , $A , $D , "{h}: to display this message"
	db $A , $D , "{m}: display zero page memory" , $A , $D , $00
acia_error_message: db "ACIA overrun!! exiting" , $A , $D , $00 

	.org $fffc ; 6502 reset vector
	.word $8000
	.word acia_routine ; no interrupt routine 


