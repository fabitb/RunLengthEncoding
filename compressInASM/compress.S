.global _asm_advanced_compress

.code 32

## expects a square image
## _asm_advanced_compress( char *data, char *result, int result_size, int data_width );


_asm_advanced_compress:
	push {r4-r10, r12, lr};

	## r0 data position
	## r1 result position
	## r2 max result size
	## r3 data width -> data size

	## r4 data counter
	mov r4, #1;

	## r5 result counter
	mov r5, #0;
	## s1 is used to store result counter when in absolute mode

	## r6 last, r7 current
	ldrb r7, [r0];
	add r0, r0, #1;

	##run counter
	mov r8, #0;

	## r9 image width
	mov r9, r3;
	## save width in s4
	vmov s4, r9;

	## compute image size ( must be square image )
	mul r3, r9, r9;

	## s0 isAbsoluteMode
	mov r10, #0;
	vmov s0, r10;

	## r12 absoluteStartIndex
	mov r12, #0;

	## s2 absoluteRun
	vmov s2, r10;

	## s3 forceNormal
	vmov s3, r10;


mainLoop:
	cmp r4, r3;
	beq endOfData;

	## get new pixel
	mov r6, r7;
	ldrb r7, [r0];
	add r0, r0, #1;
	##increase run
	add r8, r8, #1;

	## check if isAbsoluteMode
	vmov r10, s0;
	cmp r10, #0;
	beq encodingMode;

	## ------------------------------------------------------ absoluteMode
	## increment absolutRun counter 
	vmov r10, s2;
	add r10, r10, #1;
	vmov s2, r10;

	##check for end of line
	cmp r4, r9;
	beq absoluteModeEndOfLine;

	## check last == current
	cmp r6, r7;
	beq absoluteModeLastCurrentIsEqual;
	strb r6, [r1];
	add r1, r1, #1;
	add r5, r5, #1;
	mov r8, #0;
	
	## check if result is full
	cmp r2, r5;
	ble hardTerminate;

absoluteModeCheckRunLength:
	## absolute run check run length == 255 
	vmov r10, s2;
	cmp r10, #255;
	beq absoluteModeRunTooLong;

	b continueLoop;


	## -------------------------------------------------------- encodingMode
encodingMode:
	## check end of line
	cmp r4, r9;
	beq endOfLine;

	## check last == current
	cmp r6, r7;
	beq checkMaxRunLength;
	
	## do last != current stuff here 
	cmp r8, #3;
	## branch if r8 >= #3
	bge endEncodedRun;
	## check for forced encoded run
	vmov r10, s3;
	cmp r10, #1;
	beq endEncodedRun;

	## now start absoluteRun mode
	## store startIndex and resultCounter
	## check if result is full first
	add r10, r5, #4;
	cmp r2, r10;
	blt hardTerminate;

	mov r10, #1;
	vmov s0, r10;
	mov r12, r1;
	vmov s2, r8;
	vmov s1, r5;
	mov r10, #0;
	strb r10, [r1];
	add r1, r1, #2;
	strb r6, [r1];
	add r1, r1, #1;
	add r5, r5, #3;
	cmp r8, #2;
	bne endOfLastCurrentComp;
	strb r6, [r1];
	add r1, r1, #1;
	add r5, r5, #1;


endOfLastCurrentComp:
	## set run = 0;
	mov r8, #0;


checkMaxRunLength:
	## do stuff if run == 255
	cmp r8, #255;
	beq handleMaxRunLength;


	## ---------------------------------------------------------- continue main loop
continueLoop:
	add r4, r4, #1;
	b mainLoop;


	## ---------------------------------------------------------- when main loop has ended
endOfData:
	## when mainLoop ended
	vmov r10, s0;
	cmp r10, #0;
	beq endEncodedRunEOF;

	vmov r10, s2;
	cmp r10, #1;
	bgt endAbsoluteRunEOF;

	## check if result is full
	add r10, r5, #4;
	cmp r2, r10;
	blt hardTerminate;

	## store two 1 x runs
	mov r1, r12;
	mov r10, #1;
	strb r10, [r1];
	add r1, r1, #1;
	strb r6, [r1];
	add r1, r1, #1;
	strb r10, [r1];
	add r1, r1, #1;
	strb r7, [r1];
	add r1, r1, #1;
	add r5, r5, #4;

	## --------------------------------------------------------- write EOF and return value
endOfProgram:
	## check if result is full
	add r10, r5, #2;
	cmp r2, r10;
	blt hardTerminate;

	mov r10, #0;
	strb r10, [r1];
	add r1, r1, #1;
	mov r10, #1;
	strb r10, [r1];
	add r1, r1, #1;
	add r5, r5, #2;

	##return value
	mov r0, r5;

	pop { r4-r10, r12, pc };



	## --------------------------------------------------------- extra/ special branches
	## -------------------- encoding mode specials
endOfLine:
	## check if resut is full
	add r10, r5, #4;
	cmp r2, r10;
	blt hardTerminate;

	## increment width
	vmov r10, s4;
	add r9, r9, r10;
	## save run
	strb r8, [r1];
	add r1, r1, #1;
	strb r6, [r1];
	add r1, r1, #1;

	## add end of line
	mov r10, #0;
	strb r10, [r1];
	add r1, r1, #1;
	strb r10, [r1];
	add r1, r1, #1;

	## increase result counter, run = 0, forceNormal = 0;
	add r5, r5, #4;
	mov r8, #0;
	mov r10, #0;
	vmov s3, r10;

	b continueLoop;


handleMaxRunLength:
	## check if result is full
	add r10, r5, #2;
	cmp r2, r10;
	blt hardTerminate;

	## save run and continue the main loop afterwards
	strb r8, [r1];
	add r1, r1, #1;
	strb r6, [r1];
	add r1, r1, #1;

	add r5, r5, #2;
	mov r8, #0;
	mov r10, #0;
	vmov s3, r10;
	b continueLoop;


endEncodedRun:
	## check if result is full
	add r10, r5, #2;
	cmp r2, r10;
	blt hardTerminate;

	## simply safe run
	strb r8, [r1];
	add r1, r1, #1;
	strb r6, [r1];
	add r1, r1, #1;
	add r5, r5, #2;

	mov r10, #0;
	vmov s3, r10;
	b endOfLastCurrentComp;


	## ------------------------- EOF specials
endEncodedRunEOF:
	## check if result is full
	add r10, r5, #2;
	cmp r2, r10;
	blt hardTerminate;

	## safe run when at the end of file/data
	add r8, r8, #1;
	strb r8, [r1];
	add r1, r1, #1;
	strb r6, [r1];
	add r1, r1, #1;
	add r5, r5, #2;
	b endOfProgram;

endAbsoluteRunEOF:
	## check if result is full
	add r10, r5, #1;
	cmp r2, r10;
	blt hardTerminate;

	## safe run in absolute mode when end of file/data
	strb r7, [r1];
	add r1, r1, #1;
	add r5, r5, #1;
	add r12, r12, #1;
	vmov r10, s2;
	add r10, r10, #1;
	strb r10, [r12];
	b endOfProgram;


	## ---------------------------- absolute Mode specials
absoluteModeEndOfLine:
	## end of line occurs in absolute mode
	## increment r9
	vmov r10, s4;
	add r9, r9, r10;
	## check if absoluteRun is large enough
	vmov r10, s2;
	cmp r10, #2;
	ble absoluteModeSafeTwoEncoded;

	## check if result is full
	add r10, r5, #1;
	cmp r2, r10;
	blt hardTerminate;

	## safe absoluteRun
	add r12, r12, #1;
	vmov r10, s2;
	strb r10, [r12];
	strb r6, [r1];
	add r1, r1, #1;
	add r5, r5, #1;

	## check if odd or even absoluteRun
	AND r10, r10, #1;
	cmp r10, #0;
	beq absoluteModeWriteEndOfLine;

	## check if result is full
	add r10, r5, #1;
	cmp r2, r10;
	blt hardTerminate;

	## odd absoluteRun, add a 0 at the end
	mov r10, #0;
	strb r10, [r1];
	add r1, r1, #1;
	add r5, r5, #1;

absoluteModeWriteEndOfLine:
	## check if result is full
	add r10, r5, #2;
	cmp r2, r10;
	blt hardTerminate;

	## write double 0
	mov r10, #0;
	strb r10, [r1];
	add r1, r1, #1;
	strb r10, [r1];
	add r1, r1, #1;
	add r5, r5, #2;

	## reset tracker values
	vmov s2, r10;
	vmov s0, r10;
	mov r8, #0;
	b continueLoop;

absoluteModeSafeTwoEncoded:
	## check if result is full
	add r10, r5, #1;
	cmp r2, r10;
	blt hardTerminate;

	##safe two pixels as seperate encoded runs
	## overwrite the 0 indicator and last written pixel
	sub r1, r1, #3;
	mov r10, #1;
	strb r10, [r1];
	add r1, r1, #1;
	ldrb r10, [r1, #1];
	strb r10, [r1];
	add r1, r1, #1;
	mov r10, #1;
	strb r10, [r1];
	add r1, r1, #1;
	strb r6, [r1];
	add r1, r1, #1;
	add r5, r5, #1;
	b absoluteModeWriteEndOfLine;


	## ------------------------------
absoluteModeLastCurrentIsEqual:
	## last == current during absolute mode
	## check if absolut run needs to be ended ( run > 1  -> 3 equal pixels )
	cmp r8, #1;
	bgt absoluteModeFoundThreeEqualPixel;
	
	## check if result is full
	add r10, r5, #1;
	cmp r2, r10;
	blt hardTerminate;

	## store pixel and continue with run == 255 check 
	strb r6, [r1];
	add r1, r1, #1;
	add r5, r5, #1;
	b absoluteModeCheckRunLength;


absoluteModeFoundThreeEqualPixel:
	## found run of three equal pixel -> terminate absolute run
	vmov r10, s2;
	sub r10, r10, r8;
	cmp r10, #3;
	bge absoluteModeEndAndStartEncoded;

	## absoluteRun is too short
	## revert to beginning and force encoded run
	mov r10, #1;
	vmov s3, r10;
	mov r1, r12;
	vmov r10, s2;
	sub r4, r10;
	sub r0, r10;
	ldrb r7, [r0];
	## revert r5
	vmov r5, s1;

absoluteModeResetTrackerValues:
	mov r10, #0;
	mov r8, #0;
	vmov s0, r10;
	vmov s2, r10;
	b absoluteModeCheckRunLength;


absoluteModeEndAndStartEncoded:
	## end absoluteRun
	add r12, r12, #1;
	strb r10, [r12];
	## revert the last equal pixels
	## ( they will be safed in encoded mode )
	sub r1, r1, #1;
	sub r5, r5, #1;
	sub r0, r0, #2;
	sub r4, r4, #2;
	
	## check for odd absoluteRun
	AND r10, r10, #1;
	cmp r10, #0;
	beq absoluteModeResetTrackerValues;

	## check if result is full
	add r10, r5, #1;
	cmp r2, r10;
	blt hardTerminate;

	## absoluteRun is odd, add 0 at the end
	mov r10, #0;
	strb r10, [r1];
	add r1, r1, #1;
	add r5, r5, #1;
	b absoluteModeResetTrackerValues;

	## ------------------------------
absoluteModeRunTooLong:
	## absoluteRun == 255 so it needs to be terminated
	## safe absoluteRun after the 0 indicator
	add r12, r12, #1;
	strb r10, [r12];

	## reset tracker values
	mov r8, #0;
	mov r10, #0;
	vmov s0, r10;
	vmov s2, r10;
	b continueLoop;




	## called when result has no space left
	## programm will be ended with -1 as return
hardTerminate:
	mov r0, #0;
	sub r0, r0, #1;
	pop { r4-r10, r12, pc };
