//flex
// includd parser.tab.h and parser.scantype.h
// Track lines with %option yylineno
// For each matched token, allocate TokenDAta, fill in:
//      tokenclass, linenum, tokenstr, nvalue, cvalue,svalute
// set yylval.tokenData = tokenData; and return TOKEN_NAME;
// begin win whitespace, identifiesrs, intigers, constants, and one keyword


%{
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "parser.scantype.h"
#include "parser.tab.h"
%}

%option noyywrap
%option yylineno

%%

[0-9]+  {
            TokenData *tokenData = new TokenData;

            tokenData->tokenclass = NUMCONST;
            tokenData->linenum = yylineno;
            tokenData->tokenstr = strdup(yytext);
            tokenData->nvalue = atoll(yytext);
            tokenData->cvalue = '\0';
            tokenData->svalue = NULL;

            yylval.tokenData = tokenData;
            return NUMCONST;
        }

[ \t\r\n]+  { /* Ignore whitespace. */ }

.       {
            printf("ERROR(SCANNER): Illegal character '%s' at line %d.\n",
                   yytext, yylineno);
        }

%%