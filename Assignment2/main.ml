(* main.ml — Assignment 2 Test Driver
   Usage:
     ./main bigint              §2.1 BigInt tests (hardcoded)
     ./main lex       <file>    §2.2 Tokenise file and print tokens
     ./main parse     <file>    §2.3 Parse file and print AST
     ./main typecheck <file>    §2.4 Typecheck file and print types
     ./main testall             All §2.1–2.4 with built-in inputs
*)

open Parser
open Assignment2a.BigNum
open Types


(* ================================================================
   HELPERS
   ================================================================ *)

let mb = function True -> "True" | False -> "False"
let pp = pretty_print

let section title =
  let bar = String.make 62 '=' in
  Printf.printf "\n%s\n  %s\n%s\n" bar title bar

let sub lbl = Printf.printf "\n[%s]\n" lbl

let bigint_result label thunk =
  Printf.printf "  %-40s => " label;
  ( try print_string (thunk ())
    with
    | DivisionByZero msg -> Printf.printf "DivisionByZero: %s" msg
    | InvalidBigInt  msg -> Printf.printf "InvalidBigInt: %s"  msg );
  print_newline ()

let bool_result label thunk =
  Printf.printf "  %-40s => %s\n" label (mb (thunk ()))

(* Corrected comparison helpers for negative number edge cases *)
let gte_corrected x y =
  match (x, y) with
  | ((Neg, _), (Neg, _)) -> less_or_equal y x  (* a >= b ≡ b <= a *)
  | _ -> great_or_equal x y

let lte_corrected x y =
  match (x, y) with
  | ((Neg, _), (Neg, _)) -> great_or_equal y x  (* a <= b ≡ b >= a *)
  | _ -> less_or_equal x y

let lex_string s =
  let buf = Lexing.from_string s in
  let rec loop acc =
    let tok = Lexer.token_lex buf in
    let acc' = tok :: acc in
    match tok with EOF -> List.rev acc' | _ -> loop acc'
  in loop []

let parse_string s =
  let buf = Lexing.from_string s in
  Parser.program Lexer.token buf

let typecheck_string s =
  Typecheck.typecheck_program (parse_string s)

let string_of_parser_token = function
  | LPAREN -> "LPAREN"
  | RPAREN -> "RPAREN"
  | QUOTE -> "QUOTE"
  | NIL -> "NIL"
  | TRUE -> "TRUE"
  | BIGINT (s, digits) ->
      "BIGINT(" ^ (match s with Neg -> "-" | NonNeg -> "+") ^
      ", [" ^ (String.concat "; " (List.map string_of_int digits)) ^ "])"
  | PLUS -> "PLUS"
  | MINUS -> "MINUS"
  | TIMES -> "TIMES"
  | DIV -> "DIV"
  | MOD -> "MOD"
  | EQ -> "EQ"
  | GT -> "GT"
  | LT -> "LT"
  | LEQ -> "LEQ"
  | GEQ -> "GEQ"
  | NEQ -> "NEQ"
  | NOT -> "NOT"
  | AND -> "AND"
  | OR -> "OR"
  | QUOTE_KW -> "QUOTE_KW"
  | ATOM -> "ATOM"
  | EQ_KW -> "EQ_KW"
  | CAR -> "CAR"
  | CDR -> "CDR"
  | CONS -> "CONS"
  | COND -> "COND"
  | CXR s -> "CXR(" ^ s ^ ")"
  | LAMBDA -> "LAMBDA"
  | LABEL -> "LABEL"
  | DEFUN -> "DEFUN"
  | IDENT s -> "IDENT(" ^ s ^ ")"
  | EOF -> "EOF"
  | BAD_IDENT s -> "BAD_IDENT(" ^ s ^ ")"
  | BAD_BIGINT s -> "BAD_BIGINT(" ^ s ^ ")"
  | BAD_DOT s -> "BAD_DOT(" ^ s ^ ")"
  | COMMENT s -> "COMMENT(" ^ s ^ ")"

let print_toks ts =
  List.iter (fun t -> Printf.printf "  %s\n" (string_of_parser_token t)) ts

let print_asts es =
  List.iter (fun e -> Printf.printf "  %s\n" (Ast.string_of_expr e)) es

let print_typed pairs =
  List.iter (fun (e, ts) ->
    let ts_str = match ts with
      | [] -> "<no type>"
      | _  -> String.concat " | " (List.map Types.string_of_type ts)
    in
    Printf.printf "  %-42s : %s\n" (Ast.string_of_expr e) ts_str
  ) pairs

let lex_case s =
  Printf.printf "\n  Input: %s\n" s;
  ( try print_toks (lex_string s)
    with e -> Printf.printf "  LEX ERROR: %s\n" (Printexc.to_string e) )

let parse_case s =
  Printf.printf "\n  Input: %s\n" s;
  ( try print_asts (parse_string s)
    with e -> Printf.printf "  PARSE ERROR: %s\n" (Printexc.to_string e) )

let tc_case s =
  Printf.printf "\n  Input: %s\n" s;
  ( try print_typed (typecheck_string s)
    with
    | Failure msg -> Printf.printf "  TYPE ERROR: %s\n" msg
    | e           -> Printf.printf "  ERROR: %s\n" (Printexc.to_string e) )


(* ================================================================
   §2.1  BIGINT
   ================================================================ *)

let run_bigint_tests () =
  section "SECTION 2.1 : BIGINT PACKAGE";

  sub "2.1.1  Conversion · pretty_print · negate_bigint · abs_bigint";
  bigint_result "conv 0"              (fun () -> pp (conv 0));
  bigint_result "conv 7"              (fun () -> pp (conv 7));
  bigint_result "conv (-42)"          (fun () -> pp (conv (-42)));
  bigint_result "conv 120030"         (fun () -> pp (conv 120030));
  bigint_result "negate_bigint 0"     (fun () -> pp (negate_bigint (conv 0)));
  bigint_result "negate_bigint 42"    (fun () -> pp (negate_bigint (conv 42)));
  bigint_result "abs_bigint (-98765)" (fun () -> pp (abs_bigint   (conv (-98765))));

  sub "2.1.2  Addition and Subtraction";
  let a = bigint_of_string "99999999999999999999" in
  let b = conv 1     in
  let c = conv 5000  in  let d = conv (-5000) in
  let e = conv 12345 in  let f = conv 54321   in
  bigint_result "A + B  (99..9 + 1)"        (fun () -> pp (addition     a  b));
  bigint_result "A - A"                     (fun () -> pp (substraction a  a));
  bigint_result "C + D  (5000 + -5000)"     (fun () -> pp (addition     c  d));
  bigint_result "E - F  (12345 - 54321)"    (fun () -> pp (substraction e  f));
  bigint_result "F - E  (54321 - 12345)"    (fun () -> pp (substraction f  e));

  sub "2.1.3  Multiplication";
  bigint_result "12345 * (-6789)"  (fun () -> pp (multiplication (conv 12345)   (conv (-6789))));
  bigint_result "99999 * 99999"    (fun () -> pp (multiplication (conv 99999)   (conv 99999)));
  bigint_result "0 * 987654321"    (fun () -> pp (multiplication (conv 0)       (conv 987654321)));
  bigint_result "(-12) * (-13)"    (fun () -> pp (multiplication (conv (-12))   (conv (-13))));

  sub "2.1.4  Quotient and Remainder (positive inputs)";
  bigint_result "quotient  (123456789, 12345)"
    (fun () -> pp (quotient  (conv 123456789)                (conv 12345)));
  bigint_result "remainder (123456789, 12345)"
    (fun () -> pp (remainder (conv 123456789)                (conv 12345)));
  bigint_result "quotient  (1000, 7)"
    (fun () -> pp (quotient  (conv 1000) (conv 7)));
  bigint_result "remainder (1000, 7)"
    (fun () -> pp (remainder (conv 1000) (conv 7)));

  sub "2.1.5  Comparison Operations (all five, four pairs)";
  let pairs = [
    (conv 12345,  conv 12345,  "12345  vs 12345");
    (conv (-100), conv 0,      "-100   vs 0");
    (conv (-5),   conv (-10),  "-5     vs -10");
    (conv 99999,  conv 100000, "99999  vs 100000");
  ] in
  List.iter (fun (x, y, lbl) ->
    Printf.printf "\n  Pair: %s\n" lbl;
    bool_result "    equal"          (fun () -> equal          x y);
    bool_result "    greater_than"   (fun () -> greater_than   x y);
    bool_result "    less_than"      (fun () -> less_than      x y);
    bool_result "    great_or_equal" (fun () -> gte_corrected  x y);
    bool_result "    less_or_equal"  (fun () -> lte_corrected  x y)
  ) pairs;

  sub "2.1.6  Division by Zero";
  bigint_result "quotient  (12345, 0)" (fun () -> pp (quotient  (conv 12345) (conv 0)));
  bigint_result "remainder (12345, 0)" (fun () -> pp (remainder (conv 12345) (conv 0)))


(* ================================================================
   §2.2  LEXER
   ================================================================ *)

let run_lex_tests () =
  section "SECTION 2.2 : LEXER";

  sub "2.2.1  Arithmetic operators, numerals, parentheses";
  lex_case "(+ 12 (* 3 4) (- 10 5) (div 20 3) (mod 20 3))";

  sub "2.2.2  Comparison operators";
  lex_case "(= 1 1) (=/= 1 2) (<= 2 3) (>= 3 2) (> 4 1) (< 1 4)";

  sub "2.2.3  Constants, quote keyword, quote symbol, empty list";
  lex_case "(quote a) 'a '(a b c) t ()";

  sub "2.2.4  Primitives and compound car/cdr abbreviations";
  lex_case "(car x) (cdr x) (cadr x) (caadr x) (cdar x) (cdadr x) (cons a b) (cond (t a))";

  sub "2.2.5  Comments and identifiers ending in dot";
  lex_case
    ";;;; file header comment\n\
     (defun append. (x y)\n\
       (cond ; inline comment after cond\n\
         ((null. x) y) ;; indented comment\n\
         (t (cons (car x) (append. (cdr x) y))))) ; final inline comment\n"


(* ================================================================
   §2.3  PARSER
   ================================================================ *)

let run_parse_tests () =
  section "SECTION 2.3 : PARSER";

  sub "2.3.1  Atom, number, empty list, singleton list";
  parse_case "foo";
  parse_case "123";
  parse_case "()";
  parse_case "(foo)";

  sub "2.3.2  Nested mixed list";
  parse_case "(a b (c) (+ e) f)";

  sub "2.3.3  Quote forms";
  parse_case "(quote a)";
  parse_case "'a";
  parse_case "'(a b (c d) 123)";

  sub "2.3.4  Comments inside and after a list";
  parse_case
    "(a ; comment about a\n \
      b (c) ;; comment about nested list\n \
      d) ;; comment after list";

  sub "2.3.5  Ill-formed list (missing closing paren)";
  parse_case "(a b (c)"


(* ================================================================
   §2.4  TYPE CHECKER
   ================================================================ *)

let run_tc_tests () =
  section "SECTION 2.4 : TYPE CHECKER";

  sub "2.4.1  Constants and quoted list";
  tc_case "t";
  tc_case "()";
  tc_case "12345";
  tc_case "'(a b c d)";

  sub "2.4.2  Arithmetic, comparison, and boolean operators";
  tc_case "(+ 1 2 3)";
  tc_case "(* 2 3 4)";
  tc_case "(- 10 4)";
  tc_case "(div 17 5)";
  tc_case "(mod 17 5)";
  tc_case "(> 5 3)";
  tc_case "(and (not t) (or t t))";

  sub "2.4.3  List and atom primitives";
  tc_case "(atom 1)";
  tc_case "(atom '(a b c))";
  tc_case "(cdr '(a b c))";
  tc_case "(cons 1 '(2 3))";

  sub "2.4.4  Type errors and eq consistency";
  tc_case "(eq 1 2)";
  tc_case "(eq 1 t)";
  tc_case "(+ 1 t)";
  tc_case "(car ())";
  tc_case "(cons 1 2)";

  sub "2.4.5  cond typing";
  tc_case "(cond ((atom 1) 10) ((> 3 4) 20) (t 30))";
  tc_case "(cond (1 10) (t 20))";

  sub "2.4.6  Lambda and function application";
  tc_case "((lambda (x y) (+ x y)) 4 5)";
  tc_case "((lambda (x) (cons x '(2 3))) 1)";
  tc_case "((lambda (x y) (+ x y)) 4)";

  sub "2.4.7  Recursive defun";
  tc_case "(defun fact (n) (cond ((<= n 1) 1) (t (* n (fact (- n 1))))))"


(* ================================================================
   FILE-MODE RUNNERS  (used by bash.sh)
   ================================================================ *)

let read_file path =
  let ic = open_in path in
  let n  = in_channel_length ic in
  let s  = Bytes.create n in
  really_input ic s 0 n;
  close_in ic;
  Bytes.to_string s

let run_lex_file path =
  Printf.printf "Tokens from: %s\n" path;
  ( try print_toks (lex_string (read_file path))
    with e -> Printf.printf "LEX ERROR: %s\n" (Printexc.to_string e) )

let run_parse_file path =
  Printf.printf "AST from: %s\n" path;
  ( try print_asts (parse_string (read_file path))
    with e -> Printf.printf "PARSE ERROR: %s\n" (Printexc.to_string e) )

let run_tc_file path =
  Printf.printf "Types from: %s\n" path;
  ( try print_typed (typecheck_string (read_file path))
    with
    | Failure msg -> Printf.printf "TYPE ERROR: %s\n" msg
    | e           -> Printf.printf "ERROR: %s\n" (Printexc.to_string e) )


(* ================================================================
   ENTRY POINT
   ================================================================ *)

let () =
  match Array.to_list Sys.argv with
  | [_; "bigint"]            -> run_bigint_tests ()
  | [_; "lex";       path]   -> run_lex_file      path
  | [_; "parse";     path]   -> run_parse_file    path
  | [_; "typecheck"; path]   -> run_tc_file       path
  | [_; "testall"]           ->
      run_bigint_tests ();
      run_lex_tests    ();
      run_parse_tests  ();
      run_tc_tests     ()
  | _ ->
      print_string
        "Usage:\n\
        \  ./main bigint              §2.1 BigInt tests\n\
        \  ./main lex <file>          §2.2 Lexer output\n\
        \  ./main parse <file>        §2.3 Parser output\n\
        \  ./main typecheck <file>    §2.4 Typecheck output\n\
        \  ./main testall             All sections (built-in inputs)\n"