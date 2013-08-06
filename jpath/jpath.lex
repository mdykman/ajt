%{


extern int jpathcolumn;

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

#include "jpath.y.h"

#define YY_USER_ACTION 				\
	{ jpathlloc.first_line = jpathlloc.last_line = yylineno; \
	jpathlloc.first_column = jpathcolumn; jpathlloc.last_column = jpathcolumn+yyleng-1; \
	jpathcolumn += yyleng; }

%}

%Start STRING SSTRING

%option prefix="jpath" header-file="jpath.l.h" outfile="jpath.l.c"
%option nodefault noyywrap yylineno

%%

<STRING>[^"\\]+ {
      jpathlval.str = strdup(yytext);
      return CHAR;
   }

<STRING>"\\".  {
      pEsc(&jpathlval.str,yytext);
      return CHAR;
   }

<STRING>["]  {
      BEGIN INITIAL;
      return '\"';
   }


<SSTRING>[^'\\]+ {
      jpathlval.str = strdup(yytext);
      return CHAR;
   }

<SSTRING>"\\".  {
      pEsc(&jpathlval.str,yytext);
      return CHAR;
   }

<SSTRING>[']  {
      BEGIN INITIAL;
      return '\'';
   }

["]   {
      BEGIN STRING;
      return '\"';
   }

[']   {
      BEGIN SSTRING;
      return '\'';
   }

[*][*] { return DSTAR; }
[*]	{ return '*'; } 
[/]   { return '/'; }

[.][.][.] { return TDOT; }
[.][.] { return DDOT; }
[.] { return '.'; }

null { return NULLV; }
 /*
object { return OBJECT; }
array { return ARRAY; }
scalar { return SCALAR; }
number { return NUMBER; }
text { return TEXT; }
 */


div  { return DIV; }


[<][=] { return LTE; }
[>][=] { return GTE; }
[!][=] { return NE; }

[-+*%=()[\]><] { return *yytext; }
   /*
sqrt { return SQRT; }
pow { return POW; }
sin { return SIN; }
cos { return COS; }
log { return LOG; }
floor { return FLOOR; }
ciel { return CEIL; }
round { return ROUND; }
rand { return RAND; }


group { return GROUP; }
if { return IF; }
sort { return SORT; }
uniq { return UNIQ; }

key { return QKEY; }
value { return VALUE; } 
 
name { return NAME; } 
	
avg { return AVG; }
min { return MIN; }
max { return MAX; }
size { return SIZE; }
sum { return SUM; }

string { return STRING; }
concat { return CONCAT; }
upper { return UPPER; }
lower { return LOWER; }
indexof { return INDEXOF; }
substr { return SUBSTR; }
match { return MATCH; }
rsub { return RSUB; }

eq { return EQ; }
neq { return NEQ; }
gt { return GT; }
lt { return LT; }
gte { return GTES; }
lte { return LTES; }

   */
[-+]?[0-9]+ { 
		jpathlval.ival = atol(yytext);
		return INTEGER; 
	}
[-+]?[0-9]+[.][0-9]+(e[-+]?[0-9]+)? { 
		char*endp;
		jpathlval.fval = strtod(yytext,&endp);
		return FLOAT; 
	}

[$a-zA-Z_][$a-zA-Z0-9_-]+      { 
	jpathlval.str = strdup(yytext);
	return LABEL; 
	}

. { // matches garbage
	yyterminate();
}

[\n] { 
   //	I should never see one of these
}

%%

