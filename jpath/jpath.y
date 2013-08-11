%{
// jpath

// /**/field/*
// **/f/if(../dept = 32)/id

// */users/*/group(dept)
// */users/{id,dept}


// */[id,dept]

// count(**/email)
// **/email/count()


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


#define PARAMPAIR(j,x,y) {	\
		JpathNode **__prm = JPATHALLOC(sizeof(JpathNode*)*3);	\
		__prm[0] = (x);	\
		__prm[1] = (y);	\
		__prm[2] = NULL;	\
		(j)->params = __prm;	\
	}

int jpathcolumn = 0;

%}

%code requires {
	#include "jpath.h"
}

%union {
	JpathNode *jp;
	jpathproc proc;
	JpathNode **plist;
	char*str;
	double fval;
	long ival;
}

%locations

%parse-param { JpathNode **jpexp }

%type<str> chars dstr sstr string label 

%type<jp> func fstep bstep step fcall const
%type<jp> relpath cmpexp orexp mathexp pexp
%type<jp> pathstep test nametest kindtest ttop  jpath abspath mathop cmpop

%type<plist> plist


%token JPAND JPOR
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

jpath : abspath  { 
		$$ = $1; 
		*jpexp = $$;
	}

abspath 
	: relpath { $$ = $1; 
	}
	| '/' relpath { 
	 	 $$ = JPATHFUNC("topp",__jptopparent,0,0); 
		 JPATHAPPEND($$,$2);
//		 $$->next = $2;
	}

relpath
	: cmpexp  { $$ = $1; 
	}
	| relpath '/' cmpexp {
		$$ = $1;
//		$$->next = $3;
		 JPATHAPPEND($$,$3);
	}

/*
sortexp
	: groupexp { $$ = $1; }
	| SORT '(' jpath ')'

groupexp
	: ifexp { $$ = $1; }
	| GROUP '(' jpath ')'

ifexp
	: cmpexp { $$ = $1; }
	| IF '(' jpath ')'

*/

cmpexp
   : orexp { $$ = $1; }
	| cmpexp cmpop orexp	{
		$$ = $2;
		PARAMPAIR($$,$1,$3);
	}

cmpop
	: '=' 	{ $$ = JPATHFUNC("cmpeq",__jpeq,2,1); }
	| '<' 	{ $$ = JPATHFUNC("cmplt",__jplt,2,1); }
	| '>' 	{ $$ = JPATHFUNC("cmpgt",__jpgt,2,1); }
	| NE 		{ $$ = JPATHFUNC("cmpne",__jpneq,2,1); }
	| GTE 	{ $$ = JPATHFUNC("cmpgte",__jpgte,2,1); }
	| LTE 	{ $$ = JPATHFUNC("cmplte",__jplte,2,1); }

orexp
	: mathexp { $$ = $1; }
	| orexp '|' mathexp {
		$$ = JPATHFUNC("union",__jpunion,2,1); 
		PARAMPAIR($$,$1,$3);
	}

mathexp 
	: pathstep  { $$ = $1; }
	| mathexp mathop pathstep {
		$$ = $2;
		PARAMPAIR($$,$1,$3);
	}

mathop 
	: '+' { $$ = JPATHFUNC("add",__jpadd,2,1); }
	| '-' { $$ = JPATHFUNC("sub",__jpsub,2,1); }
	| '*' { $$ = JPATHFUNC("mul",__jpmul,2,1); }
	| DIV { $$ = JPATHFUNC("div",__jpdiv,2,1); }
	| '%' { $$ = JPATHFUNC("mod",__jpmod,2,1); }

pathstep
   : step  { $$ = $1; }
	| test  { $$ = $1; }
	| pexp { $$ = $1; }
	| dex { $$ = NULL; }
	| pathstep dex { $$ = NULL; }

test
   : nametest { $$ = $1; }
	| kindtest { $$ = $1; }

nametest: label { 
	$$ = JPATHFUNCDATA("name",__jpnametest,jsonCreateString(NULL,$1));  
	}

label: LABEL { $$ = $1; }

kindtest 
	: ttop '(' ')' { $$ = $1; }

ttop 
	: NUMBER	{ $$ = JPATHFUNC("number",__jpnumbertest,-1,0); } 
   | TEXT	{ $$ = JPATHFUNC("text",__jptexttest,-1,0); }
   | SCALAR	{ $$ = JPATHFUNC("scalar",__jpscalartest,-1,0); }
   | ARRAY	{ $$ = JPATHFUNC("array",__jparraytest,-1,0); }
   | OBJECT	{ $$ = JPATHFUNC("object",__jpobjecttest,-1,0); }
   | NULLV	{ $$ = JPATHFUNC("nulltest",__jpnulltest,-1,0); }

pexp
	: const { $$ = $1; }
	| '(' jpath ')' { $$ = $2; }
	| var { $$ = NULL; }
	| fcall  { 
		/* only valid in jtl ?? */
			$$ = $1;
		}

fcall 
	: func '(' plist ')' {
		$$ = $1;
		$$->params = $3;
	}
	| func '(' ')' { $$ = $1; }
	
func 
	: label { 
		$$ = functionFactory($1);
	}

plist
	: jpath {
		$$ = (JpathNode**)JPATHALLOC(sizeof(JpathNode*) * 2);
		$$[0] = ($1); 
		$$[1] = NULL;
	}
	| plist ',' jpath {
		int n = plistSize($1);
		$$ = (JpathNode**)JPATHALLOC(sizeof(JpathNode*) * (n+2));
		int i;
		for(i = 0; i < n; ++i) {
			$$[i] = $1[i];
		}
		$$[i] = $3; $$[i+1] = NULL;
	}

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


// needs a whole variable table thing to implmenet this one
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
			JPATHFREE($1);
			JPATHFREE($2);
		}

dex
	: '[' rangexp ']'

rangexp : jpath DDOT jpath 
	| jpath DDOT
	| plist

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


void jsonPopulateArray(JsonNode*array, JsonNodeSet *ns) {
	int i;
	for(i=0;i<ns->count;++i) {
		jsonArrayAppend(array,jsonCloneNode(ns->nodes[i]));
	}
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

JpathNode* jsonGetJpathParam(JpathNode*ptr,int x)  { 
	JpathNode **pp = ptr->params;
	int i = 0;
	for(;i <= x && pp != NULL && (*pp) != NULL; ++i,++pp){
		if((x) == i) return *pp;
	}
	return NULL;
}

JsonNodeSet *evalParam(JtlEngine *engine,JsonNodeSet *ctx,JpathNode *p,int n) {
	JpathNode *p1 = jsonGetJpathParam(p,n);
	if(p1 != NULL) {
		return __jpathExecute(engine,ctx,p1);
	}
	return NULL;
}

JsonNodeSet *tempContext(JtlEngine *engine,JsonNodeSet*ctx,JpathNode *p) {
	JpathNode *p1 = jsonGetJpathParam(p,0);
	if(p1!=NULL) {
		JsonNodeSet*ctx2=__jpathExecute(engine,ctx,p1);
		ctx=ctx2;
	}
	return ctx;
}

#define JSONENDCONTEXT()   	\
	{ if(ctx != context) freeJsonNodeSet(context); }

#define JSONSTARTCONTEXT(en,x,p)   	\
	JsonNodeSet *context = (x);		\
	if((p) != NULL && (p)->nargs!=0) { \
	JsonNodeSet *_ctx = tempContext(en,context,(p));	\
	if(_ctx != NULL) {			\
		context = _ctx;					\
	} }								\


#define JSONTESTPARAMS(p,x)	\
	if((x) != -1)  { 				\
		if((x) > 0) { 				\
			JpathNode **pp = (p)->params;				\
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
		} 					\
	}
	
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

JsonNodeSet *__monadic(JtlEngine *engine,JsonNodeSet *ctx,JpathNode *jn,JsonNode*(*mono)(JsonNode*) ) {
	JSONSTARTCONTEXT(engine,ctx,jn)
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<context->count;++i) {
		addJsonNode(rjns,mono(context->nodes[i]));
	}
	JSONENDCONTEXT();
	return rjns;
}

JsonNode *__nulltype(JsonNode*jn) {
	int n = jn->type == TYPE_STRING  && jn->str == NULL ? 1 : 0;
	return jsonCreateNumber(NULL,n,n);
}
JsonNode *__stringtype(JsonNode*jn) {
	int n = jn->type == TYPE_STRING ? 1 : 0;
	return jsonCreateNumber(NULL,n,n);
}
JsonNode *__arraytype(JsonNode*jn) {
	int n = jn->type == TYPE_ARRAY ? 1 : 0;
	return jsonCreateNumber(NULL,n,n);
}
JsonNode *__objecttype(JsonNode*jn) {
	int n = jn->type == TYPE_OBJECT ? 1 : 0;
	return jsonCreateNumber(NULL,n,n);
}
JsonNode *__numtype(JsonNode*jn) {
	int n = jn->type == TYPE_NUMBER ? 1 : 0;
	return jsonCreateNumber(NULL,n,n);
}
JsonNode *__scalartype(JsonNode*jn) {
	int n = jn->type == TYPE_NUMBER || jn->type == TYPE_STRING ? 1 : 0;
	return jsonCreateNumber(NULL,n,n);
}

JsonNodeSet *__jpnulltest(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __monadic(engine,ctx,jn,__nulltype);
}

JsonNodeSet *__jpobjecttest(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __monadic(engine,ctx,jn,__objecttype);
}

JsonNodeSet *__jparraytest(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __monadic(engine,ctx,jn,__arraytype);
}

JsonNodeSet *__jptexttest(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __monadic(engine,ctx,jn,__stringtype);
}

JsonNodeSet *__jpnumbertest(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __monadic(engine,ctx,jn,__numtype);
}

JsonNodeSet *__jpscalartest(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __monadic(engine,ctx,jn,__scalartype);
}

/*
JsonNodeSet *__jpselect(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	JsonNodeSet *rjns = newJsonNodeSet();
	int i;
	JsonNode* sel = jsonCreateArray(NULL);
	JpathNode **params = jn->params;
	while(*params) {
		JsonNode*pr = jPathExecute(ctx,*params);
		jsonArrayAppend(sel,jsonCloneNode(pr));
		++params;
	}

	for(i=0;i<ctx->count;++i) {
		if(ctx->nodes[i]-> type == TYPE_OBJECT) {
			JsonNode *it = ctx->nodes[i]->first;
			while(it) {
				it = it->next;
			}
		}
	}
}
*/

JsonNodeSet *__jpnot(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	JsonNodeSet *rjns = newJsonNodeSet();
	int i;
	for(i=0;i<ctx->count;++i) {
		int test = jsonTestBooleanNode(ctx->nodes[i]) == 0 ? 1 : 0;
		addJsonNode(rjns,jsonCreateNumber(NULL,test,test));
	}
	return rjns;
}

JsonNodeSet *__jpnametest(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
//	JSONTESTPARAMS(jn,0);
	JsonNodeSet *rjns = newJsonNodeSet();
	if(ctx->count > 0) {
	TRACE("");
		int i=0;
		for(;i<ctx->count;++i) {
	TRACE(jn->data->str);
	TRACEJSON(ctx->nodes[i]);
			JsonNode *ir = jsonGetMember(
				ctx->nodes[i],
				jn->data->str);
			if(ir != NULL) {
	TRACE("adding");
	TRACEJSON(ir);
				addJsonNode(rjns,jsonCloneNode(ir));
			} else {
	TRACE("");
//				if(ctx->count == 1) addJsonNode(rjns,jsonCreateNull(NULL));
			}
		}
	}
	return rjns;
}

/* single operand numeric functions */
JsonNodeSet *__numeric(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn,double (*dfunc)(double)) {
	JSONSTARTCONTEXT(engine,ctx,jn)
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<context->count;++i) {
		JsonNode *n = context->nodes[i];
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
	JSONENDCONTEXT();
	return rjns;
}

JsonNodeSet *__jpround(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __numeric(engine,ctx,jn,round);	
}

JsonNodeSet *__jpceil(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __numeric(engine,ctx,jn,ceil);	
}

JsonNodeSet *__jpfloor(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __numeric(engine,ctx,jn,floor);	
}

JsonNodeSet *__jpsqrt(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __numeric(engine,ctx,jn,sqrt);	
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

JsonNodeSet *__jprand(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __numeric(engine,ctx,jn,jrand);	
}


JsonNodeSet *__jppeach(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	JSONSTARTCONTEXT(engine,ctx,jn);
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<context->count;++i) {
		JsonNode *pp = context->nodes[i]->parent;
		while(pp != NULL) {
			addJsonNode(rjns,pp);
			pp = pp->parent;
		}
	}
	JSONENDCONTEXT();
	return rjns;
}

JsonNodeSet *__jptopparent(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	JSONSTARTCONTEXT(engine,ctx,jn);
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<context->count;++i) {
		JsonNode *pp =  context->nodes[i];
		while(pp->parent) {
			pp=pp->parent;
		}
		addJsonNode(rjns,pp);
	}
	JSONENDCONTEXT();
	return rjns;
}

JsonNodeSet *__jpparent(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	JSONSTARTCONTEXT(engine,ctx,jn);
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<context->count;++i) {
		JsonNode *pp = context->nodes[i]->parent;
		if(pp != NULL) addJsonNode(rjns,pp);
	}
	JSONENDCONTEXT();
	return rjns;
}

JsonNodeSet *__jpeachrecurse(JtlEngine* engine,JsonNodeSet *result,JsonNode *ctx) {
	addJsonNode(result,jsonCloneNode(ctx));

	if(ctx->type == TYPE_ARRAY) {
		int i=0;
		JsonNode *eech = ctx->first;
		while(eech != NULL) {
			__jpeachrecurse(engine,result,eech);
			eech = eech->next;
		}
	} else if(ctx->type == TYPE_OBJECT) {
		int i=0;
		JsonNode *eech = ctx->first;
		while(eech != NULL) {
			__jpeachrecurse(engine,result,eech->first);
			eech = eech->next;
		}
	} 
	return result;
}

JsonNodeSet *__jpeachdeep(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<ctx->count;++i) {
		__jpeachrecurse(engine,rjns,ctx->nodes[i]);	
	}
	return  rjns;
}

JsonNodeSet *__jpeach(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
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
		} else if(n->type == TYPE_OBJECT) {
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

JsonNodeSet *__jpident(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	JsonNodeSet *rjns = newJsonNodeSet();
	TRACE("IDENT");
	int i=0;
	for(;i<ctx->count;++i) {
		addJsonNode(rjns,jsonCloneNode(ctx->nodes[i]));
	}
	return rjns;
}

JsonNodeSet *__jpnoop(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __jpident(engine,ctx,jn);
}

JsonNodeSet * __jpevaldata(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *jn) {
	JsonNodeSet *rjns = newJsonNodeSet();
TRACE("eval data");
	int i=0;
	for(;i<ctx->count;++i) {
TRACE("eval data loop");
	addJsonNode(rjns,jsonCloneNode(jn->data));
//		addJsonNode(rjns,(jn->data));
	}
TRACE("eval data return");
	return rjns;
}

JsonNodeSet *__jpif(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
TRACE("IF!!!");
	JsonNodeSet *rjns = newJsonNodeSet();
	JSONTESTPARAMS(jn,1);
	if(ctx->count == 0) { return rjns; }
	JpathNode *p1 = jsonGetJpathParam(jn,0);
	JsonNodeSet*test=__jpathExecute(engine,ctx,p1);
	int i;
	if(test->count == 1) {
		if(jsonTestBooleanNode(test->nodes[0])) {
			for(i=0;i<ctx->count;++i) {
				addJsonNode(rjns,jsonCloneNode(ctx->nodes[i]));
			}
		}
	} else if(test->count == ctx->count) {
		for(i=0;i<ctx->count;++i) {
			if(jsonTestBooleanNode(test->nodes[i])) {
				addJsonNode(rjns,jsonCloneNode(ctx->nodes[i]));
			}
		}
	} else if(ctx->count == 1 && ctx->nodes[0]->type == TYPE_ARRAY && test->count == ctx->nodes[0]->children) {
		JsonNode *it = ctx->nodes[0]->first;
		for(i=0;i<test->count && it != NULL;++i) {
			if(jsonTestBooleanNode(test->nodes[i])) {
				addJsonNode(rjns,jsonCloneNode(it));
			}
			it =it->next;
		}
	} else if(test->count == 0) {
	// empty result
	} else {
fprintf(stderr,"JPIF:: test->count = %d, ctx->count = %d\n",test->count,ctx->count);
		addJsonNode(rjns,jsonCreateString(NULL,"!!mismatch error in test statement!!"));
	}
	freeJsonNodeSet(test);
	return rjns;
}

JsonNodeSet*__jparith(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn,double(arithop)(double,double)) {
	JSONTESTPARAMS(jn,2);
	JsonNodeSet *rjns = newJsonNodeSet();

	if(ctx->count == 0) { return rjns; }
	JpathNode *p1 = jsonGetJpathParam(jn,0);
	JpathNode *p2 = jsonGetJpathParam(jn,1);
	JsonNodeSet* rs1 = __jpathExecute(engine,ctx,p1);
	JsonNodeSet* rs2 = __jpathExecute(engine,ctx,p2);
	double r;
	int i;
	if(rs1->count == rs2->count) {
		for(i=0;i<rs2->count;++i) {
			r = arithop(rs1->nodes[i]->fval,rs2->nodes[i]->fval);
			addJsonNode(rjns,jsonCreateNumber(NULL,(long)r,r));
		}
	} else if(rs1->count == 1) {
		for(i=0;i<rs2->count;++i) {
			r = arithop(rs1->nodes[0]->fval,rs2->nodes[i]->fval);
			addJsonNode(rjns,jsonCreateNumber(NULL,(long)r,r));
		}
	} else if(rs2->count == 1) {
		for(i=0;i<rs1->count;++i) {
			r = arithop(rs1->nodes[i]->fval,rs2->nodes[0]->fval);
			addJsonNode(rjns,jsonCreateNumber(NULL,(long)r,r));
		}
	}
	return rjns;

}

double __arithadd(double a, double b) { return a + b ; }
double __arithsub(double a, double b) { return a - b ; }
double __arithmul(double a, double b) { return a * b ; }
double __arithdiv(double a, double b) { return a / b ; }
double __arithmod(double a, double b) { return ((long)a) % ((long)b) ; }
double __arithpow(double a, double b) { return pow(a,b); }


JsonNodeSet*__jpadd(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jparith(engine,ctx,jn,__arithadd); }
JsonNodeSet*__jpsub(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jparith(engine,ctx,jn,__arithsub); }
JsonNodeSet*__jpmul(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jparith(engine,ctx,jn,__arithmul); }
JsonNodeSet*__jpdiv(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jparith(engine,ctx,jn,__arithdiv); }
JsonNodeSet*__jpmod(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jparith(engine,ctx,jn,__arithmod); }
JsonNodeSet*__jppow(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jparith(engine,ctx,jn,__arithpow); }

int __cmplt(int n) { return n < 0 ? 1 : 0; }
int __cmpgt(int n) { return n > 0 ? 1 : 0; }
int __cmplte(int n) { return n <= 0 ? 1 : 0; }
int __cmpgte(int n) { return n >= 0 ? 1 : 0; }
int __cmpneq(int n) { return n != 0 ? 1 : 0; }
int __cmpeq(int n) { return n == 0 ? 1 : 0; }

JsonNodeSet*__jpgte(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jpcompare(engine,ctx,jn,__cmpgte); }
JsonNodeSet*__jplte(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jpcompare(engine,ctx,jn,__cmplte); }
JsonNodeSet*__jpeq(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jpcompare(engine,ctx,jn,__cmpeq); }
JsonNodeSet*__jpneq(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jpcompare(engine,ctx,jn,__cmpneq); }
JsonNodeSet*__jplt(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jpcompare(engine,ctx,jn,__cmplt); }
JsonNodeSet*__jpgt(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) { return __jpcompare(engine,ctx,jn,__cmpgt); }

// this is a derivation
JsonNodeSet*__jpcompare(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn,int(cmpop)(int)) {
	JSONTESTPARAMS(jn,2);
	JsonNodeSet *rjns = newJsonNodeSet();

TRACE("jpcompare");
	if(ctx->count == 0) { return rjns; }
	JpathNode *p1 = jsonGetJpathParam(jn,0);
	JpathNode *p2 = jsonGetJpathParam(jn,1);
TRACE("jpcompare p1");
	JsonNodeSet* rs1 = __jpathExecute(engine,ctx,p1);
TRACE("jpcompare p2");
	JsonNodeSet* rs2 = __jpathExecute(engine,ctx,p2);

TRACE("jpcompare apply");
	int cmp,i;
	if(rs1->count == rs2->count) {
TRACE("jpcompare apply 1");

#ifdef DEBUG
fprintf(stderr,"jpcompare, same count: %d\n",rs1->count);
#endif

		for(i=0;i<rs2->count;++i) {
TRACE("");
			cmp = compareJsonNodes(rs1->nodes[i],rs2->nodes[i]);
TRACE("");
			cmp = cmpop(cmp);
TRACE("");
			addJsonNode(rjns,jsonCreateNumber(NULL,(long)cmp,cmp));
TRACE("");
		}
	} else if(rs1->count == 1) {
TRACE("jpcompare apply 2");
		for(i=0;i<rs2->count;++i) {
			cmp = compareJsonNodes(rs1->nodes[0],rs2->nodes[i]);
			cmp = cmpop(cmp);
			addJsonNode(rjns,jsonCreateNumber(NULL,(long)cmp,cmp));
		}
	} else if(rs2->count == 1) {
TRACE("jpcompare apply 3");
		for(i=0;i<rs1->count;++i) {
			cmp = compareJsonNodes(rs1->nodes[i],rs2->nodes[0]);
			cmp = cmpop(cmp);
			addJsonNode(rjns,jsonCreateNumber(NULL,(long)cmp,cmp));
		}
	} else if(rs1->count == 0 || rs2->count == 0) {
TRACE("jpcompare apply 4");
	// no result
	} else {
TRACE("jpcompare apply 5");
		addJsonNode(rjns,jsonCreateString(NULL,"!!error matching in comparison"));
	}
	return rjns;
}

JsonNodeSet *__jpul(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn,int(*modifier)(int)) {
	JsonNodeSet *rjns = newJsonNodeSet();
	if(ctx->count == 0) { return rjns; }
	JSONTESTPARAMS(jn,1);
	JSONSTARTCONTEXT(engine,ctx,jn);
	int i = 0;
	for(i=0;i<context->count;++i) {
		JsonNode* rs = jpathExecute(engine,context->nodes[i],jn);
		char* txt =  jsonToString(rs);
		freeJsonNode(rs);

		int j,slen = strlen(txt);
		for(j =0;j<slen;++j) {
			txt[j] = modifier(txt[j]);
		}
		addJsonNode(rjns,jsonCreateString(NULL,txt));
		JPATHFREE(txt);
	}
	return ctx;
}

JsonNodeSet *__jplower(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __jpul(engine,ctx,jn,tolower);
}

JsonNodeSet *__jpupper(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	return __jpul(engine,ctx,jn,toupper);
}

JsonNodeSet *__jpconcat(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	JSONTESTPARAMS(jn,-1);

	int i = 0;
	for(i=0;i<ctx->count;++i) {
		JpathNode**p = jn->params;
		// initialize;
		char*buff = NULL;
		for(; *p != NULL; ++p) {
			JsonNode* rs = jpathExecute(engine,ctx->nodes[i],*p);
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

JsonNodeSet * __jpavg(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) {
	JsonNodeSet * ns = newJsonNodeSet();
	if(ctx->count == 0) { return ns; }
TRACE("");
	JSONSTARTCONTEXT(engine,ctx,p);

TRACE("");
	int cnt = context->count;
TRACE("");
/* 
	__jpsum will return a  NodeSet with a single member
		that member will be
		TYPE_NUMBER if context consists of an array of numbers
		TYPE_OBJECT if context consists of an array of objects, sum for each discovered field 
		```?? TYPE_ARRAY to be tranversed optionally?
		on error: TYPE_NUMBER with value NAN
  */
TRACE("");
	JsonNodeSet *rs = __jpsum(engine,context,p);
TRACE("");
	JsonNode*r=rs->nodes[0];
TRACE("");
	freeJsonNodeSet(rs);
	rs = newJsonNodeSet();
TRACE("");
	if(r->type == TYPE_NUMBER) {
TRACE("");
		if(isnan(r->fval)) {
TRACE("");
			addJsonNode(rs,jsonCreateNumber(NULL,0L,NAN));
		} else {
TRACE("");
			double df = r->fval / context->count;
TRACE("");
			addJsonNode(rs,jsonCreateNumber(NULL,(long) df,df));
TRACE("");
		}
	} else {
TRACE("");
	// it's an object::
		JsonNode* container = jsonCreateObject(NULL);
		JsonNode *el =   r->first;
		while(el != NULL) {
			double df = el->first->fval;
			if(df == NAN) {
				jsonCreateNull(container);
	 		} else {
				 df /= context->count;
				jsonObjectAppend(container,el->str,jsonCreateNumber(NULL,(long)df,df));
			}
		}
		el = el->next;
	}
//	freeJsonNode(r);
TRACE("");
	JSONENDCONTEXT();
	return rs;
}

JsonNodeSet * __jpcount(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) {
	JsonNodeSet * rs = newJsonNodeSet();
	if(ctx->count == 0) { return rs; }
	JSONSTARTCONTEXT(engine,ctx,p);
//	JsonNode *parent = jsonGetParent(context->nodes[0]);
	// check if all input nodes share the same parent
	addJsonNode(rs,jsonCreateNumber(NULL,context->count,context->count));
	JSONENDCONTEXT();
	return rs;
}

JsonNodeSet * __jpsize(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) {
	JsonNodeSet * ns = newJsonNodeSet();
	JSONSTARTCONTEXT(engine,ctx,p);
	if(context->count == 0) { return ns; }
	int i;
	for(i=0;i<context->count;++i) {
		JsonNode *jjn = jsonCreateNumber(NULL,context->nodes[i]->children,context->nodes[i]->children);
		addJsonNode(ns, jjn);
	}
	JSONENDCONTEXT()
	return ns;
}

JsonNodeSet * __jplimit(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p,double(*choose)(double,double),int acc) {
	JsonNodeSet * ns = newJsonNodeSet();
	if(ctx->count == 0) { return ns; }
TRACE("");
	JSONSTARTCONTEXT(engine,ctx,p)
TRACE("");


	int i;
	double total = NAN;
	for(i=0;i<context->count;++i) {
TRACE("");
	TRACEJSON(context->nodes[i]);


		if(context->nodes[i]->type == ARRAY) {
TRACE("limiting arrays");
			JsonNode *arr = jsonCreateArray(NULL);
			JsonNode *it = context->nodes[i]->first;
			JsonNodeSet *pps = newJsonNodeSet();
			JsonNode*dummy = jsonCreateNull(NULL);
			addJsonNode(pps,dummy);
			while(it) {
				pps->nodes[0] = it;
				JsonNodeSet *ir = __jplimit(engine,pps,p,choose,acc);
//				addJsonNodeSet(ns,ir);
				jsonPopulateArray(arr,ir);
				freeJsonNodeSet(ir);
				it = it->next;
			}
			pps->nodes[0] = dummy;
			freeJsonNodeSet(pps);
			addJsonNode(ns,arr);
		} else {
TRACE("limiting singles");
				total = choose(context->nodes[i]->fval,total);
		}
		fprintf(stderr,"choosing from %f, total is %f\n",context->nodes[i]->fval,total);
			/*
		if(context->nodes[i]->type == ARRAY) {
TRACE("");



			JsonNode*it=context->nodes[i]->first;
			while(it) {
TRACE("");
				fprintf(stderr,"choosing from %f\n",it->fval);
				total = choose(it->fval,total);
				it = it->next;
			}
		}

	*/




	}
	addJsonNode(ns,jsonCreateNumber(NULL,(long)total,total));
	JSONENDCONTEXT();
TRACE("");
	return ns;
}

double mostof(double a, double b) { return isnan(b) ? a : (a > b ? a : b); }
double sumof(double a, double b) { 
	double result = isnan(b) ? a : (a + b);
	fprintf(stderr,"a = %f, b = %f, result = %f\n",a,b,result);
	return result;
}
double leastof(double a, double b) { return isnan(b) ? a : (a < b ? a : b); }

JsonNodeSet * __jpmin(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) { return __jplimit(engine,ctx,p,leastof,0); }
JsonNodeSet * __jpmax(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) { return __jplimit(engine,ctx,p,mostof,0); }
JsonNodeSet * __jpsum(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) { return __jplimit(engine,ctx,p,sumof,0); }

JsonNodeSet * __jpunion(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) { 
	JSONTESTPARAMS(p,2);
	JsonNodeSet *r1=evalParam(engine,ctx,p,0);
	JsonNodeSet *r2=evalParam(engine,ctx,p,1);
	addJsonNodeSet(r1,r2);
	freeJsonNodeSet(r2);
	return r1;
}

JpathNode* functionFactory(const char*fname) {
	JpathNode*result = NULL;

	if(strcmp(fname,"size") == 0) 			{ result = JPATHFUNC("size",		__jpsize,	-1,	1); } 

	else if(strcmp(fname,"avg") == 0) 		{ result = JPATHFUNC("avg",		__jpavg,		-1,	1); } 
	else if(strcmp(fname,"min") == 0) 		{ result = JPATHFUNC("min",		__jpmin,		-1,	1); } 
	else if(strcmp(fname,"max") == 0) 		{ result = JPATHFUNC("max",		__jpmax,		-1,	1); } 
	else if(strcmp(fname,"sum") == 0) 		{ result = JPATHFUNC("sum",		__jpsum,		-1,	1); } 

	else if(strcmp(fname,"sqrt") == 0) 		{ result = JPATHFUNC("sqrt",		__jpsqrt,	-1,	0); } 
	else if(strcmp(fname,"pow") == 0) 		{ result = JPATHFUNC("pow",		__jppow,		-1,	0); } 
	else if(strcmp(fname,"floor") == 0) 	{ result = JPATHFUNC("floor",		__jpfloor,	-1,	0); } 
	else if(strcmp(fname,"ceil") == 0) 		{ result = JPATHFUNC("ceil",		__jpceil,	-1,	0); } 
	else if(strcmp(fname,"round") == 0) 	{ result = JPATHFUNC("round",		__jpround,	-1,	0); } 
	else if(strcmp(fname,"rand") == 0) 		{ result = JPATHFUNC("rand",		__jprand,	-1,	0); } 


	else if(strcmp(fname,"upper") == 0) 	{ result = JPATHFUNC("upper",		__jpupper,	1,		0); } 
	else if(strcmp(fname,"lower") == 0) 	{ result = JPATHFUNC("lower",		__jplower,	1,		0); } 

	else if(strcmp(fname,"if") == 0) 		{ result = JPATHFUNC("if",			__jpif,		1,		1); } 
	else if(strcmp(fname,"group") == 0) 	{ result = JPATHFUNC("group",		__jpgroup,	1,	1); } 

	else if(strcmp(fname,"eq") == 0) 		{ result = JPATHFUNC("eq",			__jpeq,		2,		0); } 
	else if(strcmp(fname,"neq") == 0) 		{ result = JPATHFUNC("neq",		__jpneq,		2,		0); } 
	else if(strcmp(fname,"gt") == 0) 		{ result = JPATHFUNC("gt",			__jpgt,		2,		0); } 
	else if(strcmp(fname,"lt") == 0) 		{ result = JPATHFUNC("lt",			__jplt,		2,		0); } 
	else if(strcmp(fname,"gte") == 0) 		{ result = JPATHFUNC("gte",		__jpgte,		2,		0); } 
	else if(strcmp(fname,"lte") == 0) 		{ result = JPATHFUNC("lte",		__jplte,		2,		0); } 

	else if(strcmp(fname,"concat") == 0) 	{ result = JPATHFUNC("concat",	__jpconcat,	-1,	0); } 

	else if(strcmp(fname,"substr") == 0) 	{ result = JPATHFUNC("substr",	__jpnoop,	-1,	1); } 
	else if(strcmp(fname,"match") == 0) 	{ result = JPATHFUNC("match",		__jpnoop,	-1,	1); } 
	else if(strcmp(fname,"indexof") == 0) 	{ result = JPATHFUNC("indexof",	__jpnoop,	-1,	1); } 
	else if(strcmp(fname,"rsub") == 0) 		{ result = JPATHFUNC("rsub",		__jpnoop,	-1,	1); } 
	else if(strcmp(fname,"stringf") == 0) 	{ result = JPATHFUNC("stringf",	__jpnoop,	-1,	0); } 

	else if(strcmp(fname,"key") == 0) 		{ result = JPATHFUNC("key",		__jpnoop,	-1,	1); } 
	else if(strcmp(fname,"value") == 0) 	{ result = JPATHFUNC("value",		__jpnoop,	-1,	1); } 
	else if(strcmp(fname,"sort") == 0) 		{ result = JPATHFUNC("sort",		__jpnoop,	-1,	1); } 

	else { 
		result = JPATHFUNC("UDF",__jpudf,-1,0); 
		result->data = jsonCreateString(NULL,fname); 
	} 
	return result;
}

#define JPINITCAPACITY 100


int __compareJsonNodes(JsonNode*a,JsonNode*b) {
	if(a==b) return 0;
	if(a==NULL) return 1;
	if(b==NULL) return -1;

	if(a->type != b->type) return a->type-b->type < 0 ? -1 : a->type-b->type > 0 ? 1 : 0;
	switch(a->type) {
		case TYPE_STRING: {
			if(a->str == NULL && b->str == NULL) return 0;
			if(a->str==NULL) return 1;
			if(b->str==NULL) return -1;
			return strcmp(a->str,b->str);
		}
		case TYPE_NUMBER: {
			if(isnan(a->fval)) return 1;
			if(isnan(b->fval)) return -1;
			return a->fval == b->fval ? 0 : a->fval - b->fval < 0 ? -1 : 1;
		}
		case TYPE_ELEMENT: {
			int r = strcmp(a->str,b->str);
			if(r == 0) return compareJsonNodes(a->first,b->first);
			else return r;
		}
		case TYPE_OBJECT: 
		case TYPE_ARRAY: {
			if(a->children > b->children) return -1;
			if(a->children < b->children) return 1;
			JsonNode*ait = a->first;
			JsonNode*bit = b->first;
			while(ait != NULL && bit != NULL) {
				int r = compareJsonNodes(ait,bit);
				if(r!=0) return r;
				ait=ait->next;
				bit=bit->next;
			}
			if(ait == NULL && bit == NULL) return 0;
			if(ait == NULL) return 1;
			if(bit == NULL) return -1;
			return 0;
		}
		default: fprintf(stderr,"bad type found in node compare: %d\n",a->type);

	}
	// should never hit this
	return 0;
}

int compareJsonNodes(JsonNode*a,JsonNode*b) {
	int __n = __compareJsonNodes(a,b);
#ifdef DEBUG
fprintf(stderr,"compareNodes returns %d\n",__n);
#endif
	return __n;
}

typedef struct __jpgrouplist {
	JsonNodeSet *keys;
	JsonNode *arrays;
} jpgrouplist;

void freeGroupList(jpgrouplist*gl) {
	int i;
	for(i=0;i<gl->keys->count;++i) {
		freeJsonNode(gl->keys->nodes[i]);
	}
	freeJsonNodeSet(gl->keys);
	// arrays is NOT detroyed as it is the product of the the process
	JPATHFREE(gl);
}
jpgrouplist *newGroupList() {
	jpgrouplist * gl= (jpgrouplist*)JPATHALLOC(sizeof(jpgrouplist));
	gl->keys = newJsonNodeSet();
	gl->arrays = jsonCreateArray(NULL);

	return gl;
}

int addToGroup(jpgrouplist *gl,JsonNode *expr, JsonNode *item) {
	int i = 0;
	JsonNode *rrs = gl->arrays->first;
	item = jsonCloneNode(item);
	for(i=0;i<gl->keys->count;++i) {
TRACE("ATG before compare");
		if(compareJsonNodes(gl->keys->nodes[i],expr) == 0) {
TRACE("ATG reuse");
			jsonArrayAppend(rrs,item);
TRACEJSON(gl->arrays);
			return 0;
		}
		rrs = rrs->next;
	}

TRACE("ATG create new slot");
TRACE("ATG key");
TRACEJSON(expr);
TRACE("ATG item");
TRACEJSON(item);
	addJsonNode(gl->keys,expr);
	JsonNode *arr = jsonCreateArray(gl->arrays);
TRACE("ATG new arr array");
TRACEJSON(arr);
	jsonArrayAppend(arr,item);
TRACE("ATG new element");
TRACEJSON(arr);
//	jsonArrayAppend(gl->arrays,arr);
TRACE("ATG result");
TRACEJSON(gl->arrays);
	return 1;
}

JsonNodeSet *__jpgroup(JtlEngine* engine,JsonNodeSet *ctx, JpathNode*p) {
	JSONTESTPARAMS(p,1);
	jpgrouplist* gl = newGroupList();

	JpathNode *p1=jsonGetJpathParam(p,0);
	int i;
	TRACE("jpgroup");
	for(i=0;i<ctx->count;++i) {
		if(ctx->nodes[i]->type == TYPE_ARRAY) {
			JsonNode*it = ctx->nodes[i]->first;
			while(it!=NULL) {
TRACE("jpgroup loop");
				JsonNode *test = jpathExecute(engine,it,p1);
				if(addToGroup(gl,test,it) == 0) {
					freeJsonNode(test);
				}
				it=it->next;
			}
		}
	}
	TRACE("jpgrouping complete");

	JsonNodeSet *rjns= newJsonNodeSet();
	addJsonNode(rjns,gl->arrays);
	freeGroupList(gl);
	TRACE("end jpgroup");
	return rjns;
}

JsonNodeSet *__jpfunc(JtlEngine* engine,JsonNodeSet *ctx, JpathNode*p) {
	const char*fname=p->name;
	if(strcmp(fname,"size") == 0) {
	} else {
		return __jpudf(engine,ctx,p);
	}
}

JsonNodeSet * __jpudf(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) {
	// to be implemented
	return __jpident(engine,ctx,p);
}

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

JsonNode *jpathExecute(JtlEngine* engine,JsonNode *ctx,JpathNode *jn) {
	JsonNode*res = NULL;
	JsonNodeSet *_ctx = newJsonNodeSet();
	addJsonNode(_ctx,ctx);
	
	JsonNodeSet *rs = __jpathExecute(engine,_ctx,jn);
	TRACE("");
	if(rs!=NULL) {
	TRACE("");
		if(rs->count == 0) {
	TRACE("");
			res = jsonCreateNull(NULL);
	TRACE("");
		} else if(rs->count == 1) {
	TRACE("");
			res = jsonNodeSetGet(rs,0);
		} else {
	TRACE("");
			res = jsonCreateArray(NULL);
			int i;
			for(i = 0; i < rs->count; ++i) {
				jsonArrayAppend(res,rs->nodes[i]);
			}
		}
	}
	TRACE("");
	freeJsonNodeSet(rs);
	TRACE("");
	freeJsonNodeSet(_ctx);
	TRACE("");
	return res;
}

JsonNodeSet *__jpathExecuteSingle(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {

#ifdef DEBUG
fprintf(stderr,"\tjpathExecute command: %s - ctx size = %d",jn->name,ctx->count);
if(jn->params) {
	JpathNode ** ptr = jn->params;
	int __pct = 0;
	while(*ptr) { ++__pct; ++ptr; }
	fprintf(stderr," %d params",__pct);
}
fprintf(stderr,"\n");
#endif
	JsonNodeSet *rjns;
	// aggregate flag means the function expects the whole context at once
	// otherwise, item at a time
	if(jn->aggr) {
	TRACE("aggregate");
		rjns = jn->proc(engine,ctx,jn);
	} else { 
	TRACE("itemized");
		rjns = newJsonNodeSet();
		if(ctx->count > 0) {
// we are going to resuse the same nodeset over and over, only
// swapping out the single json node therein contained
// so I seed it with a dummy
			JsonNodeSet *params = newJsonNodeSet();
			addJsonNode(params, jsonCreateNumber(NULL,0,0));
			jsonFree(params->nodes[0]);

TRACE("exec");
TRACE(jn->name);
			int i = 0;
			for(; i < ctx->count; ++i) {
TRACE("context");
TRACEJSON(ctx->nodes[i]);
				if(ctx->nodes[i]->type == TYPE_ARRAY) {
TRACE("array");
//					JsonNode *arr = jsonCreateArray(NULL);
					JsonNode*el = ctx->nodes[i]->first;
					while(el) {
						params->nodes[0] = el;
						JsonNodeSet *ir = jn->proc(engine,params,jn);
//						jsonPopulateArray(arr,ir);
						addJsonNodeSet(rjns,ir);
						freeJsonNodeSet(ir);
						el = el->next;
					}
//					addJsonNode(rjns,arr);
				} else {
TRACE("object or scalar");
					params->nodes[0] = ctx->nodes[i];
					JsonNodeSet *ir = jn->proc(engine,params,jn);
					addJsonNodeSet(rjns,ir);
					freeJsonNodeSet(ir);
				}
			}
			freeJsonNodeSet(params);
		}
	}
	return rjns;
}


JsonNodeSet *__jpathExecute(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) {
	JpathNode *p = jn;
	JsonNodeSet *rjns=ctx;
	JsonNodeSet * result;
	while(jn!=NULL) {
		result = __jpathExecuteSingle(engine,rjns,jn);


		// do not try to manage the calling context
		// but clean up any interim contexts that arise
		if(ctx != rjns) freeJsonNodeSet(rjns);
		rjns = result;
		jn=jn->next;
	}
	return rjns;
}
int jpatherror(JpathNode**p,const char*msg) {
 fprintf(stderr,"!!!!error at %d: %s\n",jpathcolumn,(msg)) ;
}

int plistSize(JpathNode**jpn) {
	int n = 0;
	while(*jpn) {
		++n;
		++jpn;
	}

	return n;
}

JpathNode*parseJpath(const char *s) {
TRACE("");
   YY_BUFFER_STATE buff = SCANSTRING(s);
   SWITCHTOBUFFER(buff);
	JpathNode *exp;
TRACE("");
   int res = PARSE(&exp);
TRACE("");
   DELETEBUFFER(buff);
	if(res == 0) {
TRACE("");
	   return exp;
	} else {
TRACE("");
		return NULL;
	}
}
