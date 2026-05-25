open Env
open Types

type expr = Ast.expr
type expr_list = Ast.expr list

(* Helper functions *)
(* Compares two LITHP types, treating TAny as compatible with everything. *)
let rec types_equal t1 t2 = match (t1, t2) with
  | (TInt, TInt) -> true
  | (TBool, TBool) -> true
  | (TAny, _) | (_, TAny) -> true
  | (TList n1, TList n2) -> n1 = n2
  | (TFun (args1, ret1), TFun (args2, ret2)) -> 
      List.length args1 = List.length args2 && 
      List.for_all2 types_equal args1 args2 && 
      types_equal ret1 ret2
  | (TSymbol, TSymbol) -> true
  | _ -> false

let global_env : (string * lithp_type list) list ref = ref []
(* Checks whether a type is a list type. *)
let is_list_type = function
  | TList _ -> true
  | _ -> false

(* Returns the encoded length of a list type, or 0 for non-lists. *)
let list_length = function
  | TList n -> n
  | _ -> 0

(* Extends an environment with one parameter bound to a singleton type list. *)
let extend_param name typ env =
  (name, [typ]) :: env

(* Extends an environment with a typed value payload (if used by callers). *)
let extend_with_value name typ value env =
  (name, (typ, Some value)) :: env

(* Registers a top-level function name and its inferred type(s). *)
let register_function name types =
  global_env := (name, types) :: !global_env
 
(* Looks up a function type in the global function environment. *)
let lookup_global name =
  try
    Some (List.assoc name !global_env)
  with Not_found -> None

(* Extracts lambda arity from an expression, defaulting to 1 when unknown. *)
let get_lambda_arity expr = match expr with
  | Ast.List (Ast.Symbol "lambda" :: Ast.List params :: _) -> List.length params
  | Ast.List (Ast.Symbol "lambda" :: Ast.Nil :: _) -> 0
  | _ -> 1 
  
(*check functions*)
(* Infers the type(s) produced by quote forms. *)
let check_quote env args = match args with
  | [Ast.List es] -> [TList (List.length es)]
  | [Ast.Num _] -> [TInt]
  | [Ast.Bool _] -> [TSymbol]
  | [Ast.Symbol _] -> [TSymbol]
  | [Ast.Nil] -> [TList 0]
  | _ -> []

(* atom always produces a boolean when called with one argument. *)
let check_atom env args = match args with
  | [x] -> [TBool]
  | _ -> []

(* Resolves a symbol from local env first, then global function env. *)
let rec lookup_with_global name env =
  try 
    List.assoc name env
  with Not_found ->
    match lookup_global name with
    | Some types -> types
    | None -> failwith ("Unbound variable: " ^ name)

(* eq returns Bool when both arguments have at least one compatible type. *)
let rec check_eq env args = match args with
  | [x; y] -> 
    let tx = infer env x in
    let ty = infer env y in
    let compatible = List.exists (fun t1 ->
      List.exists (fun t2 -> types_equal t1 t2) ty) tx in
    if compatible then [TBool] else []
  | _ -> []

(* car checks list-ness and returns possible head element types. *)
and check_car env args = match args with
  | [x] ->
      let inferred_types = infer env x in
      (match List.find_opt (function 
        | TList n when n > 0 -> true
        | _ -> false) inferred_types with
       | Some _ -> [TInt; TBool; TList 0]  
       | None -> failwith "car expects a non-empty list")
  | _ -> failwith "car expects exactly one argument"
 (* cdr returns the tail list type for non-empty lists. *)
 and check_cdr env args = match args with
  | [x] ->
      let inferred_types = infer env x in
      (match List.find_opt (function 
        | TList n when n > 0 -> true 
        | TAny -> true         (* ← FIX #4: Accept TAny *)
        | _ -> false) inferred_types with
       | Some (TList n) -> [TList (n - 1)]
       | Some TAny -> [TAny]  (* ← FIX #4: Return TAny *)
       | _ -> failwith "cdr expects a non-empty list argument")
  | _ -> failwith "cdr expects exactly one argument"
 
 (* caddr validates list length >= 3 and returns the third element type. *)
 and check_caddr env args = match args with
   | [x] ->
       let inferred_types = infer env x in
       (match List.find_opt (function TList n when n >= 3 -> true | _ -> false) inferred_types with
        | Some (TList n) -> [TAny]
       | _ -> failwith "caddr expects a list of length at least 3")
   | _ -> failwith "caddr expects exactly one argument"
 
  (* cddr validates list length >= 2 and returns the list after two drops. *)
  and check_cddr env args = match args with
   | [x] ->
       let inferred_types = infer env x in
       (match List.find_opt (function TList n when n >= 2 -> true | _ -> false) inferred_types with
        | Some (TList n) -> [TList (n - 2)]
       | _ -> failwith "cddr expects a list of length at least 2")
   | _ -> failwith "cddr expects exactly one argument"

 (* cons prepends one element to a list and updates list length type. *)
 and check_cons env args = match args with
   | [x; y] ->
       let inferred_types = infer env y in
       (match List.find_opt is_list_type inferred_types with
        | Some (TList n) -> [TList (n + 1)]
        | _ -> if List.exists (fun t-> t = TAny) inferred_types then
            [TList 1] 
          else failwith "cons expects second argument to be a list")
    | _ -> failwith "cons expects exactly two arguments"
   
(* cond collects result types from clauses whose test can be truthy. *)
and check_cond env args = match args with
  | [] -> failwith "cond expects at least one clause"
  | clauses -> 
      let result_types = List.concat (List.map (fun clause -> match clause with
        | Ast.List [test; result_expr] ->
            let test_types = infer env test in
            if List.exists (fun t->
              match t with 
              | TBool -> true
              | TSymbol -> true
              | TList n when n> 0 -> true 
              | _ -> false ) test_types 
              then infer env result_expr
              else []
        | _ -> []) clauses) in
      (match result_types with
       | [] -> failwith "cond clauses must have valid test and result expressions"
       | types -> List.sort_uniq compare types)

(* Typechecks arithmetic operators and enforces integer arguments. *)
and check_arith_op env op args =
  let all_int = List.for_all (fun arg -> List.exists (fun t -> types_equal t TInt) (infer env arg)) args in
  match op with 
  | "+" | "*" ->
    if List.length args >= 2 && all_int then [TInt] else []
  | "-" | "div" | "mod" ->
    if List.length args = 2 && all_int then [TInt] else []
  | _ -> failwith "Unknown arithmetic operator"

(* Wrapper that dispatches arithmetic checking from an AST argument list. *)
and check_arith env args = match args with
  | Ast.Symbol op :: rest -> check_arith_op env op rest
  | _ -> failwith "Arithmetic check expects operator followed by arguments"

(* Typechecks comparison operators and returns Bool when valid. *)
and check_compare_op env op args = match op with
  | ">" | "<" | ">=" | "<=" -> (match args with
      | x :: y :: _ -> if List.for_all (fun arg -> List.exists (fun t -> types_equal t TInt) (infer env arg)) args then [TBool] else failwith (op ^ " expects integer arguments")
      | _ -> failwith (op ^ " expects at least two arguments"))
  | _ -> failwith ("Unknown comparison operator: " ^ op)

(* Wrapper that dispatches comparison checking from an AST argument list. *)
and check_compare env args = match args with
  | Ast.Symbol op :: rest -> check_compare_op env op rest
  | _ -> failwith "Comparison check expects operator followed by arguments"

(* Typechecks logical operators over boolean arguments. *)
and check_logic_op env op args = match op with
  | "not" -> (match args with
      | [x] -> if List.exists (fun t -> types_equal t TBool) (infer env x) then [TBool] else failwith "not expects a boolean argument"
      | _ -> failwith "not expects exactly one argument")
  | "and" | "or" -> (match args with
      | [x; y] -> if List.for_all (fun arg -> List.exists (fun t -> types_equal t TBool) (infer env arg)) args then [TBool] else failwith (op ^ " expects all arguments to be booleans")
      | _ -> failwith (op ^ " expects exactly two arguments"))

  | _ -> failwith ("Unknown logical operator: " ^ op)

(* Wrapper that dispatches logic checking from an AST argument list. *)
and check_logic env args = match args with
  | Ast.Symbol op :: rest -> check_logic_op env op rest
  | _ -> failwith "Logic check expects operator followed by arguments"

(* Builds function type(s) for lambda expressions from body inference. *)
and check_lambda env args = match args with
  | [Ast.List params; body] -> 
      let param_types = List.map (fun param -> match param with
        | Ast.Symbol name -> (name, TAny)
        | _ -> failwith "lambda parameters must be symbols") params in
      let new_env = List.fold_left (fun acc (name, t) -> 
        extend_param name t acc) env param_types in
      let body_types = infer new_env body in
      List.map (fun ret_type -> TFun (List.map snd param_types, ret_type)) body_types
  | [Ast.Nil; body] ->
      let body_types = infer env body in
      List.map (fun ret_type -> TFun ([], ret_type)) body_types
  | _ -> failwith "lambda expects a parameter list and a body"

(* Typechecks label by registering and validating a named function expression. *)
and check_label env args = match args with 
  | [Ast.Nil; body] ->
    let body_types = infer env body in
    List.map (fun ret_type -> TFun ([], ret_type)) body_types
  | [Ast.Symbol name; func_expr] ->
      let arity = get_lambda_arity func_expr in
      let placeholder = TFun (List.init arity (fun _ -> TAny), TAny) in
      register_function name [placeholder];
      
      let func_types = infer env func_expr in
      (match List.find_opt (function TFun _ -> true | _ -> false) func_types with
       | Some (TFun _ as fn_type) -> 
           register_function name [fn_type];  
           [fn_type]
       | _ -> failwith "label requires a function expression")
  | _ -> failwith "label expects a name and function"

 (* Typechecks defun, supporting recursion via placeholder then concrete type. *)
 and check_defun env args = match args with 
  | [Ast.Symbol name; Ast.Nil; body] ->
    let fn_type_placeholder = TFun ([], TAny) in
    register_function name [fn_type_placeholder];
    let env_with_fn = (name, [fn_type_placeholder]) :: env in
    let body_types = infer env_with_fn body in
    let actual_type = TFun ([], List.hd body_types) in
    register_function name [actual_type];
    [actual_type]

  | [Ast.Symbol name; Ast.List params; body] ->
      let param_types = List.map (fun param -> match param with
        | Ast.Symbol pname -> (pname, TAny)
        | _ -> failwith "defun parameters must be symbols") params in
      
      let param_tys = List.map snd param_types in
      let fn_type_placeholder = TFun (param_tys, TAny) in
      register_function name [fn_type_placeholder];
      let env_with_fn = (name, [fn_type_placeholder]) :: env in
      let new_env = List.fold_left (fun acc (pname, t) -> 
        extend_param pname t acc) env_with_fn param_types in
      
      let body_types = infer new_env body in
      let actual_type = TFun (param_tys, List.hd body_types) in
      register_function name [actual_type];
      
      [actual_type]
  | _ -> failwith "defun expects name, parameter list, and body"
 

(* Typechecks function application against all possible function signatures. *)
and check_apply env func args =
  let func_types = infer env func in
  let arg_type_lists = List.map (infer env) args in
  let matching_return_types =
    List.fold_left (fun acc ftype ->
      match ftype with
      | TFun (param_types, ret_type) ->
          let arity_ok = List.length param_types = List.length arg_type_lists in
          let args_ok =
            arity_ok &&
            List.for_all2
              (fun param inferred -> List.exists (fun t -> types_equal param t) inferred)
              param_types arg_type_lists
          in
          if args_ok then ret_type :: acc else acc
      | _ -> acc)
      []
      func_types
  in
  match matching_return_types with
  | [] -> failwith ("Function application type error: got " ^ 
                    string_of_int (List.length arg_type_lists) ^ " args")
  | types -> List.rev (List.sort_uniq compare types)
 
(* Verifies whether an expression can have an expected type. *)
and check env expr expected =
  List.exists (fun inferred -> types_equal inferred expected) (infer env expr)

(* Typechecks each top-level expression using the empty base environment. *)
and typecheck_program exprs =
  List.map (fun e -> (e, infer Env.empty e)) exprs

(* Main inference entry point that computes all possible types for an expression. *)
and infer env expr = match expr with
  | Ast.Num _ -> [TInt]
  | Ast.Bool _ -> [TBool]
  | Ast.Symbol s -> 
      (try lookup_with_global s env with Failure _ -> failwith ("Unbound variable: " ^ s))
  | Ast.Nil -> [TBool; TList 0]
  | Ast.List (Ast.Symbol op :: args) -> (
      try match op with
      | "quote" -> check_quote env args
      | "atom" -> check_atom env args
      | "eq" -> check_eq env args
      | "car" -> check_car env args
      | "cdr" -> check_cdr env args
      | "caddr" -> check_caddr env args
      | "cddr" -> check_cddr env args
      | "cons" -> check_cons env args
      | "cond" -> check_cond env args
      | "+" | "-" | "*" | "div" | "mod" -> check_arith_op env op args
      | ">" | "<" | ">=" | "<=" -> check_compare_op env op args
      | "not" | "and" | "or" -> check_logic_op env op args
      | "lambda" -> check_lambda env args
      | "label" -> check_label env args
      | "defun" -> check_defun env args
      | _ -> check_apply env (Ast.Symbol op) args
      with Failure msg -> failwith ("Error in " ^ op ^ ": " ^ msg)
    )
  | Ast.List (func :: args) ->
      check_apply env func args
  | _ -> []