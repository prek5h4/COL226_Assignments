%{

%}

/* Tokens with NO value */
%token LPAREN RPAREN QUOTE NIL TRUE EOF
%token PLUS MINUS TIMES DIV MOD
%token EQ GT LT LEQ GEQ NEQ
%token NOT AND OR
%token QUOTE_KW ATOM EQ_KW CAR CDR CONS COND
%token LAMBDA LABEL DEFUN

/* Tokens WITH a value */
%token <string> IDENT
%token <string> CXR
%token <Assignment2a.BigNum.sign * int list> BIGINT

/* Lexer-only tokens added here so ocamlyacc generates them */
%token <string> BAD_BIGINT
%token <string> BAD_IDENT
%token <string> BAD_DOT
%token <string> COMMENT

%start program
%type <Ast.expr list> program

%%
/* The top-level entry point: a sequence of expressions followed by EOF */
program:
    | expr_seq EOF { List.rev $1 }
;

/* A helper to collect multiple expressions/comments at the top level */
expr_seq:
    | /* empty */          { [] }
    | expr_seq expr        { $2 :: $1 }
    | expr_seq COMMENT     { $1 } /* Skip comments */
;

expr:
    | BIGINT                  { Ast.Num $1 }
    | TRUE                    { Ast.Bool true }
    | NIL                     { Ast.Nil }
    | IDENT                   { Ast.Symbol $1 }
    | CXR                     { Ast.Symbol $1 }
    | PLUS                    { Ast.Symbol "+" }
    | MINUS                   { Ast.Symbol "-" }
    | TIMES                   { Ast.Symbol "*" }
    | DIV                     { Ast.Symbol "div" }
    | MOD                     { Ast.Symbol "mod" }
    | EQ                      { Ast.Symbol "=" }
    | GT                      { Ast.Symbol ">" }
    | LT                      { Ast.Symbol "<" }
    | LEQ                     { Ast.Symbol "<=" }
    | GEQ                     { Ast.Symbol ">=" }
    | NEQ                     { Ast.Symbol "=/=" }
    | NOT                     { Ast.Symbol "not" }
    | AND                     { Ast.Symbol "and" }
    | OR                      { Ast.Symbol "or" }
    | LAMBDA                  { Ast.Symbol "lambda" }
    | LABEL                   { Ast.Symbol "label" }
    | DEFUN                   { Ast.Symbol "defun" }
    | QUOTE_KW                { Ast.Symbol "quote" }
    | ATOM                    { Ast.Symbol "atom" }
    | EQ_KW                   { Ast.Symbol "eq" }
    | CAR                     { Ast.Symbol "car" }
    | CDR                     { Ast.Symbol "cdr" }
    | CONS                    { Ast.Symbol "cons" }
    | COND                    { Ast.Symbol "cond" }
    /* Handle the ' shorthand for quote */
    | QUOTE expr              { Ast.List [Ast.Symbol "quote"; $2] }
    /* Handle S-Expressions (lists) */
    | LPAREN expr_list RPAREN { Ast.List (List.rev $2) }
;

/* Rule to handle contents inside parentheses */
expr_list:
    | /* empty */              { [] }
    | expr_list expr           { $2 :: $1 }
    | expr_list COMMENT        { $1 } /* Skip comments inside lists */
;

%%