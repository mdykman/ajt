
all : jpath.y.o jpath.l.o

jpath.y.h : jpath.y.c

jpath.y.c : jpath.y
	yacc -p jpath --defines="jpath.y.h" -o jpath.y.c jpath.y

jpath.l.c: jpath.lex
	flex jpath.lex
