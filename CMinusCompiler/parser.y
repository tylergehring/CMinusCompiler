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

static void printToken(TokenData *tokenData, const char *tokenName) {
    printf("Line %d Token: %s\n", tokenData->linenum, tokenName);
}

static void printNumber(TokenData *tokenData, const char *tokenName) {
    printf("Line %d Token: %s Value: %lld Input: %s\n",
           tokenData->linenum, tokenName, tokenData->nvalue, tokenData->tokenstr);
}

static void printIdentifier(TokenData *tokenData) {
    printf("Line %d Token: ID Value: %s\n", tokenData->linenum, tokenData->svalue);
}

static void printCharacter(TokenData *tokenData) {
    printf("Line %d Token: CHARCONST Value: '", tokenData->linenum);
    fwrite(tokenData->svalue, 1, tokenData->nvalue, stdout);
    printf("' Input: %s\n", tokenData->tokenstr);
}

static void printString(TokenData *tokenData) {
    printf("Line %d Token: STRINGCONST Value: \"", tokenData->linenum);
    fwrite(tokenData->svalue, 1, tokenData->nvalue, stdout);
    printf("\" Len: %lld Input: %s\n", tokenData->nvalue, tokenData->tokenstr);
}


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

token : NUMCONST   { printNumber($1, "NUMCONST"); }
    | BOOLCONST  { printNumber($1, "BOOLCONST"); }
    | CHARCONST  { printCharacter($1); }
    | STRINGCONST { printString($1); }
    | ID         { printIdentifier($1); }
    | SEMI       { printToken($1, ";"); }
    | COMMA      { printToken($1, ","); }
    | LPAREN     { printToken($1, "("); }
    | RPAREN     { printToken($1, ")"); }
    | LBRACKET   { printToken($1, "["); }
    | RBRACKET   { printToken($1, "]"); }
    | LBRACE     { printToken($1, "{"); }
    | RBRACE     { printToken($1, "}"); }
    | COLON      { printToken($1, ":"); }
    | INT        { printToken($1, "INT"); }
    | BOOL       { printToken($1, "BOOL"); }
    | CHAR       { printToken($1, "CHAR"); }
    | STATIC     { printToken($1, "STATIC"); }
    | IF         { printToken($1, "IF"); }
    | THEN       { printToken($1, "THEN"); }
    | ELSE       { printToken($1, "ELSE"); }
    | WHILE      { printToken($1, "WHILE"); }
    | DO         { printToken($1, "DO"); }
    | FOR        { printToken($1, "FOR"); }
    | TO         { printToken($1, "TO"); }
    | BY         { printToken($1, "BY"); }
    | RETURN     { printToken($1, "RETURN"); }
    | BREAK      { printToken($1, "BREAK"); }
    | AND        { printToken($1, "AND"); }
    | OR         { printToken($1, "OR"); }
    | NOT        { printToken($1, "NOT"); }
    | LE         { printToken($1, "LEQ"); }
    | GE         { printToken($1, "GEQ"); }
    | EQ         { printToken($1, "EQ"); }
    | NE         { printToken($1, "NEQ"); }
    | PLUSEQ     { printToken($1, "ADDASS"); }
    | MINUSEQ    { printToken($1, "SUBASS"); }
    | MULTEQ     { printToken($1, "MULASS"); }
    | DIVEQ      { printToken($1, "DIVASS"); }
    | PLUSPLUS   { printToken($1, "INC"); }
    | MINUSMINUS { printToken($1, "DEC"); }
    | SHL        { printToken($1, "MIN"); }
    | SHR        { printToken($1, "MAX"); }
    | PLUS       { printToken($1, "+"); }
    | MINUS      { printToken($1, "-"); }
    | MULT       { printToken($1, "*"); }
    | DIV        { printToken($1, "/"); }
    | MOD        { printToken($1, "%"); }
    | LT         { printToken($1, "<"); }
    | GT         { printToken($1, ">"); }
    | ASSIGN     { printToken($1, "="); }
        | QUESTION   { printToken($1, "?"); }
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

