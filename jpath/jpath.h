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


//typedef JsonNode* (*jpathproc)(JsonNode*context,JsonNode*array);
typedef JsonNodeSet* (*jpathproc)(JsonNodeSet*context,struct __JpathNode **array);

	typedef struct __JpathNode {
		jpathproc proc;
		const char *name;
//		JsonNode *params;
		struct __JpathNode **params;
		int aggr;
		int nargs;
		struct __JpathNode *next;
	} JpathNode;

#define JPATHFUNC(nm,p,n,a) newJpathNode((p),(nm),NULL,(n),(a),NULL)
JpathNode * newJpathNode(jpathproc proc, const char* name,JpathNode **params, int nargs, int ag, JpathNode *next) ;
int parseJpath(const char *s);

JsonNodeSet * __jpavg(JsonNodeSet *ctx, JpathNode **p) ;
JsonNodeSet * __jpmin(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpmax(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpsum(JsonNodeSet *ctx, JpathNode **p);
JsonNodeSet * __jpsize(JsonNodeSet *ctx, JpathNode **p);

JsonNodeSet *jpathExecute(JsonNodeSet *ctx,JpathNode *jn) ;

#endif // end of file
