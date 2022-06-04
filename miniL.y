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
vector <string> functionMap;
void addFunc(string name) {
	functionMap.push_back(name);
}
int numTemps = 0;
int numLabels = 0;

vector <string> tempVector;
vector <string> identVector;
string temporize() {
	string ret = "__temp__" + to_string(numTemps);
	tempVector.push_back("__temp__" + to_string(numTemps));
	++numTemps;
	return ret;
}
vector <string> labelVector;
string labelize() {
	string ret = "__label__" + to_string(numLabels);
	labelVector.push_back(ret);
	++numLabels;
	return ret;
}

int numRegs = 0;
int numIdents = 0;

bool root = true;
bool Func = true;

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

%type <grammar> program function declaration declarations Ident statements statement variable if_2 
%type <grammar> while_2 do_2 for_2 varLoop read_2 write_2 continue_2 return_2 bool_expr relation_expr
%type <grammar> relation_exprs ece comp expression addSub multi_expr term expressionLoop var
%%

startprogram:	program {}
	    	;

program:	function program
       		{}
		|
		{}
		;

function:	FUNCTION Ident SEMICOLON BEGINPARAMS declarations ENDPARAMS BEGINLOCALS declarations ENDLOCALS BEGINBODY statements ENDBODY
		{if (Func == 0) {code += "endfunc\n\n";} Func = true;}
		;

declarations:	
	    	{}
		| declaration SEMICOLON declarations
		{}
		;

declaration:	IDENT COLON INTEGER
	   	{code += ". "; string pls($1); string tempo = "";							
			for (int k = 0; k < pls.size(); ++k) {	
                                if (pls.at(k) == ' ' || pls.at(k) == '(' || pls.at(k) == ')' || pls.at(k) == ';') {
                                        k = 69;
                                }
                                else {
                                        code += pls.at(k); tempo += pls.at(k);
                                }
                        }
		if (root) {code += "\n= " + tempo; code += ", $" + to_string(numRegs); ++numRegs; root = false;} 
		code += "\n"; identVector.push_back(tempo); ++numIdents;}
		| IDENT COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
		{code += ".[] "; code += $1; code += ", "; code += $5; code += "\n";}
		;

Ident:		IDENT
     		{string tempo;
		 if (Func == true) {functionMap.push_back($1); Func = false; code += "func "; string pls($1);
			for (int k = 0; k < pls.size(); ++k) {
                                if (pls.at(k) == ' ' || pls.at(k) == '(' || pls.at(k) == ')' || pls.at(k) == ';') {
                                        k = 69;
                                }
                                else {
                                        code += pls.at(k); tempo += pls.at(k);
                                }
                        }
		
		}
		else if (assignedFlag) {assignedFlag = false; --numIdents;}
		else {string t = temporize(); code += ". " + t; code += "\n= "; code += t + ", "; string pls($1);
			for (int k = 0; k < pls.size(); ++k) {
				if (pls.at(k) == ' ' || pls.at(k) == '(' || pls.at(k) == ')' || pls.at(k) == ';') {
					k = 69;
				}
                              	else {
                                       	code += pls.at(k); tempo += pls.at(k);
				}
			}
		}
		code += "\n"; identVector.push_back(tempo); ++numIdents;}
		;

statements:	statement SEMICOLON statements
	  	{}
		| statement SEMICOLON
		{}
		;

statement:	variable
	  	{}
	  	| if_2
		{}
		| while_2
		{}
		| do_2
		{}
		| for_2
		{}
		| read_2
		{if (readFlag) {readFlag = false; code += ".< " + string(identVector.at(numIdents-1)) + "\n";}}
		| write_2
		{if (writeFlag) {writeFlag = false; code += ".> " + string(identVector.at(numIdents-2)) + "\n";}}
		| continue_2
		{}
		| return_2
		{}
		;

variable:	var ASSIGN expression
    		{assignedFlag = true; code += "= " + string(identVector.at(numIdents-2)) + ", __temp__" + to_string(numTemps-1);}
		;

if_2:		IF bool_expr THEN statements ENDIF
   		{code += ": __label__" + to_string(numLabels-1) + "\n";}
		| IF bool_expr THEN statements ELSE statements ENDIF
		{}
		;

while_2:		WHILE bool_expr BEGINLOOP statements ENDLOOP
      		{}
		;

do_2:		DO BEGINLOOP statements ENDLOOP WHILE bool_expr
   		{}
		;

for_2:		FOR var ASSIGN NUMBER SEMICOLON bool_expr SEMICOLON var ASSIGN expression BEGINLOOP statements ENDLOOP
    		{}
		;

varLoop:
       		{}
		| COMMA var varLoop
		  {}
		;

read_2:		READ var varLoop
     		{readFlag = true;}
		;
     
write_2:		WRITE var varLoop
      		{writeFlag = true;}
		;

continue_2:	CONTINUE
	 	{code += "continue\n";}
		;

return_2:	RETURN expression
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

expression:	multi_expr addSub
	  	{if (LTEflag == true){
			LTEflag = false;
			string label = labelize(); 
			string t = temporize(); 
			code += ". __temp__" + to_string(numTemps-1); 
			code += "\n<= __temp__" + to_string(numTemps-1) + ", "; 
			code += "__temp__" + to_string(numTemps - 3); 
			code += ", __temp__" + to_string(numTemps - 2) + "\n?:= " + label + ", __temp__" + to_string(numTemps-1) + "\n"; 
			string lab2 = labelize(); 
			code += ":= " + lab2 + "\n" + ": " + label + "\n";
		}
		 if (GTEflag == true) {
			GTEflag = false; 
			string label = labelize(); 
			string t = temporize(); 
			code += ". __temp__" + to_string(numTemps-1); 
			code += "\n>= __temp__" + to_string(numTemps-1) + ", ";
			code += "__temp__" + to_string(numTemps - 3); 
			code += ", __temp__" + to_string(numTemps - 2) + "\n?:= " + label + ", __temp__" + to_string(numTemps-1) + "\n"; 
			string lab2 = labelize(); 
			code += ":= " + lab2 + "\n" + ": " + label + "\n";
		}
		 if (LTflag == true) {
			LTflag = false; 
			string label = labelize(); 
			string t = temporize(); 
			code += ". __temp__" + to_string(numTemps-1); 
			code += "\n< __temp__" + to_string(numTemps-1) + ", "; 
			code += "__temp__" + to_string(numTemps - 3); 
			code += ", __temp__" + to_string(numTemps - 2) + "\n?:= " + label + ", __temp__" + to_string(numTemps-1) + "\n"; 
			string lab2 = labelize(); code += ":= " + lab2 + "\n" + ": " + label + "\n";
		}
		 if (GTflag == true) {
			GTflag = false; string label = labelize(); 
			string t = temporize(); code += ". __temp__" + to_string(numTemps-1); 
			code += "\n> __temp__" + to_string(numTemps-1) + ", "; 
			code += "__temp__" + to_string(numTemps - 3); 
			code += ", __temp__" + to_string(numTemps - 2) + "\n?:= " + label + ", __temp__" + to_string(numTemps-1) + "\n"; 
			string lab2 = labelize(); code += ":= " + lab2 + "\n" + ": " + label + "\n";
		}
		 if (SUBflag == true) {
			SUBflag = false; string t = temporize(); 
			code += ". __temp__" + to_string(numTemps-1); 
			code += "\n- __temp__" + to_string(numTemps-1) + ", "; 
			code += "__temp__" + to_string(numTemps - 3); 
			code += ", __temp__" + to_string(numTemps - 2) + "\n";
		} 
		 if (ADDflag == true) {
			ADDflag = false; 
			string t = temporize(); 
			code += ". __temp__" + to_string(numTemps-1); 
			code += "\n+ __temp__" + to_string(numTemps-1) + ", "; 
			code += "__temp__" + to_string(numTemps - 6); 
			code += ", __temp__" + to_string(numTemps - 2) + "\n";
		}
		 if (MULTflag == true) {
			MULTflag = false; 
			string t = temporize(); 
			code += ". __temp__" + to_string(numTemps-1); 
			code += "\n* __temp__" + to_string(numTemps-1) + ", "; 
			code += "__temp__" + to_string(numTemps - 3); code += ", __temp__" + to_string(numTemps - 2) + "\n";
		}
		 if (DIVflag == true) {
			DIVflag = false; 
			string t = temporize(); 
			code += ". __temp__" + to_string(numTemps-1); 
			code += "\n/ __temp__" + to_string(numTemps-1) + ", "; 
			code += "__temp__" + to_string(numTemps - 3); 
			code += ", __temp__" + to_string(numTemps - 2) + "\n";
		}
		 if (MODflag == true) {
			MODflag = false; 
			string t = temporize(); 
			code += ". __temp__" + to_string(numTemps-1); 
			code += "\n% __temp__" + to_string(numTemps-1) + ", "; 
			code += "__temp__" + to_string(numTemps - 3); 
			code += ", __temp__" + to_string(numTemps - 2) + "\n";
		}
		;}

addSub:	
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
    		{}
		| var
		  {}
		| SUB NUMBER
		  {}
		| NUMBER
		  {string t = temporize(); code+= ". " + t + "\n= " + t + ", "; code += to_string($1) + "\n";}
		| IDENT LPAREN expression RPAREN
		  {code += "param __temp__" + to_string(numTemps-1) + "\n";

			string t = temporize(); code += ". " + t + "\n"; code += "call "; string pls($1);
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

expressionLoop:	
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
	for (int i = 0; i < functionMap.size() - 1; ++i) {
		for (int j = i+1; j < functionMap.size(); ++j) {
			if (functionMap.at(i) == functionMap.at(j)) {
				no_error = false;
				cerr << "Multiple functions with same name detected. \n";
			}
		}
	}
	if (no_error) {
                ofstream file;
                file.open("Output.mil");
                file << code;
                file.close();
        }
	else {
		cout << "Error encountered while generating code." << endl;
	}
	return 1;
}
