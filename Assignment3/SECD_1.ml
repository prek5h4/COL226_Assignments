open Ast

type opcode =
  | LOOKUP of var
  | MKCLOS of var * opcode list
  | APP
  | RET
  | PUSH_NUM of int
  | PUSH_BOOL of bool

  (*using list implementation*)
type val_closure = Clo of var * opcode list * env
                  | VNum of int
                  | VBool of bool

and env = (var * val_closure) list (*using list implementation*)

type stack = val_closure  list
type dump  = (stack * env * opcode list) list

(*implementing compiler*)

let rec compile e  = match e with
  | Var x -> [LOOKUP(x)]
  | Lam (x, e) -> [MKCLOS (x, compile e  @ [RET])] (*as fn call add RET*)
  | App (e1, e2) -> compile e1  @ compile e2  @ [APP] (*compile e1, then e2, then apply*)
  | Num n -> [PUSH_NUM n]
  | Bool b -> [PUSH_BOOL b]


let rec lookup_env env x = match env with
  | [] -> failwith ("Unbound variable: " ^ x)
  | (y,v) :: xs -> if x = y then v else lookup_env xs x

let extend env x v = (x, v) :: env

let rec run (s : stack) (gamma : env) (c : opcode list) (d : dump) =
  match c with
  | [] ->
      (match s, d with
       | [v], []  -> v                            (* done *)
       | v :: _, (s', g', c') :: d' ->            (*this case is for when we have a value on the stack and a dump *)
           run (v :: s') g' c' d'
       | _ -> failwith "Stuck")

  | LOOKUP x :: c' ->
      run (lookup_env gamma x :: s) gamma c' d        (* Var rule *)

  | MKCLOS (x, c1) :: c' ->
      run (Clo (x, c1, gamma) :: s) gamma c' d   (* Clos rule *)

  | APP :: c' ->
      (match s with
       | v2 :: Clo (x, c1, gamma1) :: s' ->       (* App rule *)
           run [] (extend gamma1 x v2) c1 ((s', gamma, c') :: d)
       | _ -> failwith "APP: type error")
  
  | PUSH_NUM n :: c' ->
      run (VNum n :: s) gamma c' d

  | PUSH_BOOL b :: c' ->
      run (VBool b :: s) gamma c' d

  | RET :: _ ->
      (match s, d with
       | v :: _, (s', gamma', c') :: d' ->         (* Ret rule *)
           run (v :: s') gamma' c' d'
       | _ -> failwith "RET: empty dump")
  ;;

let rec string_of_val = function (*helper function to convert values to strings*)
  | Clo (x, _, _) -> "<closure λ" ^ x ^ ">"
  | VNum n        -> string_of_int n
  | VBool b       -> string_of_bool b