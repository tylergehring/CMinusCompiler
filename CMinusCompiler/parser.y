// bison

%code requires {
    typedef struct AstNode AstNode;
}

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "parser.scantype.h"

extern int yylex();
extern FILE *yyin;
extern int yydebug;

#define YYERROR_VERBOSE

typedef enum {
    AST_PROGRAM,
    AST_DECL_LIST,
    AST_VAR_DECL,
    AST_FUN_DECL,
    AST_PARAM_GROUP,
    AST_VAR_DECL_INIT,
    AST_VAR_DECL_ID,
    AST_TYPE_SPEC,
    AST_STMT_LIST,
    AST_EXPR_STMT,
    AST_COMPOUND_STMT,
    AST_IF_STMT,
    AST_WHILE_STMT,
    AST_FOR_STMT,
    AST_RETURN_STMT,
    AST_BREAK_STMT,
    AST_ITER_RANGE,
    AST_ASSIGN_EXPR,
    AST_BINARY_EXPR,
    AST_UNARY_EXPR,
    AST_CALL_EXPR,
    AST_ARRAY_REF,
    AST_IDENTIFIER,
    AST_CONST,
    AST_EMPTY
} AstKind;

typedef struct AstNode {
    AstKind kind;
    int line;
    char *name;
    char *op;
    int intValue;
    char charValue;
    char *stringValue;
    int isStatic;
    int arraySize;
    struct AstNode *left;
    struct AstNode *right;
    struct AstNode *third;
    struct AstNode *body;
    struct AstNode *next;
} AstNode;

static AstNode *astRoot = NULL;

static AstNode *newNode(AstKind kind, int line) {
    AstNode *node = (AstNode *) calloc(1, sizeof(AstNode));
    if (node == NULL) {
        fprintf(stderr, "out of memory\n");
        exit(1);
    }
    node->kind = kind;
    node->line = line;
    return node;
}

static AstNode *appendList(AstNode *head, AstNode *item) {
    if (item == NULL) {
        return head;
    }
    if (head == NULL) {
        return item;
    }
    AstNode *cur = head;
    while (cur->next != NULL) {
        cur = cur->next;
    }
    cur->next = item;
    return head;
}

static AstNode *makeTypeSpec(const char *name) {
    AstNode *node = newNode(AST_TYPE_SPEC, 0);
    node->name = strdup(name);
    return node;
}

static AstNode *makeVarDeclId(const char *name, int arraySize) {
    AstNode *node = newNode(AST_VAR_DECL_ID, 0);
    node->name = strdup(name);
    node->arraySize = arraySize;
    return node;
}

static AstNode *makeVarDeclInit(AstNode *id, AstNode *init) {
    AstNode *node = newNode(AST_VAR_DECL_INIT, 0);
    node->left = id;
    node->right = init;
    return node;
}

static AstNode *makeVarDecl(AstNode *typeSpec, AstNode *decls, int isStatic) {
    AstNode *node = newNode(AST_VAR_DECL, 0);
    node->left = typeSpec;
    node->right = decls;
    node->isStatic = isStatic;
    return node;
}

static AstNode *makeParamGroup(AstNode *typeSpec, AstNode *ids) {
    AstNode *node = newNode(AST_PARAM_GROUP, 0);
    node->left = typeSpec;
    node->right = ids;
    return node;
}

static AstNode *makeFunDecl(AstNode *typeSpec, const char *name, AstNode *params, AstNode *body, int hasVoidType) {
    AstNode *node = newNode(AST_FUN_DECL, 0);
    node->left = typeSpec;
    node->name = strdup(name);
    node->right = params;
    node->body = body;
    node->isStatic = hasVoidType;
    return node;
}

static AstNode *makeExprStmt(AstNode *expr) {
    AstNode *node = newNode(AST_EXPR_STMT, 0);
    node->left = expr;
    return node;
}

static AstNode *makeEmptyStmt(void) {
    AstNode *node = newNode(AST_EMPTY, 0);
    return node;
}

static AstNode *makeCompoundStmt(AstNode *decls, AstNode *stmts) {
    AstNode *node = newNode(AST_COMPOUND_STMT, 0);
    node->left = decls;
    node->right = stmts;
    return node;
}

static AstNode *makeIfStmt(AstNode *cond, AstNode *thenStmt, AstNode *elseStmt) {
    AstNode *node = newNode(AST_IF_STMT, 0);
    node->left = cond;
    node->right = thenStmt;
    node->third = elseStmt;
    return node;
}

static AstNode *makeWhileStmt(AstNode *cond, AstNode *body) {
    AstNode *node = newNode(AST_WHILE_STMT, 0);
    node->left = cond;
    node->body = body;
    return node;
}

static AstNode *makeForStmt(const char *name, AstNode *range, AstNode *body) {
    AstNode *node = newNode(AST_FOR_STMT, 0);
    node->name = strdup(name);
    node->left = range;
    node->body = body;
    return node;
}

static AstNode *makeIterRange(AstNode *start, AstNode *end, AstNode *step) {
    AstNode *node = newNode(AST_ITER_RANGE, 0);
    node->left = start;
    node->right = end;
    node->third = step;
    return node;
}

static AstNode *makeReturnStmt(AstNode *expr) {
    AstNode *node = newNode(AST_RETURN_STMT, 0);
    node->left = expr;
    return node;
}

static AstNode *makeBreakStmt(AstNode *expr) {
    AstNode *node = newNode(AST_BREAK_STMT, 0);
    node->left = expr;
    return node;
}

static AstNode *makeAssignExpr(const char *op, AstNode *lhs, AstNode *rhs) {
    AstNode *node = newNode(AST_ASSIGN_EXPR, 0);
    node->op = strdup(op);
    node->left = lhs;
    node->right = rhs;
    return node;
}

static AstNode *makeBinaryExpr(const char *op, AstNode *lhs, AstNode *rhs) {
    AstNode *node = newNode(AST_BINARY_EXPR, 0);
    node->op = strdup(op);
    node->left = lhs;
    node->right = rhs;
    return node;
}

static AstNode *makeUnaryExpr(const char *op, AstNode *operand) {
    AstNode *node = newNode(AST_UNARY_EXPR, 0);
    node->op = strdup(op);
    node->left = operand;
    return node;
}

static AstNode *makeCallExpr(const char *name, AstNode *args) {
    AstNode *node = newNode(AST_CALL_EXPR, 0);
    node->name = strdup(name);
    node->left = args;
    return node;
}

static AstNode *makeArrayRef(AstNode *base, AstNode *index) {
    AstNode *node = newNode(AST_ARRAY_REF, 0);
    node->left = base;
    node->right = index;
    return node;
}

static AstNode *makeIdentifier(const char *name) {
    AstNode *node = newNode(AST_IDENTIFIER, 0);
    node->name = strdup(name);
    return node;
}

static AstNode *makeConstInt(long long value) {
    AstNode *node = newNode(AST_CONST, 0);
    node->name = strdup("int");
    node->intValue = (int) value;
    return node;
}

static AstNode *makeConstChar(char value) {
    AstNode *node = newNode(AST_CONST, 0);
    node->name = strdup("char");
    node->charValue = value;
    return node;
}

static AstNode *makeConstString(const char *value) {
    AstNode *node = newNode(AST_CONST, 0);
    node->name = strdup("string");
    node->stringValue = strdup(value);
    return node;
}

static AstNode *makeConstBool(int value) {
    AstNode *node = newNode(AST_CONST, 0);
    node->name = strdup("bool");
    node->intValue = value;
    return node;
}

static AstNode *makeOpNode(const char *op) {
    AstNode *node = newNode(AST_EMPTY, 0);
    node->op = strdup(op);
    return node;
}

static void printAst(AstNode *node, int indent) {
    if (node == NULL) {
        return;
    }

    for (int i = 0; i < indent; i++) {
        printf("  ");
    }

    switch (node->kind) {
        case AST_PROGRAM:
            printf("Program\n");
            printAst(node->left, indent + 1);
            break;
        case AST_DECL_LIST:
            printf("DeclList\n");
            printAst(node->left, indent + 1);
            printAst(node->next, indent + 1);
            break;
        case AST_VAR_DECL:
            printf("VarDecl\n");
            printAst(node->left, indent + 1);
            printAst(node->right, indent + 1);
            break;
        case AST_FUN_DECL:
            printf("FunDecl: %s\n", node->name ? node->name : "<anon>");
            printAst(node->left, indent + 1);
            printAst(node->right, indent + 1);
            printAst(node->body, indent + 1);
            break;
        case AST_PARAM_GROUP:
            printf("ParamGroup\n");
            printAst(node->left, indent + 1);
            printAst(node->right, indent + 1);
            break;
        case AST_VAR_DECL_INIT:
            printf("VarDeclInit\n");
            printAst(node->left, indent + 1);
            printAst(node->right, indent + 1);
            break;
        case AST_VAR_DECL_ID:
            printf("VarId: %s", node->name ? node->name : "<anon>");
            if (node->arraySize >= 0) {
                printf("[%d]", node->arraySize);
            }
            printf("\n");
            break;
        case AST_TYPE_SPEC:
            printf("Type: %s\n", node->name ? node->name : "<unknown>");
            break;
        case AST_STMT_LIST:
            printf("StmtList\n");
            printAst(node->left, indent + 1);
            printAst(node->next, indent + 1);
            break;
        case AST_EXPR_STMT:
            printf("ExprStmt\n");
            printAst(node->left, indent + 1);
            break;
        case AST_COMPOUND_STMT:
            printf("CompoundStmt\n");
            printAst(node->left, indent + 1);
            printAst(node->right, indent + 1);
            break;
        case AST_IF_STMT:
            printf("IfStmt\n");
            printAst(node->left, indent + 1);
            printAst(node->right, indent + 1);
            printAst(node->third, indent + 1);
            break;
        case AST_WHILE_STMT:
            printf("WhileStmt\n");
            printAst(node->left, indent + 1);
            printAst(node->body, indent + 1);
            break;
        case AST_FOR_STMT:
            printf("ForStmt: %s\n", node->name ? node->name : "<anon>");
            printAst(node->left, indent + 1);
            printAst(node->body, indent + 1);
            break;
        case AST_RETURN_STMT:
            printf("ReturnStmt\n");
            printAst(node->left, indent + 1);
            break;
        case AST_BREAK_STMT:
            printf("BreakStmt\n");
            printAst(node->left, indent + 1);
            break;
        case AST_ITER_RANGE:
            printf("IterRange\n");
            printAst(node->left, indent + 1);
            printAst(node->right, indent + 1);
            printAst(node->third, indent + 1);
            break;
        case AST_ASSIGN_EXPR:
            printf("AssignExpr: %s\n", node->op ? node->op : "=");
            printAst(node->left, indent + 1);
            printAst(node->right, indent + 1);
            break;
        case AST_BINARY_EXPR:
            printf("BinaryExpr: %s\n", node->op ? node->op : "?");
            printAst(node->left, indent + 1);
            printAst(node->right, indent + 1);
            break;
        case AST_UNARY_EXPR:
            printf("UnaryExpr: %s\n", node->op ? node->op : "?");
            printAst(node->left, indent + 1);
            break;
        case AST_CALL_EXPR:
            printf("CallExpr: %s\n", node->name ? node->name : "<anon>");
            printAst(node->left, indent + 1);
            break;
        case AST_ARRAY_REF:
            printf("ArrayRef\n");
            printAst(node->left, indent + 1);
            printAst(node->right, indent + 1);
            break;
        case AST_IDENTIFIER:
            printf("Identifier: %s\n", node->name ? node->name : "<anon>");
            break;
        case AST_CONST:
            printf("Const: %s", node->name ? node->name : "<unknown>");
            if (strcmp(node->name, "int") == 0) {
                printf(" %d", node->intValue);
            } else if (strcmp(node->name, "char") == 0) {
                printf(" '%c'", node->charValue);
            } else if (strcmp(node->name, "string") == 0) {
                printf(" \"%s\"", node->stringValue ? node->stringValue : "");
            } else if (strcmp(node->name, "bool") == 0) {
                printf(" %s", node->intValue ? "true" : "false");
            }
            printf("\n");
            break;
        case AST_EMPTY:
            printf("Empty\n");
            break;
        default:
            printf("Node\n");
            break;
    }
}

static void freeAst(AstNode *node) {
    if (node == NULL) {
        return;
    }
    freeAst(node->left);
    freeAst(node->right);
    freeAst(node->third);
    freeAst(node->body);
    freeAst(node->next);
    free(node->name);
    free(node->op);
    free(node->stringValue);
    free(node);
}

void yyerror(const char *msg) {
    printf("ERROR(PARSER): %s\n", msg);
}
%}

%start program

%union {
    int num;
    TokenData *tokenData;
    AstNode *node;
};

%token <tokenData> NUMCONST BOOLCONST CHARCONST STRINGCONST ID
%token <tokenData> SEMI COMMA LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE COLON
%token <tokenData> INT BOOL CHAR STATIC IF THEN ELSE WHILE DO FOR TO BY RETURN BREAK AND OR NOT
%token <tokenData> LE GE EQ NE PLUSEQ MINUSEQ MULTEQ DIVEQ PLUSPLUS MINUSMINUS SHL SHR
%token <tokenData> PLUS MINUS MULT DIV MOD LT GT ASSIGN QUESTION

%type <node> program declList decl varDecl scopedVarDecl varDeclList varDeclInit varDeclId typeSpec funDecl parms parmList parmTypeList parmIdList parmId stmt expStmt compoundStmt localDecls stmtList matchedStmt unmatchedStmt matchedIterStmt iterRange returnStmt breakStmt exp simpleExp andExp unaryRelExp relExp relop minmaxExp minmaxop sumExp sumop mulExp mulop unaryExp unaryop factor mutable immutable call args argList constant

%%

program
    : declList {
          $$ = newNode(AST_PROGRAM, 0);
          $$->left = $1;
          astRoot = $$;
      }
    ;

declList
    : declList decl {
          $$ = newNode(AST_DECL_LIST, 0);
          $$->left = $1;
          $$->next = $2;
      }
    | decl {
          $$ = newNode(AST_DECL_LIST, 0);
          $$->left = $1;
      }
    ;

decl
    : varDecl { $$ = $1; }
    | funDecl { $$ = $1; }
    ;

varDecl
    : typeSpec varDeclList SEMI {
          $$ = makeVarDecl($1, $2, 0);
      }
    ;

scopedVarDecl
    : STATIC typeSpec varDeclList SEMI {
          $$ = makeVarDecl($2, $3, 1);
      }
    | typeSpec varDeclList SEMI {
          $$ = makeVarDecl($1, $2, 0);
      }
    ;

varDeclList
    : varDeclList COMMA varDeclInit {
          $$ = appendList($1, $3);
      }
    | varDeclInit {
          $$ = $1;
      }
    ;

varDeclInit
    : varDeclId {
          $$ = makeVarDeclInit($1, NULL);
      }
    | varDeclId COLON simpleExp {
          $$ = makeVarDeclInit($1, $3);
      }
    ;

varDeclId
    : ID {
          $$ = makeVarDeclId($1->svalue, -1);
      }
    | ID LBRACKET NUMCONST RBRACKET {
          $$ = makeVarDeclId($1->svalue, (int) $3->nvalue);
      }
    ;

typeSpec
    : INT { $$ = makeTypeSpec("int"); }
    | BOOL { $$ = makeTypeSpec("bool"); }
    | CHAR { $$ = makeTypeSpec("char"); }
    ;

funDecl
    : typeSpec ID LPAREN parms RPAREN stmt {
          $$ = makeFunDecl($1, $2->svalue, $4, $6, 0);
      }
    | ID LPAREN parms RPAREN stmt {
          $$ = makeFunDecl(makeTypeSpec("void"), $1->svalue, $3, $5, 1);
      }
    ;

parms
    : parmList { $$ = $1; }
    | /* empty */ { $$ = NULL; }
    ;

parmList
    : parmList SEMI parmTypeList {
          $$ = appendList($1, $3);
      }
    | parmTypeList {
          $$ = $1;
      }
    ;

parmTypeList
    : typeSpec parmIdList {
          $$ = makeParamGroup($1, $2);
      }
    ;

parmIdList
    : parmIdList COMMA parmId {
          $$ = appendList($1, $3);
      }
    | parmId {
          $$ = $1;
      }
    ;

parmId
    : ID {
          $$ = makeVarDeclId($1->svalue, -1);
      }
    | ID LBRACKET RBRACKET {
          $$ = makeVarDeclId($1->svalue, -1);
      }
    ;

stmt
    : matchedStmt { $$ = $1; }
    | unmatchedStmt { $$ = $1; }
    ;

expStmt
    : exp SEMI { $$ = makeExprStmt($1); }
    | SEMI { $$ = makeEmptyStmt(); }
    ;

compoundStmt
    : LBRACE localDecls stmtList RBRACE {
          $$ = makeCompoundStmt($2, $3);
      }
    ;

localDecls
    : localDecls scopedVarDecl {
          $$ = appendList($1, $2);
      }
    | /* empty */ { $$ = NULL; }
    ;

stmtList
    : stmtList stmt {
          $$ = appendList($1, $2);
      }
    | /* empty */ { $$ = NULL; }
    ;

matchedStmt
    : IF simpleExp THEN matchedStmt ELSE matchedStmt {
          $$ = makeIfStmt($2, $4, $6);
      }
    | expStmt { $$ = $1; }
    | compoundStmt { $$ = $1; }
    | matchedIterStmt { $$ = $1; }
    | returnStmt { $$ = $1; }
    | breakStmt { $$ = $1; }
    ;

unmatchedStmt
    : IF simpleExp THEN matchedStmt {
          $$ = makeIfStmt($2, $4, NULL);
      }
    | IF simpleExp THEN unmatchedStmt {
          $$ = makeIfStmt($2, $4, NULL);
      }
    | IF simpleExp THEN matchedStmt ELSE unmatchedStmt {
          $$ = makeIfStmt($2, $4, $6);
      }
    | WHILE simpleExp DO unmatchedStmt {
          $$ = makeWhileStmt($2, $4);
      }
    | FOR ID ASSIGN iterRange DO unmatchedStmt {
          $$ = makeForStmt($2->svalue, $4, $6);
      }
    ;

matchedIterStmt
    : WHILE simpleExp DO matchedStmt {
          $$ = makeWhileStmt($2, $4);
      }
    | FOR ID ASSIGN iterRange DO matchedStmt {
          $$ = makeForStmt($2->svalue, $4, $6);
      }
    ;

iterRange
    : simpleExp {
          $$ = makeIterRange($1, NULL, NULL);
      }
    | simpleExp TO simpleExp {
          $$ = makeIterRange($1, $3, NULL);
      }
    | simpleExp TO simpleExp BY simpleExp {
          $$ = makeIterRange($1, $3, $5);
      }
    ;

returnStmt
    : RETURN SEMI { $$ = makeReturnStmt(NULL); }
    | RETURN exp SEMI { $$ = makeReturnStmt($2); }
    ;

breakStmt
    : BREAK SEMI { $$ = makeBreakStmt(NULL); }
    | BREAK exp SEMI { $$ = makeBreakStmt($2); }
    ;

exp
    : mutable ASSIGN exp {
          $$ = makeAssignExpr("=", $1, $3);
      }
    | mutable PLUSEQ exp {
          $$ = makeAssignExpr("+=", $1, $3);
      }
    | mutable MINUSEQ exp {
          $$ = makeAssignExpr("-=", $1, $3);
      }
    | mutable MULTEQ exp {
          $$ = makeAssignExpr("*=", $1, $3);
      }
    | mutable DIVEQ exp {
          $$ = makeAssignExpr("/=", $1, $3);
      }
    | mutable PLUSPLUS {
          $$ = makeAssignExpr("++", $1, NULL);
      }
    | mutable MINUSMINUS {
          $$ = makeAssignExpr("--", $1, NULL);
      }
    | simpleExp { $$ = $1; }
    ;

simpleExp
    : simpleExp OR andExp {
          $$ = makeBinaryExpr("or", $1, $3);
      }
    | andExp { $$ = $1; }
    ;

andExp
    : andExp AND unaryRelExp {
          $$ = makeBinaryExpr("and", $1, $3);
      }
    | unaryRelExp { $$ = $1; }
    ;

unaryRelExp
    : NOT unaryRelExp {
          $$ = makeUnaryExpr("not", $2);
      }
    | relExp { $$ = $1; }
    ;

relExp
    : minmaxExp relop minmaxExp {
          $$ = makeBinaryExpr($2->op, $1, $3);
      }
    | minmaxExp { $$ = $1; }
    ;

relop
    : LE { $$ = makeOpNode("<="); }
    | LT { $$ = makeOpNode("<"); }
    | GT { $$ = makeOpNode(">"); }
    | GE { $$ = makeOpNode(">="); }
    | EQ { $$ = makeOpNode("=="); }
    | NE { $$ = makeOpNode("!="); }
    ;

minmaxExp
    : minmaxExp minmaxop sumExp {
          $$ = makeBinaryExpr($2->op, $1, $3);
      }
    | sumExp { $$ = $1; }
    ;

minmaxop
    : SHL { $$ = makeOpNode("<<"); }
    | SHR { $$ = makeOpNode(">>"); }
    ;

sumExp
    : sumExp sumop mulExp {
          $$ = makeBinaryExpr($2->op, $1, $3);
      }
    | mulExp { $$ = $1; }
    ;

sumop
    : PLUS { $$ = makeOpNode("+"); }
    | MINUS { $$ = makeOpNode("-"); }
    ;

mulExp
    : mulExp mulop unaryExp {
          $$ = makeBinaryExpr($2->op, $1, $3);
      }
    | unaryExp { $$ = $1; }
    ;

mulop
    : MULT { $$ = makeOpNode("*"); }
    | DIV { $$ = makeOpNode("/"); }
    | MOD { $$ = makeOpNode("%"); }
    ;

unaryExp
    : unaryop unaryExp {
          $$ = makeUnaryExpr($1->op, $2);
      }
    | factor { $$ = $1; }
    ;

unaryop
    : MINUS { $$ = makeOpNode("-"); }
    | MULT { $$ = makeOpNode("*"); }
    | QUESTION { $$ = makeOpNode("?"); }
    ;

factor
    : immutable { $$ = $1; }
    | mutable { $$ = $1; }
    ;

mutable
    : ID {
          $$ = makeIdentifier($1->svalue);
      }
    | ID LBRACKET exp RBRACKET {
          $$ = makeArrayRef(makeIdentifier($1->svalue), $3);
      }
    ;

immutable
    : LPAREN exp RPAREN { $$ = $2; }
    | call { $$ = $1; }
    | constant { $$ = $1; }
    ;

call
    : ID LPAREN args RPAREN {
          $$ = makeCallExpr($1->svalue, $3);
      }
    ;

args
    : argList { $$ = $1; }
    | /* empty */ { $$ = NULL; }
    ;

argList
    : argList COMMA exp {
          $$ = appendList($1, $3);
      }
    | exp {
          $$ = $1;
      }
    ;

constant
    : NUMCONST {
          $$ = makeConstInt($1->nvalue);
      }
    | CHARCONST {
          $$ = makeConstChar($1->cvalue);
      }
    | STRINGCONST {
          $$ = makeConstString($1->svalue);
      }
    | BOOLCONST {
          $$ = makeConstBool((int) $1->nvalue);
      }
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

    if (result == 0 && astRoot != NULL) {
        printAst(astRoot, 0);
    }

    if (yyin != NULL && yyin != stdin) {
        fclose(yyin);
    }

    freeAst(astRoot);
    return result;
}
