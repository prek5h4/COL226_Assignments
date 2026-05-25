type lithp_type =
	| TInt
	| TBool
	| TList of int
	| TFun of lithp_type list * lithp_type
	| TSymbol
	| TAny

val string_of_type : lithp_type -> string
val types_equal : lithp_type -> lithp_type -> bool
val is_list_type : lithp_type -> bool
val list_length : lithp_type -> int
