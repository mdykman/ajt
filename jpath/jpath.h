#ifndef JPATH_PARSER_H
#define JPATH_PARSER_H

#include "../ajt.h"

#define JSONNODESETINT 1024;

#define JPATHREALLOC(x,y)  realloc(x,y)
#define JPATHALLOC(x)  malloc(x)
#define JPATHFREE(x)  free(x)
#define JPATHSTRDUP(x)  strdup(x)

typedef struct __JsonNodeSet {
	JsonNode ** nodes;
	int count;
	int capacity;
} JsonNodeSet;

JsonNodeSet * newJsonNodeSet() ;
void freeJsonNodeSet(JsonNodeSet *js) ;

struct JpathNode;

typedef JsonNodeSet* (*jpathproc)(JtlEngine* engine,JsonNodeSet*context,struct JpathNode *array);


	typedef struct JpathNode {
		jpathproc proc;
		const char *name;
		struct JpathNode **params;
		JsonNode *data;
		int aggr;
		int nargs;
		struct JpathNode *next;
	} JpathNode;

#define JPATHAPPEND(ch,n)  								\
	{																\
		JpathNode *__it = (ch); 							\
		while(__it->next != NULL) __it=__it->next;	\
		__it->next = (n);										\
	}
		
		

int plistSize(JpathNode**);

JpathNode* functionFactory(const char*fname);

#define JPATHFUNC(nm,p,n,a) 		\
	newJpathNode((p),(nm),NULL,NULL,(n),(a),NULL)
	
#define JPATHFUNCDATA(nm,p,d) \
	newJpathNode((p),(nm),NULL,(d),0,0,NULL)

JpathNode * newJpathNode(jpathproc proc, const char* name,JpathNode **params, JsonNode*data, int nargs, int ag, JpathNode *next) ;
JpathNode* parseJpath(const char *s);

JsonNode *jpathExecute(JtlEngine* engine,JsonNode *ctx,JpathNode *jn) ;
JsonNodeSet *__jpathExecute(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn) ;

int compareJsonNodes(JsonNode*a,JsonNode*b);


JsonNodeSet * __jpnoop		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpevaldata	(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpparent	(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jptopparent(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jppeach		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpeach		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpeachdeep	(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ;

JsonNodeSet * __jpceil		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpfloor		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jprand		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpsqrt		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpround		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ;

JsonNodeSet * __jpavg		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpmin		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpmax		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpsum		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpsize		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpcount		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);

JsonNodeSet * __jpconcat	(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jplower		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpupper		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jplt			(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jplte		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpgt			(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpgte		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpeq			(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpneq		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpnot		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);

JsonNodeSet*__jpif(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn);

JsonNodeSet*__jpadd(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn);
JsonNodeSet*__jpsub(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn);
JsonNodeSet*__jpmul(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn);
JsonNodeSet*__jpdiv(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn);
JsonNodeSet*__jpmod(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn);
JsonNodeSet*__jppow(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn);

JsonNodeSet * __jptexttest		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpnumbertest	(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpscalartest	(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jparraytest		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpobjecttest	(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpnulltest		(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);

JsonNodeSet * __jpnametest	(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);

JsonNodeSet * __jpudf(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p);

JsonNodeSet*__jpcompare	(JtlEngine* engine,JsonNodeSet *ctx,JpathNode *jn,int(cmpop)(int)) ;

JsonNodeSet * __jpunion(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ; 
JsonNodeSet * __jpgroup(JtlEngine* engine,JsonNodeSet *ctx, JpathNode *p) ; 

#endif // end of file
