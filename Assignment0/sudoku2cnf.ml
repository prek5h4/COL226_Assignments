open List;;


(* taking input*)
let read_sudoku filename =
  let ic = open_in filename in
  let lines = ref [] in
  try
    while true do
      lines := input_line ic :: !lines
    done;
    !lines  
  with End_of_file ->
    close_in ic;
    List.rev !lines  
;;


(*input handling*)
let string_to_chars s =
  List.init (String.length s) (String.get s);;



type literal = int;;
type clause = literal list;;
type cnf = clause list;;

let var n i j v =
  (* i, j, v are 1 based *)
  (i-1) * n * n + (j-1) * n  + v
;;

let char_to_value (n:int) (c:char) =
match c with
| '0' -> 16 
| '.' -> -1
| '1' .. '9' ->
  Char.code c - Char.code '0'  
| 'A' .. 'Z' -> 
  10 + Char.code c - Char.code 'A' 
| _ -> -1
;;


(*now creating a list containing values of sudoku*)

let rec chars_to_values n lst =
  match lst with
  | [] -> []
  | x::xs -> (char_to_value n x) :: (chars_to_values n xs)
;;

let sudoku_to_values n lines =
  List.map (fun line -> chars_to_values n (string_to_chars line)) lines
;;

(* generating unit clauses for pre-filled cells *)
let rec generate_unit_clauses n lst idx =
  match lst with
  | [] -> []
  | x::xs ->
    match x with
    | -1 -> generate_unit_clauses n xs (idx + 1)
    | v ->
      let i = (idx / n) + 1 in
      let j = (idx mod n) + 1 in
      let clause = [var n i j v] in
      clause :: (generate_unit_clauses n xs (idx + 1))
;;
(**
let n = 9;;
let print_clause (cl : int list) =
  List.iter (fun x ->
    print_int x;
    print_string " ") cl;
  print_endline "0"
  ;;

let () =
  let cn = generate_unit_clauses n (List.flatten (sudoku_to_values n (read_sudoku "input.txt"))) 0 in
  List.iter (fun cl -> print_clause cl) cn; 
  print_endline (string_of_int (List.length cn))
*)
(*cell constraints*)

(*ensuring at least one value per cell
∀i,j, (x(i,j,1)∨x(i,j,2)∨...∨x(i,j,n)) *)

let cell_has_atleast_one_val (n:int) (i:int) (j:int): cnf =
  [List.init n (fun v -> var n i j (v + 1))]
;;

(*used pairwise negation to ensure at most one value per cell
∀v /=v′, ¬x(i,j,v)∨¬x(i,j,v′) *)

let cell_has_atmost_one_val (n:int) (i:int) (j:int): cnf = 
  let vals = List.init n (fun v->v +1) in  (*generates possible values in cell*)
  let rec aux vals =
    match vals with
    | [] -> []
    | v::rest ->
      let new_clauses = 
      List.map( fun v2 -> [-(var n i j v); -(var n i j v2)]) rest 
      in
      new_clauses @ (aux rest)
  in
  aux vals
;;

let rec combine_cell_atmost (n:int) (i:int) (j:int) : cnf =
  match i with
  | _ when i > n -> []
  | _ ->
    match j with
    | _ when j > n -> combine_cell_atmost n (i+1) 1
    | _ ->
      cell_has_atmost_one_val n i j @ combine_cell_atmost n i (j+1) ;;

let rec combine_cell_atleast (n:int) (i:int) (j:int) : cnf =
  match i with
  | _ when i > n -> []
  | _ ->
    match j with
    | _ when j > n -> combine_cell_atleast n (i+1) 1
    | _ ->
      cell_has_atleast_one_val n i j @ combine_cell_atleast n i (j+1) ;;
(*combining both the conditions for constraints for a single cell*)

let cell_constraints (n:int) (i:int) (j:int): cnf =
  let at_least_one = combine_cell_atleast n i j in
  let at_most_one = combine_cell_atmost n i j in
  at_least_one @ at_most_one
;;

(*row constraints*)

let row_has_atleast_one_val (n:int) (i:int) (j:int) (v:int): cnf = 
  [List.init n (fun jj -> var n i (jj+1) v)]
;;

let row_has_atmost_one_val (n:int) (i:int) (j:int) (v:int): cnf =
  let vals = List.init n (fun jj -> var n i (jj+1) v) in  
  let rec aux vals =
    match vals with
    | [] -> []
    | j::rest ->
      let new_clauses = List.map( fun j2 -> [-j; -j2]) rest in
      new_clauses @ (aux rest)
  in
  aux vals
;;

let rec combine_row_atleast (n:int) (i:int) (j:int) (v:int) : cnf =
  match i with
  | _ when i > n -> []
  | _ -> 
    match v with
    | _ when v > n -> combine_row_atleast n (i+1) 1 1
    | _ -> row_has_atleast_one_val n i 1 v @ combine_row_atleast n i 1 (v+1)
;;

let rec combine_row_atmost (n:int) (i:int) (v:int) : cnf =
  match i with
  | _ when i > n -> []
  | _ -> 
    match v with
    | _ when v > n -> combine_row_atmost n (i+1) 1
    | _ -> row_has_atmost_one_val n i 1 v @ combine_row_atmost n i (v+1)
;; 


let row_constraints (n:int) (i:int) (j:int) (v:int): cnf =
  let at_least_one = combine_row_atleast n 1 1 1 in
  let at_most_one = combine_row_atmost n 1 1 in
  at_least_one @ at_most_one
;;

(*column constraints*)

let col_has_atleast_one_val (n:int) (i:int) (j:int) (v:int): cnf = 
  [List.init n (fun ii -> var n (ii+1) j v)]
;;

let col_has_atmost_one_val (n:int) (i:int) (j:int) (v:int): cnf =
  let vals = List.init n (fun ii -> var n (ii+1) j v) in  
  let rec aux vals =
    match vals with
    | [] -> []
    | i::rest ->
      let new_clauses = List.map( fun i2 -> [-i; -i2]) rest in
      new_clauses @ (aux rest)
  in
  aux vals
;;

let rec combine_col_atleast (n:int) (i:int) (j:int) (v:int) : cnf =
  match j with
  | _ when j > n -> []
  | _ -> 
    match v with
    | _ when v > n -> combine_col_atleast n 1 (j+1) 1
    | _ -> col_has_atleast_one_val n 1 j v @ combine_col_atleast n 1 j (v+1)
;;


let rec combine_col_atmost (n:int) (j:int) (v:int) : cnf =
  match j with
  | _ when j > n -> []
  | _ -> 
    match v with
    | _ when v > n -> combine_col_atmost n (j+1) 1
    | _ -> col_has_atmost_one_val n 1 j v @ combine_col_atmost n j (v+1)
;; 
(*
let n = 9;;
let print_clause (cl : int list) =
  List.iter (fun x ->
    print_int x;
    print_string " ") cl;
  print_endline "0"
  ;;

let () =
  let cn = combine_col_atmost n 1 1 in
  List.iter (fun cl -> print_clause cl) cn; 
  print_endline (string_of_int (List.length cn))
;;
*)
let col_constraints (n:int) (i:int) (j:int) (v:int): cnf =
  let at_least_one = combine_col_atleast n 1 1 1 in
  let at_most_one = combine_col_atmost n 1 1 in
  at_least_one @ at_most_one
;;


(*block constraints*)

(*ensuring at least one occurrence of value v in block containing cell (i,j) 
and  br = (i-1)/sqrt(n), bc = (j-1)/sqrt(n) signify block row and column as they are computing 
the starting indices of the block containing cell (i,j) *)

let block_has_atleast_one_val (n:int) (i:int) (j:int) (v:int): cnf = 
  let root_n = int_of_float (sqrt (float_of_int n)) in
  [List.init n (fun idx -> 
    let br = idx / root_n in
    let bc = idx mod root_n in
    var n (br + ( ( (i -1) / root_n) * root_n) +1) (bc + ( ( (j -1) / root_n) * root_n) +1) v
  )]
;;

let block_has_atmost_one_val (n:int) (i:int) (j:int) (v:int): cnf =
  let root_n = int_of_float (sqrt (float_of_int n)) in
  let vals = List.init n (fun idx -> 
    let br = idx / root_n in
    let bc = idx mod root_n in
    var n (br + ( ( (i -1) / root_n) * root_n) +1) (bc + ( ( (j -1) / root_n) * root_n) +1) v
  ) in  
  let rec aux vals =
    match vals with
    | [] -> []
    | v::rest ->
      let new_clauses = List.map( fun v2 -> [-v; -v2]) rest in
      new_clauses @ (aux rest)
  in
  aux vals
;;
let rec combine_blocks_atleast (n:int) (v:int) (i:int) (j:int) : cnf =
  let root_n = int_of_float (sqrt (float_of_int n)) in
  if v > n then []
  else if j > n then combine_blocks_atleast n v (i + root_n) 1
  else if i > n then combine_blocks_atleast n (v + 1) 1 1
  else
    let current_block = block_has_atleast_one_val n i j v in
    current_block @ (combine_blocks_atleast n v i (j + root_n))
;;

let rec combine_blocks_atmost (n:int) (v:int) (i:int) (j:int) : cnf =
  let root_n = int_of_float (sqrt (float_of_int n)) in
  if v > n then []
  else if j > n then combine_blocks_atmost n v (i + root_n) 1
  else if i > n then combine_blocks_atmost n (v + 1) 1 1
  else
    let current_block = block_has_atmost_one_val n i j v in
    current_block @ (combine_blocks_atmost n v i (j + root_n))
;;



let block_constraints (n:int) (i:int) (j:int) (v:int): cnf =
  let at_least_one = combine_blocks_atleast n 1 1 1 in
  let at_most_one = combine_blocks_atmost n 1 1 1 in
  at_least_one @ at_most_one
  ;;

(*
let print_clause (cl : int list) =
  List.iter (fun x ->
    print_int x;
    print_string " ") cl;
  print_endline "0"
  ;;
let n = 9;;
let () =
  let cn = combine_blocks_atmost n 1 1 1 in
 
  iter (fun cl -> print_clause cl) cn; 
  print_endline (string_of_int (length cn))
;;
*)
(*combining all constraints*)




let all_constraints (n:int): cnf =
  let cell_cnf = cell_constraints n 1 1 in
  let row_cnf = row_constraints n 1 1 1 in
  let col_cnf = col_constraints n 1 1 1 in
  let block_cnf = block_constraints n 1 1 1 in
  cell_cnf @ row_cnf @ col_cnf @ block_cnf
;;
(*
let print_clause (cl : int list) =
  List.iter (fun x ->
    print_int x;
    print_string " ") cl;
  print_endline "0"
  ;;
let n = 9;;
let () =
  let cn = all_constraints n in
 
  (*iter (fun cl -> print_clause cl) cn;*)
  print_endline (string_of_int (length cn))
;;
*)
(*DIMNACS output*)

let print_clause (c: clause) : unit =
  List.iter (fun l -> Printf.printf "%d " l) c;
  Printf.printf "0\n"
;;

let print_cnf (n:int)(cnf: cnf) : unit =
  let num_vars = n*n*n in
  let num_clauses = List.length cnf in
  Printf.printf "p cnf %d %d\n" num_vars num_clauses;
  List.iter print_clause cnf
;;

let print_clause (cl : int list) =
  List.iter (fun x ->
    print_int x;
    print_string " ") cl;
  print_endline "0"
  ;;
(*
let n = 9;;
let () =
  let cf = all_constraints n in
  let unit_c = generate_unit_clauses n (List.flatten (sudoku_to_values n (read_sudoku "input.txt"))) 0 in
  let cn = cf @ unit_c in
  (*iter (fun cl -> print_clause cl) cn;*)
  print_endline (string_of_int (length cn))
;;
*)
let ()=
  let filename = Sys.argv.(1) in
  let lines = read_sudoku filename in
  let n = List.length lines in
  let values = sudoku_to_values n lines in
  let unit_clauses = generate_unit_clauses n (List.flatten values) 0 in
  let constraints = all_constraints n in
  let full_cnf = unit_clauses @ constraints in
  (*
  print_int(length full_cnf);
  print_endline "" *)
  print_cnf n full_cnf
  
;; 
