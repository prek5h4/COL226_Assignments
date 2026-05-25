# Assignment 4: Stack-based Evaluator for Combinatory Logic

## Overview

This assignment implements a compiler from Lambda Calculus to Combinatory Logic (CL) and a stack-based evaluator for CL terms. The implementation follows the theory presented in the lecture notes on Combinatory Logic.

## Theory Background

### What is Combinatory Logic?

Combinatory Logic is a formal system that provides a way to encode functions without using binding or bound variable occurrences. It was developed by Moses Schönfinkel around 1921 as a target language for proof systems.

### The Three Combinators

- **I** (Identity): `I x = x`
- **K** (Constant): `K x y = x`
- **S** (Substitution): `S x y z = (x z)(y z)`

These three combinators are sufficient to express any computable function!

### Translation from Lambda Calculus

The translation uses an abstraction operation `[x]P` that removes a variable from a term:

1. `[x]x = I`
2. `[x]P = K P` when `x` is not free in `P`
3. `[x](P Q) = S ([x]P) ([x]Q)`

Then we can translate lambda terms:
- `⌈x⌉ = x`
- `⌈e1 e2⌉ = ⌈e1⌉ ⌈e2⌉`
- `⌈λx.e⌉ = [x](⌈e⌉)`


### What Each Function Should Do

#### `occurs_free: string -> comb -> bool`
Helper to check if a variable occurs free in a CL term.

#### `abs: string -> comb -> comb`
Implements the `[x]P` abstraction operation:
```ocaml
[x]x = I
[x]P = K P  (when x not in P)
[x](P Q) = S ([x]P) ([x]Q)
```

#### `trans2CL: lam -> comb`
Translates lambda calculus to combinatory logic:
```ocaml
⌈x⌉ = x
⌈e1 e2⌉ = ⌈e1⌉ ⌈e2⌉
⌈λx.e⌉ = [x](⌈e⌉)
```

#### `wnf: comb -> comb list -> comb`
Stack-based evaluator using these reduction rules:
```ocaml
(I, c::s) => (c, s)
(K, c1::c2::s) => (c1, s)
(S, c1::c2::c3::s) => (Appc(Appc(c1,c3), Appc(c2,c3)), s)
(Appc(c1,c2), s) => (c1, c2::s)
Otherwise => unstack c s
```

#### `unstack: comb -> comb list -> comb`
Rebuilds term from stack when no reduction rules apply:
```ocaml
unstack(c, []) = c
unstack(c, c2::rest) = 
  let c' = wnf(c2, []) in
  unstack(Appc(c, c'), rest)
```

## File Structure

```
Ass4.ml              
README.md            
```

## How to Use

### Running the Corrected Implementation

```bash
ocaml
# use "Ass4.ml";;
```

### Running Tests

```bash
ocaml
# use "Ass4.ml";;
```

### Example Usage

```ocaml
(* Evaluate basic combinators *)
let term1 = Appc (I, Vc "x");;
eval term1;;  (* Returns: Vc "x" *)

let term2 = Appc (Appc (K, Vc "a"), Vc "b");;
eval term2;;  (* Returns: Vc "a" *)

(* Translate lambda calculus to CL *)
let id = Lam ("x", V "x");;
trans2CL id;;  (* Returns: I *)

let const = Lam ("x", Lam ("y", V "x"));;
trans2CL const;;  (* Returns: K *)

(* Church numerals *)
let comb_zero = trans2CL zero;;
let comb_one = trans2CL one;;
let comb_succ = trans2CL succ;;

(* Apply successor to zero *)
let result = eval (Appc (comb_succ, comb_zero));;
```

## Test Suite Coverage

The test suite includes:

1. **Basic Combinator Evaluation** (Tests 1)
   - I combinator
   - K combinator
   - S combinator

2. **Abstraction Operation** (Tests 2)
   - `[x]x = I`
   - `[x]y = K y`
   - `[x](x x) = S I I`

3. **Lambda Calculus Translation** (Tests 3)
   - Identity function
   - Constant function
   - Self-application

4. **Church Numerals** (Tests 4)
   - Translation of 0, 1, 2, 3
   - Successor function

5. **Church Arithmetic** (Tests 5)
   - Addition
   - Multiplication

6. **Complex Lambda Terms** (Tests 6)
   - Function composition
   - Omega combinator

7. **Stack Operations** (Tests 7)
   - Various stack configurations
   - Edge cases

8. **Back Translation** (Tests 8)
   - CL to Lambda Calculus

9. **Round-trip Translation** (Tests 9)
   - Lambda -> CL -> Lambda

10. **Edge Cases** (Tests 10)
    - Empty stack
    - Nested applications

## Key Concepts to Understand

### Why Use Combinatory Logic?

- **No variable binding**: Avoids the complexity of α-conversion and β-reduction
- **Simple substitution**: No capture-avoiding substitution needed
- **Target language**: Good intermediate representation for compilers
- **Theoretical importance**: Shows that binding is not fundamental to computation

### The Abstraction Operation

The abstraction `[x]P` is the key to eliminating variables. It answers:
"How do I make a function that, when given argument R, behaves like P[R/x]?"

The three rules systematically build up this behavior using only S, K, and I.

### Stack-based Evaluation

The stack machine provides an efficient way to evaluate CL terms:
- Push arguments onto stack
- When you have enough arguments, apply reduction rules
- If stuck, rebuild the term from the stack

This is similar to how real machines evaluate function calls!

