/* cs152-miniL phase1 */
%{   
/* write your C code here for definitions of variables and including headers */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <sstream>
#include <iostream>
#include <queue>
#include <stack>
#include <vector>
#include <cstdlib>

#include "miniL-parser.hpp"
extern "C" int yylex();
int currLine = 1, currpos = 1;

%}
   /* some common rules */
DIGIT	[0-9]
LETTER	[a-z|A-Z]
IDENT	{LETTER}([_]*{LETTER}*{DIGIT}*)*({LETTER}|{DIGIT})

%%
 /* specific lexer rules in regex */
"function"	{currpos += yyleng; return FUNCTION;}
"beginparams"   {currpos += yyleng; return BEGINPARAMS;}
"endparams"	{currpos += yyleng; return ENDPARAMS;} 
"beginlocals"	{currpos += yyleng; return BEGINLOCALS;}
"endlocals"	{currpos += yyleng; return ENDLOCALS;}
"beginbody"	{currpos += yyleng; return BEGINBODY;}
"endbody"	{currpos += yyleng; return ENDBODY;}
"integer"	{currpos += yyleng; return INTEGER;}
"array"		{currpos += yyleng; return ARRAY;}
"of"		{currpos += yyleng; return OF;}
"if"		{currpos += yyleng; return IF;}
"then"		{currpos += yyleng; return THEN;}
"endif"		{currpos += yyleng; return ENDIF;}
"else"		{currpos += yyleng; return ELSE;}
"for"		{currpos += yyleng; return FOR;}
"while"		{currpos += yyleng; return WHILE;}
"do"		{currpos += yyleng; return DO;}
"beginloop"	{currpos += yyleng; return BEGINLOOP;}
"endloop"	{currpos += yyleng; return ENDLOOP;}
"continue"	{currpos += yyleng; return CONTINUE;}
"read"		{currpos += yyleng; return READ;}
"write"		{currpos += yyleng; return WRITE;}
"and"		{currpos += yyleng; return AND;}
"or"		{currpos += yyleng; return OR;}
"not"		{currpos += yyleng; return NOT;}
"true"		{currpos += yyleng; return TRUE;}
"false"		{currpos += yyleng; return FALSE;}
"return"	{currpos += yyleng; return RETURN;}

"-"           	{currpos += yyleng; return SUB;}
"+"           	{currpos += yyleng; return ADD;}
"*"             {currpos += yyleng; return MULT;}
"/"             {currpos += yyleng; return DIV;}
"%"		{currpos += yyleng; return MOD;}

"=="		{currpos += yyleng; return EQ;}
"<>"		{currpos += yyleng; return NEQ;}
"<"		{currpos += yyleng; return LT;}
">"		{currpos += yyleng; return GT;}
"<="		{currpos += yyleng; return LTE;}
">="		{currpos += yyleng; return GTE;}

{DIGIT}+        {currpos += yyleng; yylval.numVal = atoi(yytext); return NUMBER;}
{LETTER}	{currpos += yyleng; yylval.identVal = yytext; return IDENT;} 
{IDENT}         {currpos += yyleng; yylval.identVal = yytext; return IDENT;}
 
([_]+{DIGIT}*{IDENT}*)    {printf("Error at line %d, column %d: identifier \"%s\" cannot start with an underscore\n", currpos, currLine, yytext); exit(0);}
({IDENT}[_])    {printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", currpos, currLine, yytext); exit(0);}
({DIGIT}+{IDENT}) {printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currpos, currLine, yytext); exit(0);}

";"		{currpos += yyleng; return SEMICOLON;}
":"		{currpos += yyleng; return COLON;}
","		{currpos += yyleng; return COMMA;}
"("		{currpos += yyleng; return LPAREN;}
")"		{currpos += yyleng; return RPAREN;}
"["		{currpos += yyleng; return L_SQUARE_BRACKET;}
"]"		{currpos += yyleng; return R_SQUARE_BRACKET;}
":="		{currpos += yyleng; return ASSIGN;}

[##].* 		{currLine++; currpos = 1;}
[ ] 		{currpos += yyleng;}
[ \t]           {currpos += yyleng;}
"\n"            {currLine++; currpos = 1;}

.               {printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currpos, yytext); exit(0);}
%%
