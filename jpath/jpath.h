#ifndef JPATH_PARSER_H
#define JPATH_PARSER_H

//#include "../ajt.h"



typedef JsonNode* (*jpathproc)(JsonNode*context,JsonNode*array);

	typedef struct __jpathnode {
		jpathproc proc;
		JsonNode *params;
		int aggregate;
		struct __jpathnode *next;
	} jpathnode;

int parseJpath(const char *s);

//JsonNode *jpathExecuteChain(JsonNode *context,jpathnode *jn) ;
#endif // end of file
