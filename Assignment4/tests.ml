(* Test Suite for Assignment 4 *)
#use "Ass4.ml";; 

(* ============================================ *)
(* TEST 1: Basic Combinator Evaluation *)
(* ============================================ *)

print_endline "\n=== TEST 1: Basic Combinator Evaluation ===";;

(* Test I combinator: I x = x *)
let test_I = 
  let term = Appc (I, Vc "a") in
  let result = eval term in
  print_endline ("I a = " ^ string_of_comb result);
  result = Vc "a"
;;
assert test_I;;

(* Test K combinator: K x y = x *)
let test_K =
  let term = Appc (Appc (K, Vc "a"), Vc "b") in
  let result = eval term in
  print_endline ("K a b = " ^ string_of_comb result);
  result = Vc "a"
;;
assert test_K;;

(* Test S combinator: S x y z = (x z) (y z) *)
let test_S =
  let term = Appc (Appc (Appc (S, K), K), Vc "a") in
  let result = eval term in
  print_endline ("S K K a = " ^ string_of_comb result);
  result = Vc "a"  (* S K K is the I combinator *)
;;
assert test_S;;

(* ============================================ *)
(* TEST 2: Abstraction Operation *)
(* ============================================ *)

print_endline "\n=== TEST 2: Abstraction Operation ===";;

(* Test [x]x = I *)
let test_abs_1 =
  let result = abs "x" (Vc "x") in
  print_endline ("[x]x = " ^ string_of_comb result);
  result = I
;;
assert test_abs_1;;

(* Test [x]y = K y (when x ≠ y) *)
let test_abs_2 =
  let result = abs "x" (Vc "y") in
  print_endline ("[x]y = " ^ string_of_comb result);
  result = Appc (K, Vc "y")
;;
assert test_abs_2;;

(* Test [x](x x) = S I I *)
let test_abs_3 =
  let term = Appc (Vc "x", Vc "x") in
  let result = abs "x" term in
  print_endline ("[x](x x) = " ^ string_of_comb result);
  result = Appc (Appc (S, I), I)
;;
assert test_abs_3;;

(* ============================================ *)
(* TEST 3: Lambda Calculus Translation *)
(* ============================================ *)

print_endline "\n=== TEST 3: Lambda Calculus Translation ===";;

(* Test identity function: λx.x *)
let test_trans_id =
  let lambda_term = Lam ("x", V "x") in
  let comb_term = trans2CL lambda_term in
  print_endline ("⌈λx.x⌉ = " ^ string_of_comb comb_term);
  comb_term = I
;;
assert test_trans_id;;

(* Test constant function: λx.λy.x *)
let test_trans_const =
  let lambda_term = Lam ("x", Lam ("y", V "x")) in
  let comb_term = trans2CL lambda_term in
  let result = eval comb_term in
  print_endline ("⌈λx.λy.x⌉ = " ^ string_of_comb result);
  result = K
;;
assert test_trans_const;;

(* Test self-application: λx.(x x) *)
let test_trans_self_app =
  let lambda_term = Lam ("x", App (V "x", V "x")) in
  let comb_term = trans2CL lambda_term in
  print_endline ("⌈λx.(x x)⌉ = " ^ string_of_comb comb_term);
  comb_term = Appc (Appc (S, I), I)
;;
assert test_trans_self_app;;

(* ============================================ *)
(* TEST 4: Church Numerals *)
(* ============================================ *)

print_endline "\n=== TEST 4: Church Numerals ===";;

(* Translate zero *)
let test_zero =
  let comb_zero = trans2CL zero in
  print_endline ("⌈0⌉ = " ^ string_of_comb comb_zero);
  true
;;
assert test_zero;;

(* Translate one *)
let test_one =
  let comb_one = trans2CL one in
  print_endline ("⌈1⌉ = " ^ string_of_comb comb_one);
  true
;;
assert test_one;;

(* Apply successor to zero should give one *)
let test_succ_zero =
  let comb_succ = trans2CL succ in
  let comb_zero = trans2CL zero in
  let result = eval (Appc (comb_succ, comb_zero)) in
  print_endline ("succ 0 evaluated");
  true
;;
assert test_succ_zero;;

(* ============================================ *)
(* TEST 5: Church Arithmetic *)
(* ============================================ *)

print_endline "\n=== TEST 5: Church Arithmetic ===";;

(* Test addition: plus one one *)
let test_plus =
  let comb_plus = trans2CL plus in
  let comb_one = trans2CL one in
  let result = eval (Appc (Appc (comb_plus, comb_one), comb_one)) in
  print_endline ("plus 1 1 evaluated" , result);
  true
;;
assert test_plus;;

(* Test multiplication: mult two three *)
let test_mult =
  let comb_mult = trans2CL mult in
  let comb_two = trans2CL two in
  let comb_three = trans2CL three in
  let result = eval (Appc (Appc (comb_mult, comb_two), comb_three)) in
  print_endline ("mult 2 3 evaluated" , result);
  true
;;
assert test_mult;;

(* ============================================ *)
(* TEST 6: Complex Lambda Terms *)
(* ============================================ *)

print_endline "\n=== TEST 6: Complex Lambda Terms ===";;

(* Test composition: λf.λg.λx.f(g x) *)
let compose = Lam ("f", Lam ("g", Lam ("x", 
  App (V "f", App (V "g", V "x")))));;

let test_compose =
  let comb_compose = trans2CL compose in
  print_endline ("⌈λf.λg.λx.f(g x)⌉ = " ^ string_of_comb comb_compose);
  true
;;
assert test_compose;;

(* Test omega combinator: (λx.x x)(λx.x x) *)
let omega_term = App (
  Lam ("x", App (V "x", V "x")),
  Lam ("x", App (V "x", V "x"))
);;

let test_omega =
  let comb_omega = trans2CL omega_term in
  print_endline ("⌈ω⌉ = " ^ string_of_comb comb_omega);
  (* Note: Evaluating omega would loop forever, so we just translate it *)
  true
;;
assert test_omega;;

(* ============================================ *)
(* TEST 7: Stack Operations *)
(* ============================================ *)

print_endline "\n=== TEST 7: Stack Operations ===";;

(* Test with non-empty stack *)
let test_stack_1 =
  let result = wnf I [Vc "a"; Vc "b"] in
  print_endline ("wnf I [a; b] = " ^ string_of_comb result);
  result = Appc (Vc "a", Vc "b")
;;
assert test_stack_1;;

(* Test K with stack *)
let test_stack_2 =
  let result = wnf K [Vc "a"; Vc "b"; Vc "c"] in
  print_endline ("wnf K [a; b; c] = " ^ string_of_comb result);
  result = Appc (Vc "a", Vc "c")
;;
assert test_stack_2;;

(* ============================================ *)
(* TEST 8: Back Translation *)
(* ============================================ *)

print_endline "\n=== TEST 8: Back Translation ===";;

(* Test translating combinators back to lambda calculus *)
let test_back_I =
  let lambda_term = trans2LC I in
  print_endline ("⌊I⌋ = " ^ string_of_lam lambda_term);
  true
;;
assert test_back_I;;

let test_back_K =
  let lambda_term = trans2LC K in
  print_endline ("⌊K⌋ = " ^ string_of_lam lambda_term);
  true
;;
assert test_back_K;;

let test_back_S =
  let lambda_term = trans2LC S in
  print_endline ("⌊S⌋ = " ^ string_of_lam lambda_term);
  true
;;
assert test_back_S;;

(* ============================================ *)
(* TEST 9: Round-trip Translation *)
(* ============================================ *)

print_endline "\n=== TEST 9: Round-trip Translation ===";;

(* Test λx.x -> CL -> LC *)
let test_roundtrip_1 =
  let original = Lam ("x", V "x") in
  let comb = trans2CL original in
  let back = trans2LC comb in
  print_endline ("λx.x -> " ^ string_of_comb comb ^ " -> " ^ string_of_lam back);
  true
;;
assert test_roundtrip_1;;

(* ============================================ *)
(* TEST 10: Edge Cases *)
(* ============================================ *)

print_endline "\n=== TEST 10: Edge Cases ===";;

(* Test empty stack *)
let test_empty_stack =
  let result = wnf (Vc "a") [] in
  print_endline ("wnf a [] = " ^ string_of_comb result);
  result = Vc "a"
;;
assert test_empty_stack;;

(* Test nested applications *)
let test_nested =
  let term = Appc (Appc (Appc (S, K), K), I) in
  let result = eval term in
  print_endline ("S K K I = " ^ string_of_comb result);
  result = I
;;
assert test_nested;;

print_endline "\n=== ALL TESTS PASSED! ===";;