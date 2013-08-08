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
      jpathlval.str = JPATHSTRDUP(yytext);
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
      jpathlval.str = JPATHSTRDUP(yytext);
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

	/* eat whitespace */
[ \t]+	{}

	
[*][*] { return DSTAR; }
[*]	{ return '*'; } 
[/]   { return '/'; }

[.][.][.] { return TDOT; }
[.][.] { return DDOT; }
[.] { return '.'; }

 /*
object { return OBJECT; }
array { return ARRAY; }
scalar { return SCALAR; }
number { return NUMBER; }
text { return TEXT; }
 */


false	{ jpathlval.ival = 0; return INTEGER; }
true	{ jpathlval.ival = 1; return INTEGER; }


null { return NULLV; }
div  { return DIV; }
and  { return JPAND; }
or   { return JPOR; }


[-+]?[0-9]+ { 
		jpathlval.ival = atol(yytext);
		return INTEGER; 
	}
[-+]?[0-9]+[.][0-9]+(e[-+]?[0-9]+)? { 
		char*endp;
		jpathlval.fval = strtod(yytext,&endp);
		return FLOAT; 
	}

[a-zA-Z_][a-zA-Z0-9_.-]+      { 
	jpathlval.str = JPATHSTRDUP(yytext);
	return LABEL; 
	}

[<][=] { return LTE; }
[>][=] { return GTE; }
[!][=] { return NE; }

[!-+*%=()[\]><] { return *yytext; }

    /*
[\n] { 
   //	I should never see one of these
}
    */

. { // matches garbage
	yyterminate();
}

%%

