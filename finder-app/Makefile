
CC=gcc
#Set empty CROSS_COMPILE if not set by command line
CROSS_COMPILE ?=
TARGET = writer
SRC = writer.c

all: ${TARGET}

${TARGET}: ${SRC}
	${CROSS_COMPILE}${CC}  ${SRC} -o ${TARGET}

clean: 
	rm ${TARGET}