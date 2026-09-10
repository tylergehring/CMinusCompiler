//bison

// Define a Union containing TokenData*
// Define tokens such as NUMCONST, ID, BOOLCONST, keywords, multi-char operations
// Write grammar rules. Each should print the tokens line number, class, and values
// add main()


%{ 
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "parser.scantype.h"

extern int yylex();
extern FILE *yyin;
extern int yydebug;

#define YYERROR_VERBOSE

void yyerror(const char *msg) {
      printf("ERROR(SCANNER): %s\n", msg);
}

//// any C/C++ functions or globals that might be used in grammar below


// -------------------------------------------------------------
%}

%union {
    int num;
    TokenData *tokenData;
};

%token <tokenData> NUMCONST

// -------------------------------------------------------------
%%
tokenlist : tokenlist token | token ;

token : NUMCONST{ printf("NUMCONST\n"); };


// -------------------------------------------------------------
%%

int main(int argc, char *argv[]) {
    if (argc == 2) {
        yyin = fopen(argv[1], "r");

        if (yyin == NULL) {
            perror(argv[1]);
            return 1;
        }
    }
    else if (argc > 2) {
        fprintf(stderr, "usage: c- [filename]\n");
        return 1;
    }

    yyparse();

    if (yyin != NULL && yyin != stdin) {
        fclose(yyin);
    }
}

