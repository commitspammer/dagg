/*
 * daggparser.y:
 * Description: Syntax analyser for the DAGG Programming Language.
 */

%{

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <ctype.h>
#include "table.h"
#include "errors.h"
//#include "vector.h"
//#include "matrix.h"

int yylex(void);
int yyerror(char *msg);
extern int yylineno;
extern char *yytext;
extern FILE *yyin;
extern FILE *yyout;
char *cat(int vacount,...);
int countc(char *s, char c);
char *uniquifylabels(char *s);
char *idof(char *var);
char *dereftype(char *t);
char *paramof(char *funt, int i);
char *returnof(char *funt, int i);

%}

%union {
	char *sval;
	struct slist {
		char *data[100]; //TODO LET ME GROW
		int size;
	} slist;
	struct expval {
		char *text;
		char *type;
	} expval;
	struct explist {
		struct expval data[100];
		int size;
	} explist;
	struct elifval {
		char *text;
		char *label;
	} elifval;
	struct paramval {
		char *id;
		char *type;
	} paramval;
	struct paramlist {
		struct paramval data[100];
		int size;
	} paramlist;
};

%start program

%token <sval> ID PRIMITIVE STRING BOOL INT FLOAT
%token ASSIGN COLON COMMA ENDMARKER
%token FOR IN WHILE DO IF THEN ELSE BREAK CONTINUE RETURN PRINT SCAN
%token PLUS MINUS TIMES FLOATDIVISION INTDIVISION REMAINDER EXPONENTIATION
%token NOT AND OR EQUAL NOTEQUAL GREATER GREATEREQUAL LESSER LESSEREQUAL
%token LENGTH PUSH POP CONCATENATION RANGE //INTERVAL
%token OPENPARENTHESIS CLOSEPARENTHESIS OPENCURLY CLOSECURLY OPENBRACKETS CLOSEBRACKETS

%type <sval> subscript variable type opttype
%type <sval> vectorconcatenation vectorpush vectorpop
%type <sval> compoundstatement statement block function functionlist globallist
%type <sval> ifstatement whilestatement dowhilestatement forstatement
%type <sval> declaration initialization assignment
%type <sval> printstatement scanstatement breakstatement continuestatement returnstatement
%type <slist> subscriptlist variablelist
%type <elifval> elsechain
%type <paramval> parameter
%type <paramlist> optparameterlist parameterlist
%type <expval> expression
%type <explist> expressionlist

%left OR
%left AND
%left NOT
%nonassoc EQUAL NOTEQUAL GREATER GREATEREQUAL LESSER LESSEREQUAL
%left PLUS MINUS
%left TIMES INTDIVISION FLOATDIVISION REMAINDER
%right EXPONENTIATION
%nonassoc UNARYMINUS LENGTH CONCATENATION

%% /* Inicio da segunda seção, onde colocamos as regras BNF */

program : {up();} globallist functionlist
{
	char *includes = "#include <stdio.h>\n#include <stdlib.h>\n#include <stdbool.h>\n#include <stdarg.h>\n#include <math.h>\n#include <string.h>\n\n";
	fprintf(yyout, "%s", includes);
	FILE *vectorimpl = fopen("vector.c", "r"); 
	FILE *matriximpl = fopen("matrix.c", "r"); 
	char c;
	while ((c = getc(vectorimpl)) != EOF) putc(c, yyout);
	while ((c = getc(matriximpl)) != EOF) putc(c, yyout);
	fclose(vectorimpl);
	fclose(matriximpl);
	fprintf(yyout, "%s", $2);
	fprintf(yyout, "%s", $3);
	down();
}
        | ENDMARKER program
        ;

globallist : {$$ = "";}
           | globallist declaration ENDMARKER {$$ = cat(2, $1, $2);}
           ;

functionlist : function {$$ = $1;}
             | functionlist function {$$ = cat(3, $1, "\n", $2);}
             ;

function : ID OPENPARENTHESIS optparameterlist CLOSEPARENTHESIS opttype
{
	char *funct = "";
	if ($3.size > 0) funct = $3.data[0].type;
	for (int i = 1; i < $3.size; i++)
		funct = cat(3, funct, ",", $3.data[i].type);

	char *returnt = "";
	if (strcmp($5, "void")) returnt = $5;
	funct = cat(3, funct, "->", returnt);

	if (!insert($1, funct)) alreadydecl(yylineno, $1);
	up();
	for (int i = 0; i < $3.size; i++)
		if (!insert($3.data[i].id, $3.data[i].type))
			alreadydecl(yylineno, $3.data[i].id);
} block
{
	char *params = "";
	if ($3.size > 0) params = cat(3, $3.data[0].type, " ", $3.data[0].id);
	for (int i = 1; i < $3.size; i++)
		params = cat(5, params, ", ", $3.data[i].type, " ", $3.data[i].id);
	char *txt = cat(7, $5, " ", $1, "(", params, ")\n", $7);
	$$ = txt;
	down();
}
         ;

opttype : {$$ = "void";}
        | COLON type {$$ = $2;}
        ;

type : PRIMITIVE
{
	if (!strcmp($1, "bool")) $$ = "bool";
	else if (!strcmp($1, "int")) $$ = "int";
	else if (!strcmp($1, "real")) $$ = "float";
	else if (!strcmp($1, "texto")) $$ = "char*";
	else fatal(yylineno, "unknown primitive");
}
     | OPENBRACKETS type CLOSEBRACKETS
{
	if (!strcmp($2, "int")) $$ = "_Vector*";
	else if (!strcmp($2, "_Vector*")) $$ = "_Matrix*";
	else if (!strcmp($2, "_Matrix*")) unsupp(yylineno, "int vectors over 2 dimensions");
	else unsupp(yylineno, "non int vectors");
}
     ;

optparameterlist : {$$.size = 0;}
                 | parameterlist {$$ = $1;}
                 ;

parameterlist : parameter {$$.size = 0; $$.data[$$.size++] = $1;}
              | parameterlist COMMA parameter {$$.data[$$.size++] = $3;}
              ;

parameter : ID COLON type {$$.id = $1; $$.type = $3;}
          ;

block : OPENCURLY compoundstatement CLOSECURLY {$$ = cat(3, "{\n", $2, ";}\n");}
      | OPENCURLY CLOSECURLY {$$ = "{\n;}\n";}
      ;

compoundstatement : statement {$$ = $1;}
                  | compoundstatement statement {$$ = cat(2, $1, $2);}
                  ;

statement : declaration ENDMARKER {$$ = $1;}
          | assignment ENDMARKER {$$ = $1;}
          | initialization ENDMARKER {$$ = $1;}
          | printstatement ENDMARKER {$$ = $1;}
          | scanstatement ENDMARKER {$$ = $1;}
          | breakstatement ENDMARKER {$$ = $1;}
          | continuestatement ENDMARKER {$$ = $1;}
          | returnstatement ENDMARKER {$$ = $1;}
          //| function // :(
          | forstatement {$$ = $1;}
          | whilestatement {$$ = $1;}
          | dowhilestatement ENDMARKER {$$ = $1;}
          | ifstatement {$$ = $1;}
          | expression ENDMARKER {$$ = cat(2, $1.text, ";\n");} //TODO ALLOW ONLY FUNCALLS?
          | vectorconcatenation ENDMARKER {$$ = $1;}
          | vectorpush ENDMARKER {$$ = $1;}
          | vectorpop ENDMARKER {$$ = $1;}
          ;

printstatement : PRINT expressionlist
{
	char *txt = "";
	for (int i = 0; i < $2.size; i++) {
		if (!strcmp($2.data[i].type, "bool"))
			txt = cat(4, txt, "printf(\"\%d\",", $2.data[i].text, ");\n");
		else if (!strcmp($2.data[i].type, "int"))
			txt = cat(4, txt, "printf(\"\%d\",", $2.data[i].text, ");\n");
		else if (!strcmp($2.data[i].type, "float"))
			txt = cat(4, txt, "printf(\"\%f\",", $2.data[i].text, ");\n");
		else if (!strcmp($2.data[i].type, "char*"))
			txt = cat(4, txt, "printf(\"\%s\",", $2.data[i].text, ");\n");
		else fatal(yylineno, "invalid print type");
	}
	$$ = txt;
}
               ;

scanstatement : SCAN variablelist
{
	char *txt = "";
	for (int i = 0; i < $2.size; i++) {
		if (countc($2.data[i], '[') > 0) notid(yylineno, $2.data[i]);
		Symbol symb;
		if (!lookup($2.data[i], &symb)) notdecl(yylineno, $2.data[i]);
		if (!strcmp(symb.type, "bool"))
			fatal(yylineno, "bool cannot be scanned");
		else if (!strcmp(symb.type, "int"))
			txt = cat(4, txt, "scanf(\"\%d\",&", $2.data[i], ");\n");
		else if (!strcmp(symb.type, "float"))
			txt = cat(4, txt, "scanf(\"\%f\",&", $2.data[i], ");\n");
		else if (!strcmp(symb.type, "char*"))
			txt = cat(4, txt, "scanf(\"\%s\",", $2.data[i], ");\n");
		else fatal(yylineno, "invalid scan type");
	}
	$$ = txt;
}
              ;

breakstatement : BREAK {$$ = "goto _JUMP;\n";}
               ;

continuestatement : CONTINUE {$$ = "goto _LOOP;\n";}
                  ;

returnstatement : RETURN {$$ = "return;\n";}
                | RETURN expression {$$ = cat(3, "return ", $2.text, ";\n");}
                ;

expressionlist : expression {$$.size = 0; $$.data[$$.size++] = $1;}
               | expressionlist COMMA expression {$$.data[$$.size++] = $3;}
               ;

declaration : variablelist COLON type
{
	char *txt = "";
	for (int i = 0; i < $1.size; i++) {
		if (countc($1.data[i], '[') > 0) notid(yylineno, $1.data[i]);
		if (!insert($1.data[i], $3)) alreadydecl(yylineno, $1.data[i]);
		txt = cat(5, txt, $3, " ", $1.data[i], ";\n");
	}
	$$ = txt;
}
            ;

assignment : variablelist ASSIGN expressionlist
{
	char *txt = "";
	if ($1.size != $3.size) unmatchassign(yylineno, $1.size, $3.size);
	for (int i = 0; i < $1.size; i++) {
		Symbol symb;
		if (!lookup(idof($1.data[i]), &symb)) notdecl(yylineno, idof($1.data[i]));
		char *type = symb.type;
		for (int k = 0; k < countc($1.data[i], '['); k++) type = dereftype(type);
		if (type == NULL) badderef(yylineno, symb.name);
		if (strcmp(type, $3.data[i].type))
			unmatchtype(yylineno, $1.data[i], type, $3.data[i].text, $3.data[i].type);
		txt = cat(5, txt, $1.data[i], "=", $3.data[i].text, ";\n");
	}
	$$ = txt;
}
           ;

initialization : variablelist COLON type ASSIGN expressionlist
{
	char *txt = "";
	for (int i = 0; i < $1.size; i++) {
		if (countc($1.data[i], '[') > 0) notid(yylineno, $1.data[i]);
		if (!insert($1.data[i], $3)) alreadydecl(yylineno, $1.data[i]);
	}
	if ($1.size != $5.size) unmatchassign(yylineno, $1.size, $5.size);
	for (int i = 0; i < $1.size; i++) {
		Symbol symb;
		if (!lookup($1.data[i], &symb)) notdecl(yylineno, $1.data[i]);
		if (strcmp(symb.type, $5.data[i].type))
			unmatchtype(yylineno, symb.name, symb.type, $5.data[i].text, $5.data[i].type);
		txt = cat(7, txt, $3, " ", $1.data[i], "=", $5.data[i].text, ";\n");
	}
	$$ = txt;
}
               ;

variablelist : variable {$$.size = 0; $$.data[$$.size++] = $1;}
             | variablelist COMMA variable {$$.data[$$.size++] = $3;}
             ;

variable : ID {$$ = $1;}
         | ID subscriptlist
{
	Symbol symb;
	if (!lookup($1, &symb)) notdecl(yylineno, $1);
	if (strcmp(symb.type, "_Vector*") && strcmp(symb.type, "_Matrix*"))
		badtype(yylineno, $1, symb.type, "vector or matrix");
	char *txt = $1;
	char *type = symb.type;
	for (int i = 0; i < $2.size; i++) {
		if ((type = dereftype(type)) == NULL) badderef(yylineno, symb.name);
		txt = cat(3, txt, "->data", $2.data[i]);
	}
	$$ = txt;
}
         ;

subscriptlist : subscript {$$.size = 0; $$.data[$$.size++] = $1;}
              | subscriptlist subscript
{
	if ($1.size >= 2) unsupp(yylineno, "vector literals over 2 dimensions");
	$$.data[$$.size++] = $2;
}
              ;

subscript : OPENBRACKETS expression CLOSEBRACKETS
{
	if (strcmp($2.type, "int")) badtype(yylineno, $2.text, $2.type, "int");
	$$ = cat(3, "[", $2.text, "]");
}
          ;

expression : expression PLUS expression
{
	if (strcmp($1.type, "int") && strcmp($1.type, "float")) badtype(yylineno, $1.text, $1.type, "number");
	if (strcmp($3.type, "int") && strcmp($3.type, "float")) badtype(yylineno, $3.text, $3.type, "number");
	$$.text = cat(3, $1.text, "+", $3.text);
	$$.type = !strcmp($1.type, $3.type) ? $1.type : "float";
}
           | expression MINUS expression
{
	if (strcmp($1.type, "int") && strcmp($1.type, "float")) badtype(yylineno, $1.text, $1.type, "number");
	if (strcmp($3.type, "int") && strcmp($3.type, "float")) badtype(yylineno, $3.text, $3.type, "number");
	$$.text = cat(3, $1.text, "-", $3.text);
	$$.type = !strcmp($1.type, $3.type) ? $1.type : "float";
}
           | expression TIMES expression
{
	if (strcmp($1.type, "int") && strcmp($1.type, "float")) badtype(yylineno, $1.text, $1.type, "number");
	if (strcmp($3.type, "int") && strcmp($3.type, "float")) badtype(yylineno, $3.text, $3.type, "number");
	$$.text = cat(3, $1.text, "*", $3.text);
	$$.type = !strcmp($1.type, $3.type) ? $1.type : "float";
}
           | expression INTDIVISION expression
{
	if (strcmp($1.type, "int")) badtype(yylineno, $1.text, $1.type, "int");
	if (strcmp($3.type, "int")) badtype(yylineno, $3.text, $3.type, "int");
	$$.text = cat(3, $1.text, "/", $3.text);
	$$.type = "int";
}
           | expression FLOATDIVISION expression
{
	if (strcmp($1.type, "int") && strcmp($1.type, "float")) badtype(yylineno, $1.text, $1.type, "number");
	if (strcmp($3.type, "int") && strcmp($3.type, "float")) badtype(yylineno, $3.text, $3.type, "number");
	$$.text = cat(4, "(float)(", $1.text, ")/", $3.text);
	$$.type = "float";
}
           | expression REMAINDER expression
{
	if (strcmp($1.type, "int")) badtype(yylineno, $1.text, $1.type, "int");
	if (strcmp($3.type, "int")) badtype(yylineno, $3.text, $3.type, "int");
	$$.text = cat(3, $1.text, "%", $3.text);
	$$.type = "int";
}
           | expression EXPONENTIATION expression
{
	if (strcmp($1.type, "int") && strcmp($1.type, "float")) badtype(yylineno, $1.text, $1.type, "number");
	if (strcmp($3.type, "int") && strcmp($3.type, "float")) badtype(yylineno, $3.text, $3.type, "number");
	$$.text = cat(5, "(float)pow((double)(", $1.text, "),(double)(", $3.text, "))");
	$$.type = "float";
}
           | MINUS expression %prec UNARYMINUS
{
	if (strcmp($2.type, "int") && strcmp($2.type, "float")) badtype(yylineno, $2.text, $2.type, "number");
	$$.text = cat(2, " -", $2.text);
	$$.type = $2.type;
}
           | OPENPARENTHESIS expression CLOSEPARENTHESIS
{
	$$.text = cat(3, "(", $2.text, ")");
	$$.type = $2.type;
}
           | INT {$$.text = $1; $$.type = "int";}
           | FLOAT {$$.text = $1; $$.type = "float";}
           | ID
{
	$$.text = $1;
	Symbol s;
	if (lookup($1, &s)) $$.type = s.type;
	else notdecl(yylineno, $1);
}

           | expression EQUAL expression
{
	if (!strcmp($1.type, "char*") && !strcmp($1.type, "char*")) {
		$$.text = cat(5, "!strcmp(", $1.text, ",", $3.text, ")");
	} else {
		if (strcmp($1.type, "bool") && strcmp($1.type, "int") && strcmp($1.type, "float"))
			badtype(yylineno, $1.text, $1.type, "bool, number or string");
		if (strcmp($3.type, "bool") && strcmp($1.type, "int") && strcmp($1.type, "float"))
			badtype(yylineno, $3.text, $3.type, "bool, number or string");
		$$.text = cat(3, $1.text, "==", $3.text);
	}
	$$.type = "bool";
}
           | expression NOTEQUAL expression
{
	if (!strcmp($1.type, "char*") && !strcmp($1.type, "char*")) {
		$$.text = cat(5, "strcmp(", $1.text, ",", $3.text, ")");
	} else {
		if (strcmp($1.type, "bool") && strcmp($1.type, "int") && strcmp($1.type, "float"))
			badtype(yylineno, $1.text, $1.type, "bool, number or string");
		if (strcmp($3.type, "bool") && strcmp($1.type, "int") && strcmp($1.type, "float"))
			badtype(yylineno, $3.text, $3.type, "bool, number or string");
		$$.text = cat(3, $1.text, "!=", $3.text);
	}
	$$.type = "bool";
}
           | expression GREATER expression
{
	if (strcmp($1.type, "int") && strcmp($1.type, "float")) badtype(yylineno, $1.text, $1.type, "number");
	if (strcmp($3.type, "int") && strcmp($3.type, "float")) badtype(yylineno, $3.text, $3.type, "number");
	$$.text = cat(3, $1.text, ">", $3.text);
	$$.type = "bool";
}
           | expression LESSER expression
{
	if (strcmp($1.type, "int") && strcmp($1.type, "float")) badtype(yylineno, $1.text, $1.type, "number");
	if (strcmp($3.type, "int") && strcmp($3.type, "float")) badtype(yylineno, $3.text, $3.type, "number");
	$$.text = cat(3, $1.text, "<", $3.text);
	$$.type = "bool";
}
           | expression GREATEREQUAL expression
{
	if (strcmp($1.type, "int") && strcmp($1.type, "float")) badtype(yylineno, $1.text, $1.type, "number");
	if (strcmp($3.type, "int") && strcmp($3.type, "float")) badtype(yylineno, $3.text, $3.type, "number");
	$$.text = cat(3, $1.text, ">=", $3.text);
	$$.type = "bool";
}
           | expression LESSEREQUAL expression
{
	if (strcmp($1.type, "int") && strcmp($1.type, "float")) badtype(yylineno, $1.text, $1.type, "number");
	if (strcmp($3.type, "int") && strcmp($3.type, "float")) badtype(yylineno, $3.text, $3.type, "number");
	$$.text = cat(3, $1.text, "<=", $3.text);
	$$.type = "bool";
}
           | expression OR expression
{
	if (strcmp($1.type, "bool")) badtype(yylineno, $1.text, $1.type, "bool");
	if (strcmp($3.type, "bool")) badtype(yylineno, $3.text, $3.type, "bool");
	$$.text = cat(3, $1.text, "||", $3.text);
	$$.type = "bool";
}
           | expression AND expression
{
	if (strcmp($1.type, "bool")) badtype(yylineno, $1.text, $1.type, "bool");
	if (strcmp($3.type, "bool")) badtype(yylineno, $3.text, $3.type, "bool");
	$$.text = cat(3, $1.text, "&&", $3.text);
	$$.type = "bool";
}
           | NOT expression
{
	if (strcmp($2.type, "bool")) badtype(yylineno, $2.text, $2.type, "bool");
	$$.text = cat(2, "!", $2.text);
	$$.type = "bool";
}
           | BOOL
{
	if (!strcmp($1, "verdadeiro")) $$.text = "1";
	else if (!strcmp($1, "falso")) $$.text = "0";
	else fatal(yylineno, "unknown bool");
	$$.type = "bool";
}

           | ID OPENPARENTHESIS expressionlist CLOSEPARENTHESIS
{
	Symbol symb;
	if (!lookup($1, &symb)) notdecl(yylineno, $1);
	if (paramof(symb.type, $3.size) == NULL) unmatchcall(yylineno, $3.size);
	if (paramof(symb.type, $3.size+1) != NULL) unmatchcall(yylineno, $3.size);
	char *txt = cat(3, $1, "(", $3.data[0].text);
	for (int i = 0; i < $3.size; i++) {
		if (strcmp($3.data[i].type, paramof(symb.type, i+1)))
			badtype(yylineno, $3.data[i].text, $3.data[i].type, paramof(symb.type, i+1));
		if (i > 0) txt = cat(3, txt, ",", $3.data[i].text);
	}
	txt = cat(2, txt, ")");
	$$.text = txt;
	char *returnt = returnof(symb.type, 1);
	$$.type = returnt == NULL ? "void" : returnt;
}
           | ID OPENPARENTHESIS CLOSEPARENTHESIS
{
	Symbol symb;
	if (!lookup($1, &symb)) notdecl(yylineno, $1);
	if (paramof(symb.type, 1) != NULL) unmatchcall(yylineno, 1);
	$$.text = cat(2, $1, "()");
	char *returnt = returnof(symb.type, 1);
	$$.type = returnt == NULL ? "void" : returnt;
}

           | LENGTH expression
{
	if (strcmp($2.type, "_Vector*") && strcmp($2.type, "_Matrix*"))
		badtype(yylineno, $2.text, $2.type, "vector or matrix");
	$$.text = cat(2, $2.text, "->size");
	$$.type = "int";
}
           | OPENBRACKETS expression RANGE expression CLOSEBRACKETS
{
	if (strcmp($2.type, "int")) badtype(yylineno, $2.text, $2.type, "int");
	if (strcmp($4.type, "int")) badtype(yylineno, $4.text, $4.type, "int");
	$$.text = cat(5, "_vrange(", $2.text, ",", $4.text, ")");
	$$.type = "_Vector*"; 
}
           | OPENBRACKETS expressionlist CLOSEBRACKETS
{
	char *funcstr;
	if (!strcmp($2.data[0].type, "int")) { $$.type = "_Vector*"; funcstr = "_vof(";}
	else if (!strcmp($2.data[0].type, "_Vector*")) { $$.type = "_Matrix*"; funcstr = "_mof(";}
	else unsupp(yylineno, "non int vector literals and vector literals over 2 dimensions");
	char sizestr[5]; sprintf(sizestr, "%d", $2.size);
	char *txt = cat(4, funcstr, sizestr, ",", $2.data[0].text);
	for (int i = 1; i < $2.size; i++) {
		if (strcmp($2.data[i-1].type, $2.data[i].type))
			badtype(yylineno, $2.data[i].text, $2.data[i].type, $2.data[i-1].type);
		txt = cat(3, txt, ",", $2.data[i].text);
	}
	txt = cat(2, txt, ")");
	$$.text = txt;
}
           | OPENBRACKETS CLOSEBRACKETS {$$.text = "_vcreate()"; $$.type = "_Vector*";}
           | ID subscriptlist
{
	Symbol symb;
	if (!lookup($1, &symb)) notdecl(yylineno, $1);
	if (strcmp(symb.type, "_Vector*") && strcmp(symb.type, "_Matrix*"))
		badtype(yylineno, $1, symb.type, "vector or matrix");
	char *txt = $1;
	char *type = symb.type;
	for (int i = 0; i < $2.size; i++) {
		if ((type = dereftype(type)) == NULL) badderef(yylineno, symb.name);
		txt = cat(3, txt, "->data", $2.data[i]);
	}
	$$.text = txt;
	$$.type = type;
}
           | STRING {$$.text = $1; $$.type = "char*";}
           ;

forstatement : FOR ID IN expression
{
	up();
	char *iteratortype = dereftype($4.type);
	if (iteratortype == NULL) fatal(yylineno, "ITTYPE ERROR"); //TODO WHY SCREAM BRO
	if (!insert($2, iteratortype)) alreadydecl(yylineno, $2);
} block
{
	if (strcmp($4.type, "_Vector*") && strcmp($4.type, "_Matrix*"))
		badtype(yylineno, $4.text, $4.type, "vector or matrix");
	char *counterid = cat(2, "_", $2);
	char *counterdecl = cat(3, "int ", counterid, "=0;\n");
	char *iteratortype = dereftype($4.type);
	char *iteratordecl = cat(8, iteratortype, " ", $2, "=", $4.text, "->data[", counterid, "];\n");
	char *txt;
	txt = cat(12, "{\n", counterdecl, "_LOOP:\nif (", counterid, ">=", $4.text, "->size) goto _JUMP;\n", iteratordecl, $6, counterid, "++;\ngoto _LOOP;\n_JUMP:\n", ";}\n");
	$$ = uniquifylabels(txt);
	free(txt);
	down();
}
             ;

whilestatement : WHILE {up();} expression block
{
	if (strcmp($3.type, "bool")) badtype(yylineno, $3.text, $3.type, "bool");
	char *txt;
	txt = cat(5, "_LOOP:\nif (!(", $3.text, ")) goto _JUMP;\n", $4, "goto _LOOP;\n_JUMP:\n");
	$$ = uniquifylabels(txt);
	free(txt);
	down();
}
               ;

dowhilestatement : DO {up();} block WHILE expression
{
	if (strcmp($5.type, "bool")) badtype(yylineno, $5.text, $5.type, "bool");
	char *txt;
	txt = cat(5, "_LOOP:\n", $3, "if (", $5.text, ") goto _LOOP;\n");
	$$ = uniquifylabels(txt);
	free(txt);
	down();
}
                 ;

ifstatement : IF {up();} expression block {down();} elsechain
{
	if (strcmp($3.type, "bool")) badtype(yylineno, $3.text, $3.type, "bool");
	char *txt;
	txt = cat(9, "if (!(", $3.text, ")) goto ", $6.label, ";\n", $4, "goto _SKIP;\n", $6.text, "_SKIP:\n");
	$$ = uniquifylabels(txt);
	free(txt);
}
            ;

elsechain : {$$.text = ""; $$.label = "_SKIP";}
          | ELSE {up();} block
{
	$$.text = cat(3, "_ELSE:\n", $3, "goto _SKIP;\n");
	$$.label = "_ELSE";
	down();
}
          | ELSE {up();} IF expression block {down();} elsechain
{
	if (strcmp($4.type, "bool")) badtype(yylineno, $4.text, $4.type, "bool");
	$$.text = cat(8, "_ELIF:\nif (!(", $4.text, ")) goto ", $7.label, ";\n", $5, "goto _SKIP;\n", $7.text);
	$$.label = "_ELIF";
}
          ;

vectorconcatenation : expression CONCATENATION expression
{
	if (strcmp($1.type, "_Vector*") && strcmp($1.type, "_Matrix*"))
		badtype(yylineno, $1.text, $1.type, "vector or matrix");
	if (strcmp($3.type, "_Vector*") && strcmp($3.type, "_Matrix*"))
		badtype(yylineno, $3.text, $3.type, "vector or matrix");
	if (strcmp($1.type, $3.type))
		unmatchtype(yylineno, $1.text, $1.type, $3.text, $3.type);
	char *funcstr;
	if (!strcmp($1.type, "_Vector*")) funcstr = "_v";
	else funcstr = "_m";
	$$ = cat(6, funcstr, "concat(", $1.text, ",", $3.text, ");\n");
}
                    ;

vectorpush : variable PUSH expression
{
	Symbol symb;
	if (!lookup(idof($1), &symb)) notdecl(yylineno, idof($1));
	if (strcmp(symb.type, "_Vector*") && strcmp(symb.type, "_Matrix*"))
		badtype(yylineno, $1, symb.type, "vector or matrix");
	char *type = symb.type;
	for (int k = 0; k < countc($1, '['); k++) type = dereftype(type);
	if (type == NULL) badderef(yylineno, symb.name);

	char *derefd = dereftype(type);
	if (derefd == NULL) fatal(yylineno, "cannot push to primitive type");
	if (strcmp(derefd, $3.type)) badtype(yylineno, $3.text, $3.type, derefd);

	char *funcstr;
	if (!strcmp(type, "_Vector*")) funcstr = "_v";
	else funcstr = "_m";
	$$ = cat(6, funcstr, "push(", $1, ",", $3.text, ");\n");
}
           ;

vectorpop : variable POP variable
{
	Symbol symb1;
	if (!lookup(idof($1), &symb1)) notdecl(yylineno, idof($1));
	if (strcmp(symb1.type, "_Vector*") && strcmp(symb1.type, "_Matrix*"))
		badtype(yylineno, $1, symb1.type, "vector or matrix");
	char *type1 = symb1.type;
	for (int k = 0; k < countc($1, '['); k++) type1 = dereftype(type1);
	if (type1 == NULL) badderef(yylineno, symb1.name);

	Symbol symb2;
	if (!lookup(idof($3), &symb2)) notdecl(yylineno, idof($3));
	char *type2 = symb2.type;
	for (int k = 0; k < countc($3, '['); k++) type2 = dereftype(type2);
	if (type2 == NULL) badderef(yylineno, symb2.name);

	char *derefd = dereftype(type1);
	if (derefd == NULL) fatal(yylineno, "cannot push to primitive type");
	if (strcmp(derefd, type2)) badtype(yylineno, $3, type2, derefd);

	char *funcstr;
	if (!strcmp(type1, "_Vector*")) funcstr = "_v";
	else funcstr = "_m";
	$$ = cat(6, $3, "=", funcstr, "pop(", $1, ");\n");
}
          ;

%% /* Fim da segunda seção */

int main(int argc, char* argv[]) {
	int exitcode;
	if (argc == 1) {
		printf("reading from stdin:\n");
		exitcode = yyparse();
	} else if (argc == 3) {
		yyin = fopen(argv[1], "r");
		yyout = fopen(argv[2], "w");
		if (!yyin) fprintf(stderr, "error opening file %s\n", argv[1]);
		if (!yyout) fprintf(stderr, "error opening file %s\n", argv[2]);
		exitcode = yyparse();
		fclose(yyin);
		fclose(yyout);
	} else {
		fprintf(stderr, "usage: ./parser [SOURCEFILE.dagg] [OUTPUTFILE.c]\n");
		exitcode = 1;
	}
	print_table();
	return exitcode;
}

int yyerror(char *msg) {
	fprintf(stderr, "line %d: %s at '%s'\n", yylineno, msg, yytext);
	exit(1);
	return 0;
}

char *cat(int vacount, ...) {
	va_list valist;
	va_start(valist, vacount);
	char *strings[vacount];
	int length = 1;
	for (int i = 0; i < vacount; i++) {
		char *str = va_arg(valist, char*);
		strings[i] = str;
		length += strlen(str);
	}
	char *buffer = malloc(sizeof(char) * length);
	for (int i = 0; i < vacount; i++) {
		strcat(buffer, strings[i]);
	}
	va_end(valist);
	return buffer;
}

int countc(char *s, char c) {
	int count = 0;
	for (int i = 0; i < strlen(s); i++) if (s[i] == c) count++;
	return count;
}

char *uniquifylabels(char *s) {
	static const char labels[5][6] = {"_ELIF", "_ELSE", "_SKIP", "_LOOP", "_JUMP"};
	static int nextids[5] =          {0,      0,      0,      0     , 0     };
	static int incrementflags[5] =   {0,      0,      0,      0     , 0     };
	char *buffer = malloc(sizeof(char) * (strlen(s)*2)); //TODO EXCESSIVE ALLOC
	int size = 0;
	int start = 0;
	for (int i = 0; i < strlen(s); i++) {
		if (!strncmp(labels[0], s+i, strlen(labels[0]))) { //_ELIF
			if (isdigit(s[i + strlen(labels[0])])) continue; //if already unique
			strncpy(buffer+size, s+start, i+strlen(labels[0])-start);
			size += i+strlen(labels[0])-start;
			size += sprintf(buffer+size, "%d", nextids[0]);
			start = i + strlen(labels[0]);
			nextids[0] += incrementflags[0];
			incrementflags[0] = 1 - incrementflags[0]; //increment at every two
			continue;
		}
		
		for (int k = 1; k < 5; k++) { //_ELSE, _SKIP, _LOOP, _JUMP
			if (!strncmp(labels[k], s+i, strlen(labels[k]))) {
				if (isdigit(s[i + strlen(labels[0])])) continue; //if already unique
				strncpy(buffer+size, s+start, i+strlen(labels[k])-start);
				size += i+strlen(labels[k])-start;
				size += sprintf(buffer+size, "%d", nextids[k]);
				start = i + strlen(labels[k]);
				incrementflags[k] = 1; //increment at every call
				break;
			}
		}
	}
	strcpy(buffer+size, s+start);
	size += strlen(s+start);
	for (int k = 1; k < 5; k++) { //_ELSE, _SKIP, _LOOP, _JUMP
		nextids[k] += incrementflags[k];
		incrementflags[k] = 0;
	}
	return buffer;
}

char *idof(char *var) {
	char *buffer = strdup(var);
	for (int i = 0; i < strlen(var); i++)
		if (buffer[i] == '-' || buffer[i] == '[') buffer[i] = '\0';
	return buffer;
}

char *dereftype(char *t) {
	if (t == NULL) return NULL;
	else if (!strcmp(t, "_Vector*")) return "int";
	else if (!strcmp(t, "_Matrix*")) return "_Vector*";
	else return NULL;
}

char *paramof(char *funt, int i) {
	char *buffer = strdup(funt);
	strstr(buffer, "->")[0] = '\0';
	char *param = NULL;
	char *token = strtok(buffer, ",");
	while (token != NULL) {
		if (--i == 0) { param = strdup(token); break; }
		token = strtok(NULL, ",");
	}
	free(buffer);
	return param;
}

char *returnof(char *funt, int i) {
	char *buffer = strdup(strstr(funt, "->") + 2);
	char *param = NULL;
	char *token = strtok(buffer, ",");
	while (token != NULL) {
		if (--i == 0) { param = strdup(token); break; }
		token = strtok(NULL, ",");
	}
	free(buffer);
	return param;
}
