
(* Stack-based Evaluator for Combinatory Logic *)

(*lambda calculus terms *)
type lam = V of string
          | Lam of string * lam
          | App of lam * lam
;;

(*combinatory logic terms *)
type comb = Vc of string
            | S
            | K
            | I
            | Appc of comb * comb
;;

(* check if a variable occurs free in a comb term *)
let rec occurs_free (x: string) (c: comb) : bool =
  match c with
  | Vc y -> x = y
  | S | K | I -> false
  | Appc (c1, c2) -> occurs_free x c1 || occurs_free x c2
;;

(* Abstraction operation: [x]P 
   - [x]x = I
   - [x]P = KP when x not in vars(P)
   - [x](P1 P2) = S ([x]P1) ([x]P2)
   
   With optimizations:
   - S (K E1) (K E2) = K (E1 E2)
   - S (K E) I = E
   - S I (K E) = E
*)
let rec abs (x: string) (c: comb) : comb =
  match c with
  | Vc y when y = x -> I
  | Vc y -> Appc (K, Vc y)
  | S -> Appc (K, S)
  | K -> Appc (K, K)
  | I -> Appc (K, I)
  | Appc (c1, c2) ->
      if not (occurs_free x c) then
        Appc (K, c)
      else
        let abs_c1 = abs x c1 in
        let abs_c2 = abs x c2 in
        match abs_c1, abs_c2 with
        (* S (K E) I = E *)
        | Appc (K, e), I -> e
        (* S I (K E) = E *)
        | I, Appc (K, e) -> e
        (* S (K E1) (K E2) = K (E1 E2) *)
        | Appc (K, e1), Appc (K, e2) -> Appc (K, Appc (e1, e2))
        (* S ([x]P1) ([x]P2) *)
        | _, _ -> Appc (Appc (S, abs_c1), abs_c2)
;;

(* lambda calculus to combinatory logic 
   - ⌈x⌉ = x
   - ⌈e1 e2⌉ = ⌈e1⌉ ⌈e2⌉
   - ⌈λx.e1⌉ = [x](⌈e1⌉)
*)
let rec trans2CL (e: lam) : comb =
  match e with
  | V x -> Vc x
  | App (e1, e2) -> Appc (trans2CL e1, trans2CL e2)
  | Lam (x, e1) -> abs x (trans2CL e1)
;;

(* 
   One-step reduction rules:
   - (I, c::s) => (c, s)
   - (K, c1::c2::s) => (c1, s)
   - (S, c1::c2::c3::s) => (Appc(Appc(c1,c3), Appc(c2,c3)), s)
   - (Appc(c1,c2), s) => (c1, c2::s)
   
   If none apply, call unstack to rebuild the term
*)
let rec wnf (c: comb) (s: comb list) : comb =
  match c, s with
  | I, c' :: s' -> wnf c' s'
  | K, c1 :: _ :: s' -> wnf c1 s'
  | S, c1 :: c2 :: c3 :: s' -> 
      wnf (Appc (Appc (c1, c3), Appc (c2, c3))) s'
  | Appc (c1, c2), s' -> wnf c1 (c2 :: s')
  | _, _ -> unstack c s

(*rebuild term from stack
   - unstack(c, []) = c
   - unstack(c, c2::rest) = 
       let c' = wnf(c2, []) in
       unstack(Appc(c, c'), rest)
*)
and unstack (c: comb) (s: comb list) : comb =
  match s with
  | [] -> c
  | c2 :: rest ->
      let c' = wnf c2 [] in
      unstack (Appc (c, c')) rest
;;

(* combinatory logic to lambda calculus *)
let rec trans2LC (c: comb) : lam =
  match c with
  | Vc x -> V x
  | I -> Lam ("x", V "x")
  | K -> Lam ("x", Lam ("y", V "x"))
  | S -> Lam ("x", Lam ("y", Lam ("z", 
           App (App (V "x", V "z"), App (V "y", V "z")))))
  | Appc (c1, c2) -> App (trans2LC c1, trans2LC c2)
;;

(* printing functions for testing *)
let rec string_of_lam (e: lam) : string =
  match e with
  | V x -> x
  | Lam (x, e1) -> "(λ" ^ x ^ "." ^ string_of_lam e1 ^ ")"
  | App (e1, e2) -> "(" ^ string_of_lam e1 ^ " " ^ string_of_lam e2 ^ ")"
;;

let rec string_of_comb (c: comb) : string =
  match c with
  | Vc x -> x
  | S -> "S"
  | K -> "K"
  | I -> "I"
  | Appc (c1, c2) -> "(" ^ string_of_comb c1 ^ " " ^ string_of_comb c2 ^ ")"
;;

(* Examples *)
let eval (c: comb) : comb =
  wnf c []
;;

(* Church numerals for testing *)
let zero = Lam ("f", Lam ("x", V "x"));;
let one = Lam ("f", Lam ("x", App (V "f", V "x")));;
let two = Lam ("f", Lam ("x", App (V "f", App (V "f", V "x"))));;
let three = Lam ("f", Lam ("x", App (V "f", App (V "f", App (V "f", V "x")))));;

(* Successor function *)
let succ = Lam ("n", Lam ("f", Lam ("x", 
  App (V "f", App (App (V "n", V "f"), V "x")))));;

(* Addition function *)
let plus = Lam ("m", Lam ("n", Lam ("f", Lam ("x",
  App (App (V "m", V "f"), App (App (V "n", V "f"), V "x"))))));;

(* Multiplication function *)
let mult = Lam ("m", Lam ("n", Lam ("f",
  App (V "m", App (V "n", V "f")))));;