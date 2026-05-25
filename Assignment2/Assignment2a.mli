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


module BigNum : BIGNUM