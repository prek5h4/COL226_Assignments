(* AST types for LITHP *)
open Assignment2a.BigNum

type expr =
  | Num    of bigint
  | Symbol of string
  | Nil
  | Bool   of bool
  | List   of expr list
  | Comment of string

let rec string_of_expr = function
  | Num b      -> pretty_print b
  | Symbol s   -> s
  | Nil        -> "()"
  | Bool true  -> "t"
  | Bool false -> "nil"
  | List es    -> "(" ^ String.concat " " (List.map string_of_expr es) ^ ")"
  | Comment s  -> "; " ^ s
