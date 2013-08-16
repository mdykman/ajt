

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "ajt.h"
#include "ajson.l.h"

#include "jpath/jpath.h"

FILE *jsoutput;

// the minify callbacks
int first = 1;
int pjsonned=0;

int testBuilder(FILE *f) ;

typedef enum {
	JSONARRAY,
	JSONOBJECT,
	JSONSTART
} JSONSTACKTYPES;

JSONSTACKTYPES JSONTYPESTACK[4096]  = { JSONSTART };


JsonNode *jtlTransform(JsonNode*jtl,JsonNode *json) ;

int JSONSTACKP = 0;

int minso() {
	if(!first) {
		fprintf(jsoutput,",");
	}
	fprintf(jsoutput,"{");
//minlevel++;
	first=1;
}
int mineo() {
//minlevel--;
	fprintf(jsoutput,"}");
	first=0;
}
int minsa() {
	if(!first) {
		fprintf(jsoutput,",");
	}
	fprintf(jsoutput,"[");
	first=1;
}
int minea() {
	fprintf(jsoutput,"]");
	first=0;
}

int minkey(const char*p) {
	if(!first) {
		fprintf(jsoutput,",");
	}
	fprintf(jsoutput,"\"%s\":",p);
	first=1;
}

int minjson(const char*p) {
	fprintf(jsoutput,"\"%s\"(",p);
	pjsonned=1;
}
int minend() {
	if(pjsonned) {
		fprintf(jsoutput,")");
	}
}

int minstr(const char*p) {
	if(!first) {
		fprintf(jsoutput,",");
	}
	if(p == NULL) {
		fprintf(jsoutput,"null");
	} else {
		fprintf(jsoutput,"\"%s\"",p);
	}
	first=0;
}
int minnum(long ival, double fval) {
	if(!first) {
		fprintf(jsoutput,",");
	}
	if(ival == fval) {
		fprintf(jsoutput,"%ld",ival);
	} else {
		fprintf(jsoutput,"%f",fval);
	}
	first=0;
}



int pplevel = 0;

int ppindent(int n) {
	if(!first ) {
		fprintf(jsoutput,"\n");
		int i = 0;
		for(;i < n; ++i) {
			fprintf(jsoutput,"   ");
		}
	}
}
int ppso() {
	JSONTYPESTACK[++JSONSTACKP] = JSONOBJECT;
	if(!first) {
		fprintf(jsoutput,", ");
//		ppindent(pplevel);
	}

	fprintf(jsoutput,"{");
pplevel++;
	first=1;
}
int ppeo() {
	JSONSTACKP--;
	--pplevel;
//	if(JSONTYPESTACK[JSONSTACKP] == JSONARRAY) {
//		ppindent(pplevel);
//	}
// pplevel--;
 	ppindent(pplevel);
	fprintf(jsoutput,"}");
	first=0;
}

int ppsa() {
	if(!first) {
		fprintf(jsoutput,", ");
//		ppindent(pplevel);
	}
	if(JSONTYPESTACK[JSONSTACKP] == JSONARRAY) {
		ppindent(pplevel);
	}
	++pplevel;
	JSONTYPESTACK[++JSONSTACKP] = JSONARRAY;
	fprintf(jsoutput,"[ ");
//pplevel++;
	first=1;
}

int ppea() {
	JSONSTACKP--;
	fprintf(jsoutput," ]");
//	if(JSONTYPESTACK[JSONSTACKP] == JSONARRAY) {
		--pplevel;
//		ppindent(pplevel);
//	}
//pplevel--;
//	ppindent(pplevel);
	first=0;
}

int ppkey(const char*p) {
	if(!first) {
		fprintf(jsoutput,", ");
	}
	first=0;
	ppindent(pplevel);
	fprintf(jsoutput,"\"%s\": ",p);
	first=1;
}

int ppjson(const char*p) {
	fprintf(jsoutput,"%s (",p);
	pjsonned=1;
}

int ppend() {
	if(pjsonned) {
		fprintf(jsoutput,")");
	}
	fprintf(jsoutput,"\n");
}

int ppstr(const char*p) {
	if(!first) {
		fprintf(jsoutput,", ");
	}
	if(p == NULL) {
		fprintf(jsoutput,"null");
	} else {
		fprintf(jsoutput,"\"%s\"",p);
	}
	first=0;
}
int ppnum(long ival, double fval) {
	if(!first) {
		fprintf(jsoutput,", ");
	}
	if(ival == fval) {
		fprintf(jsoutput,"%ld",ival);
	} else {
		fprintf(jsoutput,"%f",fval);
	}
	first=0;
}

jax_callbacks minifcb = {
	minso,mineo,minsa,minea,
	minkey,NULL,minstr,minnum,
	minjson,NULL,minend,NULL
};
jax_callbacks ppfcb = {
	ppso,ppeo,ppsa,ppea,
	ppkey,NULL,ppstr,ppnum,
	ppjson,NULL,ppend,NULL
};
jax_callbacks noopfcb = {
	NULL, NULL, NULL, NULL, 
	NULL, NULL, NULL, NULL, 
	NULL, NULL, NULL, NULL
};



void showJsonNode(JsonNode*jn) {
	if(jn == NULL) {
		fprintf(stderr,"shownode: NULL\n");
	} else {
		fprintf(stderr,"type: %d\n",jn->type);
		fprintf(stderr,"children: %d\n",jn->children);
		fprintf(stderr,"first: %p\n",jn->first);
		fprintf(stderr,"next: %p\n",jn->next);
	}
}

int main(int argc, char *argv[])
{
    int minify=0; 
	 int prettyprint = 1;
	 int testbuilder = 0;
	 int quiet = 0;
	 int debug = 0;
	 int opt = -1;
	 char*filename = NULL;
	 char*jtlfile = NULL;

    int nsecs, tfnd;

    nsecs = 0;
    tfnd = 0;
	 jsoutput = stdout;
	 TRACE("");
    while ((opt = getopt(argc, argv, "j:btmpqdo:")) != -1) {
        switch (opt) {
	        case 'm':
            minify = 1;
				prettyprint = 0;
			  break;
        case 'b':
		  	testbuilder = 1;
			  break;
        case 'j':
		  		jtlfile = optarg;
            break;
        case 't':
		  		setAllowErrors(1);
            break;
        case 'p':
				prettyprint = 1;
				minify = 0;
				quiet = 0;
            break;
        case 'q':
				quiet = 1;
				minify = 0;
				prettyprint = 0;
            break;
        case 'o':
		  		filename = optarg;
				quiet = 0;
		  		break;
        case 'd':
				debug = 1;
            break;
        default: /* '?' */
            fprintf(stderr, "Usage: %s [OPTION]... FILE\n", argv[0]);
            fprintf(stderr, "\t-p        pretty-print (default)\n");
            fprintf(stderr, "\t-m        minify\n");
            fprintf(stderr, "\t-o file   output to a file instead of stdout\n");
            fprintf(stderr, "\t-q        quiet, produce no output (syntax check only)\n");
            fprintf(stderr, "\t-d        enable verbose debugging to stderr\n");
            fprintf(stderr, "\t-t        tolerate errors (tidy - experimental)\n");
            fprintf(stderr, "\t-j        transform via JTL (under development)\n");
            exit(-1);
        }
    }

	 TRACE("");
	FILE * myinput = NULL;
	// alternate input file
	if(optind <  argc) {
		myinput = fopen(argv[optind],"r");
		if(myinput == NULL) {
			fprintf(stderr,"failed to open input file `%s'\n",argv[optind]);
			exit(-2);
		}
	}
	 TRACE("");
	// alternate output file
	if(filename != NULL) {
		jsoutput = fopen(filename,"w");
		if(jsoutput == NULL) {
			fprintf(stderr,"failed to open output file `%s'\n",filename);
			exit(-3);
		}
	}

	 TRACE("");
	JsonNode * tree = jsonBuildJsonTreeFromFile(myinput == NULL ? stdin : myinput);
	 TRACE("");
	if(tree == NULL) {
		exit(-4);
	}

	 TRACE("");
	if(jtlfile != NULL) {
		FILE *jtf = fopen(jtlfile,"r");
		JsonNode * jtltree = jsonBuildJtlTreeFromFile(jtf);
		if(jtltree == NULL) {
			exit(-5);
		}
	
		fclose(jtf);
		tree = jtlTransform(jtltree,tree);
		if(tree == NULL) {
			exit(-6);
		}
	}

	 TRACE("");
	int oc = 0;
	 TRACE("");
	if(prettyprint) {
		oc=jsonPrintToFile(jsoutput,tree,JSONPRINT_PRETTY);
//	printf("line %d\n",__LINE__);
//		setCallBacks(ppfcb);
	} else if(minify) {
		oc=jsonPrintToFile(jsoutput,tree,JSONPRINT_MINIFY);
//	printf("line %d\n",__LINE__);
//.		setCallBacks(minifcb);
	} else if(quiet)  {
//	printf("line %d\n",__LINE__);
//		setCallBacks(noopfcb);
	}

//	printf("line %d\n",__LINE__);
//	int result = parseJsonFile(myinput == NULL ? stdin : myinput,0);
//   int result =  jsonparse();
	if(filename != NULL) {
		fclose(jsoutput);
	}
	if(myinput!=NULL) {
		fclose(myinput);
	}
	return 0;
}

void jsonShowTree(FILE* out,JsonNode*js,int indent) {
	int i = 0;
	for(i=0;i<indent;++i) {
		fprintf(out,"   ");
	}
	fprintf(out,"type %d: %s - %ld (%f)\n",js->type,js->str,js->ival,js->fval);
	if(js->first) {
		jsonShowTree(out,js->first,indent+1);
	}
	if(js->next) {
		jsonShowTree(out,js->next,indent);
	}
}

/*
int addNodeToParent(JsonNode*p,JsonNode*c) {
	int result = 0;
	switch(p->type) {
		case TYPE_ARRAY:
			jsonArrayAppend(p,c);
			result = 1;
		break;
		case TYPE_OBJECT:
			if(c->type == TYPE_ELEMENT) {
				
			}
		break;
		case TYPE_ELEMENT:
		break;
	}
	return result;	
	if(p->type == TYPE_OBJECT) {
		if(c->type != TYPE_ELEMENT) {
		}
	} else if(p->type == TYPE_ARRAY) {
		jsonArrayAppend(p,c);
	}
}
*/
 /// TODO:: make filenames unique and dynamic
 /// TODO:: clean up files when done

const char* jtlMd5(JsonNode *json) {
	char*tmpfile = "/tmp/curl-temp";
	char*md5file = "/tmp/md5-temp";
	char buff[8192] = { 0 };

	tmpfile = tmpnam(NULL);
	jtlWriteFile(tmpfile,json);

	md5file = tmpnam(NULL);
	sprintf(buff,"md5sum %s > %s",tmpfile,md5file);
	FILE *inp = fopen(md5file,"r");

	char * res = JPATHALLOC(33);
	fread(res,1,32,inp);
	fclose(inp);
	res[32] = 0;
	return res;

}

void httpencode(char*buff,char*data) {
	int counter = 0;
	while(*data) {
		if(isalnum(*data) || *data == '_') {
			counter += sprintf(buff+counter,"%c",*data);
		} else {
			counter += sprintf(buff+counter,"%02x",*data);
		}
	}
}

int jtlWriteFile(const char*fname,JsonNode *paths) {
	FILE *outp = fopen(fname,"w");
	int r = jsonPrintToFile(outp,paths,JSONPRINT_PRETTY);
	fclose(outp);
	return r;
}

JsonNode *jtlReadFile(JsonNode *paths) {
	JsonNode * jsontree = NULL;
	switch(paths->type) {
		case TYPE_STRING: {
			FILE *inp = fopen(paths->str,"r");
			jsontree = jsonBuildJsonTreeFromFile(inp);
			fclose(inp);
		}
		break;
		case TYPE_ARRAY: {
			JsonNode *it = paths->first;
			jsontree = jsonCreateArray(NULL);
			while(it != NULL) {
				JsonNode *res = jtlReadFile(it);
				appendJsonNode(jsontree,res);
				it = it->next;
			}
		}
		break;
	}
	return jsontree;
}

const char* curlParam(char*buff,const char*name,JsonNode*val) {
	switch(val->type) {
		case TYPE_NUMBER: {
			if(val->ival == val->fval) {
				sprintf(buff,"-F %s=%ld ",name,val->ival);
			} else {
				sprintf(buff,"-F %s=%f ",name,val->fval);
			}
		}
		break;

		case TYPE_STRING: {
			sprintf(buff,"-F %s=",name);
			httpencode(buff+strlen(buff),val->str);
			sprintf(buff+strlen(buff)," ");
		}
		break;

		case TYPE_ARRAY: {
			JsonNode *ch = val->first;
			while(ch) {
				curlParam(buff+strlen(buff),name,ch);
				ch = ch->next;
			}
		}
		break;
		case TYPE_OBJECT: {
			char *tmpfile = tmpnam(NULL);
			jtlWriteFile(tmpfile,val);
			sprintf(buff,"<%s ",tmpfile);
		}
		break;
	}
}

JsonNode *jtlCurl(const char*uri,JsonNode *options) {
	char*tmpfile = "/tmp/curl-temp";
	char buff[8192] = { 0 };
	sprintf(buff,"curl ");
	if(options != NULL && options->type == TYPE_OBJECT) {
		// TODO:: what am I doi ng here?
		JsonNode *data = jsonGetMember(options,"method");
		data = jsonGetMember(options,"data");
		if(data != NULL) {
			JsonNode *pp=data->first;
			while(pp) {
				JsonNode *val = pp->first;
				curlParam(buff+strlen(buff),pp->str,val);
				pp = pp->next;
			}
		}
	}
	// TODO::  this is bad!!
	tmpfile = tmpnam(NULL);
	sprintf(buff+strlen(buff),"\"%s\" > %s",uri,tmpfile);

#ifdef DEBUG
	fprintf(stderr,"CURL command line: %s\n",buff);
#endif

	int r = system(buff);
	JsonNode *result = NULL;
	if(r == 0) {
//		result = jtlReadFile(tmpfile);
		FILE *inp = fopen(tmpfile,"r");
		result = jsonBuildJsonTreeFromFile(inp);
		fclose(inp);
	}
	return result;
}

JsonNode *jtlTraverse(JtlEngine*engine,JsonNode *jtl,JsonNode* context,JsonNode*parent) {
	JsonNode*result = NULL;
	JsonNode*it;
	char buf[1024];
	if(jtl!=NULL) switch(jtl->type) {
		case TYPE_FUNC:
			if(strcmp(jtl->str,"jpath") == 0) {
				if(jtl->first == NULL) return NULL;
				JpathNode *p =parseJpath(jtl->first->str);
				// make sure the source context is never distrurbed
				context = jsonCloneNode(context);
				result = jpathExecute(engine,context,p);
				freeJsonNode(context);
				appendJsonNode(parent,result);
			} else if(strcmp(jtl->str,"fetch") == 0) {
				JsonNode *jn = jtl->first;
				const char* uri = jn->str;
				jn = jn->next;
				result = jtlCurl(uri,jn);
				appendJsonNode(parent,result);
			} else if(strcmp(jtl->str,"file") == 0) {
				result = jtlReadFile(jtl->first);
				appendJsonNode(parent,result);
			} else {
				JsonNode*udf = jsonGetMember(engine->reference,jtl->str);
				if(udf == NULL) {
					sprintf(buf,"!!UDF '%s' not found; ignoring!!\n",jtl->str);
					result = jsonCreateString(parent,strdup(buf));
					fprintf(stderr,"%s",buf);
				} else {
					jtlTraverse(engine,udf,context,parent);
				}
			}
		break;
		case TYPE_ARRAY:
			result = jsonCreateArray(parent);
			it = jtl->first;
			while(it != NULL) {
				jtlTraverse(engine,it,context,result);
				it = it->next;
			}
		break;
		case TYPE_OBJECT:
			result = jsonCreateObject(parent);
			it = jtl->first;
			while(it != NULL) {
				jtlTraverse(engine,it,context,result);
				it = it->next;
			}
		break;
		case TYPE_ELEMENT:
			result = jsonCreateElement(parent,jtl->str);
			jtlTraverse(engine,jtl->first,context,result);
		break;
		case TYPE_STRING:
			result = jsonCreateString(parent,jtl->str);
		break;
		case TYPE_NUMBER:
			result = jsonCreateNumber(parent,jtl->ival,jtl->fval);
		break;
		default: {
			sprintf(buf,"unknown type in traverse: %d\n",jtl->type);
			result = jsonCreateString(parent,strdup(buf));
			fprintf(stderr,"%s",buf);
		}

	}
	return result;
}
JsonNode *jtlTransform(JsonNode*jtl,JsonNode *json) {
	JtlEngine engine = { jtl };
//	engine.reference = jtl;
	JsonNode *ex = jsonGetMember(jtl,"jtldefault");
	if(ex == NULL) {
		ex = jtl;
	} else {
// seed engine with init constants
		JsonNode *init=jsonGetMember(jtl,"jtlinit");
	}
	JsonNode *result = jtlTraverse(&engine,ex,json,NULL);
	return result;
}

/*
int testBuilder(FILE *f) {
		JsonNode * tree = jsonBuildJsonTreeFromFile(f);
		if(tree != NULL) {
			fprintf(stderr,"everything seemed to work...\n");
			jsonShowTree(stderr,tree,0);
			jsonFree(tree);
			return 0;
		}
		return 1;
}


*/
