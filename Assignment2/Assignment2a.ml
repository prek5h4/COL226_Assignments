(*ASSIGNMENT 2A: BIGINT*)
(*Structure Of the Code:
  1.  remove_leading_zeros : removes leading zeros from a bigint representation
  2.  valid_bigint          : checks if a bigint is valid
  3.  abs_bigint            : returns the absolute value of a bigint
  4.  negate_bigint         : returns the negation of a bigint
  5.  pretty_print          : prints a bigint in string format
  6.  conv                  : converts an integer to a bigint
  7. bigint_of_string       : converts a string to a bigint
  8.  compare_digits        : compares two lists of digits
  9.  compare_abs           : compares two absolute values of bigints
  10. equal                 : checks if two bigints are equal
  11. greater_than          : checks if first bigint is greater than second
  12. less_than             : checks if first bigint is less than second
  13. great_or_equal        : checks if first bigint is >= second
  14. less_or_equal         : checks if first bigint is <= second
  15. add_ints              : adds two lists of digits with carry
  16. subs_ints             : subtracts two lists of digits with borrow
  17. multiply_int_with_no  : multiplies a list of digits with a single digit
  18. multiply_ints         : multiplies two lists of digits
  19. divide_ints           : divides two lists of digits, returning quotient and remainder
  20. remainder_ints        : computes the remainder of division of two lists of digits
  21. addition              : adds two bigints
  22. substraction          : subtracts second bigint from first
  23. multiplication        : multiplies two bigints
  24. quotient              : divides first bigint by second, returning the quotient
  25. remainder             : divides first bigint by second, returning the remainder
*)

module type BIGNUM = sig
  type sign = Neg | NonNeg
  type bigint = sign * int list
  type myBool = True | False

  exception InvalidBigInt of string
  exception DivisionByZero of string

  val zero : bigint

  val remove_leading_zeros : bigint -> bigint
  val valid_bigint : bigint -> myBool
  val abs_bigint : bigint -> bigint
  val negate_bigint : bigint -> bigint
  val pretty_print : bigint -> string
  val conv : int -> bigint
  val bigint_of_string : string -> bigint

  val compare_digits : int list * int list -> int
  val compare_abs : bigint -> bigint -> int
  val equal : bigint -> bigint -> myBool
  val greater_than : bigint -> bigint -> myBool
  val less_than : bigint -> bigint -> myBool
  val great_or_equal : bigint -> bigint -> myBool
  val less_or_equal : bigint -> bigint -> myBool

  val add_ints : int list -> int list -> int -> int list
  val subs_ints : int list -> int list -> int -> int list
  val multiply_int_with_no : int list -> int list -> int -> int list
  val multiply_ints : int list -> int list -> int list
  val divide_ints : int list -> int list -> (sign * int list) * (sign * int list)
  val remainder_ints : int list -> int list -> int list

  val addition : bigint -> bigint -> bigint
  val substraction : bigint -> bigint -> bigint
  val multiplication : bigint -> bigint -> bigint
  val quotient : bigint -> bigint -> bigint
  val remainder : bigint -> bigint -> bigint
end

module BigNum : BIGNUM = struct

  type sign = Neg | NonNeg
  type bigint = sign * int list
  type myBool = True | False

  exception InvalidBigInt of string
  exception DivisionByZero of string

  (* Canonical zero *)
  let zero : bigint = (NonNeg, [0])

  (* Returns bigint without leading zeros *)
  let rec remove_leading_zeros (s, dig) = match dig with
    | []   -> (NonNeg, [0])
    | [0]  -> (NonNeg, [0])
    | 0::xs -> remove_leading_zeros (s, xs)
    | _    -> (s, dig)

  (* Checks if bigint is valid *)
  let valid_bigint (_, dig) : myBool =
    let rec check_digits d = match d with
      | []    -> True
      | x::xs -> if x >= 0 && x <= 9 then check_digits xs else False
    in
    check_digits dig

  (* Returns the absolute value of a bigint *)
  let abs_bigint (s, dig) : bigint =
    if valid_bigint (s, dig) = False then raise (InvalidBigInt "Not a valid bigint")
    else (NonNeg, dig)

  (* Reverses the sign of the bigint *)
  let negate_bigint (s, dig) : bigint =
    if valid_bigint (s, dig) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      let new_sign = match s with
        | Neg    -> NonNeg
        | NonNeg -> Neg
      in
      (new_sign, dig)

  (* Converts bigint to a human-readable string *)
  let pretty_print (s, dig) : string =
    if valid_bigint (s, dig) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      let sign_str = match s with Neg -> "-" | NonNeg -> "" in
      let dig_str  = String.concat "" (List.map string_of_int dig) in
      sign_str ^ dig_str

  (* Converts a native int to a bigint (MSB on the left) *)
  let conv (num : int) : bigint =
    if num = 0 then (NonNeg, [0])
    else
      let sign    = if num < 0 then Neg else NonNeg in
      let abs_num = abs num in
      let rec digits n acc = match n with
        | 0 -> acc
        | _ -> digits (n / 10) ((n mod 10) :: acc)
      in
      remove_leading_zeros (sign, digits abs_num [])

    let bigint_of_string (s : string) : bigint =
      let s = String.trim s in
      if s = "" then raise (InvalidBigInt "Empty string is not a valid bigint")
      else
        let sign = if String.get s 0 = '-' then Neg else NonNeg in
        let digits_str = if sign = Neg then String.sub s 1 (String.length s - 1) else s in
        if digits_str = "" then raise (InvalidBigInt "No digits found in the string")
        else
          let rec parse_digits str acc idx =
            if idx >= String.length str then List.rev acc
            else
              let c = String.get str idx in
              if c >= '0' && c <= '9' then parse_digits str ((int_of_char c - int_of_char '0') :: acc) (idx + 1)
              else raise (InvalidBigInt "Invalid character in bigint string")
          in
          remove_leading_zeros (sign, parse_digits digits_str [] 0)

  (* Compares two raw digit lists (MSB first); returns -1, 0, or 1 *)
  let rec compare_digits (d1, d2) = match d1, d2 with
    | [], []     ->  0
    | [], _      -> -1
    | _, []      ->  1
    | x::xs, y::ys ->
        if x > y then 1
        else if x < y then -1
        else compare_digits (xs, ys)

  (* Compares absolute values of two bigints *)
  let compare_abs (s1, d1) (s2, d2) : int =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      let len1 = List.length d1 in
      let len2 = List.length d2 in
      if len1 > len2 then 1
      else if len1 < len2 then -1
      else compare_digits (d1, d2)

  (* Checks if two bigints are equal *)
  let equal (s1, d1) (s2, d2) : myBool =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      match s1, s2 with
      | NonNeg, NonNeg
      | Neg,    Neg    -> if compare_abs (s1, d1) (s2, d2) = 0 then True else False
      | _              -> False

  (* Checks if first bigint is greater than second *)
  let greater_than (s1, d1) (s2, d2) : myBool =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      match s1, s2 with
      | NonNeg, Neg    -> True
      | Neg,    NonNeg -> False
      | NonNeg, NonNeg -> if compare_abs (s1, d1) (s2, d2) >  0 then True else False
      | Neg,    Neg    -> if compare_abs (s1, d1) (s2, d2) <  0 then True else False

  (* Checks if first bigint is less than second *)
  let less_than (s1, d1) (s2, d2) : myBool =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      match s1, s2 with
      | NonNeg, Neg    -> False
      | Neg,    NonNeg -> True
      | NonNeg, NonNeg -> if compare_abs (s1, d1) (s2, d2) <  0 then True else False
      | Neg,    Neg    -> if compare_abs (s1, d1) (s2, d2) >  0 then True else False

  (* Checks if first bigint is >= second *)
  let great_or_equal (s1, d1) (s2, d2) : myBool =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      match s1, s2 with
      | NonNeg, Neg    -> True
      | Neg,    NonNeg -> False
      | NonNeg, NonNeg -> if compare_abs (s1, d1) (s2, d2) >= 0 then True else False
      | Neg,    Neg    -> if compare_abs (s1, d1) (s2, d2) >= 0 then True else False

  (* Checks if first bigint is <= second *)
  let less_or_equal (s1, d1) (s2, d2) : myBool =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      match s1, s2 with
      | NonNeg, Neg    -> False
      | Neg,    NonNeg -> True
      | NonNeg, NonNeg -> if compare_abs (s1, d1) (s2, d2) <= 0 then True else False
      | Neg,    Neg    -> if compare_abs (s1, d1) (s2, d2) <= 0 then True else False

  (* Adds two raw digit lists with an initial carry *)
  let add_ints l1 l2 carry =
    let rec aux l1 l2 carry =
      match l1, l2, carry with
      | [], [], 0 -> []
      | [], [], c -> [c]
      | x::xs, [], c
      | [], x::xs, c ->
          let sum = x + c in
          (sum mod 10) :: aux xs [] (sum / 10)
      | x::xs, y::ys, c ->
          let sum = x + y + c in
          (sum mod 10) :: aux xs ys (sum / 10)
    in
    List.rev (aux (List.rev l1) (List.rev l2) carry)

  (* Subtracts two raw digit lists with an initial borrow; l1 must be >= l2 *)
  let subs_ints l1 l2 borrow =
    let rec aux l1 l2 borrow =
      match l1, l2, borrow with
      | [], [], 0 -> []
      | [], [], _ -> raise (DivisionByZero "division/substraction invalid")
      | [], _::_, _ -> raise (DivisionByZero "division/substraction invalid")
      | x::xs, [], b ->
          let diff = x - b in
          if diff < 0 then (diff + 10) :: aux xs [] 1
          else diff :: aux xs [] 0
      | x::xs, y::ys, b ->
          let diff = x - y - b in
          if diff < 0 then (diff + 10) :: aux xs ys 1
          else diff :: aux xs ys 0
    in
    List.rev (aux (List.rev l1) (List.rev l2) borrow)

  (* Multiplies a digit list by a single-digit list [y] with carry *)
  let multiply_int_with_no l1 l2 carry =
    let rec aux l1 l2 carry = match l1, l2 with
      | [], _  -> if carry = 0 then [] else [carry]
      | _, []  -> []
      | x::xs, y::[] ->
          let prod = x * y + carry in
          (prod mod 10) :: aux xs [y] (prod / 10)
      | _ -> []
    in
    List.rev (aux (List.rev l1) (List.rev l2) carry)

  (* Multiplies two raw digit lists using long multiplication *)
  let multiply_ints l1 l2 =
    let rec aux l2 shift =
      match l2 with
      | [] -> [0]
      | y :: ys ->
          let prod    = multiply_int_with_no l1 [y] 0 in
          let shifted = prod @ List.init shift (fun _ -> 0) in
          let rest    = aux ys (shift + 1) in
          add_ints shifted rest 0
    in
    aux (List.rev l2) 0

  (* Divides l1 by l2 using repeated subtraction; returns (quotient, remainder) *)
  let divide_ints l1 l2 =
    let cmp a b = compare_abs (NonNeg, a) (NonNeg, b) in
    let strip d  = snd (remove_leading_zeros (NonNeg, d)) in
    let rec aux l1 q =
      if cmp l1 l2 < 0 then (q, l1)
      else aux (strip (subs_ints l1 l2 0)) (add_ints q [1] 0)
    in
    let (q, r) = aux l1 [0] in
    (remove_leading_zeros (NonNeg, q),
     remove_leading_zeros (NonNeg, r))

  (* Returns the remainder of l1 divided by l2 *)
  let remainder_ints l1 l2 =
    let cmp a b = compare_abs (NonNeg, a) (NonNeg, b) in
    let strip d  = snd (remove_leading_zeros (NonNeg, d)) in
    let rec aux l1 =
      if cmp l1 l2 < 0 then l1
      else aux (strip (subs_ints l1 l2 0))
    in
    aux l1

  let addition (s1, d1) (s2, d2) : bigint =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      match s1, s2 with
      | NonNeg, NonNeg -> (NonNeg, add_ints d1 d2 0)
      | Neg,    Neg    -> (Neg,    add_ints d1 d2 0)
      | NonNeg, Neg    ->
          let final_sign = if compare_abs (s1, d1) (s2, d2) >= 0 then NonNeg else Neg in
          let final_dig  = match final_sign with
            | NonNeg -> subs_ints d1 d2 0
            | Neg    -> subs_ints d2 d1 0
          in
          remove_leading_zeros (final_sign, final_dig)
      | Neg, NonNeg ->
          let final_sign = if compare_abs (s1, d1) (s2, d2) >= 0 then Neg else NonNeg in
          let final_dig  = match final_sign with
            | Neg    -> subs_ints d1 d2 0
            | NonNeg -> subs_ints d2 d1 0
          in
          remove_leading_zeros (final_sign, final_dig)

  let substraction (s1, d1) (s2, d2) : bigint =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      match s1, s2 with
      | NonNeg, NonNeg ->
          let final_sign = if compare_abs (s1, d1) (s2, d2) >= 0 then NonNeg else Neg in
          let final_dig  = match final_sign with
            | NonNeg -> subs_ints d1 d2 0
            | Neg    -> subs_ints d2 d1 0
          in
          remove_leading_zeros (final_sign, final_dig)
      | Neg, Neg ->
          let final_sign = if compare_abs (s1, d1) (s2, d2) >= 0 then Neg else NonNeg in
          let final_dig  = match final_sign with
            | Neg    -> subs_ints d1 d2 0
            | NonNeg -> subs_ints d2 d1 0
          in
          remove_leading_zeros (final_sign, final_dig)
      | NonNeg, Neg -> (NonNeg, add_ints d1 d2 0)
      | Neg, NonNeg -> (Neg,    add_ints d1 d2 0)

  let multiplication (s1, d1) (s2, d2) : bigint =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else
      let final_sign = match s1, s2 with
        | NonNeg, NonNeg
        | Neg,    Neg    -> NonNeg
        | _              -> Neg
      in
      remove_leading_zeros (final_sign, multiply_ints d1 d2)

  let quotient (s1, d1) (s2, d2) : bigint =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else if d2 = [0] then raise (DivisionByZero "division by zero")
    else
      let final_sign = match s1, s2 with
        | NonNeg, NonNeg
        | Neg,    Neg    -> NonNeg
        | _              -> Neg
      in
      let ((_, qdig), _) = divide_ints d1 d2 in
      remove_leading_zeros (final_sign, qdig)

  let remainder (s1, d1) (s2, d2) : bigint =
    if valid_bigint (s1, d1) = False then raise (InvalidBigInt "Not a valid bigint")
    else if valid_bigint (s2, d2) = False then raise (InvalidBigInt "Not a valid bigint")
    else if d2 = [0] then raise (DivisionByZero "division by zero")
    else
      remove_leading_zeros (s1, remainder_ints d1 d2)



(*let () =
  let p = pretty_print in
  let tests = [
    (* description,        expected,   actual *)
    ("5 > 5",              "False",    (match greater_than (conv 5)    (conv 5)    with True->"True"|_->"False"));
    ("-5 > -5",            "False",    (match greater_than (conv (-5)) (conv (-5)) with True->"True"|_->"False"));
    ("-3 > -5",            "True",     (match greater_than (conv (-3)) (conv (-5)) with True->"True"|_->"False"));
    ("5 < 5",              "False",    (match less_than    (conv 5)    (conv 5)    with True->"True"|_->"False"));
    ("-5 < -3",            "True",     (match less_than    (conv (-5)) (conv (-3)) with True->"True"|_->"False"));
    ("5 * 5",              "25",       p (multiplication (conv 5)   (conv 5)));
    ("9 * 9",              "81",       p (multiplication (conv 9)   (conv 9)));
    ("12 * 12",            "144",      p (multiplication (conv 12)  (conv 12)));
    ("99 * 99",            "9801",     p (multiplication (conv 99)  (conv 99)));
    (*("10 / 0",             "division by zero",        p (quotient       (conv 10)  (conv 0)));*)
    ("100 / 10",           "10",       p (quotient       (conv 100) (conv 10)));
    ("3 / 10",             "0",        p (quotient       (conv 3)  (conv 10)));
    ("(-10) / 2",          "-5",       p (quotient       (conv (-10)) (conv 2)));
    ("10 mod 3",           "1",        p (remainder      (conv 10)  (conv 3)));
    ("9 mod 3",            "0",        p (remainder      (conv 9)   (conv 3)));
    ("(-10) mod 3",        "-1",       p (remainder      (conv (-10)) (conv 3)));
    ("99 + 1",             "100",      p (addition       (conv 99)  (conv 1)));
    ("1000 - 1",           "999",      p (substraction   (conv 1000) (conv 1)));
  ] 
   in
  let pass = ref 0 and fail = ref 0 in
  List.iter (fun (desc, expected, got) ->
    if expected = got then (incr pass; Printf.printf "[PASS] %s\n" desc)
    else (incr fail;
          Printf.printf "[FAIL] %s\n  expected: %s\n  got:      %s\n"
            desc expected got)
  ) tests;
  Printf.printf "\n%d passed, %d failed\n" !pass !fail
  ;;*)

end