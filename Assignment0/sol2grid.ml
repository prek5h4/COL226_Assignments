(*reads Z3 output*)
let read_z3_output filename =
  let ic = open_in filename in
  let lines = ref [] in
  try
    while true do   
      lines := input_line ic :: !lines
    done;
    ""
  with End_of_file ->
    close_in ic;
    String.concat "\n" (List.rev !lines)
;;

(*determine size of sudoku from positive literals*)
let determine_size pos_lits =
  if List.length pos_lits = 0 then 9
  else
    let max_var = List.fold_left max 0 pos_lits in
    let rec find_n n =
      if n * n * n >= max_var then n
      else find_n (n + 1)
    in
    find_n 1
;;

(*parses integers*)
let positives lst: int list = 
  let rec aux lst =
    match lst with
    | [] -> []
    | h::xs ->
      (try
        let v = int_of_string (String.trim h) in
        if v > 0 then v :: aux xs 
        else aux xs
      with Failure _ -> aux xs)
  in
  aux (String.split_on_char ' ' lst)
;;
(*decode variable to (i,j,v)*)
let decode (x:int) (n:int) =
  let x0 = x - 1 in  
  
  let i0 = x0 / (n * n) in
  let remainder = x0 mod (n * n) in
  let j0 = remainder / n in
  let v0 = remainder mod n in
  
  (* Convert back to 1-based *)
  let i = i0 + 1  in
  let j = j0 + 1 in
  let v = v0 + 1  in
  
  (i, j, v)
;;

(*convert value to character based on sudoku size*)
let value_to_char (n:int) (v:int): char =
  match n with
  | 9 ->
      (if v >= 1 && v <= 9 then
        Char.chr (Char.code '0' + v)
      else '.')
  | _ ->
      (if v = 16 then '0'
      else if v >= 1 && v <= 9 then
        Char.chr (Char.code '0' + v)
      else if v >= 10 && v <= 15 then
        Char.chr (Char.code 'A' + v - 10)
      else '.')
;;

(*build the grid*)
let empty_grid n = Array.make_matrix n n '.'

let build_grid n positives =
  let grid = empty_grid n in
  List.iter (fun x ->
    let (i, j, v) = decode x n in
    if i >= 1 && i <= n && j >= 1 && j <= n then
      grid.(i - 1).(j - 1) <- value_to_char n v
    else
      Printf.eprintf "Warning: decoded position (%d, %d, %d) out of bounds for n=%d, var=%d\n" i j v n x
  ) positives;
  Array.to_list (Array.map Array.to_list grid)
;;

(*print the grid*)
let print_grid (grid: char list list) : unit =
  List.iter (fun row ->
    List.iter (fun c -> Printf.printf "%c" c) row;
    Printf.printf "\n"
  ) grid
;;

let () =
  let filename = Sys.argv.(1) in
  let lines = read_z3_output filename in
  let pos_lits = positives lines in
  let n = determine_size pos_lits in
  let grid = build_grid n pos_lits in
  print_grid grid
;;