type sign   = Assignment2a.BigNum.sign   = Neg | NonNeg
type bigint = Assignment2a.BigNum.bigint

type token =
  (* Structure *)
  | LPAREN
  | RPAREN
  | QUOTE
  | NIL
  | TRUE

  (* Literals *)
  | BIGINT of bigint
  | BAD_BIGINT of string

  (* Arithmetic *)
  | PLUS
  | MINUS
  | TIMES
  | DIV
  | MOD
 
  (* Comparison *)
  | EQ
  | GT
  | LT
  | LEQ
  | GEQ
  | NEQ
  | NOT 
  | AND
  | OR

  (* Primitives *)
  | QUOTE_KW
  | ATOM
  | EQ_KW
  | CAR
  | CDR
  | CONS
  | COND
  | CXR of string      (* cadr, caar, cddr, etc. *)

  (* Definitions *)
  | LAMBDA
  | LABEL
  | DEFUN

  (* Identifiers *)
  | IDENT of string
  | BAD_IDENT of string
  | BAD_DOT of string
  | COMMENT of string

  | EOF

let string_of_token = function
  | LPAREN        -> "LPAREN"
  | RPAREN        -> "RPAREN"
  | QUOTE         -> "QUOTE"
  | NIL           -> "NIL"
  | TRUE          -> "TRUE"
  | BIGINT (s, digits) ->
      "BIGINT(" ^ (match s with Neg -> "-" | NonNeg -> "+") ^
      ", [" ^ (String.concat "; " (List.map string_of_int digits)) ^ "])"
  | PLUS          -> "PLUS"
  | MINUS         -> "MINUS"
  | TIMES         -> "TIMES"
  | DIV           -> "DIV"
  | MOD           -> "MOD"
  | EQ            -> "EQ"
  | GT            -> "GT"
  | LT            -> "LT"
  | LEQ           -> "LEQ"
  | GEQ           -> "GEQ"
  | NEQ           -> "NEQ"
  | NOT           -> "NOT"
  | AND           -> "AND"
  | OR            -> "OR"
  | QUOTE_KW      -> "QUOTE_KW"
  | ATOM          -> "ATOM"
  | EQ_KW         -> "EQ_KW"
  | CAR           -> "CAR"
  | CDR           -> "CDR"
  | CONS          -> "CONS"
  | COND          -> "COND"
  | CXR s         -> "CXR(" ^ s ^ ")"
  | LAMBDA        -> "LAMBDA"
  | LABEL         -> "LABEL"
  | DEFUN         -> "DEFUN"
  | IDENT s       -> "IDENT(" ^ s ^ ")"
  | EOF           -> "EOF"
  | BAD_IDENT s   -> "BAD_IDENT(" ^ s ^ ")"
  | BAD_BIGINT s  -> "BAD_BIGINT(" ^ s ^ ")"
  | BAD_DOT s     -> "BAD_DOT(" ^ s ^ ")"
  | COMMENT s     -> "COMMENT(" ^ s ^ ")"
let conv = Assignment2a.BigNum.conv