

BISONPREFIX=json
CFLAGS= -DBISONPREFIX=${BISONPREFIX} -fPIC
LDFLAGS=-lm

all:  
	$(MAKE) jpath
	$(MAKE) fullset

jpath: jpath/jpath.l.o jpath/jpath.y.o

jpath/jpath.l.o jpath/jpath.y.o : 
	cd jpath && $(MAKE) all

fullset: json-tool libajt.so libajt.a

clean:
	cd jpath && $(MAKE) clean
	-rm ajson.l.o ajson.y.o ajson.y.c ajson.l.c json-tool libajt.a libajt.so


libajt.a	: ajson.l.o ajson.y.c
	ar rcs  libajt.a ajson.y.o ajson.l.o 

libajt.so	: ajson.l.o ajson.y.c
	${CC} -shared -Wl,-soname,libajt.so ajson.y.o ajson.l.o  -o libajt.so

json-tool : ajson.y.o ajson.l.o json-main.o
	${CC} -lm ajson.y.o ajson.l.o json-main.o -o json-tool

ajson.y.c ajson.l.c ajson.y.h ajson.l.h : ajson.y ajson.lex
	flex  --header-file=ajson.l.h --prefix ${BISONPREFIX} -o ajson.l.c ajson.lex
	yacc -p ${BISONPREFIX} -r all --defines=ajson.y.h -o ajson.y.c ajson.y

