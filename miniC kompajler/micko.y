%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"
  #include "codegen.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  int out_lin = 0;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;
  int lab_num = -1;
  int var_num_to_inc = 0;
  int vars_to_inc[100];
  int var_type = 0;
  int ret_count = 0;
	int par_count = 0;
	int br_id = 0;
	int br_const[3];
  int par_type = 0;

  FILE *output;
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _LSQBRACKET
%token _RSQBRACKET
%token _ASSIGN
%token _SEMICOLON
%token _INC
%token _QMARK
%token _COLON
%token _COMMA
%token _FOR
%token _IN
%token _DOTS
%token _STEP
%token _BRANCH
%token _ONE
%token _TWO
%token _THREE
%token _OTHER
%token _ENDBRANCH
%token _DART
%token <i> _ASOP
%token <i> _MDOP
%token <i> _RELOP

%type <i> num_exp exp literal argument arg
%type <i> function_call  rel_exp if_part
%type <i> cond_exp

%nonassoc ONLY_IF
%nonassoc _ELSE


%left _ASOP
%left _MDOP

%%

program
  : global_list function_list
      {  
        if(lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
      }
  ;


global_list
	: /*empty*/
	| global_list global_var
	;

global_var
	: _TYPE _ID _SEMICOLON
	{
		int idx = lookup_symbol($2, GVAR); 
		if (idx != NO_INDEX) 
		{
				err("redefinition of '%s'", $2);
		} else {
			insert_symbol($2, GVAR, $1, NO_ATR, NO_ATR);
			code("\n%s:\n\t\tWORD\t1", $2);
		}
	}
	;


function_list
  : function
  | function_list function
  ;

function
  : _TYPE _ID
      {
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX)
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
        else 
          err("redefinition of function '%s'", $2);

        code("\n%s:", $2);
        code("\n\t\tPUSH\t%%14");
        code("\n\t\tMOV \t%%15,%%14");
      }
    _LPAREN parameter _RPAREN body
      {
		if( get_type(fun_idx) != VOID && ret_count == 0) 
	  err("Non-void function is expecting a return value"); // warn prepravljen na error 

        clear_symbols(fun_idx + 1);
        var_num = 0;
		ret_count = 0;
		par_count = 0;
        
        code("\n@%s_exit:", $2);
        code("\n\t\tMOV \t%%14,%%15");
        code("\n\t\tPOP \t%%14");
        code("\n\t\tRET");
      }
  ;

parameter
  : /* empty */
      {
				set_atr1(fun_idx, 0); 
				set_atr2(fun_idx, par_count, 0);	
			}
  | param
  ;
 
param 
	: _TYPE  
		{
		par_type = $1;
			if($1 == VOID) 
				err("parameter cannot be void type");
		}
	_ID
	{
		insert_symbol($3, PAR, par_type, ++par_count, NO_ATR);
						set_atr1(fun_idx, par_count);
						set_atr2(fun_idx, par_count-1, par_type);		

	} 
	| param _COMMA _TYPE 
		{
			par_type = $3;
			if($3 == VOID) 
				err("parameter cannot be void type");		
		}
	_ID
	{
		insert_symbol($5, PAR, par_type, ++par_count, NO_ATR);
						set_atr1(fun_idx, par_count);
						set_atr2(fun_idx, par_count-1, par_type);		

	}
	;


body
  : _LBRACKET variable_list
      {
        if(var_num)
          code("\n\t\tSUBS\t%%15,$%d,%%15", 4*var_num);
        code("\n@%s_body:", get_name(fun_idx));
      }
    statement_list _RBRACKET
  ;

variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : _TYPE 
	{ var_type = $1;
	   if($1 == VOID)
		err("variable cannot be void type");
	  } vars _SEMICOLON
  ;

vars
	: _ID
	{
        if(lookup_symbol($1, VAR|PAR) == NO_INDEX)
           insert_symbol($1, VAR, var_type, ++var_num, NO_ATR);
        else 
           err("redefinition of '%s'", $1);
      }
	| vars _COMMA _ID
	{
        if(lookup_symbol($3, VAR|PAR) == NO_INDEX)
           insert_symbol($3, VAR, var_type, ++var_num, NO_ATR);
        else 
           err("redefinition of '%s'", $3);
      }
	;

statement_list
  : /* empty */
  | statement_list statement
  ;

statement
  : compound_statement
  | assignment_statement
  | if_statement
  | return_statement
  | postinc_statement
  | void_call
  | for_statement
  | branch_statement
  ;

branch_statement
  : _BRANCH
  {
	$<i>$ = ++lab_num;
	code("\n@branch%d:", lab_num);
	code("\n\t\tJMP\t@branch_test%d", lab_num);
  }
  _LSQBRACKET _ID
  {
	int idx = lookup_symbol($4, VAR);
  	if(idx == NO_INDEX)
  		err("'%s' undeclared", $4);
	br_id = idx;
  } 
  _DART literal
  {
	if(get_type(br_id) != get_type($7))
		err("incompatible types");
	br_const[0] = $7;
  }
  _DART literal 
  {
	if(get_type(br_id) != get_type($10))
		err("inclompatible types");
	br_const[1] = $10;	
  }
  _DART literal 
  {
	if(get_type(br_id) != get_type($13))
		err("inclompatible types");
	br_const[2] = $13;
  }
  _RSQBRACKET _ONE
  {
	code("\n@one%d:\t", $<i>2);
  }
  statement _TWO
  {
	code("\n\t\tJMP\t@branch_exit%d", $<i>2);
	code("\n@two%d:\t", $<i>2);
  }
  statement _THREE 
  {
	code("\n\t\tJMP\t@branch_exit%d", $<i>2);
	code("\n@three%d:\t", $<i>2);
  }  
  statement _OTHER
  {
	code("\n\t\tJMP\t@branch_exit%d", $<i>2);	
	code("\n@other%d:\t", $<i>2);
  }
  statement _ENDBRANCH
  {
	code("\n\t\tJMP\t@branch_exit%d", $<i>2);
	code("\n@branch_test%d:\t", $<i>2);
	
	gen_cmp(br_id, br_const[0]);
	code("\n\t\tJEQ\t@one%d", $<i>2);
	gen_cmp(br_id, br_const[1]);
	code("\n\t\tJEQ\t@two%d", $<i>2);
	gen_cmp(br_id, br_const[2]);
	code("\n\t\tJEQ\t@three%d", $<i>2);
	code("\n\t\tJMP\t@other%d", $<i>2);

	code("\n@branch_exit%d:", $<i>2);
  }
  ;

for_statement
  : _FOR 
  {
	$<i>$ = ++lab_num;

  } 
  _ID _IN _LPAREN literal
  {
	int for_id = lookup_symbol($3, VAR|PAR);
	  if(for_id == NO_INDEX) 	
	    err("identifier '%s' undeclared or it is not var/par ", $3);
	 else if(get_type(for_id) != get_type($6))
		err("incompatible types");
	else{
	gen_mov($6, for_id);
	code("\n@for%d:", $<i>2); 
	}
	$<i>$ = for_id;
  }
  _DOTS literal
  {
	if(get_type($<i>7) != get_type($9))
		err("incompatible types");
  	else {
	   	gen_cmp($<i>7, $9);
		if(get_type($<i>7) == INT)
	   		code("\n\t\tJGES\t@forexit%d", $<i>2);
	  	else
	   		code("\n\t\tJGEU\t@forexit%d", $<i>2);
	}
  }
   _STEP literal _RPAREN statement
  {

	if(get_type($<i>7) != get_type($12))
		err("incompatible types");
	else{
	  	code("\n\t\t%s\t", ar_instructions[(get_type($<i>7) - 1)*AROP_NUMBER]);
	  	gen_sym_name($<i>7);
	  	code(",");
		gen_sym_name($12);
		code(",");
	  	gen_sym_name($<i>7);
	  	code("\n\t\tJMP\t@for%d", $<i>2);
	  	code("\n@forexit%d:", $<i>2);
	}
  }
  ;
  
  

void_call 
  : function_call _SEMICOLON
	{
          if(get_type($1) != VOID)
            err("Invalid non-void function call");
	}
  ;

compound_statement
  : _LBRACKET statement_list _RBRACKET
  ;

assignment_statement
  : _ID _ASSIGN num_exp _SEMICOLON
      {
        int idx = lookup_symbol($1, VAR|PAR|GVAR);
        if(idx == NO_INDEX)
          err("invalid lvalue '%s' in assignment", $1);
        else
          if(get_type(idx) != get_type($3))
            err("incompatible types in assignment");
	else
        gen_mov($3, idx);
      }
  ;

num_exp
  : exp
  | num_exp _ASOP num_exp 
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: arithmetic operation");
	else {
		int t1 = get_type($1);    
		code("\n\t\t%s\t", ar_instructions[$2 + (t1 - 1) * AROP_NUMBER]);
		gen_sym_name($1);
		code(",");
		gen_sym_name($3);
		code(",");
		free_if_reg($3);
		free_if_reg($1);
		$$ = take_reg();
		gen_sym_name($$);
		set_type($$, t1);
	}
      }
   | num_exp _MDOP exp 
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: arithmetic operation");
	else {
		int t1 = get_type($1);    
		code("\n\t\t%s\t", ar_instructions[$2 + (t1 - 1) * AROP_NUMBER]);
		gen_sym_name($1);
		code(",");
		gen_sym_name($3);
		code(",");
		free_if_reg($3);
		free_if_reg($1);
		$$ = take_reg();
		gen_sym_name($$);
		set_type($$, t1);
	}//
      }
  ;

exp
  : literal

  | _ID
      {
        $$ = lookup_symbol($1, VAR|PAR|GVAR);
        if($$ == NO_INDEX)
          err("'%s' undeclared", $1);
      }

  | function_call
      {
        $$ = take_reg();
        gen_mov(FUN_REG, $$);
      }
  
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }
  | _ID _INC 
	{ 
		  $$ = lookup_symbol($1, VAR|PAR|GVAR);
		  if($$ == -1) 
		    err("either undeclared or not allowed kind of ID %s!", $1);

	int idx = $$;
	int type = get_type($$);

	$$ = take_reg();
	gen_mov(idx, $$); //sacuva neikrementirano u neki reg
	
	if(type == INT) {
		code("\n\t\tADDS\t");	
	} else {
		code("\n\t\tADDU\t");
	}

	gen_sym_name(idx); 
	code(",$1,");
	gen_sym_name(idx);
	
	set_type($$, type);
 	}
  | _LPAREN rel_exp _RPAREN _QMARK cond_exp _COLON cond_exp
	{
		int reg = take_reg();
		if(get_type($5)!=get_type($7))
	  		err("incompatible types");
		else {  
		  	++lab_num;
		  	code("\n\t\t%s\t@false%d", opp_jumps[$2], lab_num);
		  	gen_mov($5, reg);
		  	code("\n\t\tJMP\t@exit%d", lab_num);
		  	code("\n@false%d:", lab_num);
		  	gen_mov($7, reg);
		  	code("\n@exit%d:", lab_num);
		}
		  	$$ = reg;
		  	set_type($$, get_type($5));
	}
	
  ;

cond_exp
  : _ID {
        if( ($$ = lookup_symbol($1, (VAR|PAR))) == NO_INDEX )
          err("'%s' undeclared", $1);
      }
  | literal
  ;

literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); }

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); }
  ;

function_call
  : _ID 
      {
        fcall_idx = lookup_symbol($1, FUN);
        if(fcall_idx == NO_INDEX)
          err("'%s' is not a function", $1);
	else
	par_count = 0; 
      }
    _LPAREN argument _RPAREN
      {
		
        if(get_atr1(fcall_idx) != $4)
          err("wrong number of arguments");
        code("\n\t\t\tCALL\t%s", get_name(fcall_idx));
        if($4 > 0)
          code("\n\t\t\tADDS\t%%15,$%d,%%15", $4 * 4);
        set_type(FUN_REG, get_type(fcall_idx));
        $$ = FUN_REG;
      }
  ;

argument
  : /* empty */
    { $$ = 0; }

  | arg {$$ = $1; }
  ;

arg 
	: num_exp
		{
		if(get_atr2(fcall_idx, par_count) != get_type($1))
        err("incompatible type for argument");
		 free_if_reg($1);
      code("\n\t\t\tPUSH\t");
      gen_sym_name($1);
		$$ = ++par_count;
		}
	| arg _COMMA num_exp
		{
		if(get_atr2(fcall_idx, par_count) != get_type($3))
        err("incompatible type for argument");
		free_if_reg($3);
      code("\n\t\t\tPUSH\t");
      gen_sym_name($3);
		$$ = ++par_count;
		}	
	;

if_statement
  : if_part %prec ONLY_IF
      { code("\n@exit%d:", $1); }

  | if_part _ELSE statement
      { code("\n@exit%d:", $1); }
  ;

if_part
  : _IF _LPAREN
      {
        $<i>$ = ++lab_num;
        code("\n@if%d:", lab_num);
      }
    rel_exp
      {
        code("\n\t\t%s\t@false%d", opp_jumps[$4], $<i>3); 
        code("\n@true%d:", $<i>3);
      }
    _RPAREN statement
      {
        code("\n\t\tJMP \t@exit%d", $<i>3);
        code("\n@false%d:", $<i>3);
        $$ = $<i>3;
      }
  ;

rel_exp
  : num_exp 
	{ }
	_RELOP num_exp
      {
         if(get_type($1) != get_type($4))
          err("invalid operands: relational operator");
	else {
        $$ = $3 + ((get_type($1) - 1) * RELOP_NUMBER);
    
        gen_cmp($1, $4);
	}
      }
  ;

postinc_statement
 : _ID _INC _SEMICOLON
	{
			int idx = lookup_symbol($1, VAR|PAR|GVAR);
			if(idx == NO_INDEX)	
					err("'%s' undeclared", $1);
			else{

			code("\n\t\t%s\t", ar_instructions[(get_type(idx)-1)*AROP_NUMBER]);
	
			gen_sym_name(idx);
			code(",$1,");
			gen_sym_name(idx);
			}
	}
 ;

return_statement
  : _RETURN num_exp _SEMICOLON
      {
	if(get_type(fun_idx) == VOID)
	  err("void function does not return any value");

        if(get_type(fun_idx) != get_type($2))
          err("incompatible types in return");
        gen_mov($2, FUN_REG);
		ret_count++;	
        code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));        
      }
  | _RETURN _SEMICOLON
	{
		if(get_type(fun_idx) != VOID) 
		  err("function is expectin a ret val"); // warn --- err
		ret_count++;
		code("\n\t\tJMP \t@%s_exit", get_name(fun_idx));	
	}
  ;

%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}

int main() {
  int synerr;
  init_symtab();
  output = fopen("output.asm", "w+");

  synerr = yyparse();

  clear_symtab();
  fclose(output);
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count) {
    remove("output.asm");
    printf("\n%d error(s).\n", error_count);
  }

  if(synerr)
    return -1;  //syntax error
  else if(error_count)
    return error_count & 127; //semantic errors
  else if(warning_count)
    return (warning_count & 127) + 127; //warnings
  else
    return 0; //OK
}
	
