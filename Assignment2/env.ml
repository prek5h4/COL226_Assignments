
open Types
type env = (string * lithp_type list) list
let empty = []

let lookup (x: string) (env: env) : lithp_type list =
  match List.find_opt (fun (y, _) -> y = x) env with
  | Some (_, types) -> types
  | None -> failwith ("Variable not found: " ^ x)
;;

let extend (x:string) (t:lithp_type list) (env: env) : env =
  (x, t) :: env
;;

let extend_param (x:string) (t:lithp_type) (env: env) : env =
  extend x [t] env
;;

let extend_many (x:string) (ts:lithp_type list) (env: env) : env =
  extend x ts env
;;
