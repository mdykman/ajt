%{
// jpath

// /**/field/*
// **/f/if(../dept = 32)/id

// */users/*/group(dept)
// */users/{id,dept}


// */[id,dept]

// count(**/email)
// **/email/count()

#include "jpath.l.h"

#define JPATHALLOC(x)  malloc(x)
#define JPATHFREE(x)  free(x)

#ifndef BISONPREFIX
#define BISONPREFIX jpath
#endif

#define ___BINDSTR(x,y) x ## y
#define BINDSTR(x,y) ___BINDSTR(x,y)

#define SCANSTRING BINDSTR(BISONPREFIX,_scan_string)
#define SWITCHTOBUFFER BINDSTR(BISONPREFIX,_switch_to_buffer)
#define DELETEBUFFER BINDSTR(BISONPREFIX,_delete_buffer)
#define PARSE BINDSTR(BISONPREFIX,parse)
#define INPUTSTREAM BINDSTR(BISONPREFIX,in)


#define LOCATION BINDSTR(BISONPREFIX,lloc)



%}

%code requires {
	typedef struct __jpathnode {
	} jpathnode;
}
%union {
	jpathnode *jp;
	char*str;
}

%locations

%type<str> chars

%token<str> LABEL CHAR  
%token FLOAT 
%token INTEGER

%token<jp> DDOT TDOT DSTAR 
%token<str> LTE GTE NE SQRT POW FLOOR CIEL ROUND RAND DIV
%token<str> NUMBER TEXT SCALAR ARRAY OBJECT NULLV NAME
%token<str> GROUP IF SORT UNIQ KEY VALUE AVG MIN MAX SIZE SUM
%token<str> SIN COS LOG
%token<str> STRINGF CONCAT UPPER LOWER EQ NEQ GT LT GTES LTES SUBSTR MATCH INDEXOF RSUB

%% 

jpath : abspath 

abspath 
	: relpath
	| '/' relpath

relpath
	: cmpexp 
	| relpath '/' cmpexp

cmpexp
   : orexp
	| cmpexp cmpop orexp

cmpop
	: '='
	| '<'
	| '>'
	| NE
	| GTE
	| LTE

orexp
	: mathexp
	| orexp '|' mathexp

mathexp 
	: pathstep 
	| mathexp mathop pathstep

mathop 
	: '+'
	| '-'
	| '*'
	| DIV
	| '%'

pathstep
   : step 
	| test 
	| dex
	| pexp
	| pathstep dex

test
   : nametest
	| kindtest

nametest: label

label: LABEL

kindtest 
	: ttop '(' ')'

ttop 
	: NUMBER
   | TEXT
   | SCALAR
   | ARRAY
   | OBJECT
   | NULLV

pexp
	: var
	| const
	| fcall
	| '(' jpath ')'

fcall 
	: func '(' plist ')'
	| func '(' ')'
	
func 
	: builtin
	| label

plist
	: jpath
	| plist ',' jpath

step: fstep 
	| bstep
	| '.'

bstep
	: DDOT  
	| TDOT

fstep
	: '*' 
	| DSTAR


const
	: string
	| INTEGER
	| FLOAT

var : '$' label

string
   : dstr { $$ = $1; }
   | sstr { $$ = $1; }

sstr 
	: '"' chars '"' { $$ = $2; }
	| '"' '"'

dstr 
	: '\'' chars '\''
	| '\'' '\''

chars
	: CHAR { $$ = $1; }
	| chars CHAR { 
			int n= strlen($1) +strlen($2) +1;
			$$ = JPATHALLOC(n); 
			strcpy($$,$1);
			strcat($$,$2);
		}

dex
	: '[' rangexp ']'

rangexp : jpath DDOT jpath 
	| plist

builtin
	: miscop { $$ = $1; }
  	| agop { $$ = $1; }
  	| strop { $$ = $1; }
	| arithop { $$ = $1; }

arithop
	: SQRT { $$ = $1; }
	| POW { $$ = $1; }
	| FLOOR { $$ = $1; }
	| CIEL { $$ = $1; }
	| ROUND { $$ = $1; }
	| RAND { $$ = $1; }


miscop
	: GROUP { $$ = $1; }
   | IF { $$ = $1; }
   | SORT { $$ = $1; }
   | UNIQ { $$ = $1; }
   | KEY { $$ = $1; }
   | VALUE { $$ = $1; }

agop 
	: AVG { $$ = $1; }
   | MIN { $$ = $1; }
   | MAX { $$ = $1; }
   | SIZE { $$ = $1; }
   | SUM { $$ = $1; }

strop 
	: STRINGF { $$ = $1; }
   | CONCAT { $$ = $1; }
   | UPPER { $$ = $1; }
   | LOWER { $$ = $1; }
   | EQ { $$ = $1; }
   | NEQ { $$ = $1; }
	| GT { $$ = $1; }
	| LT { $$ = $1; }
	| GTES { $$ = $1; }
	| LTES { $$ = $1; }
	| SUBSTR { $$ = $1; }
	| MATCH { $$ = $1; }
	| INDEXOF { $$ = $1; }
	| RSUB { $$ = $1; }

%% 



int parseJpath(const char *s) {
   YY_BUFFER_STATE buff = SCANSTRING(s);
   SWITCHTOBUFFER(buff);
   int res = PARSE();
   DELETEBUFFER(buff);
   return res;
}
