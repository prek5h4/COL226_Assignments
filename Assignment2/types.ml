
type lithp_type =
  | TInt
  | TBool
  | TList of int
  | TFun of lithp_type list * lithp_type
  | TSymbol
  | TAny

let rec string_of_type x = match x with
  | TInt -> "Int"
  | TBool -> "Bool"
  | TList n -> Printf.sprintf "List(%d)" n
  | TFun (arg_types, ret_type) ->
     Printf.sprintf "List(%d) -> %s" (List.length arg_types) (string_of_type ret_type)
  | TSymbol -> "Symbol"
  | TAny -> "Any"
;;

let rec types_equal t1 t2 = match t1, t2 with 
  | TInt, TInt -> true
  | TBool, TBool -> true
  | TList n1, TList n2 -> n1 = n2
  | TFun (args1, ret1), TFun (args2, ret2) ->
      List.length args1 = List.length args2 &&
      List.for_all2 types_equal args1 args2 &&
      types_equal ret1 ret2
  | TSymbol, TSymbol -> true
  | TAny, _ | _, TAny -> true
  | _ -> false

;;

let rec is_list_type t1 = match t1 with
  | TList _ -> true
  | _ -> false
;;

let rec list_length = function
  | TList n -> n
  | _ -> failwith "Not a list type"
;;