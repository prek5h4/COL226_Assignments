open Ast

(*using list implementation*)
type closure = Clo of expr * env
and env = (var * closure) list
type stack = closure list

(*lookup function*)
let rec lookup gamma x = match gamma with
  | [] -> failwith ("Unbound variable: " ^ x)
  | (y,valu)::xs -> if x = y then valu 
                    else lookup xs x
;;

let extend gamma x v = (x, v) :: gamma
;;

(*IMPLEMENTING THE RULES*)

(* <<x,gamma>> ---> gamma(x)  *)
let rule_var = function
  | (Clo (Var x, gamma), stack) -> (lookup gamma x, stack)
  | _ -> failwith "Variable not found";;

(* <<app (e1,e2) >>:stack ---> <<e1,gamma>>, <<e2,gamma>> :: stack *)
let rule_app = function
  | (Clo (App (e1, e2), gamma), stack) -> (Clo (e1, gamma), Clo (e2, gamma) :: stack)
  | _ -> failwith "Application rule not applicable";;

(* <<lam (x,e) >>:v :: stack ---> <<e, gamma[x->v]>>, stack *)
let rule_lam = function
  | (Clo (Lam (x, e), gamma), v :: stack) -> (Clo (e, extend gamma x v), stack)
  | _ -> failwith "Lambda rule not applicable"
;;


(*MAIN RUN LOOP*)

let rec run (closure, stack) =
  match (closure, stack) with

  | (Clo (Var x, gamma), s) -> run (rule_var (Clo (Var x, gamma), s))

  | (Clo (App (e1,e2), gamma), s) -> run (rule_app (Clo (App (e1,e2), gamma), s))

  | (Clo (Lam (x,e), gamma), v::s) -> run (rule_lam (Clo (Lam (x,e), gamma), v::s))

  | (Clo (Lam _, _), []) -> closure      

  | (Clo (Num _, _), []) ->closure

  | (Clo (Bool _, _), []) -> closure

  | (Clo(Num _, _), _ :: _) -> failwith "Cannot apply a number"

  | (Clo(Bool _, _), _ :: _) -> failwith "Cannot apply a boolean"
;;

(*unpack fns*)
(*converts resulting closure to a value*)
let rec unpack (Clo (e, gamma)) =
  match e with
  | Num n  -> Num n
  | Bool b -> Bool b
  | Var x  ->
      (match List.assoc_opt x gamma with
       | Some cl -> unpack cl
       | None    -> Var x)
  | App (e1, e2) ->
      App (unpack (Clo (e1, gamma)), unpack (Clo (e2, gamma)))
  | Lam (x, body) ->
      let gamma' = List.filter (fun (y, _) -> y <> x) gamma in
      Lam (x, unpack (Clo (body, gamma')))
  ;;

let rec string_of_expr = function
  | Var x        -> x
  | Lam (x, e)   -> "(λ" ^ x ^ ". " ^ string_of_expr e ^ ")"
  | App (e1, e2) -> "(" ^ string_of_expr e1 ^ " " ^ string_of_expr e2 ^ ")"
  | Num n        -> string_of_int n
  | Bool b       -> string_of_bool b

let string_of_result cl = string_of_expr (unpack cl)