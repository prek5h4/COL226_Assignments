(*
  REPRESENTING ARBITRARY SIGNATURES IN OCAML
*)

open List;;
module SMap = Map.Make(String)
(* A symbol consists of a name and its arity (number of arguments) *)
type symbol = string * int;;

(* A signature is a list of symbols defining the function symbols available *)
type signature = symbol list;;

(* Variables are represented as strings *)
type variable = string;;

(**
 * SIGNATURE UTILITIES
 *)

let sig_map (s: signature) : int SMap.t =
  List.fold_left (fun acc (name, arity) -> SMap.add name arity acc) SMap.empty s
;;
(*
 Checks if a signature has duplicate function names.
 Returns true if no duplicates exist, false otherwise.
 *)
let check_duplicates (s: signature) : bool = 
  let rec aux seen = function
    | [] -> true
    | (name, _) :: xs ->
        if List.mem name seen then
          false  (* Found duplicate *)
        else
          aux (name :: seen) xs  (* Add name to seen list *)
  in
  aux [] s
;;

(*
Checks if any symbol in the signature has negative arity.
Returns true if any negative arity is found, false otherwise.
Time Complexity: O(n) where n = number of symbols
*)
let has_negative_arity sig_map =
  SMap.exists (fun _ arity -> arity < 0) sig_map
;;

(*
check_sig: signature -> bool

Validates a signature by checking:
1. No duplicate function names
2. No negative arities

Time Complexity: O(n²) where n = length of signature
*)
let check_sig (s : signature) : bool =
  check_duplicates s &&
  let t = sig_map s in
  not (has_negative_arity t)
;;

(*
Returns the arity of a given function name in the signature.
Raises Not_found if the name doesn't exist in the signature.

Time Complexity: O(n) where n = length of signature
*)
let arity_of (s : signature) name =
  List.assoc name s;;

(*
  EXPRESSION MODULE
*)

module Exp = struct
  type t = V of variable | Node of symbol * t array

(*
Well-formed means:
1. All function symbols have correct arity matching the signature
2. Number of children matches the arity
3. All children are recursively well-formed 
Time Complexity: O(n) where n = total number of nodes in expression tree
*)
let wfexp (s : signature) (e : t) : bool =
  let rec aux = function
    | V _ -> true  (* Variables are always well-formed *)
    | Node ((name, arity), children) ->
        try  (* Check arity matches signature *)
          if arity_of s name <> arity then
            false  (* Check number of children matches arity *)
          else if Array.length children <> arity then
            false  (* Recursively check all children *)
          else
            Array.for_all aux children
        with Not_found -> 
          false  (* Symbol not in signature, so not well-formed *)
    in
  aux e
;;

(*
Computes the height of an expression tree
Time Complexity: O(n) where n = number of nodes
*)
  let rec ht (e : t) : int = match e with
    | V _ -> 1 
    | Node (_, children) ->
        1 + (Array.fold_left (max) 0 (Array.map ht children))
  ;;

  (*
  Computes the size of an expression tree (total number of nodes).
  
  Time Complexity: O(n) where n = number of nodes
  *)
  let rec size (e: t) : int = match e with
   | V _-> 1
   | Node (_, children) ->
        1 + (Array.fold_left (+) 0 (Array.map size children))
  ;;

  (*
  Collects all distinct variables in the expression.
  Uses a hash table to eliminate duplicates efficiently.
  Time Complexity: O(n) where n = number of nodes
  *)
  let vars (e: t) : variable array =
    let seen = Hashtbl.create 10 in
    let rec aux = function
      | V v -> Hashtbl.replace seen v ();  (* Mark variable as seen *)
      | Node (_, children) ->
          Array.iter aux children  (* Recursively process children *)
    in
    aux e;
    (* Collect all unique variables from hash table *)
    Array.of_list (Hashtbl.fold (fun k _ acc -> k :: acc) seen [])
  ;;
end

(*
  SUBSTITUTIONS
*)

type exp = Exp.t;;

(*
Substitution is a function mapping variables to optional expressions.
None means the variable is not substituted.
*)
type substitution = variable -> exp option;;

(*
subst: substitution -> exp -> exp
*Applies a substitution to an expression.
*Recursively replaces variables according to the substitution function.
Time Complexity: O(n) where n = number of nodes in the expression tree
*)
let subst (sub : substitution) (e:exp) : exp =
  let rec aux = function
    | Exp.V v -> 
        (match sub v with 
        | Some e' -> e'  (* Replace with substitution *)
        | None -> Exp.V v)  (* Keep original variable *)
    | Exp.Node (sym , children) ->
        (* Recursively apply to all children *)
        Exp.Node (sym, Array.map aux children)
  in
  aux e 
;;

(*
compose: substitution -> substitution -> substitution
Composes two substitutions.
Time Complexity: O(1) to create the composed substitution function
*)
let rec compose (s1 : substitution) (s2 : substitution) : substitution =
  fun v ->
    match s1 v with
    | Some e ->  Some (subst s2 e)  (* Apply s2 to result of s1 *)
    | None -> s2 v  (* If s1 doesn't substitute, try s2 *)
;;

(**
 * Position is a path through an expression tree.
 * Empty list [] represents the root.
 * [i, j, k] represents: go to i-th child, then j-th child, then k-th child.
 * Indices are 1-based.
 *)
type position = int list

(*
positions: exp -> exp -> position list
 *Finds all positions where a sub-expression occurs in an expression.
 *Returns a list of paths (positions) to each occurrence.
Time Complexity: O(n × m) where n = size of e, m = size of sub_exp
*)
let positions (e : exp) (sub_exp : exp) : position list =
  let rec aux e path =
    (* Check if current expression matches sub_exp *)
    let here =
      if e = sub_exp then [List.rev path] else []
    in
    match e with
    | Exp.V _ -> here
    | Exp.Node (_, children) ->
        (* Combine current match with matches in children *)
        here @
        (Array.to_list(Array.mapi (fun i child -> 
          aux child (i + 1 :: path)  (* 1-based indexing *)
        ) children) |> List.flatten) 
    in
  aux e []
;;     

(*
 Replaces the sub-expression at the given position with a new expression.
Returns a new expression tree with the replacement.

Time Complexity: O(n + d) where n = size of expression, d = depth of position
*)
 let edit (e : exp) (pos : position) (new_exp : exp) : exp option =
  let rec aux e path =
    match (e, path) with
    | (_, []) -> Some new_exp  (* Reached target position, replace with new_exp *)
    | (Exp.Node (sym, children), i :: xs) when i >= 1 && i <= Array.length children ->
        (match aux children.(i - 1) xs with
         | None -> None
         | Some upd_child ->
             let new_children = Array.copy children in (*edits the array*)
             new_children.(i - 1) <- upd_child;
             Some (Exp.Node (sym, new_children)))
    | _ -> None  (*error handling*)
  in
  aux e pos
;;

(*
Applies substitution IN PLACE (mutating the array).
 *Time Complexity: O(n) where n = number of nodes
 * - Each node is visited once
*)
let rec in_place_sub (s : substitution) (e : exp) : exp =
    match e with
    | Exp.V v -> 
        (match s v with 
        | Some e' -> e'
        | None -> Exp.V v)
    | Exp.Node (sym, args) ->
        (* Mutate array elements in place *)
        let rec aux i =
            if i < Array.length args then begin
                args.(i) <- in_place_sub s args.(i);
                aux (i + 1)
            end
        in
        aux 0;
        e  
;;

(* 
  PREDICATES
*)
type pred_symbol = string * int;;

type pred = 
  | T 
  | F  
  | Pred of pred_symbol * (exp array) 
  | Not of pred 
  | And of pred * pred 
  | Or of pred * pred;;

(*
Checks if a predicate is a well-formed formula with respect to a signature.
Well-formed means:
 1. T and F are always well-formed
 2. Predicate symbols have correct arity
 3. All argument expressions are well-formed
 4. All sub-formulas are well-formed
 Time Complexity: O(p × e) where p = size of predicate, e = avg expression size
*)
let wff (s : signature) (p : pred) : bool =
  let rec aux = function
    | T | F -> true  (* Constants are always well-formed *)
    | Pred ((name, arity), args) ->
        (* Check arity matches signature *)
        if arity_of s name <> arity then
          false
        (* Check number of arguments matches arity *)
        else if Array.length args <> arity then
          false
        (* Check all argument expressions are well-formed *)
        else
          Array.for_all (Exp.wfexp s) args
    | Not p1 -> aux p1
    | And (p1, p2) -> aux p1 && aux p2
    | Or (p1, p2) -> aux p1 || aux p2
  in
  aux p
;;

(*
Applies a substitution to all expressions in a predicate.
Returns a new predicate with substitutions applied.

Time Complexity: O(p × e) where p = size of predicate, e = avg expression size
*)
let psubst (p: pred) (s : substitution) : pred =
  let rec aux = function
    | T -> T
    | F -> F
    | Pred (sym, args) -> 
        (* Apply substitution to all arguments *)
        Pred (sym, Array.map (subst s) args)
    | Not p1 -> Not (aux p1)
    | And (p1, p2) -> And (aux p1, aux p2)
    | Or (p1, p2) -> Or (aux p1, aux p2)
  in
  aux p
;;

(*
 * wp: variable -> exp -> pred -> pred
This is equivalent to p[x := e] in logical notation.

Time Complexity: O(p × e) where p = size of predicate, e = size of expression
*)
let wp (x : variable) (e:exp)(p: pred) : pred =
  (* Create substitution that only replaces x *)
  let s : substitution = fun v -> 
    if v = x then 
      Some e 
    else None 
  in
  psubst p s
;;

(*
  TIME COMPLEXITY SUMMARY
  
  Signature Operations:
  - arity_of: O(n) - linear search
  
  Expression Operations:
  - wfexp: O(n) - tree traversal
  - ht: O(n) - tree traversal
  - size: O(n) - tree traversal
  - vars: O(n) - tree traversal with deduplication
  
  Substitution Operations:
  - subst: O(n) - tree traversal
  - compose: O(1) to create, O(e) per application
  - in_place_sub: O(n) - tree traversal with mutation
  
  Position Operations:
  - positions: O(n × m) - comparing at each node
  - edit: O(d) - path traversal
  
  Predicate Operations:
  - wff: O(p × e) - predicate traversal with expression checking
  - psubst: O(p × e) - predicate traversal with substitution
  - wp: O(p × e) - wrapper around psubst
  
  where:
  - n = size of expression tree
  - m = size of sub-expression
  - p = size of predicate formula
  - e = average expression size
  - d = depth of position ath
*)

