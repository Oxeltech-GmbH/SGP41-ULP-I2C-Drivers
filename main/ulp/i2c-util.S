#include "soc/rtc_cntl_reg.h"
#include "soc/rtc_io_reg.h"
#include "soc/soc_ulp.h"

#include "stack.S"

.text

write_intro:
	psr
	jump i2c_start_cond

	ld r2,r3,28 // Address
	lsh r2,r2,1
	psr
	jump i2c_write_byte
	jumpr popfail,1,ge

	ld r2,r3,24 // Register
	rsh r2,r2,8
	psr
	jump i2c_write_byte
	jumpr popfail,1,ge

	ld r2,r3,24 // Register
	psr
	jump i2c_write_byte
	jumpr popfail,1,ge


	ret



write_b:
	psr
	jump i2c_start_cond

	ld r2,r3,16 // Address
	lsh r2,r2,1
	psr
	jump i2c_write_byte
	jumpr popfail,1,ge

	ld r2,r3,12 // Register
	rsh r2,r2,8
	psr
	jump i2c_write_byte
	jumpr popfail,1,ge

	ld r2,r3,12 // Register
	psr
	jump i2c_write_byte
	jumpr popfail,1,ge
	ret


.global write48
write48:
	psr
	jump write_intro

	ld r2,r3,16 // Word 1
	rsh r2,r2,8
	psr
	jump i2c_write_byte
	jumpr fail,1,ge

	ld r2,r3,16 // data byte
	psr
	jump i2c_write_byte
	jumpr fail,1,ge

	ld r2,r3,12 // Word 2
	rsh r2,r2,8
	psr
	jump i2c_write_byte
	jumpr fail,1,ge

	ld r2,r3,12 // data byte
	psr
	jump i2c_write_byte
	jumpr fail,1,ge


	ld r2,r3,8 // Word 3
	rsh r2,r2,8
	psr
	jump i2c_write_byte
	jumpr fail,1,ge

	ld r2,r3,8 // data byte
	psr
	jump i2c_write_byte
	jumpr fail,1,ge

	psr
	jump i2c_stop_cond

	move r2,0 // Ok
	ret


read_intro:
	psr
	jump i2c_start_cond

	ld r2,r3,12
	lsh r2,r2,1
	or r2,r2,1 // Address Read
	psr
	jump i2c_write_byte
	jumpr popfail,1,ge

	ret
popfail:
	pop r1 // pop caller return address
	move r2,1
	ret


fail:
	move r2,1
	ret

.global read48
read48:
	psr
	jump read_intro


	move r2,0
	psr
	jump i2c_read_byte
	push r0

	move r2,0
	psr
	jump i2c_read_byte
	push r0

	move r2,0 // last byte
	psr
	jump i2c_read_byte
	push r0


	move r2,0
	psr
	jump i2c_read_byte
	push r0

	move r2,0
	psr
	jump i2c_read_byte
	push r0

	move r2,1 // last byte
	psr
	jump i2c_read_byte
	push r0
	

	psr
	jump i2c_stop_cond


	pop r0
	move r2,CRC_NOx // store result
	st r0,r2,0

	pop r0
	pop r2 // first byte
	lsh r2,r2,8
	or r2,r2,r0
	move r0,r2
	move r2,SRAW_NOx // store result
	st r0,r2,0

	pop r0
	move r2,CRC_VOC // store result
	st r0,r2,0

	pop r0
	pop r2 // first byte
	lsh r2,r2,8
	or r2,r2,r0
	move r0,r2
	move r2,SRAW_VOC // store result
	st r0,r2,0

	move r2,0 // OK
	ret


.global read24
read24:
	psr
	jump read_intro

	move r2,0
	psr
	jump i2c_read_byte
	push r0

	move r2,0
	psr
	jump i2c_read_byte
	push r0

	move r2,1 // last byte
	psr
	jump i2c_read_byte
	push r0
	

	psr
	jump i2c_stop_cond


	pop r0
	move r2,CRC_VOC // store result
	st r0,r2,0

	pop r0
	pop r2 // first byte
	lsh r2,r2,8
	or r2,r2,r0
	move r0,r2
	move r2,SRAW_VOC // store result
	st r0,r2,0


	move r0,0
	move r2,CRC_NOx // store result
	st r0,r2,0

	move r0,0
	move r2,SRAW_NOx // store result
	st r0,r2,0

	move r2,0 // OK
	ret





.global write0
write0:
	psr
	jump write_b

	psr
	jump i2c_stop_cond

	move r2,0 // Ok
	ret



