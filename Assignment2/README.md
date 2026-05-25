# Assignment 2 — Architecture & Code Report

## Table of Contents
1. [Module Dependency Map](#1-module-dependency-map)
2. [Assignment2a.ml — BigInt Package](#2-assignment2aml--bigint-package)
3. [types.ml — Type System ADT](#3-typesml--type-system-adt)
4. [env.ml — Type Environment](#4-envml--type-environment)
5. [token.ml — Token ADT](#5-tokenml--token-adt)
6. [Ast.ml — Abstract Syntax Tree](#6-astml--abstract-syntax-tree)
7. [lexer.mll — Lexical Analyser](#7-lexermll--lexical-analyser)
8. [parser.mly — Parser](#8-parsermly--parser)
9. [typecheck.ml — Type Checker](#9-typecheckml--type-checker)
10. [main.ml — Test Driver](#10-mainml--test-driver)

---

## 1. Module Dependency Map

```
Assignment2a.BigNum       (no dependencies)
        │
        ├──▶ Token            (re-exports BigNum.sign / bigint)
        ├──▶ Ast              (uses BigNum.pretty_print)
        ├──▶ Lexer            (uses BigNum.bigint_of_string, Parser tokens)
        │
Types                     (no dependencies)
        │
        └──▶ Env             (opens Types)
                │
                └──▶ Typecheck  (opens Env, Types; uses Ast)

Parser  (uses Ast, Token declarations)
Lexer   (uses Parser token constructors, BigNum)

main.ml opens BigNum, Types; calls Lexer, Parser, Typecheck, Token, Ast
```

The compilation order enforced by `bash.sh` is:
`types → env → Assignment2a → token → Ast → parser → lexer → typecheck → main`

---

## 2. Assignment2a.ml — BigInt Package

### 2.1 Data Representation

```
type sign   = Neg | NonNeg
type bigint = sign * int list
```

The `int list` stores decimal digits **most-significant first**, each digit in `[0, 9]`.

| Value | Representation |
|-------|---------------|
| `0`   | `(NonNeg, [0])` |
| `123` | `(NonNeg, [1; 2; 3])` |
| `-42` | `(Neg, [4; 2])` |

`type myBool = True | False` avoids a dependency on OCaml's standard `bool`.

### 2.2 Utilities

| Function | Signature | Behaviour |
|----------|-----------|-----------|
| `remove_leading_zeros` | `bigint -> bigint` | Strips leading `0` digits from the front of the list. An all-zero list collapses to `(NonNeg, [0])`. |
| `valid_bigint` | `bigint -> myBool` | Returns `True` iff every digit is in `[0..9]`. |
| `abs_bigint` | `bigint -> bigint` | Forces sign to `NonNeg`, digit list unchanged. |
| `negate_bigint` | `bigint -> bigint` | Flips `NonNeg ↔ Neg`. **Edge case:** `negate_bigint (conv 0)` returns `(Neg, [0])` which prints as `"-0"` — the implementation does not normalise negative zero. |
| `pretty_print` | `bigint -> string` | Prepends `"-"` for `Neg`, concatenates `string_of_int` for each digit. |
| `conv` | `int -> bigint` | Decomposes the absolute value by repeated `div/mod 10` (LSB→MSB), reverses to get MSB-first, then calls `remove_leading_zeros`. |
| `bigint_of_string` | `string -> bigint` | Reads a leading `-` for sign, then parses ASCII digits character by character. Raises `InvalidBigInt` for empty strings or non-digit characters. |

### 2.3 Low-Level Digit Operations

All three functions **reverse** their inputs before processing (so index 0 = LSB) and reverse the result.

#### `add_ints l1 l2 carry`
```
aux l1 l2 carry:
  case ([], [], 0)   → []
  case ([], [], c)   → [c]          ← final carry
  case (x::xs, [], c)               ← one list exhausted
  case ([], y::ys, c)
      sum  = x + c  (or y + c)
      emit sum mod 10, carry = sum / 10
  case (x::xs, y::ys, c)
      sum  = x + y + c
      emit sum mod 10, carry = sum / 10
```

#### `subs_ints l1 l2 borrow`  (requires |l1| ≥ |l2|)
```
aux l1 l2 borrow:
  diff = x - y - borrow
  if diff < 0: emit diff + 10, borrow = 1
  else:        emit diff,      borrow = 0
```
Raises `DivisionByZero` if an impossible borrow remains at end (indicates
l2 > l1 was passed — a programming error; the high-level functions prevent this).

#### `multiply_int_with_no l1 [y] carry`
Single-digit scalar multiply: `digit × y + carry`, carry propagates MSB.

#### `multiply_ints l1 l2`
Long multiplication. Iterates digits of `l2` **from LSB**; for each digit `y` at
position `shift`, computes `l1 × y` (via `multiply_int_with_no`), appends
`shift` trailing zeros (left-shift), then accumulates into a running sum with
`add_ints`. This is the standard schoolbook algorithm.

#### `divide_ints l1 l2` → `(quotient_bigint, remainder_bigint)`
**Repeated subtraction.** Counts how many times `l2` fits into `l1` by
subtracting `l2` and incrementing a counter until the remainder < `l2`.
```
aux l1 q:
  if compare_abs l1 l2 < 0 then (q, l1)
  else aux (l1 - l2) (q + 1)
```
> ⚠ This is O(quotient) — correct but potentially slow for large quotients.

#### `remainder_ints l1 l2`
Identical loop but only tracks the running dividend; returns the final value
when it drops below `l2`.

### 2.4 Signed Arithmetic

#### `addition (s1,d1) (s2,d2)`

| Signs | Rule |
|-------|------|
| `(+, +)` | `add_ints d1 d2 0`, sign `+` |
| `(-, -)` | `add_ints d1 d2 0`, sign `-` |
| `(+, -)` | subtract smaller abs from larger; sign follows the larger |
| `(-, +)` | symmetric to `(+, -)` |

#### `substraction a b` = effectively `addition a (negate b)`

| Signs | Rule |
|-------|------|
| `(+, +)` | subtract, sign of larger magnitude |
| `(-, -)` | subtract, sign of larger magnitude |
| `(+, -)` | `add_ints`, sign `+` |
| `(-, +)` | `add_ints`, sign `-` |

#### `multiplication (s1,d1) (s2,d2)`
Sign rule: same signs → `NonNeg`; different → `Neg`.
Digits: `multiply_ints d1 d2`, then `remove_leading_zeros`.

#### `quotient` / `remainder`
Both check `d2 = [0]` and raise `DivisionByZero` before calling `divide_ints`.
`quotient` applies the same sign rule as multiplication.
`remainder` keeps the sign of the **dividend** (`s1`).

### 2.5 Comparison Functions

#### `compare_digits (d1, d2)` → `{-1, 0, 1}`
1. Compare list lengths — longer = larger (more significant digits).
2. If equal length, step through pairs MSB-first; return `1/-1` on first
   differing digit, `0` if all equal.

#### `compare_abs b1 b2` → `{-1, 0, 1}`
Validates both bigints, then delegates to `compare_digits`.

#### High-level comparison functions
All five (`equal`, `greater_than`, `less_than`, `great_or_equal`, `less_or_equal`)
follow the same pattern:

```
match s1, s2 with
| NonNeg, Neg    → immediate result (positive > negative)
| Neg,    NonNeg → immediate result
| NonNeg, NonNeg → compare_abs (normal order)
| Neg,    Neg    → compare_abs (inverted: more negative = smaller)
```

---

## 3. types.ml — Type System ADT

```ocaml
type lithp_type =
  | TInt                              (* integer *)
  | TBool                             (* boolean / nil / empty list as bool *)
  | TList of int                      (* list of exactly n elements *)
  | TFun of lithp_type list * lithp_type   (* function type *)
  | TSymbol                           (* quoted symbol atom *)
  | TAny                              (* polymorphic wildcard *)
```

### `string_of_type`

| Type | Printed as |
|------|-----------|
| `TInt` | `"Int"` |
| `TBool` | `"Bool"` |
| `TList 3` | `"List(3)"` |
| `TFun ([TAny], TInt)` | `"List(1) -> Int"` |
| `TSymbol` | `"Symbol"` |
| `TAny` | `"Any"` |

> Note: `TFun` is printed as `"List(n) -> RetType"` — using the number of
> parameters rather than their types, which is a simplification.

### `types_equal t1 t2`
Structural equality with `TAny` as a wildcard: `types_equal TAny T = true`
for all `T`, enabling polymorphic unification without full inference.

### `is_list_type` / `list_length`
Simple predicates; `list_length` raises `Failure` on non-list types.

---

## 4. env.ml — Type Environment

```ocaml
type env = (string * lithp_type list) list
```

A simple association list mapping variable names to lists of possible types
(union typing).

| Function | Behaviour |
|----------|-----------|
| `empty` | `[]` — the empty environment |
| `lookup x env` | `List.find_opt` by name; raises `Failure "Variable not found"` if absent |
| `extend x ts env` | Prepends `(x, ts)` — shadows any earlier binding for `x` |
| `extend_param x t env` | Wraps `t` in a singleton list and calls `extend` |
| `extend_many x ts env` | Alias for `extend` |

The local environment is **immutable and functional** — each `extend` returns a
new list, never mutating the original. However, `Typecheck.global_env` is a
**mutable `ref`**, accumulating `defun`/`label` definitions across the program.

---

## 5. token.ml — Token ADT

`token.ml` defines the `Token.token` type that both the lexer and parser share,
plus `Token.string_of_token` for human-readable output in lex-mode.

### Token Categories

| Category | Constructors |
|----------|-------------|
| Structure | `LPAREN` `RPAREN` `QUOTE` `NIL` `TRUE` |
| Literals | `BIGINT of sign * int list` |
| Arithmetic | `PLUS MINUS TIMES DIV MOD` |
| Comparison | `EQ GT LT LEQ GEQ NEQ NOT AND OR` |
| Primitives | `QUOTE_KW ATOM EQ_KW CAR CDR CONS COND` |
| CXR family | `CXR of string` — catches `cadr`, `caar`, `cddr`, `caadr`, … |
| Definitions | `LAMBDA LABEL DEFUN` |
| Identifiers | `IDENT of string` |
| Error tokens | `BAD_BIGINT BAD_IDENT BAD_DOT` (lex-mode only) |
| Comments | `COMMENT of string` (lex-mode only) |
| End | `EOF` |

### `string_of_token`
Renders each token for display. Notable cases:
- `BIGINT(Neg, [4;2])` → `"BIGINT(-, [4; 2])"`
- `CXR "cadr"` → `"CXR(cadr)"`
- `IDENT "foo."` → `"IDENT(foo.)"`

The re-exports `type sign = Assignment2a.BigNum.sign = Neg | NonNeg` and
`type bigint = Assignment2a.BigNum.bigint` let `token.ml` carry `bigint`
payloads without importing the whole BigNum module.

---

## 6. Ast.ml — Abstract Syntax Tree

```ocaml
type expr =
  | Num    of bigint      (* integer literal *)
  | Symbol of string      (* variable, keyword, or operator *)
  | Nil                   (* the empty list () *)
  | Bool   of bool        (* the constant t *)
  | List   of expr list   (* S-expression list *)
  | Comment of string     (* comment — never produced by the parser *)
```

### `string_of_expr`
Converts an AST node back to S-expression notation:

| Node | Output |
|------|--------|
| `Num b` | `pretty_print b` |
| `Symbol s` | `s` |
| `Nil` | `"()"` |
| `Bool true` | `"t"` |
| `Bool false` | `"nil"` |
| `List es` | `"(" ^ space-joined children ^ ")"` |
| `Comment s` | `"; " ^ s` |

`string_of_expr` is used by `main.ml` to display parse results and by
`typecheck.ml` to label type-error messages.

---

## 7. lexer.mll — Lexical Analyser

`ocamllex` processes `lexer.mll` and generates `lexer.ml` with two entry-point
functions: `Lexer.token` and `Lexer.token_lex`.

### 7.1 Pattern Definitions

```
white       = [ ' ' '\t' '\n' '\r' ]+
digit       = ['0'-'9']
integer     = '-'? digit+
alpha       = ['a'-'z' 'A'-'Z']
ident       = alpha (alpha | digit | '_')* '.'?
cxr         = 'c' ['a' 'd']+ 'r'
bad_integer = '-'? digit+ (alpha | '_')+
bad_ident   = alpha (alpha | digit | '_')* '.' (alpha | digit)+
bad_dot     = alpha+ ('.' '.'+ alpha*)+
comment     = ';'+ [^ '\n']* '\n'?
```

Key design points:
- `ident` allows a single trailing `.` — this is how `append.` and `null.` become valid identifiers in LITHP style.
- `cxr` is more specific than `ident` and is listed first, so `cadr` → `CXR` not `IDENT`.
- `bad_ident` matches things like `foo.bar` (dot with chars after) and is listed before `ident` to prevent `foo.bar` being split as `foo.` + `bar`.
- `bad_dot` catches multiple dots like `foo..bar`.
- `bad_integer` catches malformed numbers like `123abc`.

### 7.2 Two Lexer Rules

#### `token` — Parser-facing rule
| Pattern | Action |
|---------|--------|
| `white` | Recurse (skip) |
| `comment` | Recurse (skip) |
| `bad_integer` | Print warning to stderr, recurse |
| `bad_dot` | Print warning to stderr, recurse |
| `bad_ident` | Print warning to stderr, recurse |
| `integer` | `BIGINT (bigint_of_string s)` |
| `cxr` | `CXR s` |
| `ident` | Keyword dispatch (see below) |
| `"()"` | `NIL` |
| `"("` / `")"` | `LPAREN` / `RPAREN` |
| `"'"` | `QUOTE` |
| `"=/="` `"<="` `">="` `"="` `"<"` `">"` | `NEQ LEQ GEQ EQ LT GT` |
| `"+"` `"*"` `"-"` `"div"` `"mod"` | `PLUS TIMES MINUS DIV MOD` |
| `eof` | `EOF` |

#### `token_lex` — Lex-driver rule
Identical pattern table, but error cases return tokens instead of recursing:

| Pattern | Action |
|---------|--------|
| `comment` | `COMMENT (Lexing.lexeme lexbuf)` |
| `bad_integer` | `BAD_BIGINT s` |
| `bad_dot` | `BAD_DOT s` |
| `bad_ident` | `BAD_IDENT s` |

### 7.3 Keyword Dispatch (shared by both rules)
When the `ident` pattern matches, the lexeme is compared against a list of
reserved words:

```
"t"      → TRUE      "quote"  → QUOTE_KW  "atom"   → ATOM
"eq"     → EQ_KW     "car"    → CAR       "cdr"    → CDR
"cons"   → CONS      "cond"   → COND      "lambda" → LAMBDA
"label"  → LABEL     "defun"  → DEFUN     "not"    → NOT
"and"    → AND       "or"     → OR
_        → IDENT s
```

### 7.4 Multi-char Operator Priority
Operators are listed longest-first to ensure maximal munch:
`"=/="` before `"="`, `"<="` before `"<"`, `">="` before `">"`.

---

## 8. parser.mly — Parser

`ocamlyacc` processes `parser.mly` and generates an LALR(1) parser.

### 8.1 Token Declarations

```
%token LPAREN RPAREN QUOTE NIL TRUE EOF
%token PLUS MINUS TIMES DIV MOD
%token EQ GT LT LEQ GEQ NEQ NOT AND OR
%token QUOTE_KW ATOM EQ_KW CAR CDR CONS COND LAMBDA LABEL DEFUN

%token <string>                         IDENT CXR
%token <string>                         BAD_BIGINT BAD_IDENT BAD_DOT COMMENT
%token <Assignment2a.BigNum.sign * int list>  BIGINT
```

The error tokens (`BAD_*`, `COMMENT`) are declared so `ocamlyacc` generates
their type definitions — they never appear in the grammar rules because `token`
(not `token_lex`) is used during parsing.

### 8.2 Grammar

```
program   → expr_seq EOF            { List.rev $1 }

expr_seq  → ε                       { [] }
          | expr_seq expr            { $2 :: $1 }
          | expr_seq COMMENT         { $1 }

expr      → BIGINT                   { Ast.Num $1 }
          | TRUE                     { Ast.Bool true }
          | NIL                      { Ast.Nil }
          | IDENT                    { Ast.Symbol $1 }
          | CXR                      { Ast.Symbol $1 }
          | PLUS                     { Ast.Symbol "+" }
          | MINUS                    { Ast.Symbol "-" }
          | TIMES                    { Ast.Symbol "*" }
          | DIV                      { Ast.Symbol "div" }
          | MOD                      { Ast.Symbol "mod" }
          | EQ                       { Ast.Symbol "=" }
          | GT                       { Ast.Symbol ">" }
          | LT                       { Ast.Symbol "<" }
          | LEQ                      { Ast.Symbol "<=" }
          | GEQ                      { Ast.Symbol ">=" }
          | NEQ                      { Ast.Symbol "=/=" }
          | NOT AND OR LAMBDA LABEL  { Ast.Symbol … }
          | DEFUN QUOTE_KW ATOM …   { Ast.Symbol … }
          | QUOTE expr               { Ast.List [Ast.Symbol "quote"; $2] }
          | LPAREN expr_list RPAREN  { Ast.List (List.rev $2) }

expr_list → ε                       { [] }
          | expr_list expr            { $2 :: $1 }
          | expr_list COMMENT         { $1 }
```

### 8.3 Left-Recursive Accumulation and Reversal

Both `expr_seq` and `expr_list` use left-recursive `$2 :: $1` to accumulate
items in **reverse order** (this is necessary for efficient LALR parsing).
They are reversed exactly once at their reduction point:
- `program` applies `List.rev $1` at the `EOF` reduction.
- The `LPAREN…RPAREN` rule applies `List.rev $2`.

### 8.4 Quote Shorthand
`QUOTE expr → Ast.List [Ast.Symbol "quote"; expr]`

`'foo` desugars to `(quote foo)` at parse time, so the type-checker never
needs to handle the `'` character separately.

### 8.5 Error Handling
An unclosed parenthesis (test §2.3.5) causes `ocamlyacc` to raise
`Parsing.Parse_error`, which `main.ml` catches and prints as a parse error.

---

## 9. typecheck.ml — Type Checker

### 9.1 Central Entry Points

```ocaml
typecheck_program : expr list -> (expr * lithp_type list) list
infer : Env.env -> Ast.expr -> lithp_type list
check : Env.env -> Ast.expr -> lithp_type -> bool
```

`infer` returns a **list of possible types** (union typing). `TAny` acts as a
wildcard: `types_equal TAny T = true` for every `T`.

### 9.2 Global Mutable State

```ocaml
let global_env : (string * lithp_type list) list ref = ref []
```

`defun` and `label` register function types in `global_env`. Because this is a
module-level `ref`, definitions persist across separate calls to
`typecheck_program` within the same process. This enables mutual recursion but
means test ordering can affect results (the `fact` defun in §2.4.7 remains
registered for any subsequent typecheck in the same run).

### 9.3 Environment Lookup

```ocaml
lookup_with_global name env:
  try List.assoc name env          (* local env first *)
  with Not_found ->
    match lookup_global name with  (* then global_env *)
    | Some ts → ts
    | None    → failwith ("Unbound variable: " ^ name)
```

### 9.4 `infer` Dispatch Table

| Expression | Result |
|------------|--------|
| `Ast.Num _` | `[TInt]` |
| `Ast.Bool _` | `[TBool]` |
| `Ast.Nil` | `[TBool; TList 0]` — nil is both a boolean and an empty list |
| `Ast.Symbol s` | `lookup_with_global s env` |
| `Ast.List (Symbol op :: args)` | Dispatch to `check_<op>` (see §9.5) |
| `Ast.List (func :: args)` | `check_apply env func args` |
| `_` | `[]` |

All `check_<op>` calls are wrapped in:
```ocaml
try ... with Failure msg -> failwith ("Error in " ^ op ^ ": " ^ msg)
```

### 9.5 Operator Checking Functions

#### `check_quote env args`
| Quoted value | Type |
|-------------|------|
| `List es` | `TList (List.length es)` |
| `Num _` | `TInt` |
| `Bool _` or `Symbol _` | `TSymbol` |
| `Nil` | `TList 0` |

#### `check_atom env args`
Always returns `[TBool]` for exactly one argument (regardless of the argument's type — any value can be tested for atomness).

#### `check_eq env args`
Returns `[TBool]` if the two arguments share at least one compatible type (via `types_equal`). Returns `[]` — no error raised — if types are incompatible. This means `(eq 1 t)` produces `<no type>`, not a type error message.

#### `check_car env args`
Infers the argument's types. If any is `TList(n)` with `n > 0`, returns `[TInt; TBool; TList 0]` (the head could be any element type). Otherwise raises `Failure "car expects a non-empty list"`.

#### `check_cdr env args`
Finds a `TList(n)` with `n > 0` in the argument's types; returns `[TList(n-1)]`. Also accepts `TAny` (returns `[TAny]`). Raises failure on empty list or non-list.

#### `check_caddr` / `check_cddr`
Specialised helpers: `caddr` requires `TList(n ≥ 3)` → `[TAny]`; `cddr` requires `TList(n ≥ 2)` → `[TList(n-2)]`.

#### `check_cons env args`
Takes `[element; list]`. Infers the second argument's type. If it is `TList n` → `[TList(n+1)]`. If `TAny` → `[TList 1]`. Otherwise raises failure.

#### `check_cond env clauses`
Iterates clauses. For each `[test; result]` pair:
- Infers the test's types.
- If any is `TBool`, `TSymbol`, or `TList(n > 0)` → the clause is **truthy-possible** → include `infer result` in the output.
- `TInt` conditions are **not** considered truthy (unlike standard Lisp).

Returns the union (`List.sort_uniq`) of all truthy-clause result types.

#### `check_arith_op env op args`

| Operator | Constraint | Result |
|----------|-----------|--------|
| `+`, `*` | ≥ 2 args, all `TInt` | `[TInt]` |
| `-`, `div`, `mod` | exactly 2 args, both `TInt` | `[TInt]` |

Returns `[]` (no error) if constraints are not met.

#### `check_compare_op env op args`
`>`, `<`, `>=`, `<=` require exactly 2 integer arguments → `[TBool]`. Raises `Failure` if arguments are not integers.

#### `check_logic_op env op args`
- `not` : 1 bool arg → `[TBool]`
- `and`, `or` : exactly 2 bool args → `[TBool]`

Raises `Failure` on arity or type mismatch.

#### `check_lambda env args`
Form: `(lambda (p1 p2 …) body)`

Each parameter `pi` is bound as `TAny` in an extended environment. The body is
inferred in that environment. Returns one `TFun` type per possible body type:
```
[TFun ([TAny; TAny; …], ret) for each ret in infer new_env body]
```

#### `check_defun env args`
Form: `(defun name (p1 p2 …) body)`

Two-phase to support recursion:
1. Register a placeholder `TFun([TAny;…], TAny)` in `global_env`.
2. Infer the body (with the placeholder available for recursive calls).
3. Register the concrete `TFun([TAny;…], actual_ret)`.
4. Return `[concrete_type]`.

#### `check_apply env func args`
Infers `func`'s types; infers each argument's types. For each `TFun(params, ret)` in the function's type list:
- Check arity matches.
- Check each `param_type` is compatible with at least one inferred arg type.
If any signature matches, collect `ret` in the result. Raises `Failure` if no
signature matches.

### 9.6 Type Compatibility Summary

| Expression | Expected Type |
|------------|--------------|
| `t` | `TBool` |
| `()` | `TBool`, `TList 0` |
| `12345` | `TInt` |
| `'(a b c d)` | `TList 4` |
| `(+ 1 2 3)` | `TInt` |
| `(> 5 3)` | `TBool` |
| `(atom 1)` | `TBool` |
| `(cdr '(a b c))` | `TList 2` |
| `(cons 1 '(2 3))` | `TList 3` |
| `(eq 1 t)` | `<no type>` (silently incompatible) |
| `(car ())` | **TYPE ERROR** (car on empty list) |
| `(cons 1 2)` | **TYPE ERROR** (second arg not a list) |
| `((lambda (x y) (+ x y)) 4 5)` | `TInt` |
| `((lambda (x y) …) 4)` (arity mismatch) | **TYPE ERROR** |
| `(defun fact (n) …)` | `TFun([TAny], TInt)` → printed as `"List(1) -> Int"` |

---

## 10. main.ml — Test Driver

### 10.1 Structure

`main.ml` is split into five logical sections:

| Section | Contents |
|---------|---------|
| Helpers | `pp`, `mb`, `section`, `sub`, `bigint_result`, `bool_result` |
| Pipeline wrappers | `lex_string`, `parse_string`, `typecheck_string` |
| Printers | `print_toks`, `print_asts`, `print_typed` |
| Test case runners | `run_bigint_tests`, `run_lex_tests`, `run_parse_tests`, `run_tc_tests` |
| File-mode runners | `run_lex_file`, `run_parse_file`, `run_tc_file` |

### 10.2 Pipeline Wrappers

```ocaml
lex_string s        (* calls Lexer.token_lex repeatedly → Token list *)
parse_string s      (* Lexing.from_string s → Parser.program Lexer.token *)
typecheck_string s  (* parse_string s → Typecheck.typecheck_program *)
```

### 10.3 Error Handling Strategy

Every test case is wrapped in a `try … with` to ensure a single failing case
does not abort the entire test run:

- `bigint_result` catches `DivisionByZero` and `InvalidBigInt`.
- `lex_case` catches any exception from the lexer.
- `parse_case` catches `Parsing.Parse_error` and others.
- `tc_case` catches `Failure msg` (type errors) and any other exception.

### 10.4 Mode Dispatch

```
Sys.argv pattern      Action
───────────────       ──────
["bigint"]            run_bigint_tests ()
["lex"; path]         run_lex_file path
["parse"; path]       run_parse_file path
["typecheck"; path]   run_tc_file path
["testall"]           all four test suites in order
_                     print usage
```

### 10.5 Note on global_env and Test Ordering

`Typecheck.global_env` is a module-level `ref []`. When `run_tc_tests` runs
§2.4.7 (`defun fact`), the `fact` function is permanently registered in
`global_env` for the remainder of the process. If additional typecheck tests
were added after §2.4.7, `fact` would be visible to them. This is inherent to
the design of `typecheck.ml` (the `.mli` does not expose `global_env`, so it
cannot be reset from `main.ml`).
