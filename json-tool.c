
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "ajson.h"
#include "ajson.l.h"

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
	fprintf(jsoutput,"\"%s\"",p);
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
	fprintf(jsoutput,"\"%s\"",p);
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
    while ((opt = getopt(argc, argv, "j:btmpqdo:")) != -1) {
//	 	printf("\t\t\tprocessing %c\n",opt);
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
            fprintf(stderr, "\t-j        trasnform via JTL\n");
            exit(1);
        }
    }

	FILE * myinput = NULL;
	if(optind <  argc) {
		myinput = fopen(argv[optind],"r");
		if(myinput == NULL) {
			fprintf(stderr,"failed to open input file `%s'\n",argv[optind]);
			exit(2);
		}
	}
	
	if(filename != NULL) {
		jsoutput = fopen(filename,"w");
		if(jsoutput == NULL) {
			fprintf(stderr,"failed to open output file `%s'\n",filename);
			exit(3);
		}
	}
	if(jtlfile != NULL) {
		FILE *jtf = fopen(jtlfile,"r");
		JsonNode * jtltree = jsonBuildJtlTreeFromFile(jtf);
		fclose(jtf);
		JsonNode * tree = jsonBuildJsonTreeFromFile(myinput);
		exit(jtlTransform(jtltree,tree));
		
	}
	if(testbuilder) {
		exit(testBuilder(myinput));
		
//		JsonNode * tree = jsonBuildTreeFromFile(myinput);
	} else if(prettyprint) {
//	printf("line %d\n",__LINE__);
		setCallBacks(ppfcb);
	} else if(minify) {
//	printf("line %d\n",__LINE__);
		setCallBacks(minifcb);
	} else if(quiet)  {
//	printf("line %d\n",__LINE__);
		setCallBacks(noopfcb);
	}

//	printf("line %d\n",__LINE__);
	int result = parseJsonFile(myinput == NULL ? stdin : myinput,0);
//   int result =  jsonparse();
	if(filename != NULL) {
		fclose(jsoutput);
	}
	if(myinput!=NULL) {
		fclose(myinput);
	}
	return result;
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

int jtlTransform(JsonNode*jtl,JsonNode *json) {
	if(jtl == NULL) {
		return 2;
	}

	if(json == NULL) {
		return 1;
	}
	JsonNode *def = jsonGetMember(jtl,"default");
	if(def == NULL) {
		def = jtl;
	}

	printf("       ---------- JTL  ------------\n\n\n");
	jsonShowTree(stdout,jtl,0);
	printf("       ---------- JSON ------------\n\n\n");
	jsonShowTree(stdout,json,0);

	return 0;
}

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
