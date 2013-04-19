%{
#include<stdio.h>
#include<math.h>
#include<string.h>
#include "ajson.h"
#include "ajson.l.h"

#define jsonparserabort(x) return(x)

extern jax_callbacks jax_default_callbacks;

extern const jax_callbacks single_callback ;
//int jsonLineNo() ;


#ifndef BISONPREFIX
#define BISONPREFIX=yy
#warning "using default prefix `yy' for parser symbols"
#endif


#define FUSE(x,y) x ## y
#define XFUSE(x,y) FUSE(x,y)

#define SCANSTRING XFUSE(BISONPREFIX,_scan_string)
#define SWITCHTOBUFFER XFUSE(BISONPREFIX,_switch_to_buffer)
#define DELETEBUFFER XFUSE(BISONPREFIX,_delete_buffer)
#define PARSE XFUSE(BISONPREFIX,parse)
#define INPUTSTREAM XFUSE(BISONPREFIX,in)


#define LOCATION XFUSE(BISONPREFIX,lloc)


#define JSONALLOC(x) malloc(x)
#define JSONFREE(x) free(x)

#define appendJsonNode(p,c) 			{ \
				if((p)->last == NULL) {			\
					(p)->first = (p)->last = (c);			\
					(p)->children = 1;						\
				} else {			\
					(c)->prev = (p)->last;			\
					(p)->last = (c)->prev->next = (c);			\
					((p)->children)++;			\
				}                            \
			}

//extern int  allowErrors;

JsonNode* jsonBuildTreeFromFile(FILE *fi,int jtl); 
JsonNode* jsonBuildTreeFromString(const char* s,int jtl); 

JsonNode* jsonCloneNode(JsonNode* jn);
#define YYERROR_VERBOSE 1
%}

%start json

%union { 
	char*str;
	double f;
	long i; 
}

%locations

%token NULLVAL BADTOKEN 
%token<i> INTEGER 
%token<f> FLOAT
%token<str> CHAR LABEL GARBAGE

%type<str> chars sstr dstr string opref
%type<i> item alistitem

%%     

json : item endp {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @2.last_column == -1 ? @1.last_column : @2.last_column ;
   @$.last_line =  @2.last_line == -1 ? @1.last_line : @2.last_line ;
		if($1 == -1) {
		// tthe only item is an error
			YYABORT;
		}
	}
	| LABEL '(' alistitem ')' endp { /* jsonp */
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @5.last_column == -1 ? @4.last_column : @5.last_column ;
   @$.last_line =  @5.last_line == -1 ? @4.last_line : @5.last_line ;
		if($3 == -1) {
		// tthe only item is an error
			YYABORT;
		}
	}
	/*
   | jsonp {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
	}

jsonp 
	: LABEL '(' alistitem ')' endp {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @5.last_column == -1 ? @4.last_column : @5.last_column ;
   @$.last_line =  @5.last_line == -1 ? @4.last_line : @5.last_line ;
		if($3 == -1) {
		// tthe only item is an error
			YYABORT;
		}
	}

	*/
endp : ';' {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
	}
   | {
	@$.first_column = -1;
   @$.first_line = -1;
   @$.last_column = -1;
   @$.last_line = -1;
	}

item 
	: object {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
		$$ = 1;
	}
  	| array {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
		$$ = 1;
  }
  | NULLVAL {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
		$$ = 1;
  		if(jax_default_callbacks.string) jax_default_callbacks.string("(null)");
		if(jax_default_callbacks.scalar) jax_default_callbacks.scalar(NULL,0,NAN);
  }
  | INTEGER {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
		$$ = 1;
  		if(jax_default_callbacks.number) jax_default_callbacks.number($1,$1);
		if(jax_default_callbacks.scalar) {
	      char buff[128];
			sprintf(buff,"%ld",$1);
  			jax_default_callbacks.scalar(buff,$1,$1);
		}
  }
  | FLOAT {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
		$$ = 1;
  		if(jax_default_callbacks.number) jax_default_callbacks.number((long)$1,$1);
		if(jax_default_callbacks.scalar) {
	      char buff[128];
			sprintf(buff,"%f",$1);
  			jax_default_callbacks.scalar(buff,(long)$1,$1);
		}
  }
  | string {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
		$$ = 1;
  		if(jax_default_callbacks.string) jax_default_callbacks.string($1);
		if(jax_default_callbacks.scalar) {
			char*end;
			double d = strtod($1,&end);
			if(end == $1) {
				jax_default_callbacks.scalar($1,0,NAN);
			} else {
				jax_default_callbacks.scalar($1,(long)d,d);
			}
		}
		JSONFREE($1);
  }
  | errorcase {
		// TODO:: make certain that error case is not the ONLY item before repoting parse success.
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
		$$ = -1;
		char buff[1024];
		sprintf(buff,"error at %d:%d",@$.first_line,@$.first_column);
		if(!jsonParserAllowErrors) {
			yyerror(buff);
			YYABORT;
		} else {
			yywarning(buff);
		}
  }

func : funcstart funcend  {
		if(!jsonParserAllowJTL) {
			yyerror("functions not allow in strict json");
			YYABORT;
		}
	}
	

funcstart : LABEL '('  {
		if(jax_default_callbacks.startfunc) jax_default_callbacks.startfunc($1);
	}

funcend : plist ')' {
		if(jax_default_callbacks.endfunc) jax_default_callbacks.endfunc();
	}

plist 
	: item
	| plist ',' item
	|

object : sobj olist  listend eobj {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @4.last_column;
   @$.last_line = @4.last_line;
	}	
   | sobj eobj {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @2.last_column;
   @$.last_line = @2.last_line;
	}

olist : oitem {
	@$.first_column = @1.first_column;

   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
	}
   | olist ',' oitem  {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @3.last_column;
   @$.last_line = @3.last_line;
	}
	| olist oitem {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @2.last_column;
   @$.last_line = @2.last_line;
		if(jsonParserAllowErrors) {
			yywarning("missing comma between object members");
		} else {
			yyerror("missing comma between object members");
			jsonparserabort(-1);
		}
	}

oitem : opref alistitem  {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @2.last_column;
   @$.last_line = @2.last_line;
	}

	/*
	| opref func
	*/

opref : LABEL ':' { 
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @2.last_column;
   @$.last_line = @2.last_line;
		if(jax_default_callbacks.key) jax_default_callbacks.key($1);
		JSONFREE($1);
	}
   | string ':' { 
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @2.last_column;
   @$.last_line = @2.last_line;
		if(jax_default_callbacks.key) jax_default_callbacks.key($1);
		JSONFREE($1);
	}
	| INTEGER ':' { 
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @2.last_column;
   @$.last_line = @2.last_line;
		char buff[128];
		sprintf(buff,"%ld",$1);
		if(jax_default_callbacks.key) jax_default_callbacks.key(buff);
	}
   | FLOAT ':' { 
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @2.last_column;
   @$.last_line = @2.last_line;
		char buff[128];
		sprintf(buff,"%f",$1);
		if(jax_default_callbacks.key) jax_default_callbacks.key(buff);
	}

array : sarr alist listend earr {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @4.last_column;
   @$.last_line = @4.last_line;
	}
   | sarr earr {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @2.last_column;
   @$.last_line = @2.last_line;
	}

sobj : '{' {
		if(jax_default_callbacks.startobject) jax_default_callbacks.startobject();
 }
eobj : '}' {
		if(jax_default_callbacks.endobject) jax_default_callbacks.endobject();
 }
sarr : '[' {
		if(jax_default_callbacks.startarray) jax_default_callbacks.startarray();
 }
earr : ']' {
		if(jax_default_callbacks.endarray) jax_default_callbacks.endarray();
 }

alistitem
	: item { $$ = 1; }
	| func { $$ = 1; }

alist : alistitem {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
	}
   | alist ',' alistitem {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @3.last_column;
   @$.last_line = @3.last_line;
	}
	| alist alistitem { /* correctable syntax error */
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @2.last_column;
   @$.last_line = @2.last_line;
		if(jsonParserAllowErrors) {
			yywarning("missing comma between array elements");
		} else {
			yyerror("missing comma between array elements");
			YYERROR;
			jsonparserabort(-1);
		}
	}

listend : ',' {
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
		if(jsonParserAllowErrors) {
			yywarning("extra comma at list and");
		}
	}
   | {
	@$.first_column = -1;
   @$.first_line = -1;
   @$.last_column = -1;
   @$.last_line = -1;
	}

string : sstr { 
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
   @$.last_column = @1.last_column;
   @$.last_line = @1.last_line;
		$$ = $1; 
	}
   | dstr { 
	@$.first_column = @1.first_column;
   @$.first_line = @1.first_line;
	}

sstr : '\''  chars '\'' { $$ = $2; }
	| '\''  '\'' { $$ =""; }

dstr : '"' chars '"' { $$ = $2; }
	|  '"' '"' { $$ =""; }

chars 
	: CHAR { $$ = $1; }
	| chars CHAR {
		int n = strlen($1) + strlen($2) + 1;
		$$ = (char*) JSONALLOC(n);
		strcpy($$,$1);
		strcat($$,$2);
		}


errorcase 
	: error ','
	| error '}'
	| error ']'
%%




int indent = 0;
int  jsonParserAllowErrors=0;
int  jsonParserAllowJTL=0;

void setAllowErrors(int a) {
	jsonParserAllowErrors = a;
}

void setAllowJTL(int a) {
	jsonParserAllowJTL = a;
}

int indenter() {
	int i = 0;
	for(;i < indent; ++i) {
		printf("  ");
	}
}


 int (*sjcb)(__JAXEVT type, const char* p, long i, double f) = NULL;

int parseJsonString(const char *s,int jtl) {
   YY_BUFFER_STATE my_string_buffer = SCANSTRING (s);
	SWITCHTOBUFFER(my_string_buffer);
	setAllowJTL(jtl);
	int res = parseJson();
	DELETEBUFFER(my_string_buffer );
	return res;
}

int parseJson() {
	if(jax_default_callbacks.startjson) jax_default_callbacks.startjson();
	int res = PARSE();
	if(res == 0 && jax_default_callbacks.endjson) jax_default_callbacks.endjson();
	return res;
}
int parseJsonFile(FILE *f,int jtl) {
	INPUTSTREAM = f == NULL ? stdin : f;
	setAllowJTL(jtl);
	int res = parseJson();
	return res;
}

JsonNode * jsonBuildJtlTreeFromString(const char*s) {
	return jsonBuildTreeFromString(s,1);
}
JsonNode * jsonBuildJtlTreeFromFile(FILE*f) {
	return jsonBuildTreeFromFile(f,1);
}

JsonNode * jsonBuildJsonTreeFromString(const char*s) {
	return jsonBuildTreeFromString(s,0);
}
JsonNode * jsonBuildJsonTreeFromFile(FILE*f) {
	return jsonBuildTreeFromFile(f,0);
}

int yywarning(const char *p) {
	return fprintf(stderr,"warning between line %d, pos %d and line %d, pos %d: %s\n",
		LOCATION.first_line,
		LOCATION.first_column,
		LOCATION.last_line,
		LOCATION.last_column,
		p);
}
int yyerror(const char *p) {
	return fprintf(stderr,"error between line %d, pos %d and line %d, pos %d: %s\n",
		LOCATION.first_line,
		LOCATION.first_column,
		LOCATION.last_line,
		LOCATION.last_column,
		p);
}

int sjcb_sj() {
	return sjcb(SJS,NULL,0,0);
}
int sjcb_ej() {
	return sjcb(EJS,NULL,0,0);
}
int sjcb_so() {
	return sjcb(SOBJ,NULL,0,0);
}
int sjcb_eo() {
	return sjcb(EOBJ,NULL,0,0);
}
int sjcb_sa() {
	return sjcb(SARR,NULL,0,0);
}
int sjcb_ea() {
	return sjcb(EARR,NULL,0,0);
}
int sjcb_key(const char*p) {
	return sjcb(KEY,p,0,0);
}
int sjcb_entmmoc(const char*p) {
	return sjcb(COM,p,0,0);
}
int sjcb_jsonp(const char*p) {
	return sjcb(JSP,p,0,0);
}
int sjcb_scalar(const char*p,long i, double f) {
	return sjcb(SCA,p,i,f);
}
int sjcb_comment(const char*p) {
	return sjcb(COM,p,0,0);
}

void setCallBacks(jax_callbacks _jcb) {
	jax_default_callbacks = _jcb;
}
void setSingleHandler(int myhandler(__JAXEVT type,const char*p,long i, double f)) {
	jax_default_callbacks = single_callback;
	sjcb = myhandler;
}


int  jax_default_so() {
	indenter();
	printf("start object\n");
	++indent;
}

int  jax_default_eo() {
	--indent;
	indenter();
	printf("end object\n");
}

int  jax_default_sj() {
	indenter();
	printf("start json\n");
	++indent;
}
int  jax_default_ej() {
	indenter();
	printf("end json\n");
	++indent;
}
int  jax_default_sa() {
	indenter();
	printf("start array\n");
	++indent;
}

int  jax_default_ea() {
	--indent;
	indenter();
	printf("end array\n");
}

int jax_default_s(const char*p) {
	indenter();
	printf("string: %s\n",p);
}

int jax_default_k(const char*p) {
	indenter();
	printf("key: %s\n",p);
}

int jax_default_n(long l, double d) {
	indenter();
	printf("number: %ld (%f)\n",l,d);
}

int jax_default_sc(const char*p,long i,double d) {
	indenter();
	printf("scalar: %s, %ld (%f)\n",p,i,d);
}

int jax_default_jp(const char*p) {
	indenter();
	printf("jsonp: %s\n",p);
}

int jax_default_comment(const char*p) {
	indenter();
	printf("comment: %s\n",p);
}

/* default handler */

jax_callbacks __jax_default_callbacks = {
	jax_default_so,
	jax_default_eo,
	jax_default_sa,
	jax_default_ea,
	jax_default_k,
	jax_default_sc,
	jax_default_s,
	jax_default_n,
	jax_default_jp,
	jax_default_sj,
	jax_default_ej,
	jax_default_comment
};

jax_callbacks jax_default_callbacks = {
	jax_default_so,
	jax_default_eo,
	jax_default_sa,
	jax_default_ea,
	jax_default_k,
	jax_default_sc,
	jax_default_s,
	jax_default_n,
	jax_default_jp,
	jax_default_sj,
	jax_default_ej,
	jax_default_comment
};

const jax_callbacks single_callback = {
	sjcb_so,
	sjcb_eo,
	sjcb_sa,
	sjcb_ea,
	sjcb_key,
	sjcb_scalar,
	NULL,
	NULL,
	sjcb_jsonp,
	sjcb_sj,
	sjcb_ej,
	sjcb_comment
};


JsonNode* jsonNewNode(JsonNode* parent,jsonnodetype t,const char* str, long ival, double fval) {
	JsonNode* p = (JsonNode*) JSONALLOC(sizeof(JsonNode));
	p->type = t;
	p->parent = parent;
	p->children = 0;

	p->first = p->last = p->prev = p->next = NULL;
	p->str = NULL;
	p->ival = 0;
	p->fval = NAN;

	switch(t) {
		case TYPE_JSONP:
		case TYPE_ELEMENT:
		case TYPE_STRING:
		case TYPE_FUNC:
			p->str = strdup(str);
		break;
		case TYPE_NUMBER:
			p->ival = ival;
			p->fval = fval;
		break;
		case TYPE_OBJECT:
		case TYPE_ARRAY:
		// nothing special to do for these at create time
		break;
		default: 
			fprintf(stderr,"unknown type %d in JsonNode\n",t);
		return NULL;
		break;
	}

	if(parent != NULL) {
		appendJsonNode(parent,p);
	}
	return p;
}

JsonNode* jsonCreateFunc(JsonNode*p,const char*str) {
	return jsonNewNode(p,TYPE_FUNC,strdup(str),0,NAN);
}

JsonNode* jsonCreateJsonp(const char*str) {
	return jsonNewNode(NULL,TYPE_JSONP,strdup(str),0,NAN);
}

JsonNode* jsonCreateKey(JsonNode*p,const char*str) {
	return jsonNewNode(p,TYPE_ELEMENT,strdup(str),0,NAN);
}
JsonNode* jsonCreateString(JsonNode*p,const char*str) {
	return jsonNewNode(p,TYPE_STRING,strdup(str),0,NAN);
}

JsonNode* jsonCreateNumber(JsonNode*p,long ival, double fval) {
	return jsonNewNode(p,TYPE_NUMBER,NULL,ival,fval);
}

JsonNode* jsonCreateObject(JsonNode*p) {
	return jsonNewNode(p,TYPE_OBJECT,NULL,0,NAN);
}

JsonNode* jsonCreateArray(JsonNode*p) {
	return jsonNewNode(p,TYPE_ARRAY,NULL,0,NAN);
}

int jsonObjectAppend(JsonNode *object,const char*key,JsonNode *ch) {
	if(object->type != TYPE_OBJECT) {
		return -1;
	}
	JsonNode *el = jsonNewNode(object,TYPE_ELEMENT,strdup(key),0,NAN);
	appendJsonNode(el,ch);
	return 1;
}

int jsonArrayAppend(JsonNode *array,JsonNode *ch) {
	if(array->type != TYPE_ARRAY) {
		return -1;
	}
	appendJsonNode(array,ch);
	return 1;
}

	

void jsonFreeInternal(JsonNode*js,int wide) {
	if(js->first) {
		jsonFreeInternal(js->first,1);
	}
	JsonNode *next = js->next;

	if(js->str) JSONFREE(js->str);
	JSONFREE(js);

	if(wide) {
		if(next) {
			jsonFreeInternal(next,1);
		}
	}
}
void jsonFree(JsonNode*js) {
	jsonFreeInternal(js,0);
}

JsonNode* jsonGetParent(JsonNode*p) {
	JsonNode *js = NULL;
	if(p->parent != NULL) {
		if(p->parent->type == TYPE_ELEMENT) {
			js = p->parent->parent;
		} else {
			js = p->parent;
		}
	}
	return js;
}

#define MINJSSTACK 4096

extern const jax_callbacks node_builder_callback;

JsonNode** jnstack = NULL;
int jnstackptr = 0;

#define JSONPARENT ( jnstackptr == 0 ? NULL : jnstack[jnstackptr-1] )

#define FIXSTACK(st,pt) 		\
		if((pt) > 0 && (st)[(pt)-1]->type == TYPE_ELEMENT) {		\
			(pt)--;		\
		}

JsonNode* jsonBuildTreeFromString(const char *s,int jtl) {
	JsonNode *tree = NULL;
	jnstack = (JsonNode**) JSONALLOC(MINJSSTACK*sizeof(JsonNode*));
	setCallBacks(node_builder_callback);
	int res = parseJsonString(s,jtl);
	if(res == 0) {
		tree=jnstack[0];
	}
	JSONFREE(jnstack);
	return tree;
}

JsonNode* __jsonCloneNode(JsonNode* jn,JsonNode *parent) {
	JsonNode *result = NULL;
	if(jn == NULL) {
		return NULL;
	}
	switch(jn->type) {
		case TYPE_JSONP:
			result = jsonCreateJsonp(jn->str);
			__jsonCloneNode(jn->first,result);
			break;
		case TYPE_OBJECT: {
				result = jsonCreateObject(parent);
				JsonNode *next = jn->first;
				while(next!=NULL) {
					__jsonCloneNode(next,result);
					next=next->next;
				}
			}
			break;
		case TYPE_ELEMENT:
			result = jsonCreateKey(parent,jn->str);
			__jsonCloneNode(jn->first,result);
			break;
		case TYPE_ARRAY: {
				result = jsonCreateArray(parent);
				JsonNode *next = jn->first;
				while(next!=NULL) {
					__jsonCloneNode(next,result);
					next=next->next;
				}
			}
			break;
		case TYPE_NUMBER:
			result = jsonCreateNumber(parent,jn->ival,jn->fval);
			break;
		case TYPE_STRING:
			result = jsonCreateString(parent,jn->str);
			break;
		case TYPE_FUNC:
			result = jsonCreateFunc(parent,jn->str);
			break;
		break;
		default:
			fprintf(stderr,"unknown type in cloneJsonNode\n");
	}
	return result;
}

JsonNode *jsonValueArray(JsonNode *jn) {
	if(jn->type == TYPE_ARRAY) {
		return jsonCloneNode(jn);
	}
	if(jn->type == TYPE_OBJECT) {
		JsonNode* na = jsonCreateArray(NULL);
		JsonNode *key = jn->first;
		while(key!=NULL) {
			jsonArrayAppend(na,jsonCloneNode(key->first));
			key= key->next;
		}
		return na;
	}
	return NULL;
}

JsonNode* jsonCloneNode(JsonNode* jn) {
	return __jsonCloneNode(jn,NULL);
}

JsonNode* jsonGetElement(JsonNode* arr,int index) {
	if(arr->type == TYPE_ARRAY || arr->type == TYPE_OBJECT) {
		if(index>=0) {
			int ctr = 0;
			JsonNode * next = arr->first;
			while(next!=NULL) {
				if(index == ctr) {
					return arr->type == TYPE_ARRAY ? next : next->first;
				}
				next=next->next;
				++ctr;
			}
		} else {
			int ctr = 1;
			index = -index;
			// searching from the end
			JsonNode *prev = arr->last;
			while(prev!= NULL) {
				if(index == ctr) {
					return arr->type == TYPE_ARRAY ? prev : prev->first;
				}
				prev = prev->prev;
				++ctr;
			}
		}
	} 
	return NULL;
}
JsonNode* jsonGetMember(JsonNode* obj,const char *name) {
	if(obj->type != TYPE_OBJECT) return NULL;
	JsonNode*key,el;
	key = obj->first;
	while(key != NULL) {
		if(strcmp(key->str,name) == 0) {
			return key->first;
		}
		key = key->next;
	}
	return NULL;
}

JsonNode* jsonBuildTreeFromFile(FILE *f,int jtl) {
	JsonNode *tree = NULL;
	jnstack = (JsonNode**) JSONALLOC(MINJSSTACK*sizeof(JsonNode*));
	setCallBacks(node_builder_callback);
	int res = parseJsonFile(f,jtl);
	if(res == 0) {
		tree=jnstack[0];
	}
	JSONFREE(jnstack);
	return tree;
}

// node builder callbacks

	int nbcb_sa() {
		JsonNode*js=jsonCreateArray(JSONPARENT);
		jnstack[jnstackptr] = js;
		jnstackptr++;
	}
	
	int nbcb_ea() {
		jnstackptr--;
		FIXSTACK(jnstack,jnstackptr);
	}
	
	int nbcb_so() {
		JsonNode*js=jsonCreateObject(JSONPARENT);
		jnstack[jnstackptr] = js;
		jnstackptr++;
	}
	
	int nbcb_eo() {
		jnstackptr--;
		FIXSTACK(jnstack,jnstackptr);
	}
	
	int nbcb_key(const char *p) {
		JsonNode*js=jsonCreateKey(JSONPARENT,p);
		jnstack[jnstackptr] = js;
		jnstackptr++;
	}
	
	int nbcb_number(long ival,double fval) {
		jsonCreateNumber(JSONPARENT,ival,fval);
		FIXSTACK(jnstack,jnstackptr);
	}
	
	int nbcb_string(const char*p) {
		jsonCreateString(JSONPARENT,p);
		FIXSTACK(jnstack,jnstackptr);
	}
	
	int nbcb_startfunc(const char*p) {
		JsonNode*js=jsonCreateFunc(JSONPARENT,p);
		jnstack[jnstackptr] = js;
		jnstackptr++;
	}

	int nbcb_endfunc() {
		jnstackptr--;
		FIXSTACK(jnstack,jnstackptr);
	}

	int nbcb_jsonp(const char*p) {
		JsonNode*js=jsonCreateJsonp(p);
		jnstack[jnstackptr] = js;
		jnstackptr++;
	}

const jax_callbacks node_builder_callback = {
	nbcb_so, nbcb_eo, nbcb_sa, nbcb_ea,
	nbcb_key, NULL, nbcb_string, nbcb_number, 
	nbcb_jsonp, NULL, NULL, NULL, 
	NULL, nbcb_startfunc, nbcb_endfunc
};


