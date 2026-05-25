
open Env
open Types
type expr = Ast.expr
type expr_list = Ast.expr list
val infer : env -> expr -> lithp_type list
(** Returns all valid types for an expression *)

val check : env -> expr -> lithp_type -> bool

val typecheck_program : expr list -> (expr * lithp_type list) list
(** typechecks a whole program returns each expr with its types *)


(**OPERATORS**)

val check_quote : env -> expr_list -> lithp_type list
val check_atom : env -> expr_list -> lithp_type list
val check_eq : env -> expr_list -> lithp_type list
val check_car : env -> expr_list -> lithp_type list
val check_cdr : env -> expr_list -> lithp_type list
val check_caddr : env -> expr_list -> lithp_type list
val check_cddr : env -> expr_list -> lithp_type list
val check_cons : env -> expr_list -> lithp_type list
val check_cond : env -> expr_list -> lithp_type list
val check_arith : env -> expr_list -> lithp_type list
val check_arith_op : env -> string -> expr_list -> lithp_type list
val check_compare : env -> expr_list -> lithp_type list
val check_compare_op : env -> string -> expr_list -> lithp_type list
val check_logic : env -> expr_list -> lithp_type list
val check_lambda : env -> expr_list -> lithp_type list
val check_label : env -> expr_list -> lithp_type list
val check_defun : env -> expr_list -> lithp_type list
val check_apply : env -> expr -> expr_list -> lithp_type list
