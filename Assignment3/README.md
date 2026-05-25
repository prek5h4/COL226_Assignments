# Assignment 3 — Abstract Machines for Functional Languages

Implementation of two abstract machines for toy functional languages based on the **Call-by-Name** and **Call-by-Value** lambda calculi, in OCaml.

---

## Table of Contents

1. [Project Structure](#project-structure)
2. [The Lambda Calculus AST](#the-lambda-calculus-ast)
3. [Krivine Machine — Call-by-Name](#krivine-machine--call-by-name)
   - [Theory](#krivine-theory)
   - [Implementation 1: List-Based Environment](#krivine-1-list-based-environment)
   - [Implementation 2: Function-Based Environment](#krivine-2-function-based-environment)
   - [The Unpack Function](#the-unpack-function)
4. [SECD Machine — Call-by-Value](#secd-machine--call-by-value)
   - [Theory](#secd-theory)
   - [Compiler](#compiler)
   - [Implementation 1: List-Based Environment](#secd-1-list-based-environment)
   - [Implementation 2: Function-Based Environment](#secd-2-function-based-environment)
5. [Call-by-Name vs Call-by-Value](#call-by-name-vs-call-by-value)
6. [Church Encodings Used in Tests](#church-encodings-used-in-tests)
7. [Test Cases and Results](#test-cases-and-results)
8. [How to Compile and Run](#how-to-compile-and-run)
9. [Extra Credit: Integers and Booleans](#extra-credit-integers-and-booleans)

---

## Project Structure

```
Assignment3/
├── Ast.ml          — Shared lambda calculus AST definition
├── krivine_1.ml    — Krivine machine with list-based environments
├── krivine_2.ml    — Krivine machine with function-based environments
├── SECD_1.ml       — SECD machine with list-based environments
├── SECD_2.ml       — SECD machine with function-based environments
└── test.ml         — All test cases for both machines, both implementations
```

---

## The Lambda Calculus AST

**File:** `Ast.ml`

```ocaml
type var = string

type expr =
  | Var  of var          (* variable: x *)
  | Lam  of var * expr   (* abstraction: λx. e *)
  | App  of expr * expr  (* application: e1 e2 *)
  | Num  of int          (* integer literal: 42 *)
  | Bool of bool         (* boolean literal: true/false *)
```

This is the shared abstract syntax tree used by both machines. Every lambda calculus expression is represented as an OCaml value of type `expr`.

| Constructor | Lambda Notation | Example |
|---|---|---|
| `Var "x"` | `x` | A variable reference |
| `Lam ("x", e)` | `λx. e` | A function definition |
| `App (e1, e2)` | `e1 e2` | A function application |
| `Num 42` | `42` | Integer (extra credit) |
| `Bool true` | `true` | Boolean (extra credit) |

---

## Krivine Machine — Call-by-Name

### Krivine Theory

The Krivine machine evaluates lambda terms using **call-by-name** semantics. This means arguments are **never evaluated before being passed** to a function — they are passed as unevaluated expressions paired with their environment (called closures).

A **closure** is a pair `<<e, γ>>` where:
- `e` is a lambda expression
- `γ` (gamma) is an environment mapping variables to closures

The machine state is a pair `(closure, stack)` where the stack holds argument closures waiting to be applied.

#### Transition Rules

```
(Op)  <<(e1 e2), γ>>, S        =>  <<e1, γ>>,  <<e2, γ>> :: S
      -- Application: push argument e2 (unevaluated) onto stack, evaluate e1

(Var) <<x, γ>>, S              =>  γ(x), S
      -- Variable: look up x in environment, return its closure

(App) <<λx.e1, γ>>, cl :: S   =>  <<e1, γ[x → cl]>>, S
      -- Lambda with arg: bind top of stack to x, evaluate body
```

The machine **halts** when:
- The current closure is a `λ` and the stack is empty (normal form reached)
- The current closure is a `Num` or `Bool` literal

#### Why Call-by-Name?

In the `(Op)` rule, `e2` is pushed as an **unevaluated closure** `<<e2, γ>>`. It is only evaluated if and when the function body actually uses the variable `x`. This is lazy evaluation — unused arguments are never evaluated.

---

### Krivine 1: List-Based Environment

**File:** `krivine_1.ml`

#### Types

```ocaml
type closure = Clo of expr * env
and env = (var * closure) list
(* Environment is a list of (variable, closure) pairs.
   New bindings are prepended so the most recent binding
   for a variable is found first (shadowing). *)

type stack = closure list
(* Stack of unevaluated argument closures *)
```

#### Environment Operations

```ocaml
(* Lookup: search the association list for variable x.
   Returns the closure bound to x, or raises an error. *)
let rec lookup gamma x = match gamma with
  | [] -> failwith ("Unbound variable: " ^ x)
  | (y, v) :: xs -> if x = y then v else lookup xs x

(* Extend: add a new binding (x -> v) at the front of the list.
   Shadowing is handled automatically since lookup finds
   the first match. *)
let extend gamma x v = (x, v) :: gamma
```

#### The Three Rules

```ocaml
(* (Var) rule: look up variable in environment, keep stack unchanged *)
let rule_var = function
  | (Clo (Var x, gamma), stack) -> (lookup gamma x, stack)
  | _ -> failwith "rule_var: not a variable"

(* (Op) rule: push unevaluated argument onto stack, continue with function *)
let rule_app = function
  | (Clo (App (e1, e2), gamma), stack) ->
      (Clo (e1, gamma), Clo (e2, gamma) :: stack)
  | _ -> failwith "rule_app: not an application"

(* (App) rule: pop argument from stack, bind to lambda's variable *)
let rule_lam = function
  | (Clo (Lam (x, e), gamma), v :: stack) ->
      (Clo (e, extend gamma x v), stack)
  | (_, []) -> failwith "rule_lam: empty stack"
  | _       -> failwith "rule_lam: not a lambda"
```

#### Run Loop

```ocaml
let rec run (closure, stack) =
  match (closure, stack) with
  | (Clo (Var _, _), s)        -> run (rule_var (closure, s))
  | (Clo (App _, _), s)        -> run (rule_app (closure, s))
  | (Clo (Lam _, _), _ :: _)   -> run (rule_lam (closure, stack))
  (* Halting states — machine is stuck in a normal form *)
  | (Clo (Lam _, _),  [])      -> closure
  | (Clo (Num _, _),  [])      -> closure
  | (Clo (Bool _, _), [])      -> closure
  (* Error states *)
  | (Clo (Num _, _),  _ :: _)  -> failwith "Cannot apply a number"
  | (Clo (Bool _, _), _ :: _)  -> failwith "Cannot apply a boolean"
```

---

### Krivine 2: Function-Based Environment

**File:** `krivine_2.ml`

The only difference from `krivine_1.ml` is how the environment is represented. All machine rules and the run loop are identical.

#### Types

```ocaml
type closure = Clo of expr * env
and env = var -> closure
(* Environment is now a FUNCTION from variables to closures.
   This is the mathematical definition of an environment. *)
```

#### Environment Operations

```ocaml
(* empty_env: base environment that raises an error for any lookup.
   Needed because there is no [] equivalent for function types. *)
let empty_env = fun x -> failwith ("Unbound variable: " ^ x)

(* lookup: just apply the environment function to the variable *)
let lookup gamma x = gamma x

(* extend: return a NEW function that checks x first,
   then delegates to the old gamma for everything else.
   This is functional update / override. *)
let extend gamma x v = fun y -> if y = x then v else gamma y
```

#### Key Difference from krivine_1

| Operation | krivine_1 (list) | krivine_2 (function) |
|---|---|---|
| Empty env | `[]` | `fun x -> failwith ...` |
| Lookup | Linear search through list | Direct function application |
| Extend | Prepend `(x,v)` to list | Return new function |
| Time complexity | O(n) lookup | O(depth) lookup |

#### Unpack (function env version)

Since the environment is a function, we cannot iterate over it with `List.assoc_opt` or `List.filter`. Instead:

```ocaml
let rec unpack (Clo (e, gamma)) =
  match e with
  | Var x ->
      (* Try looking up x; if it's free (unbound), leave it as Var x *)
      (try unpack (lookup gamma x)
       with Failure _ -> Var x)
  | Lam (x, body) ->
      (* Shadow x so we don't substitute the bound variable.
         Map x back to itself to "protect" it during unpacking. *)
      let gamma' = extend gamma x (Clo (Var x, empty_env)) in
      Lam (x, unpack (Clo (body, gamma')))
  ...
```

---

### The Unpack Function

`unpack` converts the final closure returned by `run` back into a readable lambda expression `expr`. This is necessary because the result of the Krivine machine is a closure `<<e, γ>>`, not a plain term.

#### Why Unpack is Needed

When the machine halts, the result is something like:
```
<<λy. y,  {x → <<λa. a, {}>>}>>
```
This means "the term `λy. y` in an environment where `x` is bound to `λa. a`". The `unpack` function reconstructs what the term *would be* after substituting the environment back in.

#### Algorithm (list env version)

```ocaml
let rec unpack (Clo (e, gamma)) =
  match e with
  | Num n  -> Num n       (* primitives unpack to themselves *)
  | Bool b -> Bool b
  | Var x  ->
      (* Look up x in environment; recursively unpack the result.
         If x is free (not in gamma), leave it as Var x. *)
      (match List.assoc_opt x gamma with
       | Some cl -> unpack cl
       | None    -> Var x)
  | App (e1, e2) ->
      (* Unpack both sides under the same environment *)
      App (unpack (Clo (e1, gamma)), unpack (Clo (e2, gamma)))
  | Lam (x, body) ->
      (* Remove x from gamma before unpacking the body.
         x is now a BOUND variable — we must not substitute it. *)
      let gamma' = List.filter (fun (y, _) -> y <> x) gamma in
      Lam (x, unpack (Clo (body, gamma')))
```

---

## SECD Machine — Call-by-Value

### SECD Theory

The SECD machine evaluates lambda terms using **call-by-value** semantics. Arguments are **fully evaluated before being passed** to a function.

The machine has four components:

| Component | Type | Purpose |
|---|---|---|
| **S** (Stack) | `val_closure list` | Holds evaluated values |
| **E** (Environment) | `env` | Maps variables to values |
| **C** (Control) | `opcode list` | The remaining program (opcodes to execute) |
| **D** (Dump) | `(S * E * C) list` | Saved machine states for returning from calls |

A **value closure** is `Clo (x, code, γ)` where:
- `x` is the bound variable
- `code` is the compiled body (list of opcodes)
- `γ` is the environment captured at closure creation time

#### Opcodes

```
LOOKUP(x)     — look up variable x in environment, push value onto S
MkCLOS(x, c) — create a closure with variable x and body c, push onto S
APP           — apply function to argument (both on S), save state to D
RET           — return from function call, restore state from D
PUSH_NUM(n)   — push integer literal onto S  [extra credit]
PUSH_BOOL(b)  — push boolean literal onto S  [extra credit]
```

#### Transition Rules

```
(Var)  s, γ, LOOKUP(x)::c, d
       ==>  γ(x)::s, γ, c, d
       -- Look up x, push its value onto stack

(Clos) s, γ, MkCLOS(x,c1)::c, d
       ==>  <<x,c1,γ>>::s, γ, c, d
       -- Create closure capturing current environment, push onto stack

(App)  v2::(<<x,c1,γ1>>::s), γ, APP::c, d
       ==>  [], γ1[x→v2], c1, (s,γ,c)::d
       -- v2 is arg (top of stack), <<x,c1,γ1>> is function (below it)
       -- Save current (s,γ,c) to dump, start evaluating function body

(Ret)  v::_, γ', RET::_, (s,γ,c)::d
       ==>  v::s, γ, c, d
       -- Function returned value v; restore saved state from dump
       -- Push v onto the restored stack
```

#### Why Call-by-Value?

The compiler generates `compile(e2)` **before** `APP` in the opcode sequence for an application. This means `e2` is fully evaluated and its result pushed onto `S` before `APP` fires. The `APP` rule then finds an already-evaluated value on top of the stack.

---

### Compiler

```ocaml
(* Compile a lambda expression into a list of opcodes.
   This is a pure syntactic transformation — no environment needed. *)
let rec compile = function
  | Var x        -> [LOOKUP x]
  (* Variable: emit a lookup instruction *)

  | Lam (x, e)  -> [MKCLOS (x, compile e @ [RET])]
  (* Lambda: compile body, append RET, wrap in MKCLOS.
     RET tells the machine to return when the body is done. *)

  | App (e1, e2) -> compile e1 @ compile e2 @ [APP]
  (* Application: evaluate function, then argument, then apply.
     Note: e2 is fully compiled (will be fully evaluated) before APP fires.
     This is what makes it call-by-value. *)

  | Num n        -> [PUSH_NUM n]
  | Bool b       -> [PUSH_BOOL b]
```

---

### SECD 1: List-Based Environment

**File:** `SECD_1.ml`

#### Types

```ocaml
type opcode =
  | LOOKUP   of var
  | MKCLOS   of var * opcode list
  | APP
  | RET
  | PUSH_NUM  of int
  | PUSH_BOOL of bool

type val_closure =
  | Clo   of var * opcode list * env   (* function closure *)
  | VNum  of int                        (* evaluated integer *)
  | VBool of bool                       (* evaluated boolean *)
and env = (var * val_closure) list

type stack = val_closure list
type dump  = (stack * env * opcode list) list
```

#### Run Function

```ocaml
let rec run (s : stack) (gamma : env) (c : opcode list) (d : dump) =
  match c with
  | [] ->
      (* Control is empty — check if we're truly done *)
      (match s, d with
       | [v], []               -> v          (* one value, empty dump: done *)
       | v :: _, (s',g',c')::d' -> run (v::s') g' c' d'  (* return *)
       | _ -> failwith "Stuck")

  | LOOKUP x :: c' ->
      (* (Var) rule: find x in environment, push onto stack *)
      run (lookup gamma x :: s) gamma c' d

  | MKCLOS (x, c1) :: c' ->
      (* (Clos) rule: create closure capturing current gamma *)
      run (Clo (x, c1, gamma) :: s) gamma c' d

  | APP :: c' ->
      (* (App) rule: argument v2 is on TOP, function closure below it *)
      (match s with
       | v2 :: Clo (x, c1, gamma1) :: s' ->
           run [] (extend gamma1 x v2) c1 ((s', gamma, c') :: d)
       | _ -> failwith "APP: type error or stack underflow")

  | RET :: _ ->
      (* (Ret) rule: pop result, restore saved state from dump *)
      (match s, d with
       | v :: _, (s', gamma', c') :: d' -> run (v :: s') gamma' c' d'
       | _ -> failwith "RET: empty dump")

  | PUSH_NUM n :: c'  -> run (VNum n  :: s) gamma c' d
  | PUSH_BOOL b :: c' -> run (VBool b :: s) gamma c' d
```

---

### SECD 2: Function-Based Environment

**File:** `SECD_2.ml`

Same machine logic as `SECD_1.ml`. Only the environment representation changes:

```ocaml
(* Function-based environment *)
and env = var -> val_closure

let empty_env = fun x -> failwith ("Unbound variable: " ^ x)
let lookup gamma x = gamma x
let extend gamma x v = fun y -> if y = x then v else gamma y
```

Initial call uses `empty_env` instead of `[]`:
```ocaml
SECD_2.run [] SECD_2.empty_env code []
```

---

## Call-by-Name vs Call-by-Value

| Property | Krivine (CBN) | SECD (CBV) |
|---|---|---|
| When are arguments evaluated? | Only if/when used | Always, before the call |
| Unused diverging argument | Safely ignored | Causes infinite loop |
| Duplicate argument usage | Re-evaluated each time | Evaluated once, reused |
| Environment holds | Unevaluated closures | Fully evaluated values |
| Stack holds | Unevaluated closures | Evaluated values |

#### Classic Distinguishing Example

```
(λx. λy. y)  Ω       where Ω = (λx. x x)(λx. x x) — infinite loop
```

- **Krivine** → returns `λy. y` immediately. `Ω` is pushed onto the stack but the body `λy. y` never uses `x`, so `Ω` is never evaluated.
- **SECD** → loops forever. Before calling the function, it tries to evaluate `Ω`, which diverges.

Our test cases all produce the same results on both machines because none of the test arguments diverge or have side effects.

---

## Church Encodings Used in Tests

Church encodings represent data and control flow as pure lambda terms.

```
(* Booleans *)
true  = λt. λf. t          (* selects first argument *)
false = λt. λf. f          (* selects second argument *)
if    = λb. λt. λf. b t f  (* applies boolean to two branches *)

(* Pairs *)
pair  = λx. λy. λf. f x y  (* stores x and y, applies selector f *)
fst   = λp. p true          (* selects first element *)
snd   = λp. p false         (* selects second element *)

(* Identity *)
id    = λx. x
```

These are defined in `test.ml` as OCaml values of type `expr`.

---

## Test Cases and Results

All 8 tests run on all 4 implementations (Krivine 1, Krivine 2, SECD 1, SECD 2).

| # | Test | Expression | Expected | What it tests |
|---|---|---|---|---|
| 1 | Identity | `(λx.x)(λy.y)` | `λy.y` | Basic beta reduction |
| 2 | if-true | `if true (λx.x) (λy.y)` | `λx.x` | Boolean left branch |
| 3 | if-false | `if false (λx.x) (λy.y)` | `λy.y` | Boolean right branch |
| 4 | fst pair | `fst (pair (λx.x) (λy.y))` | `λx.x` | Pair + projection |
| 5 | snd pair | `snd (pair (λx.x) (λy.y))` | `λy.y` | Pair + projection |
| 6 | Constant K | `(λx.λy.x)(λa.a)(λb.b)` | `λa.a` | Variable shadowing |
| 7 | Num literal | `42` | `42` | Integer primitive |
| 8 | Bool literal | `true` | `true` | Boolean primitive |

### Results

```
========== KRIVINE MACHINE 1 (list env) ==========
Identity      → (λy. y)    ✓
if-true       → (λx. x)    ✓
if-false      → (λy. y)    ✓
fst of pair   → (λx. x)    ✓
snd of pair   → (λy. y)    ✓
Constant K    → (λa. a)    ✓
Num 42        → 42         ✓
Bool true     → true       ✓

========== KRIVINE MACHINE 2 (function env) ==========
[identical results — confirms both env representations are equivalent]

========== SECD MACHINE 1 (list env) ==========
Identity      → <closure λy>    ✓
if-true       → <closure λx>    ✓
if-false      → <closure λy>    ✓
fst of pair   → <closure λx>    ✓
snd of pair   → <closure λy>    ✓
Constant K    → <closure λa>    ✓
Num 42        → 42              ✓
Bool true     → true            ✓

========== SECD MACHINE 2 (function env) ==========
[identical results — confirms both env representations are equivalent]
```

SECD results show `<closure λx>` because the machine returns a `val_closure`, not an unpacked term. The variable name confirms which lambda was returned.

---

## How to Compile and Run

### Prerequisites

```bash
# Install OCaml and ocamlfind
sudo apt install ocaml ocamlfind
```

### Compile Step by Step

```bash
# Clean any previous build artifacts
rm -f *.cmi *.cmx *.o

# Compile in dependency order
ocamlfind ocamlopt -c Ast.ml
ocamlfind ocamlopt -c krivine_1.ml
ocamlfind ocamlopt -c krivine_2.ml
ocamlfind ocamlopt -c SECD_1.ml
ocamlfind ocamlopt -c SECD_2.ml
ocamlfind ocamlopt -c test.ml

# Link into executable
ocamlfind ocamlopt -linkpkg \
  Ast.cmx krivine_1.cmx krivine_2.cmx SECD_1.cmx SECD_2.cmx test.cmx \
  -o run_tests

# Run
./run_tests
```

### Important Notes

- Files **must** be compiled in dependency order — `Ast.ml` first since all other files `open Ast`
- OCaml module names come from filenames: `krivine_1.ml` → module `Krivine_1`
- Module names must start with a capital letter; filenames should match (e.g. `Ast.ml` not `AST.ml`)

---

## Extra Credit: Integers and Booleans

Both machines support integer and boolean literals as primitive values, extending pure lambda calculus.

### AST Extensions

```ocaml
| Num  of int    (* integer: 42, 0, -1 *)
| Bool of bool   (* boolean: true, false *)
```

### Krivine Extensions

Num and Bool closures are **halting states** — the machine stops immediately when it reaches one (with an empty stack):

```ocaml
| (Clo (Num _, _),  []) -> closure    (* halt: integer result *)
| (Clo (Bool _, _), []) -> closure    (* halt: boolean result *)
```

`unpack` converts them back trivially:
```ocaml
| Num n  -> Num n
| Bool b -> Bool b
```

### SECD Extensions

Two new opcodes are added:

```ocaml
| PUSH_NUM  of int    (* push integer value onto stack *)
| PUSH_BOOL of bool   (* push boolean value onto stack *)
```

Two new value constructors are added to `val_closure`:

```ocaml
| VNum  of int     (* an evaluated integer on the stack *)
| VBool of bool    (* an evaluated boolean on the stack *)
```

Compiler handles them:
```ocaml
| Num n  -> [PUSH_NUM n]
| Bool b -> [PUSH_BOOL b]
```

Machine handles them:
```ocaml
| PUSH_NUM n  :: c' -> run (VNum n  :: s) gamma c' d
| PUSH_BOOL b :: c' -> run (VBool b :: s) gamma c' d
```
