open Ast

(* function-based environment implementation *)
type closure = Clo of expr * env
and env = var -> closure

(* empty environment which raises error if any variable looked up *)
let empty_env = fun x -> failwith ("Unbound variable: " ^ x)

(* lookup: just apply the function *)
let lookup gamma x = gamma x

(* return a new function that checks x first *)
let extend gamma x v = fun y -> if y = x then v else gamma y

(* (Var) <<x, gamma>>, S  =>  gamma(x), S *)
let rule_var input = match input with
  | (Clo (Var x, gamma), stack) -> (lookup gamma x, stack)
  | _ -> failwith "rule_var: not a variable"

let rule_app input = match input with
  | (Clo (App (e1, e2), gamma), stack) -> (Clo (e1, gamma), Clo (e2, gamma) :: stack)
  | _ -> failwith "rule_app: not an application"

let rule_lam input = match input with
  | (Clo (Lam (x, e), gamma), v :: stack) -> (Clo (e, extend gamma x v), stack)
  | (_, []) -> failwith "rule_lam: empty stack"
  | _ ->       failwith "rule_lam: not a lambda"

let rec run (closure, stack) =
  match (closure, stack) with
  | (Clo (Var _, _), s)         -> run (rule_var (closure, s))
  | (Clo (App _, _), s)         -> run (rule_app (closure, s))
  | (Clo (Lam _, _), _ :: _)    -> run (rule_lam (closure, stack))

  (*  normal forms *)
  | (Clo (Lam _, _),  [])       -> closure
  | (Clo (Num _, _),  [])       -> closure
  | (Clo (Bool _, _), [])       -> closure

  (* error states *)
  | (Clo (Num _, _),  _ :: _)   -> failwith "Cannot apply a number"
  | (Clo (Bool _, _), _ :: _)   -> failwith "Cannot apply a boolean"

(* UNPACK
   converts resulting closure back into a lambda term. *)
let rec unpack (Clo (e, gamma)) =
  match e with
  | Num n  -> Num n
  | Bool b -> Bool b

  | Var x ->
      (* looking up x  if unbound it's a free variable so leave it *)
      (try unpack (lookup gamma x)
       with Failure _ -> Var x)

  | App (e1, e2) ->
      App (unpack (Clo (e1, gamma)),
           unpack (Clo (e2, gamma)))

  | Lam (x, body) ->
      (* shadow x in gamma so we don't substitute the bound variable *)
      let gamma' = extend gamma x (Clo (Var x, empty_env)) in
      Lam (x, unpack (Clo (body, gamma')))

(*helper function to convert expressions to strings*)
let rec string_of_expr = function
  | Var x        -> x
  | Lam (x, e)   -> "(λ" ^ x ^ ". " ^ string_of_expr e ^ ")"
  | App (e1, e2) -> "(" ^ string_of_expr e1 ^ " " ^ string_of_expr e2 ^ ")"
  | Num n        -> string_of_int n
  | Bool b       -> string_of_bool b

let string_of_result cl = string_of_expr (unpack cl)