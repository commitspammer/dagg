/*
 * dagglexer.l:
 * Description: Lexical analyser for the DAGG Programming Language.
 */

%{

#include <stdio.h>
#include "y.tab.h"

extern int yyerror(char* msg);
extern int yylineno; /* not necessary??? */
int nlcount(char *str);

%}

blank                           " "|\t|"#"[^\n]*

%%

(" "|\t|"#"[^\n]*)+             ;
\\\n                            {yylineno++;}
(\n|;)(" "|\t|\n|"#"[^\n]*)*    {yylineno+=nlcount(yytext); return ENDMARKER;}
para                            {return FOR;}
em                              {return IN;}
enquanto                        {return WHILE;}
faca                            {return DO;}
se                              {return IF;}
entao                           {return THEN;}
senao                           {return ELSE;}
"!"                             {return NOT;}
"&"                             {return AND;}
"|"                             {return OR;}
"="                             {return EQUAL;}
"!="                            {return NOTEQUAL;}
">"                             {return GREATER;}
">="                            {return GREATEREQUAL;}
"<"                             {return LESSER;}
"<="                            {return LESSEREQUAL;}
retorne                         {return RETURN;}
quebre                          {return BREAK;}
avance                          {return CONTINUE;}
escreva                         {return PRINT;}
leia                            {return SCAN;}
"+"                             {return PLUS;}
"-"                             {return MINUS;}
"*"                             {return TIMES;}
"/"                             {return FLOATDIVISION;}
"//"                            {return INTDIVISION;}
"%"                             {return REMAINDER;}
"**"                            {return EXPONENTIATION;}
"$"                             {return LENGTH;}
"<<"                            {return PUSH;}
">>"                            {return POP;}
"++"                            {return CONCATENATION;}
"<-"                            {return ASSIGN;}
":"                             {return COLON;}
","                             {return COMMA;}
"("                             {return OPENPARENTHESIS;}
")"                             {return CLOSEPARENTHESIS;}
"{"(" "|\t|\n|"#"[^\n]*)*       {yylineno+=nlcount(yytext); return OPENCURLY;}
"}"(" "|\t|\n|"#"[^\n]*)*       {yylineno+=nlcount(yytext); return CLOSECURLY;}
"["                             {return OPENBRACKETS;}
"]"                             {return CLOSEBRACKETS;}
".."                            {return RANGE;}
(int|real|texto|bool)           {yylval.sval = strdup(yytext); return PRIMITIVE;}
(verdadeiro|falso)              {yylval.sval = strdup(yytext); return BOOL;}
[0-9]+                          {yylval.sval = strdup(yytext); return INT;}
([0-9]*"."[0-9]+)               {yylval.sval = strdup(yytext); return FLOAT;}
\"([^\\\"]|\\.)*\"              {yylval.sval = strdup(yytext); return STRING;}
[a-zA-Z][a-zA-Z0-9_]*           {yylval.sval = strdup(yytext); return ID;}
.                               {yyerror("invalid character");}

%%
//"::"                            {return INTERVAL;}
//[0-9]+                          {yylval.ival = atoi(yytext); return INT;}
//([0-9]*"."[0-9]+)               {yylval.fval = atof(yytext); return FLOAT;}

#ifndef yywrap
int yywrap(void) { return 1; }
#endif

int nlcount(char *str) {
	int count = 0;
	for (int i = 0; i < strlen(str); i++) if (str[i] == '\n') count++;
	return count;
}

/*
int main(int argc, char* argv[]) {
	yyin = fopen(argv[1], "r");
	yylex();
	return 0;
}
*/
