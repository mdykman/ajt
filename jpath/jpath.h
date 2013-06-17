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

struct __JpathNode;


typedef JsonNodeSet* (*jpathproc)(JsonNodeSet*context,struct __JpathNode **array);

	typedef struct __JpathNode {
		jpathproc proc;
		const char *name;
		struct __JpathNode **params;
		JsonNode *data;
		int aggr;
		int nargs;
		struct __JpathNode *next;
	} JpathNode;

#define JPATHFUNC(nm,p,n,a) newJpathNode((p),(nm),NULL,NULL,(n),(a),NULL)
#define JPATHFUNCDATA(nm,p,d) newJpathNode((p),(nm),NULL,(d),0,0,NULL)

JpathNode * newJpathNode(jpathproc proc, const char* name,JpathNode **params, JsonNode*data, int nargs, int ag, JpathNode *next) ;
int parseJpath(const char *s);

JsonNodeSet * __jpnoop(JsonNodeSet *ctx, JpathNode **p) ;
JsonNodeSet * __jpevaldata(JsonNodeSet *ctx, JpathNode **p) ;
JsonNodeSet * __jpparent(JsonNodeSet *ctx, JpathNode **p) ;
JsonNodeSet * __jppeach(JsonNodeSet *ctx, JpathNode **p) ;
JsonNodeSet * __jpeach(JsonNodeSet *ctx, JpathNode **p) ;
JsonNodeSet * __jpeachdeep(JsonNodeSet *ctx, JpathNode **p) ;

JsonNodeSet * __jpavg(JsonNodeSet *ctx, JpathNode **p) ;
JsonNodeSet * __jpmin(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpmax(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpsum(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpsize(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpcount(JsonNodeSet *ctx, JpathNode **p);

JsonNodeSet * __jpconcat(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jplower(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpupper(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jplt(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jplte(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpgt(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpgte(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpeq(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpneq(JsonNodeSet *ctx, JpathNode **p);

JsonNodeSet*__jpcompare(JsonNodeSet *ctx,JpathNode **jn,int(cmpop)(int)) ;
//JsonNodeSet *jpathExecute(JsonNodeSet *ctx,JpathNode *jn) ;

JsonNode *jpathExecute(JsonNode *ctx,JpathNode *jn) ;
JsonNodeSet *__jpathExecute(JsonNodeSet *ctx,JpathNode *jn) ;
#endif // end of file
