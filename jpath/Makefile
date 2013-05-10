
#CFLAGS=-std=c99

all : jpath.y.o jpath.l.o

clean :
	-rm *.o jpath.y.c jpath.l.c jpath.y.h

jpath.l.c jpath.y.c jpath.y.h : jpath.y jpath.lex
	yacc -p jpath --defines="jpath.y.h" -o jpath.y.c jpath.y
	flex jpath.lex
