
type var = string

type expr =
  | Var of var
  | Lam of var * expr
  | App of expr * expr
  | Num of int
  | Bool of bool


