type token =
  | LPAREN
  | RPAREN
  | QUOTE
  | NIL
  | TRUE
  | EOF
  | PLUS
  | MINUS
  | TIMES
  | DIV
  | MOD
  | EQ
  | GT
  | LT
  | LEQ
  | GEQ
  | NEQ
  | NOT
  | AND
  | OR
  | QUOTE_KW
  | ATOM
  | EQ_KW
  | CAR
  | CDR
  | CONS
  | COND
  | LAMBDA
  | LABEL
  | DEFUN
  | IDENT of (string)
  | CXR of (string)
  | BIGINT of (Assignment2a.BigNum.sign * int list)
  | BAD_BIGINT of (string)
  | BAD_IDENT of (string)
  | BAD_DOT of (string)
  | COMMENT of (string)

open Parsing;;
let _ = parse_error;;
# 2 "parser.mly"

# 45 "parser.ml"
let yytransl_const = [|
  257 (* LPAREN *);
  258 (* RPAREN *);
  259 (* QUOTE *);
  260 (* NIL *);
  261 (* TRUE *);
    0 (* EOF *);
  262 (* PLUS *);
  263 (* MINUS *);
  264 (* TIMES *);
  265 (* DIV *);
  266 (* MOD *);
  267 (* EQ *);
  268 (* GT *);
  269 (* LT *);
  270 (* LEQ *);
  271 (* GEQ *);
  272 (* NEQ *);
  273 (* NOT *);
  274 (* AND *);
  275 (* OR *);
  276 (* QUOTE_KW *);
  277 (* ATOM *);
  278 (* EQ_KW *);
  279 (* CAR *);
  280 (* CDR *);
  281 (* CONS *);
  282 (* COND *);
  283 (* LAMBDA *);
  284 (* LABEL *);
  285 (* DEFUN *);
    0|]

let yytransl_block = [|
  286 (* IDENT *);
  287 (* CXR *);
  288 (* BIGINT *);
  289 (* BAD_BIGINT *);
  290 (* BAD_IDENT *);
  291 (* BAD_DOT *);
  292 (* COMMENT *);
    0|]

let yylhs = "\255\255\
\001\000\002\000\002\000\002\000\003\000\003\000\003\000\003\000\
\003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
\003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
\003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
\003\000\003\000\003\000\004\000\004\000\004\000\000\000"

let yylen = "\002\000\
\002\000\000\000\002\000\002\000\001\000\001\000\001\000\001\000\
\001\000\001\000\001\000\001\000\001\000\001\000\001\000\001\000\
\001\000\001\000\001\000\001\000\001\000\001\000\001\000\001\000\
\001\000\001\000\001\000\001\000\001\000\001\000\001\000\001\000\
\001\000\002\000\003\000\000\000\002\000\002\000\002\000"

let yydefred = "\000\000\
\002\000\000\000\039\000\000\000\036\000\000\000\007\000\006\000\
\001\000\010\000\011\000\012\000\013\000\014\000\015\000\016\000\
\017\000\018\000\019\000\020\000\021\000\022\000\023\000\027\000\
\028\000\029\000\030\000\031\000\032\000\033\000\024\000\025\000\
\026\000\008\000\009\000\005\000\004\000\003\000\000\000\034\000\
\035\000\038\000\037\000"

let yydgoto = "\002\000\
\003\000\004\000\038\000\039\000"

let yysindex = "\255\255\
\000\000\000\000\000\000\001\000\000\000\065\255\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\001\255\000\000\
\000\000\000\000\000\000"

let yyrindex = "\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000"

let yygindex = "\000\000\
\000\000\000\000\028\000\000\000"

let yytablesize = 293
let yytable = "\001\000\
\009\000\005\000\041\000\006\000\007\000\008\000\010\000\011\000\
\012\000\013\000\014\000\015\000\016\000\017\000\018\000\019\000\
\020\000\021\000\022\000\023\000\024\000\025\000\026\000\027\000\
\028\000\029\000\030\000\031\000\032\000\033\000\034\000\035\000\
\036\000\040\000\000\000\000\000\042\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\005\000\043\000\006\000\007\000\008\000\010\000\011\000\
\012\000\013\000\014\000\015\000\016\000\017\000\018\000\019\000\
\020\000\021\000\022\000\023\000\024\000\025\000\026\000\027\000\
\028\000\029\000\030\000\031\000\032\000\033\000\034\000\035\000\
\036\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
\000\000\005\000\000\000\006\000\007\000\008\000\010\000\011\000\
\012\000\013\000\014\000\015\000\016\000\017\000\018\000\019\000\
\020\000\021\000\022\000\023\000\024\000\025\000\026\000\027\000\
\028\000\029\000\030\000\031\000\032\000\033\000\034\000\035\000\
\036\000\000\000\000\000\000\000\037\000"

let yycheck = "\001\000\
\000\000\001\001\002\001\003\001\004\001\005\001\006\001\007\001\
\008\001\009\001\010\001\011\001\012\001\013\001\014\001\015\001\
\016\001\017\001\018\001\019\001\020\001\021\001\022\001\023\001\
\024\001\025\001\026\001\027\001\028\001\029\001\030\001\031\001\
\032\001\006\000\255\255\255\255\036\001\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\001\001\039\000\003\001\004\001\005\001\006\001\007\001\
\008\001\009\001\010\001\011\001\012\001\013\001\014\001\015\001\
\016\001\017\001\018\001\019\001\020\001\021\001\022\001\023\001\
\024\001\025\001\026\001\027\001\028\001\029\001\030\001\031\001\
\032\001\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
\255\255\001\001\255\255\003\001\004\001\005\001\006\001\007\001\
\008\001\009\001\010\001\011\001\012\001\013\001\014\001\015\001\
\016\001\017\001\018\001\019\001\020\001\021\001\022\001\023\001\
\024\001\025\001\026\001\027\001\028\001\029\001\030\001\031\001\
\032\001\255\255\255\255\255\255\036\001"

let yynames_const = "\
  LPAREN\000\
  RPAREN\000\
  QUOTE\000\
  NIL\000\
  TRUE\000\
  EOF\000\
  PLUS\000\
  MINUS\000\
  TIMES\000\
  DIV\000\
  MOD\000\
  EQ\000\
  GT\000\
  LT\000\
  LEQ\000\
  GEQ\000\
  NEQ\000\
  NOT\000\
  AND\000\
  OR\000\
  QUOTE_KW\000\
  ATOM\000\
  EQ_KW\000\
  CAR\000\
  CDR\000\
  CONS\000\
  COND\000\
  LAMBDA\000\
  LABEL\000\
  DEFUN\000\
  "

let yynames_block = "\
  IDENT\000\
  CXR\000\
  BIGINT\000\
  BAD_BIGINT\000\
  BAD_IDENT\000\
  BAD_DOT\000\
  COMMENT\000\
  "

let yyact = [|
  (fun _ -> failwith "parser")
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'expr_seq) in
    Obj.repr(
# 30 "parser.mly"
                   ( List.rev _1 )
# 262 "parser.ml"
               : Ast.expr list))
; (fun __caml_parser_env ->
    Obj.repr(
# 35 "parser.mly"
                           ( [] )
# 268 "parser.ml"
               : 'expr_seq))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'expr_seq) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 36 "parser.mly"
                           ( _2 :: _1 )
# 276 "parser.ml"
               : 'expr_seq))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'expr_seq) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 37 "parser.mly"
                           ( _1 )
# 284 "parser.ml"
               : 'expr_seq))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : Assignment2a.BigNum.sign * int list) in
    Obj.repr(
# 41 "parser.mly"
                              ( Ast.Num _1 )
# 291 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 42 "parser.mly"
                              ( Ast.Bool true )
# 297 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 43 "parser.mly"
                              ( Ast.Nil )
# 303 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 44 "parser.mly"
                              ( Ast.Symbol _1 )
# 310 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 45 "parser.mly"
                              ( Ast.Symbol _1 )
# 317 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 46 "parser.mly"
                              ( Ast.Symbol "+" )
# 323 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 47 "parser.mly"
                              ( Ast.Symbol "-" )
# 329 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 48 "parser.mly"
                              ( Ast.Symbol "*" )
# 335 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 49 "parser.mly"
                              ( Ast.Symbol "div" )
# 341 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 50 "parser.mly"
                              ( Ast.Symbol "mod" )
# 347 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 51 "parser.mly"
                              ( Ast.Symbol "=" )
# 353 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 52 "parser.mly"
                              ( Ast.Symbol ">" )
# 359 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 53 "parser.mly"
                              ( Ast.Symbol "<" )
# 365 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 54 "parser.mly"
                              ( Ast.Symbol "<=" )
# 371 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 55 "parser.mly"
                              ( Ast.Symbol ">=" )
# 377 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 56 "parser.mly"
                              ( Ast.Symbol "=/=" )
# 383 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 57 "parser.mly"
                              ( Ast.Symbol "not" )
# 389 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 58 "parser.mly"
                              ( Ast.Symbol "and" )
# 395 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 59 "parser.mly"
                              ( Ast.Symbol "or" )
# 401 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 60 "parser.mly"
                              ( Ast.Symbol "lambda" )
# 407 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 61 "parser.mly"
                              ( Ast.Symbol "label" )
# 413 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 62 "parser.mly"
                              ( Ast.Symbol "defun" )
# 419 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 63 "parser.mly"
                              ( Ast.Symbol "quote" )
# 425 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 64 "parser.mly"
                              ( Ast.Symbol "atom" )
# 431 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 65 "parser.mly"
                              ( Ast.Symbol "eq" )
# 437 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 66 "parser.mly"
                              ( Ast.Symbol "car" )
# 443 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 67 "parser.mly"
                              ( Ast.Symbol "cdr" )
# 449 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 68 "parser.mly"
                              ( Ast.Symbol "cons" )
# 455 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 69 "parser.mly"
                              ( Ast.Symbol "cond" )
# 461 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 71 "parser.mly"
                              ( Ast.List [Ast.Symbol "quote"; _2] )
# 468 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    let _2 = (Parsing.peek_val __caml_parser_env 1 : 'expr_list) in
    Obj.repr(
# 73 "parser.mly"
                              ( Ast.List (List.rev _2) )
# 475 "parser.ml"
               : 'expr))
; (fun __caml_parser_env ->
    Obj.repr(
# 78 "parser.mly"
                               ( [] )
# 481 "parser.ml"
               : 'expr_list))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'expr_list) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : 'expr) in
    Obj.repr(
# 79 "parser.mly"
                               ( _2 :: _1 )
# 489 "parser.ml"
               : 'expr_list))
; (fun __caml_parser_env ->
    let _1 = (Parsing.peek_val __caml_parser_env 1 : 'expr_list) in
    let _2 = (Parsing.peek_val __caml_parser_env 0 : string) in
    Obj.repr(
# 80 "parser.mly"
                               ( _1 )
# 497 "parser.ml"
               : 'expr_list))
(* Entry program *)
; (fun __caml_parser_env -> raise (Parsing.YYexit (Parsing.peek_val __caml_parser_env 0)))
|]
let yytables =
  { Parsing.actions=yyact;
    Parsing.transl_const=yytransl_const;
    Parsing.transl_block=yytransl_block;
    Parsing.lhs=yylhs;
    Parsing.len=yylen;
    Parsing.defred=yydefred;
    Parsing.dgoto=yydgoto;
    Parsing.sindex=yysindex;
    Parsing.rindex=yyrindex;
    Parsing.gindex=yygindex;
    Parsing.tablesize=yytablesize;
    Parsing.table=yytable;
    Parsing.check=yycheck;
    Parsing.error_function=parse_error;
    Parsing.names_const=yynames_const;
    Parsing.names_block=yynames_block }
let program (lexfun : Lexing.lexbuf -> token) (lexbuf : Lexing.lexbuf) =
   (Parsing.yyparse yytables 1 lexfun lexbuf : Ast.expr list)
;;
