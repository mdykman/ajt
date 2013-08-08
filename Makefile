
BISONPREFIX=json
CFLAGS= -DBISONPREFIX=${BISONPREFIX} -fPIC -DDEBUG
LDFLAGS=-lm

GENERATED_FILES=	\
	ajson.l.o \
	ajson.y.o \
	ajson.y.c \
	ajson.l.c \
	ajson.y.h \
	ajson.l.h \
	ajt.o \
	ajt 
	
all: jpath ajt 

jpath: jpath/jpath.l.o jpath/jpath.y.o

jpath/jpath.l.o jpath/jpath.y.o : jpath/jpath.y jpath/jpath.lex
	cd jpath && $(MAKE) all

fullset: ajt 

clean:
	cd jpath && $(MAKE) clean
	-rm ${GENERATED_FILES}

libajt.a	: ajson.l.o ajson.y.c
	ar rcs  libajt.a ajson.y.o ajson.l.o 

libajt.so	: ajson.l.o ajson.y.c
	${CC} -shared -Wl,-soname,libajt.so ajson.y.o ajson.l.o  -o libajt.so

ajt : ajson.y.o ajson.l.o ajt.o 
	${CC} ajson.y.o ajson.l.o ajt.o jpath/jpath.l.o jpath/jpath.y.o -lm -o ajt

ajson.y.c ajson.l.c ajson.y.h ajson.l.h : ajson.y ajson.lex
	flex  --header-file=ajson.l.h --prefix ${BISONPREFIX} -o ajson.l.c ajson.lex
	yacc -p ${BISONPREFIX} -r all --defines=ajson.y.h -o ajson.y.c ajson.y

