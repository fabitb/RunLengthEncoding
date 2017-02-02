# gepasp makefile
CC=gcc
# todo: Optimisierung und Name anpassen
TARGET=asmCompress
OPTIMIZATION=0
COPTS=-g -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=hard -marm -o $(TARGET) -O$(OPTIMIZATION)

all: bin

bin: rleEncodingASM.c compress.S
	$(CC) $(COPTS) $+ 

clean:
	rm $(TARGET)
