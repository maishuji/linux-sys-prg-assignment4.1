
CC=gcc
# CROSS_COMPILE is set to empty when the varaiable is not specified in command line
# Examle of use : make CROSS_COMPILE=aarch64-none-linux-gnu- all
CROSS_COMPILE ?=
TARGET = writer
SRC = writer.c

all: ${TARGET}

${TARGET}: ${SRC}
	${CROSS_COMPILE}${CC}  ${SRC} -o ${TARGET}

clean: 
	-rm -if ${TARGET}