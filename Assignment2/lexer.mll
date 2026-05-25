{
    open Parser
    let conv = Assignment2a.BigNum.conv
}

let white       = [' ' '\t' '\n' '\r']+
let digit       = ['0'-'9']
let integer     = '-'? digit+
let alpha       = ['a'-'z' 'A'-'Z']
let ident       = alpha (alpha | digit | '_')* '.'?
let cxr         = 'c' ['a' 'd']+ 'r'
let bad_integer = '-'? digit+ (alpha | '_')+
let bad_ident   = alpha (alpha | digit | '_')* '.' (alpha | digit)+
let bad_dot     = alpha+ ('.' '.'+ alpha*)+
let comment     = ';'+ [^ '\n']* '\n'?


rule token = parse
  | white          { token lexbuf }
  | comment        { token lexbuf }   (* skip comments, never send to parser *)

  | "()"           { NIL }
  | "("            { LPAREN }
  | ")"            { RPAREN }
  | "'"            { QUOTE }

  | "=/="          { NEQ }
  | "<="           { LEQ }
  | ">="           { GEQ }
  | "="            { EQ }
  | "<"            { LT }
  | ">"            { GT }

  | "+"            { PLUS }
  | "*"            { TIMES }
  | "-"            { MINUS }
  | "div"          { DIV }
  | "mod"          { MOD }

  | bad_integer    {
        let s = Lexing.lexeme lexbuf in
        Printf.eprintf "Warning: bad integer '%s', skipping\n" s;
        token lexbuf }

  | integer        {
        let s = Lexing.lexeme lexbuf in
        BIGINT (Assignment2a.BigNum.bigint_of_string s) }

  | cxr            { CXR (Lexing.lexeme lexbuf) }
  | bad_dot        {
        let s = Lexing.lexeme lexbuf in
        Printf.eprintf "Warning: bad identifier (multiple dots) '%s', skipping\n" s;
        token lexbuf }
  | bad_ident      {
        let s = Lexing.lexeme lexbuf in
        Printf.eprintf "Warning: bad identifier '%s', skipping\n" s;
        token lexbuf }

  | ident          { match Lexing.lexeme lexbuf with
                     | "t"      -> TRUE
                     | "quote"  -> QUOTE_KW
                     | "atom"   -> ATOM
                     | "eq"     -> EQ_KW
                     | "car"    -> CAR
                     | "cdr"    -> CDR
                     | "cons"   -> CONS
                     | "cond"   -> COND
                     | "lambda" -> LAMBDA
                     | "label"  -> LABEL
                     | "defun"  -> DEFUN
                     | "not"    -> NOT
                     | "and"    -> AND
                     | "or"     -> OR
                     | s        -> IDENT s }

  | eof            { EOF }

(* 'token_lex' is used by lex mode only *)
and token_lex = parse
  | white          { token_lex lexbuf }
  | comment        { COMMENT (Lexing.lexeme lexbuf) }

  | "()"           { NIL }
  | "("            { LPAREN }
  | ")"            { RPAREN }
  | "'"            { QUOTE }

  | "=/="          { NEQ }
  | "<="           { LEQ }
  | ">="           { GEQ }
  | "="            { EQ }
  | "<"            { LT }
  | ">"            { GT }

  | "+"            { PLUS }
  | "*"            { TIMES }
  | "-"            { MINUS }
  | "div"          { DIV }
  | "mod"          { MOD }

  | bad_integer    { BAD_BIGINT (Lexing.lexeme lexbuf) }

  | integer        {
        let s = Lexing.lexeme lexbuf in
        BIGINT (Assignment2a.BigNum.bigint_of_string s) }

  | cxr            { CXR (Lexing.lexeme lexbuf) }
  | bad_dot        { BAD_DOT (Lexing.lexeme lexbuf) }
  | bad_ident      { BAD_IDENT (Lexing.lexeme lexbuf) }

  | ident          { match Lexing.lexeme lexbuf with
                     | "t"      -> TRUE
                     | "quote"  -> QUOTE_KW
                     | "atom"   -> ATOM
                     | "eq"     -> EQ_KW
                     | "car"    -> CAR
                     | "cdr"    -> CDR
                     | "cons"   -> CONS
                     | "cond"   -> COND
                     | "lambda" -> LAMBDA
                     | "label"  -> LABEL
                     | "defun"  -> DEFUN
                     | "not"    -> NOT
                     | "and"    -> AND
                     | "or"     -> OR
                     | s        -> IDENT s }

  | eof   { EOF }