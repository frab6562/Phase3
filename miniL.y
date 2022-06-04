%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <sstream>
#include <fstream>
#include <iostream>
#include <queue>
#include <stack>
#include <vector>
#include <cstdlib>

using namespace std;

extern "C" int yylex();
extern FILE * yyin;
extern int currLine;
extern int currpos;
 
void yyerror(const char * msg) {
	printf("Error: On line %d, column %d: %s \n", currLine, currpos, msg);
}

bool no_error = true;
vector <string> funcTable;
void addFunc(string name) {
	funcTable.push_back(name);
}

vector <string> tempTable;
vector <string> identTable;
vector <string> labelTable;
int numTemps = 0;
int numLabels = 0;
string make_temp() {
	string ret = "__temp__" + to_string(numTemps);
	tempTable.push_back("__temp__" + to_string(numTemps));
	++numTemps;
	return ret;
}
string make_label() {
	string ret = "__label__" + to_string(numLabels);
	labelTable.push_back(ret);
	++numLabels;
	return ret;
}
int numRegs = 0;
int numIdents = 0;

bool root = true;
bool isFunc = true;
bool writeFlag = false;
bool readFlag = false;
bool EQflag = false;
bool NEQflag = false;
bool LTflag = false;
bool LTEflag = false;
bool GTflag = false;
bool GTEflag = false;
bool ADDflag = false;
bool SUBflag = false;
bool MULTflag = false;
bool DIVflag = false;
bool MODflag = false;
bool assignedFlag = false;

string code;
%}

%union{
	char * identVal;
	int numVal;
	struct startprog {
	} startprog;
	struct grammar {
		char code;
	} grammar;
}

%error-verbose

%start startprogram

%token FUNCTION BEGINPARAMS ENDPARAMS BEGINLOCALS ENDLOCALS BEGINBODY
%token ENDBODY INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP
%token CONTINUE READ WRITE AND OR NOT TRUE FALSE RETURN
%token SUB ADD MULT DIV MOD UMINUS FOR
%token EQ NEQ LT GT LTE GTE
%token SEMICOLON COLON COMMA LPAREN RPAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN

%left MULT DIV MOD ADD SUB
%left GT GTE LT LTE EQ NEQ
%left AND OR

%right NOT
%right ASSIGN

%token <numVal> NUMBER
%token <identVal> IDENT
%type <startprog> startprogram
%type <grammar> program function declaration declarations Ident statements statement svar sif 
%type <grammar> swhile sdo sfor varLoop sread swrite scontinue sreturn bool_expr relation_expr
%type <grammar>  relation_exprs ece comp expression addSubExpr multi_expr term expressionLoop var
%%
startprogram:	program {}
	    	;

program:	function program
       		{}
		|
		{}
		;

function:	FUNCTION Ident SEMICOLON BEGINPARAMS declarations ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY statements ENDBODY
		{if (isFunc == 0) {code += "endfunc\n\n";} isFunc = true;}
		;

declarations:	
	    	{}
		| declaration SEMICOLON declarations
		{}
		;

declaration:	IDENT COLON INTEGER
	   	{code += ". "; string pls($1); string tempo = "";							// It looks like I'm taping up trash together and thats exactly what I'm doing
			for (int k = 0; k < pls.size(); ++k) {								// $1 picks up entire string so for loop is used to get the ident only by looking for the first space
                                if (pls.at(k) == ' ' || pls.at(k) == '(' || pls.at(k) == ')' || pls.at(k) == ';') {
                                        k = 69;
                                }
                                else {
                                        code += pls.at(k); tempo += pls.at(k);
                                }
                        }
		if (root) {code += "\n= " + tempo; code += ", $" + to_string(numRegs); ++numRegs; root = false;} 
		code += "\n"; identTable.push_back(tempo); ++numIdents;}
		| IDENT COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
		{code += ".[] "; code += $1; code += ", "; code += $5; code += "\n";}
		;

Ident:		IDENT
     		{string tempo;
		 if (isFunc == true) {funcTable.push_back($1); isFunc = false; code += "func "; string pls($1);
			for (int k = 0; k < pls.size(); ++k) {
                                if (pls.at(k) == ' ' || pls.at(k) == '(' || pls.at(k) == ')' || pls.at(k) == ';') {
                                        k = 69;
                                }
                                else {
                                        code += pls.at(k); tempo += pls.at(k);
                                }
                        }
		
		}
		/*else if (writeFlag) {writeFlag = false; code += ".> " + string(identTable.at(numIdents-1));}*/
		else if (assignedFlag) {assignedFlag = false; --numIdents;}
		else {string temp = make_temp(); code += ". " + temp; code += "\n= "; code += temp + ", "; string pls($1);
			for (int k = 0; k < pls.size(); ++k) {
				if (pls.at(k) == ' ' || pls.at(k) == '(' || pls.at(k) == ')' || pls.at(k) == ';') {
					k = 69;
				}
                              	else {
                                       	code += pls.at(k); tempo += pls.at(k);
				}
			}
		}
		code += "\n"; identTable.push_back(tempo); ++numIdents;}
		;

statements:	statement SEMICOLON statements
	  	{}
		| statement SEMICOLON
		{}
		;

statement:	svar
	  	{}
	  	| sif
		{}
		| swhile
		{}
		| sdo
		{}
		| sfor
		{}
		| sread
		{if (readFlag) {readFlag = false; code += ".< " + string(identTable.at(numIdents-1)) + "\n";/* string temp = make_temp(); code += ". " + temp + "\n" + "= " + temp + ", " + string(identTable.at(numIdents-1)) + "\n";*/}}
		| swrite
		{if (writeFlag) {writeFlag = false; code += ".> " + string(identTable.at(numIdents-2)) + "\n";}}
		| scontinue
		{}
		| sreturn
		{}
		;

svar:		var ASSIGN expression
    		{assignedFlag = true; code += "= " + string(identTable.at(numIdents-2)) + ", __temp__" + to_string(numTemps-1);}
		;

sif:		IF bool_expr THEN statements ENDIF
   		{code += ": __label__" + to_string(numLabels-1) + "\n";}
		| IF bool_expr THEN statements ELSE statements ENDIF
		{}
		;

swhile:		WHILE bool_expr BEGINLOOP statements ENDLOOP
      		{}
		;

sdo:		DO BEGINLOOP statements ENDLOOP WHILE bool_expr
   		{}
		;

sfor:		FOR var ASSIGN NUMBER SEMICOLON bool_expr SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP
    		{}
		;

varLoop:	/*epsilon*/
       		{}
		| COMMA var varLoop
		  {}
		;

sread:		READ var varLoop
     		{readFlag = true;}
		;
     
swrite:		WRITE var varLoop
      		{/*code += ".> ";*/ writeFlag = true;}
		;

scontinue:	CONTINUE
	 	{code += "continue\n";}
		;

sreturn:	RETURN expression
       		{code += "ret "; code += "__temp__" + to_string(numTemps-1) + "\n";}
		;

bool_expr:	relation_exprs
	 	{}
		| bool_expr OR relation_exprs
		  {}
		;

relation_exprs:	relation_expr
	      	{}
		| relation_exprs AND relation_expr
		  {}
		;

relation_expr:	NOT ece
	     	{}
		| ece
		  {}
		| TRUE
		  {}
		| FALSE
		  {}
		| LPAREN bool_expr RPAREN
		  {}
		;

ece:		expression comp expression
		{}
		;

comp:		EQ
    		{EQflag = true;}
		| NEQ
		  {EQflag = true;}
		| LT
		  {LTflag = true;}
		| GT
		  {GTflag = true;}
		| LTE
		  {LTEflag = true;}
		| GTE
		  {GTEflag = true;}
		;

expression:	multi_expr addSubExpr
	  	{if (LTEflag == true) {LTEflag = false; string lab = make_label(); string temp = make_temp(); code += ". __temp__" + to_string(numTemps-1); code += "\n<= __temp__" + to_string(numTemps-1) + ", "; code += "__temp__" + to_string(numTemps - 3); code += ", __temp__" + to_string(numTemps - 2) + "\n?:= " + lab + ", __temp__" + to_string(numTemps-1) + "\n"; string lab2 = make_label(); code += ":= " + lab2 + "\n" + ": " + lab + "\n";}
		 if (GTEflag == true) {GTEflag = false; string lab = make_label(); string temp = make_temp(); code += ". __temp__" + to_string(numTemps-1); code += "\n>= __temp__" + to_string(numTemps-1) + ", "; code += "__temp__" + to_string(numTemps - 3); code += ", __temp__" + to_string(numTemps - 2) + "\n?:= " + lab + ", __temp__" + to_string(numTemps-1) + "\n"; string lab2 = make_label(); code += ":= " + lab2 + "\n" + ": " + lab + "\n";}
		 if (LTflag == true) {LTflag = false; string lab = make_label(); string temp = make_temp(); code += ". __temp__" + to_string(numTemps-1); code += "\n< __temp__" + to_string(numTemps-1) + ", "; code += "__temp__" + to_string(numTemps - 3); code += ", __temp__" + to_string(numTemps - 2) + "\n?:= " + lab + ", __temp__" + to_string(numTemps-1) + "\n"; string lab2 = make_label(); code += ":= " + lab2 + "\n" + ": " + lab + "\n";}
		 if (GTflag == true) {GTflag = false; string lab = make_label(); string temp = make_temp(); code += ". __temp__" + to_string(numTemps-1); code += "\n> __temp__" + to_string(numTemps-1) + ", "; code += "__temp__" + to_string(numTemps - 3); code += ", __temp__" + to_string(numTemps - 2) + "\n?:= " + lab + ", __temp__" + to_string(numTemps-1) + "\n"; string lab2 = make_label(); code += ":= " + lab2 + "\n" + ": " + lab + "\n";}
		 if (SUBflag == true) {SUBflag = false; string temp = make_temp(); code += ". __temp__" + to_string(numTemps-1); code += "\n- __temp__" + to_string(numTemps-1) + ", "; code += "__temp__" + to_string(numTemps - 3); code += ", __temp__" + to_string(numTemps - 2) + "\n";/* code += "param __temp__" + to_string(numTemps-1); code += "\n";*/}
		 if (ADDflag == true) {ADDflag = false; string temp = make_temp(); code += ". __temp__" + to_string(numTemps-1); code += "\n+ __temp__" + to_string(numTemps-1) + ", "; code += "__temp__" + to_string(numTemps - 6); code += ", __temp__" + to_string(numTemps - 2) + "\n";}
		 if (MULTflag == true) {MULTflag = false; string temp = make_temp(); code += ". __temp__" + to_string(numTemps-1); code += "\n* __temp__" + to_string(numTemps-1) + ", "; code += "__temp__" + to_string(numTemps - 3); code += ", __temp__" + to_string(numTemps - 2) + "\n";}
		 if (DIVflag == true) {DIVflag = false; string temp = make_temp(); code += ". __temp__" + to_string(numTemps-1); code += "\n/ __temp__" + to_string(numTemps-1) + ", "; code += "__temp__" + to_string(numTemps - 3); code += ", __temp__" + to_string(numTemps - 2) + "\n";}
		 if (MODflag == true) {MODflag = false; string temp = make_temp(); code += ". __temp__" + to_string(numTemps-1); code += "\n% __temp__" + to_string(numTemps-1) + ", "; code += "__temp__" + to_string(numTemps - 3); code += ", __temp__" + to_string(numTemps - 2) + "\n";}
		/* yes this is very redundant but i love coding c: */}
		;

addSubExpr:	/*epsilon*/
	  	{}
		| ADD expression
		  {ADDflag = true;}
		| SUB expression
		  {SUBflag = true;}
		;

multi_expr:	term
	  	{}
		| term MULT multi_expr
		  {MULTflag = true;}
		| term DIV multi_expr
		  {DIVflag = true;}
		| term MOD multi_expr
		  {MODflag = true;}
		;

term:		SUB var 
    		{/*unary minus*/}
		| var
		  {}
		| SUB NUMBER
		  {/*string temp = make_temp(); code += "-" + to_string($2) + "\n";*/}
		| NUMBER
		  {string temp = make_temp(); code+= ". " + temp + "\n= " + temp + ", "; code += to_string($1) + "\n";}
		| IDENT LPAREN expression RPAREN
		  {code += "param __temp__" + to_string(numTemps-1) + "\n";

			string temp = make_temp(); code += ". " + temp + "\n"; code += "call "; string pls($1);
			for (int k = 0; k < pls.size(); ++k) {
                                if (pls.at(k) == ' ' || pls.at(k) == '('){
                                        k = 69;
                                }
                                else {
                                        code += pls.at(k);
                                }
                        }
                code += ", __temp__" + to_string(numTemps-1) + "\n"; }
		| Ident LPAREN expression expressionLoop RPAREN
		  {}
		;

expressionLoop:	/*epsilon*/
	      	{}
	      	| COMMA expression expressionLoop
	      	  {}
		;

var:		Ident
   		{}
		| Ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET L_SQUARE_BRACKET expression R_SQUARE_BRACKET
		  {}
		| IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET
		  {code += ".[] "; string pls($1);
		  for (int k = 0; k < pls.size(); ++k) {
                                if (pls.at(k) == ' ' || pls.at(k) == '('){
                                        k = 69;
                                }
                                else {
                                        code += pls.at(k);
                                }
                        }
		code += ",\n";
		}
		;

%%

int main(int argc, char ** argv) {
	if (argc >= 2) {
		yyin = fopen(argv[1], "r");
		if (yyin == NULL) {
			yyin = stdin;
		}
	}
	else {
		yyin = stdin;
	}
	yyparse();
	
	for (int i = 0; i < funcTable.size() - 1; ++i) {
		for (int j = i+1; j < funcTable.size(); ++j) {
			if (funcTable.at(i) == funcTable.at(j)) {
				no_error = false;
				cerr << "Multiple functions with same name detected. \n";
			}
		}
	}
	
	if (no_error) {
                ofstream file;
                file.open("CODE.mil");
                file << code;
                file.close();
        }
	else {
		cout << "Error encountered while generating code." << endl;
	}
	return 1;
}
