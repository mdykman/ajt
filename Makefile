

BISONPREFIX=json
CFLAGS= -DBISONPREFIX=${BISONPREFIX}
LDFLAGS=-lm

all: json-tool

clean:
	-rm ajson.l.o ajson.y.o ajson.y.c ajson.l.c json-tool

#minify   :  ajson.y.o ajson.l.o minify.o
#	${CC} -lm ajson.y.o ajson.l.o minify.o -o minify

json-tool : ajson.y.o ajson.l.o json-tool.o
#	${CC} -lm ajson.y.o ajson.l.o json-tool.o -o json-tool

ajson.y.c : ajson.lex ajson.y 
	flex  --header-file=ajson.l.h --prefix ${BISONPREFIX} -o ajson.l.c ajson.lex
	yacc -p ${BISONPREFIX} -r all --defines=ajson.y.h -o ajson.y.c ajson.y

ajson.l.c : ajson.lex ajson.y
	flex  --header-file=ajson.l.h --prefix ${BISONPREFIX} -o ajson.l.c ajson.lex
	flex  --header-file=ajson.l.h --prefix ${BISONPREFIX} -o ajson.l.c ajson.lex


#`%.c %.o :
#	${CC} ${CFLAGS} -c -o $@ $< 

