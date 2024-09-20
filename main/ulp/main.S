/*
 * Demo of I2C ULP routines
 */

#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "stack.S"



/* Define variables, which go into .bss section (zero-initialized data) */
	.bss


	.global	counter
counter: .long 0

	.global	offset
offset: .long 0



	.global	main_counter
main_counter: .long 0


	.global	wait_counter
wait_counter: .long 0



	.global VOC_array
VOC_array:
	.fill 150,4

	

	.global VCRC_array
VCRC_array:
	.fill 150,4



	.global NOX_array
NOX_array:
	.fill 150,4

	.global NCRC_array
NCRC_array:
	.fill 150,4


	.global stack
stack:
	.skip 100
	.global stackEnd
stackEnd:
	.long 0


	/* Code goes into .text section */
	.text
	.global entry
entry:
	move r3,stackEnd




Readwhile:
	// Read the SGP41

	move r2,740
	psr
	jump waitMs



ReadMeasurement:

	psr
	jump sgp41_measure_raw_signals

	move r2,170
	psr
	jump waitMs


	// GPIO2 LED ON
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + 12, 1, 1)

	psr
	jump sgp41_measure_raw_signals

	// GPIO2 LED OFF
	WRITE_RTC_REG(RTC_GPIO_OUT_REG, RTC_GPIO_OUT_DATA_S + 12, 1, 0)

    psr
	jump sgp41_turn_heater_off

	psr
	jump StoreData

	jumpr Readwhile,150,lt
    jump wakeUp




wakeUp:

    move r1,main_counter
	move r0,0
	st r0,r1,0 // rst main_counter

	move r1,offset
	move r0,0
	st r0,r1,0 // rst offset

	/* Wake up the SoC, end program */
	wake
	/* Stop the wakeup timer so it does not restart ULP */
	WRITE_RTC_FIELD(RTC_CNTL_STATE0_REG, RTC_CNTL_ULP_CP_SLP_TIMER_EN, 0)

waitNext:
	WAIT 0xFFFF
    move r1,wait_counter
	ld r0,r1,0
	add r0,r0,1
	st r0,r1,0 // increment wait_counter
	jumpr waitNext,18,lt
	move r1,wait_counter
	move r0,0
	st r0,r1,0 // rst wait_counter
	halt



// Wait for r2 milliseconds
waitMs:
	wait 8000
	sub r2,r2,1
	jump doneWaitMs,eq
	jump waitMs
doneWaitMs:
	ret



StoreData:
    move r1,offset
	ld r2,r1,0
   

    move r1,SRAW_VOC
	ld r0,r1,0
	move r1,VOC_array
	add r1,r1,r2
	st r0,r1,0

	move r1,SRAW_NOx
	ld r0,r1,0
	move r1,NOX_array
	add r1,r1,r2
	st r0,r1,0

	move r1,CRC_NOx
	ld r0,r1,0
	move r1,NCRC_array
	add r1,r1,r2
	st r0,r1,0

	move r1,CRC_VOC
	ld r0,r1,0
	move r1,VCRC_array
	add r1,r1,r2
	st r0,r1,0
	
    move r1,offset
	ld r0,r1,0
	add r0,r0,1
	st r0,r1,0 // increment offset

	move r1,main_counter
	ld r0,r1,0
	add r0,r0,1
	st r0,r1,0 // increment counter
	ret