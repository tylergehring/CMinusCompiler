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
%token <tokenData> BOOLCONST
%token <tokenData> CHARCONST
%token <tokenData> STRINGCONST
%token <tokenData> ID
%token <tokenData> SEMI COMMA LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE COLON
%token <tokenData> INT BOOL CHAR STATIC IF THEN ELSE WHILE DO FOR TO BY RETURN BREAK AND OR NOT
%token <tokenData> LE GE EQ NE PLUSEQ MINUSEQ MULTEQ DIVEQ PLUSPLUS MINUSMINUS SHL SHR
%token <tokenData> PLUS MINUS MULT DIV MOD LT GT ASSIGN QUESTION

// -------------------------------------------------------------
%%
tokenlist : tokenlist token | token ;

token : NUMCONST  { printf("NUMCONST\n"); }
      | BOOLCONST { printf("BOOLCONST\n"); }
      | CHARCONST { printf("CHARCONST\n"); }
      | STRINGCONST { printf("STRINGCONST\n"); }
      | ID        { printf("ID\n"); }
      | SEMI      { printf("SEMI\n"); }
      | COMMA     { printf("COMMA\n"); }
      | LPAREN    { printf("LPAREN\n"); }
      | RPAREN    { printf("RPAREN\n"); }
      | LBRACKET  { printf("LBRACKET\n"); }
      | RBRACKET  { printf("RBRACKET\n"); }
      | LBRACE    { printf("LBRACE\n"); }
      | RBRACE    { printf("RBRACE\n"); }
      | COLON     { printf("COLON\n"); }
      | INT       { printf("INT\n"); }
      | BOOL      { printf("BOOL\n"); }
      | CHAR      { printf("CHAR\n"); }
      | STATIC    { printf("STATIC\n"); }
      | IF        { printf("IF\n"); }
      | THEN      { printf("THEN\n"); }
      | ELSE      { printf("ELSE\n"); }
      | WHILE     { printf("WHILE\n"); }
      | DO        { printf("DO\n"); }
      | FOR       { printf("FOR\n"); }
      | TO        { printf("TO\n"); }
      | BY        { printf("BY\n"); }
      | RETURN    { printf("RETURN\n"); }
      | BREAK     { printf("BREAK\n"); }
      | AND       { printf("AND\n"); }
      | OR        { printf("OR\n"); }
      | NOT       { printf("NOT\n"); }
      | LE        { printf("LE\n"); }
      | GE        { printf("GE\n"); }
      | EQ        { printf("EQ\n"); }
      | NE        { printf("NE\n"); }
      | PLUSEQ    { printf("PLUSEQ\n"); }
      | MINUSEQ   { printf("MINUSEQ\n"); }
      | MULTEQ    { printf("MULTEQ\n"); }
      | DIVEQ     { printf("DIVEQ\n"); }
      | PLUSPLUS  { printf("PLUSPLUS\n"); }
      | MINUSMINUS { printf("MINUSMINUS\n"); }
      | SHL       { printf("SHL\n"); }
      | SHR       { printf("SHR\n"); }
      | PLUS      { printf("+\n"); }
      | MINUS     { printf("-\n"); }
      | MULT      { printf("*\n"); }
      | DIV       { printf("/\n"); }
      | MOD       { printf("%%\n"); }
      | LT        { printf("<\n"); }
      | GT        { printf(">\n"); }
      | ASSIGN    { printf("=\n"); }
      | QUESTION  { printf("?\n"); }
      ;


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

