%{
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "parser.scantype.h"
#include "parser.tab.h"

// Tracks source line manually; newlines embedded inside multi-line string/char
// constants do not advance it, matching the reference scanner's line counts.
static int lineNumber = 1;

// Builds a TokenData with just the fields every token shares; caller fills in the rest.
static TokenData *newToken(int tokenclass) {
    TokenData *tokenData = new TokenData;

    tokenData->tokenclass = tokenclass;
    tokenData->linenum = lineNumber;
    tokenData->tokenstr = strdup(yytext);
    tokenData->cvalue = '\0';
    tokenData->nvalue = 0;
    tokenData->svalue = NULL;

    return tokenData;
}
%}

%option noyywrap

%%

[0-9]+  {
            TokenData *tokenData = newToken(NUMCONST);
            tokenData->nvalue = atoll(yytext);

            yylval.tokenData = tokenData;
            return NUMCONST;
        }

        /* Matches a char constant with zero or one plain char/escape, never more. */
'([^'\\]|\\.)?'  {
            int len = strlen(yytext);
            char *decoded = new char[len + 1];
            int di = 0;

            for (int i = 1; i < len - 1; ) {
                if (yytext[i] == '\\') {
                    switch (yytext[i + 1]) {
                        case 'n': decoded[di++] = '\n'; break;
                        case 't': decoded[di++] = '\t'; break;
                        case '0': decoded[di++] = '\0'; break;
                        default:  decoded[di++] = yytext[i + 1]; break;
                    }
                    i += 2;
                } else {
                    decoded[di++] = yytext[i];
                    i += 1;
                }
            }
            decoded[di] = '\0';

            if (di == 0) {
                printf("ERROR(%d): Empty character ''. Characters ignored.\n", lineNumber);
                delete[] decoded;
            } else {
                TokenData *tokenData = newToken(CHARCONST);
                tokenData->cvalue = decoded[0];
                tokenData->svalue = decoded;
                tokenData->nvalue = di;

                yylval.tokenData = tokenData;
                return CHARCONST;
            }
        }

        /* Matches a double quoted string through its first unescaped quote. */
    \"([^"\\]|\\.)*\"  {
            TokenData *tokenData = newToken(STRINGCONST);
            int len = strlen(yytext);
            char *decoded = new char[len + 1];
            int di = 0;

            for (int i = 1; i < len - 1; ) {
                if (yytext[i] == '\\') {
                    switch (yytext[i + 1]) {
                        case 'n': decoded[di++] = '\n'; break;
                        case 't': decoded[di++] = '\t'; break;
                        case '0': decoded[di++] = '\0'; break;
                        default:  decoded[di++] = yytext[i + 1]; break;
                    }
                    i += 2;
                } else {
                    decoded[di++] = yytext[i];
                    i += 1;
                }
            }
            decoded[di] = '\0';
            tokenData->svalue = decoded;
            tokenData->nvalue = di;

            yylval.tokenData = tokenData;
            return STRINGCONST;
        }

"int"       { yylval.tokenData = newToken(INT);     return INT; }
"bool"      { yylval.tokenData = newToken(BOOL);    return BOOL; }
"char"      { yylval.tokenData = newToken(CHAR);    return CHAR; }
"static"    { yylval.tokenData = newToken(STATIC);  return STATIC; }
"if"        { yylval.tokenData = newToken(IF);      return IF; }
"else"      { yylval.tokenData = newToken(ELSE);    return ELSE; }
"while"     { yylval.tokenData = newToken(WHILE);   return WHILE; }
"for"       { yylval.tokenData = newToken(FOR);     return FOR; }
"to"        { yylval.tokenData = newToken(TO);      return TO; }
"then"      { yylval.tokenData = newToken(THEN);    return THEN; }
"do"        { yylval.tokenData = newToken(DO);      return DO; }
"by"        { yylval.tokenData = newToken(BY);      return BY; }
"return"    { yylval.tokenData = newToken(RETURN);  return RETURN; }
"break"     { yylval.tokenData = newToken(BREAK);   return BREAK; }
"and"       { yylval.tokenData = newToken(AND);     return AND; }
"or"        { yylval.tokenData = newToken(OR);      return OR; }
"not"       { yylval.tokenData = newToken(NOT);     return NOT; }
"&&"        { yylval.tokenData = newToken(AND);     return AND; }
"||"        { yylval.tokenData = newToken(OR);      return OR; }

"true"      {
                TokenData *tokenData = newToken(BOOLCONST);
                tokenData->nvalue = 1;

                yylval.tokenData = tokenData;
                return BOOLCONST;
            }

"false"     {
                TokenData *tokenData = newToken(BOOLCONST);
                tokenData->nvalue = 0;

                yylval.tokenData = tokenData;
                return BOOLCONST;
            }

[a-zA-Z][a-zA-Z0-9]*  {
            TokenData *tokenData = newToken(ID);
            tokenData->svalue = strdup(yytext);

            yylval.tokenData = tokenData;
            return ID;
        }

"<="    { yylval.tokenData = newToken(LE);         return LE; }
">="    { yylval.tokenData = newToken(GE);         return GE; }
"=="    { yylval.tokenData = newToken(EQ);         return EQ; }
"!="    { yylval.tokenData = newToken(NE);         return NE; }
"+="    { yylval.tokenData = newToken(PLUSEQ);     return PLUSEQ; }
"-="    { yylval.tokenData = newToken(MINUSEQ);    return MINUSEQ; }
"*="    { yylval.tokenData = newToken(MULTEQ);     return MULTEQ; }
"/="    { yylval.tokenData = newToken(DIVEQ);      return DIVEQ; }
"++"    { yylval.tokenData = newToken(PLUSPLUS);   return PLUSPLUS; }
"--"    { yylval.tokenData = newToken(MINUSMINUS); return MINUSMINUS; }
"<<"    { yylval.tokenData = newToken(SHL);        return SHL; }
">>"    { yylval.tokenData = newToken(SHR);        return SHR; }

"+"     { yylval.tokenData = newToken(PLUS);     return PLUS; }
"-"     { yylval.tokenData = newToken(MINUS);    return MINUS; }
"*"     { yylval.tokenData = newToken(MULT);     return MULT; }
"/"     { yylval.tokenData = newToken(DIV);      return DIV; }
"%"     { yylval.tokenData = newToken(MOD);      return MOD; }
"<"     { yylval.tokenData = newToken(LT);       return LT; }
">"     { yylval.tokenData = newToken(GT);        return GT; }
"="     { yylval.tokenData = newToken(ASSIGN);    return ASSIGN; }
"?"     { yylval.tokenData = newToken(QUESTION);  return QUESTION; }

";"     { yylval.tokenData = newToken(SEMI);     return SEMI; }
","     { yylval.tokenData = newToken(COMMA);    return COMMA; }
"("     { yylval.tokenData = newToken(LPAREN);   return LPAREN; }
")"     { yylval.tokenData = newToken(RPAREN);   return RPAREN; }
"["     { yylval.tokenData = newToken(LBRACKET); return LBRACKET; }
"]"     { yylval.tokenData = newToken(RBRACKET); return RBRACKET; }
"{"     { yylval.tokenData = newToken(LBRACE);   return LBRACE; }
"}"     { yylval.tokenData = newToken(RBRACE);   return RBRACE; }
":"     { yylval.tokenData = newToken(COLON);    return COLON; }

[ \t\r\n]+  {
            for (const char *p = yytext; *p; p++) {
                if (*p == '\n') lineNumber++;
            }
        }

"//"[^\n]*  { /* Ignore // comments through end of line. */ }

.       {
         printf("ERROR(%d): Invalid or misplaced input character: '%s'. Character Ignored.\n",
             lineNumber, yytext);
        }

%%