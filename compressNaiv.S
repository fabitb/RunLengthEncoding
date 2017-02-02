.global _asm_simple_compress

.code 32

## _asm_simple_compress( char *data, char *result, int dataSize, int dataWidth )
##r0 to r3 parameters
## can we just write those #0 in a char???
## TODO adjust parameters so we can return a resultSize (r7)

##start
_asm_simple_compress:
	push {r4-r10, lr};

	##save addresses of arrays
	mov r4, r0;
	mov r5, r1;
	##r6 data counter
	mov r6, #1;
	##r7 result counter
	mov r7, #0;

	##r8 last, r9 current; load first pixel
	ldrb r9, [r4];
	add r4, r4, #1;

	##run counter
	mov r10, #0;

mainloop:
	cmp r6, r2;
	beq end;

	##get new pixel and run++
	mov r8, r9;
	ldrb r9, [r4];
	add r4, r4, #1;
	add r10, r10, #1;

	## TODO end of line checking with modulo?

	## run 255 checking
	cmp r10, #255;
	beq storeRun;

	## check for same pixels, if ye, skip storing
	cmp r8, r9;
	beq continueLoop;

storeRun:
	## store run in result
	strb r10, [r5];
	add r5, r5, #1;
	strb r8, [r5];
	add r5, r5, #1;
	add r7, r7, #2;
	mov r10, #0;

continueLoop:
	add r6, r6, #1;
	b mainloop;

end: 
	#write end of file;
	strb #0, [r5];
	add r5, r5, #1;
	strb #1, [r5];
	add r5, r5, #1;
	add r7, r7, #2;

	pop {r4-r10, pc};
