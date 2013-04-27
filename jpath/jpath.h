#ifndef JPATH_PARSER_H
#define JPATH_PARSER_H



	typedef JsonNode* (*jpathproc)(JsonNode*context,JsonNode*array,jpathnode*next);

	typedef struct __jpathnode {
		jpathproc proc;
		JsonNode *params;
		struct __jpathnode *next;
	} jpathnode;

int parseJpath(const char *s);

//JsonNode *jpathExecuteChain(JsonNode *context,jpathnode *jn) ;
#endif // end of file
