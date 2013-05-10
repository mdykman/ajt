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
}

%locations

%type<str> chars dstr sstr string
%type<jp> builtin arithop miscop agop strop 

%token<str> LABEL CHAR  
%token FLOAT 
%token INTEGER

%token<jp> DDOT TDOT DSTAR 
%token<jp> LTE GTE NE SQRT POW FLOOR CIEL ROUND RAND DIV
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
	| fcall
	| '(' jpath ')'
	| var

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
   : QKEY { $$ = $1; }
   | VALUE { $$ = $1; }

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

#define JSONNODESETINIT 1024

/*
const char* jsonToString(JsonNode *j) {
}
JsonNodeSet *__jpconcat(JsonNodeSet *ctx,JpathNode **jn) {
	JSONTESTPARAMS(jn,-1);
	JpathNode**p = jn;
	int i = 0;
	for(; *p != NULL; ++p) {
		JpathNode *ps = jsonGetJpathParam(jn,0);
		JsonNodeSet* rs = jpathExecute(ctx,ps);
		JsonNode*r=jsonNodeSetGet(rs,0);
		
	}

	JsonNodeSet *rjns = newJsonNodeSet();
}
*/
JsonNodeSet * newJsonNodeSet() {
	JsonNodeSet*result = (JsonNodeSet*)JPATHALLOC(sizeof(JsonNodeSet));
	result->nodes = (JsonNode**) JPATHALLOC(JSONNODESETINIT * sizeof(JsonNode*));
	result->capacity = JSONNODESETINIT;
	result->count = 0;
	return result;
}

void freeJsonNodeSet(JsonNodeSet *js) {
	JPATHFREE(js->nodes);
	JPATHFREE(js);
}

void addJsonNode(JsonNodeSet*jns,JsonNode*node) {
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

JsonNode* jsonNodeSetGet(JsonNodeSet*ptr,int x)  { 
	if(ptr->count > x) {
		return ptr->nodes[x];
	}
	return NULL;
}

JpathNode* jsonGetJpathParam(JpathNode**ptr,int x)  { 
	int i = 0;
	for(;i <= x && (*ptr) != NULL; ++i,++ptr){
		if((x) == i) return *ptr;
	}
	return NULL;
}
	
	
#define JSONTESTPARAMS(pp,x)	\
	if((x) != -1)  { if((x) > 0) { 				\
		if(pp == NULL || (*pp) ==NULL)  {		 \
			JPATHERROR("parameters expected");		\
			return NULL;		\
		} 	else {	\
			JpathNode ** __internalPP = pp;		\
			int __internalCC = 0; 					\
			for(;(*__internalPP)!=NULL;++__internalCC,++__internalPP)  {}		\
			if((x) != __internalCC) {			\
				yyerror("incorrect number of params");		\
				return NULL;							\
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
		ctx=__jpathExecute(ctx,p1);
	}
	return NULL;
}

JsonNodeSet *jpathIf(JsonNodeSet *ctx,JpathNode **jn) {
	JSONTESTPARAMS(jn,1);
	JpathNode *p1 = jsonGetJpathParam(jn,0);
	JsonNodeSet *rjns = newJsonNodeSet();
	int i=0;
	for(;i<ctx->count;++i) {
		JsonNode*test=jpathExecute(ctx->nodes[i],jn[0]);
		if(jsonTestBooleanNode(test)) {
			addJsonNode(rjns,ctx->nodes[i]);
		}
	}
	return rjns;
}

JsonNodeSet * __jpavg(JsonNodeSet *ctx, JpathNode **p) {
	if(ctx->count == 0) {
		return newJsonNodeSet();
	}

	int freeCtx = 0;
	JsonNodeSet *_ctx = tempContext(ctx,p);
	if(_ctx != NULL) {
		ctx = _ctx;
		freeCtx = 1;
	}

	JsonNodeSet *rs = __jpsum(ctx,NULL);
	JsonNode*r=jsonNodeSetGet(rs,0);

	if(r->type == TYPE_NUMBER) {
		double df = r->fval / ctx->count;
		r->ival = (long) df;
		r->fval = df;
	} else if(r->type == TYPE_OBJECT) {
		JsonNode*key=r->first;
		while(key!=NULL) {
			JsonNode *v = key->first;
			double df = v->fval / ctx->count;
			df = v->fval / ctx->count;
			v->ival = (long) df;
			v->fval = df;
			key=key->next;
		}
	} else {
		rs = NULL;
	}

	if(freeCtx) freeJsonNodeSet(ctx);
	return rs;
}

JsonNodeSet * __jpsize(JsonNodeSet *ctx, JpathNode **p) {
	JsonNodeSet *rjns = newJsonNodeSet();
	addJsonNode(rjns,jsonCreateNumber(NULL,ctx->count,ctx->count));
	return rjns;
}

JsonNodeSet * __jpmax(JsonNodeSet *ctx, JpathNode **p) {
	if(ctx->count == 0) {
		return newJsonNodeSet();
	}

	int freeCtx = 0;
	JsonNodeSet *_ctx = tempContext(ctx,p);
	if(_ctx != NULL) {
		ctx = _ctx;
		freeCtx = 1;
	}

	double total = 0;
	if(ctx->count>0) {
		total = ctx->nodes[0]->fval;
	}

	int i = 0;
	for(;i<ctx->count;++i) {
		total = total > ctx->nodes[i]->fval ? total : ctx->nodes[i]->fval;
	}
	if(freeCtx) freeJsonNodeSet(ctx);
	JsonNodeSet * ns = newJsonNodeSet();
	addJsonNode(ns,jsonCreateNumber(NULL,(long)total,total));
	return ns;
}

JsonNodeSet * __jpmin(JsonNodeSet *ctx, JpathNode **p) {
	if(ctx->count == 0) {
		return newJsonNodeSet();
	}

	int freeCtx = 0;
	JsonNodeSet *_ctx = tempContext(ctx,p);
	if(_ctx != NULL) {
		ctx = _ctx;
		freeCtx = 1;
	}
	double total = 0;
	if(ctx->count>0) {
		total = ctx->nodes[0]->fval;
	}

	int i = 0;
	for(;i<ctx->count;++i) {
		total = total < ctx->nodes[i]->fval ? total : ctx->nodes[i]->fval;
	}
	if(freeCtx) freeJsonNodeSet(ctx);
	JsonNodeSet * ns = newJsonNodeSet();
	addJsonNode(ns,jsonCreateNumber(NULL,(long)total,total));
	return ns;
}

JsonNodeSet * __jpsum(JsonNodeSet *ctx, JpathNode **p) {
	JsonNodeSet*res = newJsonNodeSet();
	int freeCtx = 0;
	if(ctx->count == 0) {
		addJsonNode(res,jsonCreateNumber(NULL,0,0));
	} else {
		JsonNodeSet *_ctx = tempContext(ctx,p);
		if(_ctx != NULL) {
			ctx = _ctx;
			freeCtx = 1;
		}

		JsonNode *ff = ctx->nodes[0];
//		 heuristics based on type of first element
		if(ff->type == TYPE_NUMBER) {
			double total;
			int i=0;
			for(;i<ctx->count;++i) {
				total += ctx->nodes[i]->fval;
			}
			// TODO:: this guy is a mem-leak candidate
			addJsonNode(res,jsonCreateNumber(NULL,(long)total,total));
		} else if(ff->type == TYPE_OBJECT) {
			JsonNode *robj = jsonCreateObject(NULL);
			int i = 0;
			for(;i<ctx->count;++i) {
				JsonNode*eech=ctx->nodes[i];
				if(eech->type == TYPE_OBJECT) {
					JsonNode *key = eech->first;
					while(key!=NULL ) {
						if(key->first!=NULL && key->first->type == TYPE_NUMBER) {
							JsonNode*qk=jsonGetMember(robj,key->str);
							if(qk==NULL) {
								qk = jsonCreateNumber(NULL,0,0);
								jsonObjectAppend(robj,key->str,qk);
							}
							qk->fval += key->first->fval;
							qk->ival = (long) qk->fval;
						}
						key=key->next;
					}
				}
			}
			addJsonNode(res,robj);
		}
	}
	if(freeCtx) freeJsonNodeSet(ctx);
	return res;
}

JpathNode * newJpathNode(jpathproc proc, const char* name,JpathNode **params, int nargs, int ag, JpathNode *next) {
	JpathNode* jp = JPATHALLOC(sizeof(JpathNode));
	jp->proc = proc;
	jp->name = name;
	jp->params = params;
	jp->nargs = nargs;
	jp->aggr = ag;
	jp->next = next;
	return jp;
}

JsonNode *jpathExecute(JsonNode *ctx,JpathNode *jn) {
	JsonNodeSet *_ctx = newJsonNodeSet();
	addJsonNode(_ctx,ctx);
	JsonNodeSet *rs = __jpathExecute(_ctx,jn);
	freeJsonNodeSet(_ctx);
	return jsonNodeSetGet(rs,0);

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
