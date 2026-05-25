open Ast

(* ============================================================
   HELPER: pretty-print an expr for readable output
   ============================================================ *)
let rec string_of_expr = function
  | Var x        -> x
  | Lam (x, e)   -> "(λ" ^ x ^ ". " ^ string_of_expr e ^ ")"
  | App (e1, e2) -> "(" ^ string_of_expr e1 ^ " " ^ string_of_expr e2 ^ ")"
  | Num n        -> string_of_int n
  | Bool b       -> string_of_bool b

(* ============================================================
   CHURCH ENCODINGS  (shared by both machines)
   ============================================================ *)

let church_true  = Lam ("t", Lam ("f", Var "t"))
let church_false = Lam ("t", Lam ("f", Var "f"))
let church_if    = Lam ("b", Lam ("t", Lam ("f",
                     App (App (Var "b", Var "t"), Var "f"))))
let church_pair  = Lam ("x", Lam ("y", Lam ("f",
                     App (App (Var "f", Var "x"), Var "y"))))
let church_fst   = Lam ("p", App (Var "p", church_true))
let church_snd   = Lam ("p", App (Var "p", church_false))
let church_id    = Lam ("x", Var "x")

(* ============================================================
   TEST EXPRESSIONS
   ============================================================ *)

let test1 = App (church_id, Lam ("y", Var "y"))
let test2 = App (App (App (church_if, church_true),
                      Lam ("x", Var "x")),
                      Lam ("y", Var "y"))
let test3 = App (App (App (church_if, church_false),
                      Lam ("x", Var "x")),
                      Lam ("y", Var "y"))
let test4 = App (church_fst,
                 App (App (church_pair, Lam ("x", Var "x")),
                                        Lam ("y", Var "y")))
let test5 = App (church_snd,
                 App (App (church_pair, Lam ("x", Var "x")),
                                        Lam ("y", Var "y")))
let test6 = App (App (Lam ("x", Lam ("y", Var "x")),
                      Lam ("a", Var "a")),
                      Lam ("b", Var "b"))
let test7 = Num 42
let test8 = Bool true

(* ============================================================
   SHARED TEST RUNNER HELPER
   ============================================================ *)

let test_cases = [
  ("Identity applied to identity",   test1);
  ("Church if-true  (expect λx.x)",  test2);
  ("Church if-false (expect λy.y)",  test3);
  ("fst of pair     (expect λx.x)",  test4);
  ("snd of pair     (expect λy.y)",  test5);
  ("Constant fn K A B (expect λa.a)", test6);
  ("Num literal 42",                  test7);
  ("Bool literal true",               test8);
]

(* ============================================================
   KRIVINE_1 TESTS  (list-based env)
   ============================================================ *)
let () =
  Printf.printf "========== KRIVINE MACHINE 1 (list env) ==========\n\n";
  List.iter (fun (name, expr) ->
    Printf.printf "Test: %s\n" name;
    Printf.printf "Input:  %s\n" (string_of_expr expr);
    let init_closure = Krivine_1.Clo (expr, []) in
    let result   = Krivine_1.run (init_closure, []) in
    let unpacked = Krivine_1.unpack result in
    Printf.printf "Result: %s\n\n" (string_of_expr unpacked)
  ) test_cases

(* ============================================================
   KRIVINE_2 TESTS  (function-based env)
   ============================================================ *)
let () =
  Printf.printf "========== KRIVINE MACHINE 2 (function env) ==========\n\n";
  List.iter (fun (name, expr) ->
    Printf.printf "Test: %s\n" name;
    Printf.printf "Input:  %s\n" (string_of_expr expr);
    let init_closure = Krivine_2.Clo (expr, Krivine_2.empty_env) in
    let result   = Krivine_2.run (init_closure, []) in
    let unpacked = Krivine_2.unpack result in
    Printf.printf "Result: %s\n\n" (string_of_expr unpacked)
  ) test_cases

(* ============================================================
   SECD_1 TESTS  (list-based env)
   ============================================================ *)
let () =
  Printf.printf "========== SECD MACHINE 1 (list env) ==========\n\n";
  List.iter (fun (name, expr) ->
    Printf.printf "Test: %s\n" name;
    Printf.printf "Input:  %s\n" (string_of_expr expr);
    let code   = SECD_1.compile expr in
    let result = SECD_1.run [] [] code [] in
    Printf.printf "Result: %s\n\n" (SECD_1.string_of_val result)
  ) test_cases

(* ============================================================
   SECD_2 TESTS  (function-based env)
   ============================================================ *)
let () =
  Printf.printf "========== SECD MACHINE 2 (function env) ==========\n\n";
  List.iter (fun (name, expr) ->
    Printf.printf "Test: %s\n" name;
    Printf.printf "Input:  %s\n" (string_of_expr expr);
    let code   = SECD_2.compile expr in
    let result = SECD_2.run [] SECD_2.empty_env code [] in
    Printf.printf "Result: %s\n\n" (SECD_2.string_of_val result)
  ) test_cases