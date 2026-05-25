[README.md](https://github.com/user-attachments/files/28218614/README.md)
# First-Order Logic Signatures and Expressions in OCaml

An OCaml implementation for representing and manipulating first-order logic signatures, expressions, substitutions, and predicates.

---

## Overview

This program implements a formal system for first-order logic, providing:

1. **Signature validation** - ensuring function symbols are well-defined
2. **Expression construction** - building and validating expression trees
3. **Substitution operations** - replacing variables with expressions
4. **Predicate formulas** - representing and manipulating logical formulas
5. **Position-based editing** - modifying expressions at specific locations

---

## Type Representations

### Core Types

```ocaml
type symbol = string * int              (* Function symbols: (name, arity) *)
type signature = symbol list            (* Signature: list of function symbols *)
type variable = string                  (* Variables: simple string identifiers *)
type pred_symbol = string * int         (* Predicate symbols: (name, arity) *)
```

### Expression Types

```ocaml
type exp = 
  | V of variable                       (* Variable *)
  | Node of symbol * exp array          (* Function application *)
```

### Predicate Types

```ocaml
type pred = 
  | T                                   (* True *)
  | F                                   (* False *)
  | Pred of pred_symbol * exp array     (* Predicate application *)
  | Not of pred                         (* Negation *)
  | And of pred * pred                  (* Conjunction *)
  | Or of pred * pred                   (* Disjunction *)
```

### Other Types

```ocaml
type substitution = variable -> exp option   (* Partial function from variables to expressions *)
type position = int list                     (* Path from root (1-indexed list of child indices) *)
```

---

## Module Structure

```
Program Structure:
├── Signature Operations
│   ├── sig_map             - Create map from signature
│   ├── check_duplicates    - Check for duplicate symbols
│   ├── has_negative_arity  - Check for negative arities
│   ├── check_sig           - Main validation function
│   └── arity_of            - Lookup symbol arity
│
├── Expression Module (Exp)
│   ├── wfexp              - Well-formedness check
│   ├── ht                 - Height computation
│   ├── size               - Size computation
│   └── vars               - Variable extraction
│
├── Substitution Operations
│   ├── subst              - Apply substitution
│   ├── compose            - Compose substitutions
│   └── in_place_sub       - In-place substitution (mutating)
│
├── Position Operations
│   ├── positions          - Find sub-expression positions
│   └── edit               - Replace at position
│
└── Predicate Operations
    ├── wff                - Well-formedness check
    ├── psubst             - Apply substitution to predicate
    └── wp                 - Weakest precondition
```

---

## Function Reference & Time Complexity

| Function | Type | Description | Time Complexity |
|----------|------|-------------|-----------------|
| **Signature Functions** |
| `check_sig` | `signature -> bool` | Validates signature (no duplicates, arities ≥ 0) | O(n²) |
| `arity_of` | `signature -> string -> int` | Gets symbol arity | O(n) |
| `sig_hashtbl` | `signature -> (string, int) Hashtbl.t` | Creates hash table | O(n) |
| `has_negative_arity` | `Hashtbl.t -> bool` | Checks all arities ≥ 0 | O(n) |
| **Expression Functions** |
| `Exp.wfexp` | `signature -> exp -> bool` | Well-formedness check | O(n) |
| `Exp.ht` | `exp -> int` | Expression height | O(n) |
| `Exp.size` | `exp -> int` | Number of nodes | O(n) |
| `Exp.vars` | `exp -> variable array` | Extract distinct variables | O(n) |
| **Substitution Functions** |
| `subst` | `substitution -> exp -> exp` | Apply substitution (functional) | O(n) |
| `compose` | `substitution -> substitution -> substitution` | Compose substitutions (s1 ∘ s2) | O(1)* |
| `in_place_sub` | `substitution -> exp -> exp` | In-place substitution (mutating) | O(n) |
| **Position Functions** |
| `positions` | `exp -> exp -> position list` | Find all positions of sub-expression | O(n×m) |
| `edit` | `exp -> position -> exp -> exp` | Replace sub-expression at position | O(d) |
| **Predicate Functions** |
| `wff` | `signature -> pred -> bool` | Well-formedness check | O(p×e) |
| `psubst` | `pred -> substitution -> pred` | Apply substitution to predicate | O(p×e) |
| `wp` | `variable -> exp -> pred -> pred` | Weakest precondition p[e/x] | O(p×e) |

**Legend**: 
- n = size of signature or expression
- m = size of sub-expression
- d = depth of position path
- p = size of predicate formula
- e = average expression size
- \* = O(1) to create, O(e) per application

---

## Requirements

### OCaml Version
- OCaml 4.08 or later recommended

### Standard Libraries
- `List` - List operations
- `Array` - Array operations (map, fold, iter, etc.)
- `Hashtbl` - Hash table for efficient lookups

### Compilation

```bash
# Compile to bytecode
ocamlc -o signatures signatures.ml

# Compile to native code
ocamlopt -o signatures signatures.ml

# Interactive mode
ocaml
# open "signatures.ml";;
```
