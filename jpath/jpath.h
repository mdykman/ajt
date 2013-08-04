#ifndef JPATH_PARSER_H
#define JPATH_PARSER_H

#include "../ajt.h"

#define JSONNODESETINT 1024;

typedef struct __JsonNodeSet {
	JsonNode ** nodes;
	int count;
	int capacity;
} JsonNodeSet;

JsonNodeSet * newJsonNodeSet() ;
void freeJsonNodeSet(JsonNodeSet *js) ;

struct JpathNode;

typedef JsonNodeSet* (*jpathproc)(JsonNodeSet*context,struct JpathNode *array);


	typedef struct JpathNode {
		jpathproc proc;
		const char *name;
		struct JpathNode **params;
		JsonNode *data;
		int aggr;
		int nargs;
		struct JpathNode *next;
	} JpathNode;

#define JPATHFUNC(nm,p,n,a) 		\
	newJpathNode((p),(nm),NULL,NULL,(n),(a),NULL)
	
#define JPATHFUNCDATA(nm,p,d) \
	newJpathNode((p),(nm),NULL,(d),0,0,NULL)

#define JPATHAPPEND(ch,n)  								\
	{																\
		JpathNode *__it = (ch); 							\
		while(__it->next != NULL) __it=__it->next;	\
		__it->next = (n);										\
	}
		
		

int plistSize(JpathNode**);

JpathNode* functionFactory(const char*fname);

int compareJsonNodes(JsonNode*a,JsonNode*b);

JpathNode * newJpathNode(jpathproc proc, const char* name,JpathNode **params, JsonNode*data, int nargs, int ag, JpathNode *next) ;
JpathNode* parseJpath(const char *s);

JsonNodeSet * __jpnoop		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpevaldata	(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpparent	(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jptopparent(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jppeach		(JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpeach		(JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpeachdeep	(JsonNodeSet *ctx, JpathNode *p) ;

JsonNodeSet * __jpceil		(JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpfloor		(JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jprand		(JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpsqrt		(JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpround		(JsonNodeSet *ctx, JpathNode *p) ;

JsonNodeSet * __jpavg		(JsonNodeSet *ctx, JpathNode *p) ;
JsonNodeSet * __jpmin		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpmax		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpsum		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpsize		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpcount		(JsonNodeSet *ctx, JpathNode *p);

JsonNodeSet * __jpconcat	(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jplower		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpupper		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jplt			(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jplte		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpgt			(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpgte		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpeq			(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpneq		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpnot		(JsonNodeSet *ctx, JpathNode *p);

JsonNodeSet*__jpif(JsonNodeSet *ctx,JpathNode *jn);

JsonNodeSet*__jpadd(JsonNodeSet *ctx,JpathNode *jn);
JsonNodeSet*__jpsub(JsonNodeSet *ctx,JpathNode *jn);
JsonNodeSet*__jpmul(JsonNodeSet *ctx,JpathNode *jn);
JsonNodeSet*__jpdiv(JsonNodeSet *ctx,JpathNode *jn);
JsonNodeSet*__jpmod(JsonNodeSet *ctx,JpathNode *jn);
JsonNodeSet*__jppow(JsonNodeSet *ctx,JpathNode *jn);

JsonNodeSet * __jptexttest		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpnumbertest	(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpscalartest	(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jparraytest		(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpobjecttest	(JsonNodeSet *ctx, JpathNode *p);
JsonNodeSet * __jpnulltest		(JsonNodeSet *ctx, JpathNode *p);

JsonNodeSet * __jpnametest	(JsonNodeSet *ctx, JpathNode *p);

JsonNodeSet * __jpudf(JsonNodeSet *ctx, JpathNode *p);

JsonNodeSet*__jpcompare	(JsonNodeSet *ctx,JpathNode *jn,int(cmpop)(int)) ;

JsonNodeSet * __jpunion(JsonNodeSet *ctx, JpathNode *p) ; 
JsonNodeSet * __jpgroup(JsonNodeSet *ctx, JpathNode *p) ; 

JsonNode *jpathExecute(JsonNode *ctx,JpathNode *jn) ;
JsonNodeSet *__jpathExecute(JsonNodeSet *ctx,JpathNode *jn) ;

#endif // end of file
