%{

#include "ajson.h"
#include "ajson.y.h"

void pEsc(char**target,const char* text);
int yycolumn = 1;
#define YY_USER_ACTION jsonlloc.first_line = jsonlloc.last_line = yylineno; \
    jsonlloc.first_column = yycolumn; jsonlloc.last_column = yycolumn+yyleng-1; \
	     yycolumn += yyleng;
%}

%Start STRING SSTRING COMMENT 

%option yylineno


%%
   /* end comment */
<COMMENT>[*]+[/] { BEGIN INITIAL; }
   /* allow '*' as long as it isn't followed by '/' */
<COMMENT>[*][^/] {  }
    /* comment text */
<COMMENT>[^*]+ {  }

<STRING>[^"\n\r\\]+ { 
		jsonlval.str = strdup(yytext);
		return CHAR;
   }

     /* any line ending */
<SSTRING,STRING>"\r\n"|[\r]|[\n] {
	if(jsonParserAllowErrors) {
		yywarning("unterminated string");
		BEGIN INITIAL; 
		return '\"';
	} else {
		jsonerror("unterminated string");
		return BADTOKEN;
	}
}
<STRING>"\\".  {
		pEsc(&jsonlval.str,yytext);
		return CHAR;
	}

<STRING>["]  { 
		BEGIN INITIAL; 
		return '\"';
	}


<SSTRING>[^'\\]+ {  
		jsonlval.str = strdup(yytext);
		return CHAR;
   }

<SSTRING>"\\".  {
		pEsc(&jsonlval.str,yytext);
		return CHAR;
	}

<SSTRING>[']  { 
		BEGIN INITIAL; 
		return '\'';
	}

["]  	{ 
		BEGIN STRING; 
		return '\"';
	}
				
[']  	{ 
		BEGIN SSTRING; 
		return '\'';
	}
				
[/][*] { 
		BEGIN COMMENT; 
	}


[-+]?[0-9]+[.][0-9]+(e[-+]?[0-9]+)? { 
		return FLOAT; 
	}

[-+]?[0-9]+ { 
		jsonlval.i = atol(yytext);
		return INTEGER; 
	}

null { return NULLVAL; }

[$a-zA-Z_][$a-zA-Z0-9_-]+ { 
		jsonlval.str = strdup(yytext);
		return LABEL;
	}

    /* ignore line comments */
[/][/].*$    {  }

[,]		{ return ','; }
[:]		{  return ':'; }
[[]		{  return '['; }
[\]]		{  return ']'; }
[(]		{  return '('; }
[)]		{  return ')'; }
[{]		{  return '{'; }
[}]		{  return '}'; }


[ \r\t]+ {  }

([\r][\n])|[\r]|[\n]  {   yycolumn = 1; }

.   { 
		  
		if(jsonParserAllowErrors) {
			yywarning("unrecognized character in input");
		} else {
			char bb[1024];
			sprintf(bb,"unrecognized character in input: %c",yytext[0]);
			jsonerror(bb);
//			YYERROR;
//			yyterminate();
			// TODO:: setup error flagging, 
		}
	}
%%

/*
int jsonLineNo() {
	return jsonlineno;
}
*/

     /* TODO:: needs upgrading to handle unicode */
void pEsc(char**target,const char* text) {
		(*target) = (char*) malloc(2);
		(*target)[1] = 0;
		switch(text[1]) {
			case 'n' : (*target)[0] = '\n'; break;
			case 'r' : (*target)[0] = '\r'; break;
			case 't' : (*target)[0] = '\t'; break;
			default  : (*target)[0] = text[1];
		}
}

int yywrap() {
	return 1;
}
