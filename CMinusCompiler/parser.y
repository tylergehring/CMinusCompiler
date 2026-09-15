// bison

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
    printf("ERROR(PARSER): %s\n", msg);
}
%}

%start program

%union {
    int num;
    TokenData *tokenData;
};

%token <tokenData> NUMCONST BOOLCONST CHARCONST STRINGCONST ID
%token <tokenData> SEMI COMMA LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE COLON
%token <tokenData> INT BOOL CHAR STATIC IF THEN ELSE WHILE DO FOR TO BY RETURN BREAK AND OR NOT
%token <tokenData> LE GE EQ NE PLUSEQ MINUSEQ MULTEQ DIVEQ PLUSPLUS MINUSMINUS SHL SHR
%token <tokenData> PLUS MINUS MULT DIV MOD LT GT ASSIGN QUESTION

%%

program
    : declList
    ;

declList
    : declList decl
    | decl
    ;

decl
    : varDecl
    | funDecl
    ;

varDecl
    : typeSpec varDeclList SEMI
    ;

scopedVarDecl
    : STATIC typeSpec varDeclList SEMI
    | typeSpec varDeclList SEMI
    ;

varDeclList
    : varDeclList COMMA varDeclInit
    | varDeclInit
    ;

varDeclInit
    : varDeclId
    | varDeclId COLON simpleExp
    ;

varDeclId
    : ID
    | ID LBRACKET NUMCONST RBRACKET
    ;

typeSpec
    : INT
    | BOOL
    | CHAR
    ;

funDecl
    : typeSpec ID LPAREN parms RPAREN stmt
    | ID LPAREN parms RPAREN stmt
    ;

parms
    : parmList
    | /* empty */
    ;

parmList
    : parmList SEMI parmTypeList
    | parmTypeList
    ;

parmTypeList
    : typeSpec parmIdList
    ;

parmIdList
    : parmIdList COMMA parmId
    | parmId
    ;

parmId
    : ID
    | ID LBRACKET RBRACKET
    ;

stmt
    : matchedStmt
    | unmatchedStmt
    ;

expStmt
    : exp SEMI
    | SEMI
    ;

compoundStmt
    : LBRACE localDecls stmtList RBRACE
    ;

localDecls
    : localDecls scopedVarDecl
    | /* empty */
    ;

stmtList
    : stmtList stmt
    | /* empty */
    ;

matchedStmt
    : IF simpleExp THEN matchedStmt ELSE matchedStmt
    | expStmt
    | compoundStmt
    | matchedIterStmt
    | returnStmt
    | breakStmt
    ;

unmatchedStmt
    : IF simpleExp THEN matchedStmt
    | IF simpleExp THEN unmatchedStmt
    | IF simpleExp THEN matchedStmt ELSE unmatchedStmt
    | WHILE simpleExp DO unmatchedStmt
    | FOR ID ASSIGN iterRange DO unmatchedStmt
    ;

matchedIterStmt
    : WHILE simpleExp DO matchedStmt
    | FOR ID ASSIGN iterRange DO matchedStmt
    ;

iterRange
    : simpleExp
    | simpleExp TO simpleExp
    | simpleExp TO simpleExp BY simpleExp
    ;

returnStmt
    : RETURN SEMI
    | RETURN exp SEMI
    ;

breakStmt
    : BREAK SEMI
    | BREAK exp SEMI
    ;

exp
    : mutable ASSIGN exp
    | mutable PLUSEQ exp
    | mutable MINUSEQ exp
    | mutable MULTEQ exp
    | mutable DIVEQ exp
    | mutable PLUSPLUS
    | mutable MINUSMINUS
    | simpleExp
    ;

simpleExp
    : simpleExp OR andExp
    | andExp
    ;

andExp
    : andExp AND unaryRelExp
    | unaryRelExp
    ;

unaryRelExp
    : NOT unaryRelExp
    | relExp
    ;

relExp
    : minmaxExp relop minmaxExp
    | minmaxExp
    ;

relop
    : LE
    | LT
    | GT
    | GE
    | EQ
    | NE
    ;

minmaxExp
    : minmaxExp minmaxop sumExp
    | sumExp
    ;

minmaxop
    : SHL
    | SHR
    ;

sumExp
    : sumExp sumop mulExp
    | mulExp
    ;

sumop
    : PLUS
    | MINUS
    ;

mulExp
    : mulExp mulop unaryExp
    | unaryExp
    ;

mulop
    : MULT
    | DIV
    | MOD
    ;

unaryExp
    : unaryop unaryExp
    | factor
    ;

unaryop
    : MINUS
    | MULT
    | QUESTION
    ;

factor
    : immutable
    | mutable
    ;

mutable
    : ID
    | ID LBRACKET exp RBRACKET
    ;

immutable
    : LPAREN exp RPAREN
    | call
    | constant
    ;

call
    : ID LPAREN args RPAREN
    ;

args
    : argList
    | /* empty */
    ;

argList
    : argList COMMA exp
    | exp
    ;

constant
    : NUMCONST
    | CHARCONST
    | STRINGCONST
    | BOOLCONST
    ;

%%

int main(int argc, char *argv[]) {
    if (argc == 2) {
        yyin = fopen(argv[1], "r");

        if (yyin == NULL) {
            perror(argv[1]);
            return 1;
        }
    } else if (argc > 2) {
        fprintf(stderr, "usage: c- [filename]\n");
        return 1;
    }

    int result = yyparse();

    if (yyin != NULL && yyin != stdin) {
        fclose(yyin);
    }

    return result;
}
