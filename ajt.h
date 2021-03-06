#ifndef AJSON_H
#define AJSON_H

#include<stdio.h>


#define DEFAULT_FLOAT_FORMAT "%.6f"


#define JSONPRINT_MINIFY  0
#define JSONPRINT_PRETTY  1
#define JSONPRINT_SQUOTE  2
#define JSONPRINT_TABFILL 4

#ifdef DEBUG
#define TRACE(x) fprintf(stderr,"%s:%d - %s\n",__FILE__,__LINE__,(x))
#define TRACEJSON(x) jsonPrintToFile(stderr,x,JSONPRINT_PRETTY)
#else
#define TRACE(x) 
#define TRACEJSON(x) 
#endif


#define JSONALLOC(x) malloc(x)
#define JSONFREE(x) { free(x); TRACE("JSONFREE"); }

typedef struct __jax_callbacks {
	int (*startobject)();
	int (*endobject)();
	int (*startarray)();
	int (*endarray)();
	int (*key)(const char*);
	/*
		each scalar value encountered will trigger 'scalar' plus 1 of 'string' or 'number'.
		typically, you want to either trap 'scalar', or trap both 'string' and 'number'
	*/
	int (*scalar)(const char *,long ,double );
	int (*string)(const char*);
	int (*number)(long ,double );

	int (*jsonp)(const char*);
	int (*startjson)();
	int (*endjson)();
	int (*comment)(const char*);
	int (*error)(const char*);
	int (*startfunc)(const char*);
	int (*endfunc)();
	
} jax_callbacks;


/* used for single handler */
typedef const enum {
	SOBJ,
	EOBJ,
	SARR,
	EARR,
	KEY,
	SCA, 
	JSP,
	SJS,
	EJS,
	COM,
	FUNC
} __JAXEVT;



typedef enum  {
	TYPE_JSONP,
	TYPE_OBJECT,
	TYPE_ELEMENT,
	TYPE_ARRAY,
	TYPE_NUMBER,
	TYPE_STRING,
	TYPE_FUNC,
} jsonnodetype;

typedef struct __JsonNode {
	jsonnodetype type;
	struct __JsonNode * parent;
	/* children */
	struct __JsonNode * first;
	struct __JsonNode * last;
	int children;

	/* siblings */
	struct __JsonNode * prev;
	struct __JsonNode * next;

	char* str;
	long ival;
	double fval;
} JsonNode;

typedef struct __JtlEngine {
	JsonNode * reference;
} JtlEngine;


#define appendJsonNode(p,c)         { \
            if((p)->last == NULL) {       \
               (p)->first = (p)->last = (c);       \
               (p)->children = 1;                  \
            } else {       \
               (c)->prev = (p)->last;        \
               (p)->last = (c)->prev->next = (c);        \
               ((p)->children)++;         \
            }                            \
         }

extern void freeJsonNode(JsonNode*jn);


extern int  jsonParserAllowErrors;
extern int  jsonParserAllowJTL;
 extern int (*sjcb)(__JAXEVT type, const char* p, long i, double f);
extern jax_callbacks __jax_default_callbacks;
// extern jsonError(const char* msg);
//extern yyerror(const char* msg);


 void setSingleHandler(int myhandler(__JAXEVT type,const char*p,long i, double f)) ;
 void setCallBacks(jax_callbacks _jcb) ;
	int yywarning(const char *p) ;

 extern void setAllowErrors(int a);
 extern void setAllowJxt(int a);
 extern int parseJsonFile(FILE*f,int jtl);
 extern int parseJsonString(const char*s,int jtl) ;

  extern JsonNode* jsonNewNode(JsonNode* parent,jsonnodetype t,const char* str, long ival, double fval) ;
  extern JsonNode* jsonCreateString(JsonNode*p,const char*str) ;
  extern JsonNode* jsonCreateNumber(JsonNode*p,long ival, double fval) ;
  extern JsonNode* jsonCreateObject(JsonNode*p) ;
  extern JsonNode* jsonCreateArray(JsonNode*p) ;
  extern JsonNode* jsonCreateElement(JsonNode*p,const char*str) ;
  extern JsonNode* jsonCreateNull(JsonNode*p) ;
  extern JsonNode* jsonGetParent(JsonNode*p) ;

  extern int jsonObjectAppend(JsonNode *object,const char*key,JsonNode *ch) ;
  extern int jsonArrayAppend(JsonNode *array,JsonNode *ch) ;
	extern int jsonArrayAppendAll(JsonNode *array,JsonNode *ch) ;
  


extern JsonNode* jsonBuildJsonTreeFromString(const char *s) ;
extern JsonNode* jsonBuildJsonTreeFromFile(FILE *f) ;

extern JsonNode* jsonBuildTreeFromFile(FILE *fi,int jtl); 
extern JsonNode* jsonBuildTreeFromString(const char* s,int jtl); 

extern JsonNode* jsonCloneNode(JsonNode* jn);
extern JsonNode* jsonGetMember(JsonNode* obj,const char *name);

extern JsonNode* jsonBuildJtlTreeFromString(const char *s) ;
extern JsonNode* jsonBuildJtlTreeFromFile(FILE *f) ;


extern int jsonPrintToFile(FILE *f,JsonNode *node,int options);

extern void jsonFree(JsonNode*js) ;

#endif
