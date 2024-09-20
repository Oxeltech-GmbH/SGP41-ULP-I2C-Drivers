#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "stack.S"



.set SGP41_ADDR,0x59 // 7-bit address

.set EXECUTE_CONDITIONING,0x2612
.set MEASURE_RAW_SIGNALS,0x2619
.set TURN_HEATER,0x3615 

.set HEX_PER1,0x8000
.set HEX_PER2,0xA266
.set HEX_PER3,0x6693


/* Define variables, which go into .bss section (zero-initialized data) */
	.bss

	.global temp
temp:	.long 0

	.global SRAW_VOC
SRAW_VOC: .long 0

	.global CRC_VOC
CRC_VOC: .long 0

	.global CRC_NOx
CRC_NOx: .long 0

	.global SRAW_NOx
SRAW_NOx: .long 0


	/* Code goes into .text section */
	.text

.global sgp41_measure_raw_signals
sgp41_measure_raw_signals:

	move r1,SGP41_ADDR
	push r1
	move r1,MEASURE_RAW_SIGNALS
	push r1
	move r1,HEX_PER1
	push r1
	move r1,HEX_PER2
	push r1
	move r1,HEX_PER3
	push r1
	psr
	jump write48
	add r3,r3,5 // remove 5 arguments from stack
	move r0,r2 // test for error in r2
	jumpr fail,1,ge

	// Wait 50ms for sensor computation
	move r2,50
	psr
	jump waitMs


	// Read 48 bit result
	move r1,SGP41_ADDR
	push r1
	psr
	jump read48
	add r3,r3,1 // remove call parameters from stack

	move r0,r2 // test for error
	jumpr fail,1,ge
	
	ret


.global sgp41_execute_conditioning 
sgp41_execute_conditioning :

	move r1,SGP41_ADDR
	push r1
	move r1,EXECUTE_CONDITIONING
	push r1
	move r1,HEX_PER1
	push r1
	move r1,HEX_PER2
	push r1
	move r1,HEX_PER3
	push r1
	psr
	jump write48
	add r3,r3,5 // remove 5 arguments from stack
	move r0,r2 // test for error in r2
	jumpr fail,1,ge

	// Wait 50ms for sensor computation
	move r2,50
	psr
	jump waitMs



	// Read 24 bit result
	move r1,SGP41_ADDR
	push r1
	psr
	jump read24
	add r3,r3,1 // remove call parameters from stack

	move r0,r2 // test for error
	jumpr fail,1,ge

	ret


fail:
	move r1,temp
	move r0,0 // 0 signals error
	st r0,r1,0
	ret


	.global sgp41_turn_heater_off
sgp41_turn_heater_off:
	move r1,SGP41_ADDR
	push r1
	move r1,TURN_HEATER
	push r1

	psr
	jump write0
	add r3,r3,2 // remove 2 arguments from stack
	move r0,r2 // test for error in r2
	jumpr fail,1,ge
	ret



// Wait for r2 milliseconds
waitMs:
	wait 8000
	sub r2,r2,1
	jump doneWaitMs,eq
	jump waitMs
doneWaitMs:
	ret
