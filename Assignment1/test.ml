#use "Assignment1.ml";;
(* ================================================================
   TEST SUITE (WITH VISUAL OUTPUTS)
   ================================================================
*)

let () = print_endline "\n========================================"
let () = print_endline "STARTING TESTS"
let () = print_endline "========================================\n"

(* Helper for converting association lists to substitution functions *)
let make_sub lst : substitution = fun v -> List.assoc_opt v lst

(* --- PRETTY PRINTERS --- *)
(* These convert your custom tree types into readable strings *)

let rec string_of_exp = function
  | Exp.V v -> v
  | Exp.Node ((sym, _), children) ->
      if Array.length children = 0 then sym
      else
        let child_strs = Array.map string_of_exp children |> Array.to_list in
        sym ^ "(" ^ String.concat ", " child_strs ^ ")"

let rec string_of_pred = function
  | T -> "T"
  | F -> "F"
  | Pred ((sym, _), args) ->
      if Array.length args = 0 then sym
      else
        let arg_strs = Array.map string_of_exp args |> Array.to_list in
        sym ^ "(" ^ String.concat ", " arg_strs ^ ")"
  | Not p -> "~(" ^ string_of_pred p ^ ")"
  | And (p1, p2) -> "(" ^ string_of_pred p1 ^ " /\\ " ^ string_of_pred p2 ^ ")"
  | Or (p1, p2) -> "(" ^ string_of_pred p1 ^ " \\/ " ^ string_of_pred p2 ^ ")"

(* ================================================================
   PART 1 & 2: Basic Validations (Kept silent unless they fail)
   ================================================================ *)
let () =
  print_endline "Running PART 1 & 2 (check_sig, wfexp, ht, size, vars)...";
  assert (check_sig [("f", 2); ("g", 1); ("a", 0)] = true);
  assert (check_sig [("f", 2); ("g", -3)] = false);
  
  let s2 = [("f", 2); ("g", 1); ("a", 0)] in
  let t_node = Exp.Node (("f", 2), [| Exp.Node (("g", 1), [| Exp.V "x" |]); Exp.Node (("a", 0), [||]) |]) in
  assert (Exp.wfexp s2 t_node = true);
  assert (Exp.ht t_node = 3);
  assert (Exp.size t_node = 4);
  print_endline "-> Validations passed!\n"

(* ================================================================
   PART 3: Substitutions & Composition (Now with printouts!)
   ================================================================ *)
let () =
  print_endline "Running PART 3: Substitutions & Edits...";
  let x = Exp.V "x" in
  let y = Exp.V "y" in
  let z = Exp.V "z" in
  let a = Exp.Node (("a", 0), [||]) in
  let b = Exp.Node (("b", 0), [||]) in


  (* 1. Substitution *)
  let s1 = make_sub [("x", Exp.Node (("h", 2), [|b; y|])); ("y", Exp.Node (("g", 1), [|a|]))] in
  let e1 = Exp.Node (("fn", 3), [|Exp.Node (("g", 1), [|x|]); Exp.Node (("h", 2), [|x; y|]); z|]) in
  let res_subst = subst s1 e1 in
  Printf.printf "Original e1: %s\n" (string_of_exp e1);
  Printf.printf "After subst: %s\n\n" (string_of_exp res_subst);

  (* 2. Composition *)
  let s1_comp = make_sub [("x", Exp.Node (("g", 1), [|y|]))] in
  let s2_comp = make_sub [("x", b); ("y", Exp.Node (("h", 2), [|a; b|])); ("z", a)] in
  let e2 = Exp.Node (("h", 2), [|x; z|]) in
  let res_comp = subst (compose s1_comp s2_comp) e2 in
  Printf.printf "Original e2: %s\n" (string_of_exp e2);
  Printf.printf "After comp : %s\n\n" (string_of_exp res_comp);

  (* 3. InPlace Substitution *)
  let e4 = Exp.Node (("f", 2), [|x; Exp.Node (("g", 1), [|x|])|]) in
  let s4 = make_sub [("x", Exp.Node (("g", 1), [|b|]))] in
  Printf.printf "Before inplace: %s\n" (string_of_exp e4);
  let _ = in_place_sub s4 e4 in 
  Printf.printf "After inplace : %s\n\n" (string_of_exp e4)

(* ================================================================
   PART 5: Predicates (Now with printouts!)
   ================================================================ *)
let () =
  print_endline "Running PART 5: Predicates...";
  let x = Exp.V "x" in
  let y = Exp.V "y" in
  let a = Exp.Node (("a", 0), [||]) in
  let b = Exp.Node (("b", 0), [||]) in

  (* Psubst *)
  let s_p = make_sub [("x", Exp.Node (("h", 2), [|b; y|])); ("y", Exp.Node (("g", 1), [|a|]))] in
  let p_p = Or (Pred (("Q", 1), [|x|]), Pred (("P", 2), [|x; y|])) in
  let res_psubst = psubst p_p s_p in
  Printf.printf "Original Pred: %s\n" (string_of_pred p_p);
  Printf.printf "After psubst : %s\n\n" (string_of_pred res_psubst);

  (* Wp *)
  let p_wp = And (Not (Pred (("P", 2), [|x; y|])), Pred (("Q", 1), [|x|])) in
  let sub_exp = Exp.Node (("g", 1), [|b|]) in
  let res_wp = wp "x" sub_exp p_wp in
  Printf.printf "Original Wp Pred: %s\n" (string_of_pred p_wp);
  Printf.printf "After wp(x:=g(b)): %s\n\n" (string_of_pred res_wp);
  
  print_endline "========================================";
  print_endline "ALL TESTS COMPLETED SUCCESSFULLY!";