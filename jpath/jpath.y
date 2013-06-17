%{
// jpath

// /**/field/*
// **/f/if(../dept = 32)/id

// */users/*/group(dept)
// */users/{id,dept}


// */[id,dept]

// count(**/email)
// **/email/count()


#define JPATHREALLOC(x,y)  realloc(x,y)
#define JPATHALLOC(x)  malloc(x)
#define JPATHFREE(x)  free(x)

#define JPATHERROR(x) jpatherror(x)
#define JPATHWARNING(x)  fprintf(stderr,"warning at %d: %s\n",jpathcolumn,(x)) 

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



#include <math.h>
#include <stdio.h>
#include <ctype.h>

#include "jpath.l.h"



int jpatherror(const char*msg) ;
int jpathcolumn = 0;
%}

%code requires {
	#include "jpath.h"
}

%union {
	JpathNode *jp;
	jpathproc proc;
	char*str;
	double fval;
	long ival;
}

%locations

%type<str> chars dstr sstr string
%type<jp> builtin arithop miscop agop strop 
%type<jp> fstep bstep step

%type<jp> const

%token<str> LABEL CHAR  
%token<fval> FLOAT 
%token<ival> INTEGER

%token<jp> DDOT TDOT DSTAR 
%token<jp> LTE GTE NE SQRT POW FLOOR CEIL ROUND RAND DIV
%token<jp> NUMBER TEXT SCALAR ARRAY OBJECT NULLV NAME
%token<jp> GROUP IF SORT UNIQ QKEY VALUE AVG MIN MAX SIZE SUM
%token<jp> SIN COS LOG
%token<jp> STRINGF CONCAT UPPER LOWER EQ NEQ GT LT GTES LTES SUBSTR MATCH INDEXOF RSUB

%% 

jpath : abspath 

abspath 
	: relpath
	| '/' relpath

relpath
	: sortexp 
	| relpath '/' cmpexp


sortexp
	: groupexp
	| SORT '(' jpath ')'

groupexp
	: ifexp
	| GROUP '(' jpath ')'

ifexp
	: cmpexp
	| IF '(' jpath ')'

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
	: const
	| '(' jpath ')'
	| var
	| fcall  { 
		/* only valid in jtl*/
		}

fcall 
	: func '(' plist ')'
	| func '(' ')'
	
func 
	: builtin
	| label

plist
	: jpath
	| plist ',' jpath

step: fstep { $$ = $1; }
	| bstep { $$ = $1; }
	| '.' { $$ = JPATHFUNC("self",__jpnoop,-1,1); }

bstep
	: DDOT { $$ = JPATHFUNC("parent",__jpparent,-1,1); } 
	| TDOT{ $$ = JPATHFUNC("peach",__jppeach,-1,1); }

fstep
	: '*' { $$ = JPATHFUNC("star",__jpeach,-1,1); }
	| DSTAR { $$ = JPATHFUNC("dstar",__jpeachdeep,-1,1); }


const
	: string { 
		 $$ = JPATHFUNCDATA("string",__jpevaldata,jsonCreateString(NULL,$1)); 
	}
	| INTEGER{ 
		 $$ = JPATHFUNCDATA("integer",__jpevaldata,jsonCreateNumber(NULL,$1,$1)); 
	}
	| FLOAT{ 
		 $$ = JPATHFUNCDATA("float",__jpevaldata,jsonCreateNumber(NULL,$1,$1)); 
	}


var : '$' label

string
   : dstr { $$ = $1; }
   | sstr { $$ = $1; }

sstr 
	: '"' chars '"' { $$ = $2; }
	| '"' '"' { $$ = ""; }

dstr 
	: '\'' chars '\'' { $$ = $2; }
	| '\'' '\'' { $$ = ""; }

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
	| jpath DDOT
	| plist

builtin
	: miscop { $$ = $1; }
  	| agop { $$ = $1; }
  	| strop { $$ = $1; }
	| arithop { $$ = $1; }

arithop
	: SQRT { $$ = JPATHFUNC("sqrt",__jpsqrt,-1,1); }
	| POW { $$ = JPATHFUNC("pow",__jpnoop,-1,1); }
	| FLOOR { $$ = JPATHFUNC("floor",__jpfloor,-1,1); }
	| CEIL { $$ = JPATHFUNC("ciel",__jpceil,-1,1); }
	| ROUND { $$ = JPATHFUNC("round",__jpnoop,-1,1); }
	| RAND { $$ = JPATHFUNC("rand",__jprand,-1,1); }


miscop
   : QKEY { $$ = JPATHFUNC("qkey",__jpnoop,-1,1); }
   | VALUE { $$ = JPATHFUNC("value",__jpnoop,-1,1); }
/*
	: GROUP { $$ = $1; }
   | IF { $$ = $1; }
JpathNode * newJpathNode(jpathproc proc, const char* name,JpathNode **params, int nargs, int ag, JpathNode *next) {
#define JPATHFUNC(nm,p,n,a) newJpathNode((p),(nm),NULL,(n),(a),NULL)
*/

agop 
	: AVG { $$ =  JPATHFUNC("avg",__jpavg,-1,1); }
   | MIN { $$ =  JPATHFUNC("min",__jpmin,-1,1); }
   | MAX { $$ =  JPATHFUNC("max",__jpmax,-1,1); }
   | SIZE { $$ =  JPATHFUNC("size",__jpsize,-1,1); }
   | SUM { $$ = JPATHFUNC("sum",__jpsum,-1,1); }

strop 
	: STRINGF { $$ = $1; }
   | CONCAT { JPATHFUNC("concat",__jpconcat,-1,0); }
   | UPPER { $$ = JPATHFUNC("upper",__jpupper,1,0); }
   | LOWER { $$ = JPATHFUNC("lower",__jplower,1,0); }
   | EQ { $$ = JPATHFUNC("eq",__jpeq,2,0); }
   | NEQ { $$ = JPATHFUNC("neq",__jpneq,2,0); }
	| GT { $$ = JPATHFUNC("gt",__jpgt,2,0); }
	| LT { $$ = JPATHFUNC("lt",__jplt,2,0); }
	| GTES { $$ = JPATHFUNC("gtes",__jpgte,2,0); }
	| LTES { $$ = JPATHFUNC("ltes",__jplte,2,0); }
	| SUBSTR { $$ = JPATHFUNC("substr",__jpnoop,-1,1); }
	| MATCH { $$ = JPATHFUNC("match",__jpnoop,-1,1); }
	| INDEXOF { $$ = JPATHFUNC("indexof",__jpnoop,-1,1); }
	| RSUB { $$ = JPATHFUNC("rsub",__jpnoop,-1,1); }

%% 

#define JSONNODESETINIT 1024

JsonNode* jsonNodeSetGet(JsonNodeSet*ptr,int x)  { 
	if(ptr->count > x) {
		return ptr->nodes[x];
	}
	return NULL;
}

char* jsonToString(JsonNode *j) {
	if(j->type == TYPE_STRING) {
		return strdup(j->str);
	} else if(j->type == TYPE_NUMBER) {
		char *buff=(char*)JPATHALLOC(64);
		if(j->ival == j->fval) {
			sprintf(buff,"%ld",j->ival);
		} else {
			sprintf(buff,"%f",j->fval);
		}
		return buff;
	}
	return "";
}

char* jsonAppendString(const char*left, const char* right) {

	int ln = left == NULL ? 0 : strlen(left);
	int rn = left == NULL ? 0 : strlen(right);

	char* buff = (char*)JPATHALLOC(ln + rn + 1);
	buff[0] =0;
	if(left!=NULL)  strcpy(buff,left);
	if(right!=NULL) strcat(buff,right);
	return buff;
}

void freeJsonNodeSet(JsonNodeSet *js) {
	JPATHFREE(js->nodes);
	JPATHFREE(js);
}

void addJsonNode(JsonNodeSet*jns,JsonNode*node) {
	// ignore duplicates
	int i;
	for(i=0;i<jns->count;++i) {
		if(jns->nodes[i] == node) return;
	}
	if(jns->count+1 >= jns->capacity) {
		jns->capacity*=2;
		jns->nodes = (JsonNode**)JPATHREALLOC(jns->nodes,jns->capacity*sizeof(JsonNode*));
	}
	jns->nodes[jns->count] = node;
	jns->count++;
}

void addJsonNodeSet(JsonNodeSet*jns,JsonNodeSet*other) {
	int i;
	for(i=0;i<other->count;++i) {
		addJsonNode(jns,other->nodes[i]);
	}
}

int jsonTestBooleanNode(JsonNode*ctx) {
	switch(ctx->type) {
		case TYPE_STRING:
			if(ctx->str != NULL && strlen(ctx->str) > 0) {
				char **endp;
				long l = strtol(ctx->str,endp,10);
				if(*endp > ctx->str) {
					return l != 0 ? 1 : 0;
				}
				return 1;
			} else {
				return 0;
			}
			
		case TYPE_NUMBER:
					return ctx->ival != 0 ? 1 : 0;
		break;
		default :
			return ctx->children > 0 ? 1 : 0;
	}
}

JpathNode* jsonGetJpathParam(JpathNode**ptr,int x)  { 
	int i = 0;
	for(;i <= x && (*ptr) != NULL; ++i,++ptr){
		if((x) == i) return *ptr;
	}
	return NULL;
}
	
	


#define JSONSTARTCONTEXT(x,p)   	\
	{ \
	JsonNodeSet *_ctx = tempContext((x),p);	\
	if(_ctx != NULL) {			\
		freeJsonNodeSet(x);     \
		(x) = _ctx;					\
	} }								\

#define JSONTESTPARAMS(pp,x)	\
	if((x) != -1)  { if((x) > 0) { 				\
		if(pp == NULL || (*pp) ==NULL)  {		 \
			JPATHERROR("parameters expected");		\
			return newJsonNodeSet();					\
		} 	else {											\
			JpathNode ** __internalPP = pp;		\
			int __internalCC = 0; 					\
			for(;(*__internalPP)!=NULL;++__internalCC,++__internalPP)  {}		\
			if((x) != __internalCC) {			\
				yyerror("incorrect number of params");		\
				return newJsonNodeSet();					\
			}												\
		}				\
	} }
	
int jsonTestBoolean(JsonNodeSet*test) {
	int result	;
	if(test->count == 0) {
		result = 0;
	} else if(test->count > 1) {
		result = 1;
	} else {
		JsonNode*jn = test->nodes[0];
		result = jsonTestBooleanNode(jn);
	}
	return result;
}
JsonNodeSet *tempContext(JsonNodeSet*ctx,JpathNode **p) {
	JpathNode *p1 = jsonGetJpathParam(p,0);
	if(p1!=NULL) {
		JsonNodeSet*ctx2=__jpathExecute(ctx,p1);
		freeJsonNodeSet(ctx);
		ctx=ctx2;
	}
	return ctx;
}

JsonNodeSet * newJsonNodeSet() {
	JsonNodeSet*result = (JsonNodeSet*)JPATHALLOC(sizeof(JsonNodeSet));
	result->nodes = (JsonNode**) JPATHALLOC(JSONNODESETINIT * sizeof(JsonNode*));
	result->capacity = JSONNODESETINIT;
	result->count = 0;
	return result;
}

JsonNodeSet* json2NodeSet(JsonNode *n) {
	JsonNodeSet *rjns = newJsonNodeSet();
	JsonNode*p;
	if(n->type == TYPE_ARRAY) {
		p = n->first;
		while(p != NULL) {
			addJsonNode(rjns,jsonCloneNode(p));
			p = p->next;
		}
	}
	else if(n->type == TYPE_OBJECT) {
		p = n->first;
		while(p != NULL) {
			addJsonNode(rjns,jsonCloneNode(p->first));
			p = p->next;
		}
	} else {
			addJsonNode(rjns,jsonCloneNode(n));
	}

	return rjns;
}

JsonNodeSet *__numeric(JsonNodeSet *ctx,JpathNode **jn,double (*dfunc)(double)) {
	JSONSTARTCONTEXT(ctx,jn)
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<ctx->count;++i) {
		JsonNode *n = ctx->nodes[i];
		if(n->type == TYPE_NUMBER) {
			double res = dfunc(n->fval);
			if(res == NAN) {
				addJsonNode(rjns,jsonCreateNumber(NULL,0L,NAN));
			} else {
				addJsonNode(rjns,jsonCreateNumber(NULL,(long)res,res));
			}
		} else if(n->type == TYPE_STRING) {
			if(n->str == NULL) {
				addJsonNode(rjns,jsonCreateNumber(NULL,0L,NAN));
			} else {
				char*endp;
				double dd = strtol(n->str,&endp,10);
				if(endp == n->str) {
					addJsonNode(rjns,jsonCreateNumber(NULL,0L,NAN));
				} else {
					double res = dfunc(dd);
					if(res == NAN) {
						addJsonNode(rjns,jsonCreateNumber(NULL,0L,NAN));
					} else {
						addJsonNode(rjns,jsonCreateNumber(NULL,(long)res,res));
					}
				}
			}
		} else {
			addJsonNode(rjns,jsonCreateNumber(NULL,0L,NAN));
		}
	}
	return rjns;
}

JsonNodeSet *__jpround(JsonNodeSet *ctx,JpathNode **jn) {
	return __numeric(ctx,jn,round);	
}

JsonNodeSet *__jpceil(JsonNodeSet *ctx,JpathNode **jn) {
	return __numeric(ctx,jn,ceil);	
}

JsonNodeSet *__jpfloor(JsonNodeSet *ctx,JpathNode **jn) {
	return __numeric(ctx,jn,floor);	
}

JsonNodeSet *__jpsqrt(JsonNodeSet *ctx,JpathNode **jn) {
	return __numeric(ctx,jn,sqrt);	
}

double jrand(double d) {
	unsigned int max = RAND_MAX;
	double res = rand_r(&max);
	res /= RAND_MAX;
	if(d != 0) {
		res *= d;
	}

	return res;
}

JsonNodeSet *__jprand(JsonNodeSet *ctx,JpathNode **jn) {
	return __numeric(ctx,jn,jrand);	
}


JsonNodeSet *__jppeach(JsonNodeSet *ctx,JpathNode **jn) {
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<ctx->count;++i) {
		JsonNode *pp = ctx->nodes[i]->parent;
		while(pp != NULL) {
			addJsonNode(rjns,pp);
			pp = pp->parent;
		}
	}
	return rjns;
}

JsonNodeSet *__jpparent(JsonNodeSet *ctx,JpathNode **jn) {
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<ctx->count;++i) {
		JsonNode *pp = ctx->nodes[i]->parent;
		if(pp != NULL) addJsonNode(rjns,pp);
	}
	return rjns;
}

JsonNodeSet *__jpeachrecurse(JsonNodeSet *result,JsonNode *ctx) {
	addJsonNode(result,jsonCloneNode(ctx));

	if(ctx->type == TYPE_ARRAY) {
		int i=0;
		JsonNode *eech = ctx->first;
		while(eech != NULL) {
			__jpeachrecurse(result,eech);
			eech = eech->next;
		}
	} else if (ctx->type == TYPE_OBJECT) {
		int i=0;
		JsonNode *eech = ctx->first;
		while(eech != NULL) {
			__jpeachrecurse(result,eech->first);
			eech = eech->next;
		}
	} 
	return result;
}

JsonNodeSet *__jpeachdeep(JsonNodeSet *ctx,JpathNode **jn) {
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<ctx->count;++i) {
		__jpeachrecurse(rjns,ctx->nodes[i]);	
	}
	return  rjns;
}

JsonNodeSet *__jpeach(JsonNodeSet *ctx,JpathNode **jn) {
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<ctx->count;++i) {
		JsonNode*n = ctx->nodes[i];
		if(n->type == TYPE_ARRAY) {
			JsonNode *eech = n->first;
			while(eech != NULL) {
				addJsonNode(rjns,jsonCloneNode(eech));
				eech = eech->next;
			}
		} else if (n->type == TYPE_OBJECT) {
			JsonNode *eech = n->first;
			while(eech != NULL) {
				addJsonNode(rjns,jsonCloneNode(eech->first));
				eech = eech->next;
			}
		} else {
			addJsonNode(rjns,jsonCloneNode(n));
		}
	}
	return rjns;
}

JsonNodeSet *__jpident(JsonNodeSet *ctx,JpathNode **jn) {
	return ctx;
}
JsonNodeSet *__jpnoop(JsonNodeSet *ctx,JpathNode **jn) {
	return ctx;
}

JsonNodeSet * __jpevaldata(JsonNodeSet *ctx, JpathNode **jn) {
	JSONTESTPARAMS(jn,1);
	JsonNodeSet *rjns = newJsonNodeSet();
	JpathNode *p = jsonGetJpathParam(jn,0);
	int i=0;
	for(;i<ctx->count;++i) {
		addJsonNode(rjns,jsonCloneNode(p->data));
		JsonNode*test=jpathExecute(ctx->nodes[i],p);
	}
	return rjns;
}

JsonNodeSet *__jpif(JsonNodeSet *ctx,JpathNode **jn) {
	JsonNodeSet *rjns = newJsonNodeSet();
	if(ctx->count == 0) { return rjns; }
	JSONTESTPARAMS(jn,1);
	JpathNode *p1 = jsonGetJpathParam(jn,0);
	int i=0;
	for(;i<ctx->count;++i) {
		JsonNode*test=jpathExecute(ctx->nodes[i],p1);
		if(jsonTestBooleanNode(test)) {
			addJsonNode(rjns,ctx->nodes[i]);
		}
		freeJsonNode(test);
	}
	return rjns;
}

int __cmplt(int n) { return n < 0 ? 1 : 0; }
int __cmpgt(int n) { return n > 0 ? 1 : 0; }
int __cmplte(int n) { return n <= 0 ? 1 : 0; }
int __cmpgte(int n) { return n >= 0 ? 1 : 0; }
int __cmpneq(int n) { return n != 0 ? 1 : 0; }
int __cmpeq(int n) { return n == 0 ? 1 : 0; }

JsonNodeSet*__jpgte(JsonNodeSet *ctx,JpathNode **jn) { return __jpcompare(ctx,jn,__cmpgte); }
JsonNodeSet*__jplte(JsonNodeSet *ctx,JpathNode **jn) { return __jpcompare(ctx,jn,__cmplte); }
JsonNodeSet*__jpeq(JsonNodeSet *ctx,JpathNode **jn) { return __jpcompare(ctx,jn,__cmpeq); }
JsonNodeSet*__jpneq(JsonNodeSet *ctx,JpathNode **jn) { return __jpcompare(ctx,jn,__cmpneq); }
JsonNodeSet*__jplt(JsonNodeSet *ctx,JpathNode **jn) { return __jpcompare(ctx,jn,__cmplt); }
JsonNodeSet*__jpgt(JsonNodeSet *ctx,JpathNode **jn) { return __jpcompare(ctx,jn,__cmpgt); }

// this is a derivation
JsonNodeSet*__jpcompare(JsonNodeSet *ctx,JpathNode **jn,int(cmpop)(int)) {
	JSONTESTPARAMS(jn,2);
	if(ctx->count == 0) { return ctx; }
	JpathNode *p1 = jsonGetJpathParam(jn,0);
	JpathNode *p2 = jsonGetJpathParam(jn,1);

	int i;
	for(i=0;i<ctx->count;++i) {
		JsonNode* rs = jpathExecute(ctx->nodes[i],p1);
		char* str1 = jsonToString(rs);
		freeJsonNode(rs);
		rs = jpathExecute(ctx->nodes[i],p2);
		char* str2 = jsonToString(rs);
		freeJsonNode(rs);

		int r = strcmp(str1,str2);
		JPATHFREE(str1);
		JPATHFREE(str2);
		r = cmpop(r);
		ctx->nodes[i] = jsonCreateNumber(ctx->nodes[i],r,r);
	}
	return ctx;
}

// this is a replacement
JsonNodeSet *__jpul(JsonNodeSet *ctx,JpathNode **jn,int(*modifier)(int)) {
	JSONTESTPARAMS(jn,1);
	int i = 0;
	JpathNode*p = jn[0];
	for(i=0;i<ctx->count;++i) {
		JsonNode* rs = jpathExecute(ctx->nodes[i],p);
		char* txt =  jsonToString(rs);
		freeJsonNode(rs);

		int j,slen = strlen(txt);
		for(j =0;j<slen;++j) {
			txt[j] = modifier(txt[j]);
		}
		ctx->nodes[i]=jsonCreateString(ctx->nodes[i]->parent,txt);
		JPATHFREE(txt);
	}
	return ctx;
}

JsonNodeSet *__jplower(JsonNodeSet *ctx,JpathNode **jn) {
	return __jpul(ctx,jn,tolower);
}

JsonNodeSet *__jpupper(JsonNodeSet *ctx,JpathNode **jn) {
	return __jpul(ctx,jn,toupper);
}

JsonNodeSet *__jpconcat(JsonNodeSet *ctx,JpathNode **jn) {
	JSONTESTPARAMS(jn,-1);

	int i = 0;
	for(i=0;i<ctx->count;++i) {
		JpathNode**p = jn;
		// initialize;
		char*buff = NULL;
		for(; *p != NULL; ++p) {
			JsonNode* rs = jpathExecute(ctx->nodes[i],*p);
			char* txt = jsonToString(rs);
			char* buff2 = jsonAppendString(buff, txt);

			JSONFREE(txt);
			JSONFREE(buff);
			buff=(char*)buff2;
		}
		ctx->nodes[i] = jsonCreateString(ctx->nodes[i],buff);
		JSONFREE(buff);
	}
	return ctx;
}

JsonNodeSet * __jpavg(JsonNodeSet *ctx, JpathNode **p) {
	JSONSTARTCONTEXT(ctx,p)
	if(ctx->count == 0) { return ctx; }

	int cnt = ctx->count;
	JsonNodeSet *rs = __jpsum(ctx,NULL);
	JsonNode*r=ctx->nodes[0];
	double df = r->fval / cnt;
	r->ival = (long) df;
	r->fval = df;
	return rs;
}

JsonNodeSet * __jpcount(JsonNodeSet *ctx, JpathNode **p) {
	JSONSTARTCONTEXT(ctx,p)
	if(ctx->count == 0) { return ctx; }
	JsonNodeSet * rs = newJsonNodeSet();
	JsonNode *parent = jsonGetParent(ctx->nodes[0]);
	// check if all input nodes share the same parent
	int i;
	for(i=0;i<ctx->count;++i) {
		JsonNode*pp = jsonGetParent(ctx->nodes[i]);
		parent = parent == pp ? parent : NULL;
	}
	addJsonNode(rs,jsonCreateNumber(parent,ctx->count,ctx->count));
	return rs;
}

JsonNodeSet * __jpsize(JsonNodeSet *ctx, JpathNode **p) {
	JSONSTARTCONTEXT(ctx,p)
	if(ctx->count == 0) { return ctx; }
	int i;
	for(i=0;i<ctx->count;++i) {
		ctx->nodes[i] = jsonCreateNumber(ctx->nodes[i],ctx->nodes[i]->children,ctx->nodes[i]->children);
	}
	return ctx;
}

JsonNodeSet * __jplimit(JsonNodeSet *ctx, JpathNode **p,double(*choose)(double,double),int acc) {
	JSONSTARTCONTEXT(ctx,p)
	if(ctx->count == 0) { return ctx; }
	JsonNodeSet * ns = newJsonNodeSet();
	JsonNode *parent = ctx->nodes[0]->parent;


	if(ctx->nodes[0]->type == TYPE_NUMBER) {
		double total = acc ? ctx->nodes[0]->fval : 0;

		int i = 0;
		for(;i<ctx->count;++i) {
			total = choose(total,ctx->nodes[i]->fval);
			// if they all share a parent, then the result will share that parent
			parent = parent == ctx->nodes[i]->parent ? parent : NULL;
		}
		freeJsonNodeSet(ctx);
		addJsonNode(ns,jsonCreateNumber(parent,(long)total,total));
	} else if(ctx->nodes[0]->type == TYPE_OBJECT) {
		JsonNode*r=jsonCreateObject(NULL);
		int i;
		for(i=0;i<ctx->count;++i) {
			if(ctx->nodes[i]->type == TYPE_OBJECT) {
				JsonNode*key= ctx->nodes[i]->first;
				while(key!=NULL) {
					const char*name=key->str;
					JsonNode* val=key->first;
					if(val->type == TYPE_NUMBER) {
						JsonNode* rn=jsonGetMember(r,name);
						if(rn == NULL) {
							double total = acc ? val->fval : 0;
							rn = jsonCreateNumber(r,(long)total,total);	
						}
						rn->fval = choose(rn->fval,val->fval);
						rn->ival = (long) rn->fval;
					}
					key =key->next;
				}
				parent = parent == ctx->nodes[i]->parent ? parent : NULL;
			}
		}
		r->parent=parent;
		addJsonNode(ns,r);
	}
	return ns;
}

double mostof(double a, double b) { return a > b ? a : b; }
double sumof(double a, double b) { return a + b; }
double leastof(double a, double b) { return a < b ? a : b; }

JsonNodeSet * __jpmin(JsonNodeSet *ctx, JpathNode **p) { return __jplimit(ctx,p,leastof,0); }
JsonNodeSet * __jpmax(JsonNodeSet *ctx, JpathNode **p) { return __jplimit(ctx,p,mostof,0); }
JsonNodeSet * __jpsum(JsonNodeSet *ctx, JpathNode **p) { return __jplimit(ctx,p,sumof,1); }

JpathNode * newJpathNode(jpathproc proc, const char* name,JpathNode **params, JsonNode*data,int nargs, int ag, JpathNode *next) {
	JpathNode* jp = JPATHALLOC(sizeof(JpathNode));
	jp->proc = proc;
	jp->name = name;
	jp->params = params;
	jp->nargs = nargs;
	jp->aggr = ag;
	jp->next = next;
	jp->data = data;
	return jp;
}

JsonNode *jpathExecute(JsonNode *ctx,JpathNode *jn) {
	JsonNode*res = NULL;
	JsonNodeSet *_ctx = newJsonNodeSet();
	addJsonNode(_ctx,ctx);
	JsonNodeSet *rs = __jpathExecute(_ctx,jn);
	if(rs!=NULL) {
		res = jsonNodeSetGet(rs,0);
		freeJsonNodeSet(rs);
	}
	freeJsonNodeSet(_ctx);
	return res;
}

JsonNodeSet *__jpathExecute(JsonNodeSet *ctx,JpathNode *jn) {

	JsonNodeSet *rjns;
	if(jn->aggr) {
		rjns = jn->proc(ctx,jn->params);
	} else { 
		rjns = newJsonNodeSet();
		JsonNodeSet *params = newJsonNodeSet();
		if(ctx->count > 0) {
			addJsonNode(params, jsonCreateNumber(NULL,0,0));
			jsonFree(params->nodes[0]);

			int i = 0;
			for(; i < ctx->count; ++i) {
				params->nodes[0] = ctx->nodes[i];
				JsonNodeSet *ir = jn->proc(params,jn->params);
				addJsonNodeSet(rjns,ir);
				freeJsonNodeSet(ir);
			}
			freeJsonNodeSet(params);
		}
	}

	JsonNodeSet * result;
	if(jn->next != NULL) {
		result = __jpathExecute(rjns,jn->next);
		freeJsonNodeSet(rjns);
	} else {
		result = rjns;
	}
	return result;
}

int jpatherror(const char*msg) {
 fprintf(stderr,"error at %d: %s\n",jpathcolumn,(msg)) ;
}

int parseJpath(const char *s) {
   YY_BUFFER_STATE buff = SCANSTRING(s);
   SWITCHTOBUFFER(buff);
   int res = PARSE();
   DELETEBUFFER(buff);
   return res;
}
