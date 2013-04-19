

BISONPREFIX=json
CFLAGS= -DBISONPREFIX=${BISONPREFIX}
LDFLAGS=-lm

all: json-test scb minify json-tool

clean:
	-rm ajson.l.o ajson.y.o ajson.y.c ajson.l.c json-test json-tool scb

#minify   :  ajson.y.o ajson.l.o minify.o
#	${CC} -lm ajson.y.o ajson.l.o minify.o -o minify

scb : ajson.y.o ajson.l.o scb.o
#	${CC} -lm ajson.y.o ajson.l.o scb.o -o scb

json-tool : ajson.y.o ajson.l.o json-tool.o
#	${CC} -lm ajson.y.o ajson.l.o json-tool.o -o json-tool

json-test : ajson.y.o ajson.l.o json-test.o
#	${CC} -lm ajson.y.o ajson.l.o json-test.o -o json-test

ajson.y.c : ajson.lex ajson.y 
	yacc -p ${BISONPREFIX} -r all --defines=ajson.y.h -o ajson.y.c ajson.y

ajson.l.c : ajson.lex ajson.y
	flex  --header-file=ajson.l.h --prefix ${BISONPREFIX} -o ajson.l.c ajson.lex


#`%.c %.o :
#	${CC} ${CFLAGS} -c -o $@ $< 

