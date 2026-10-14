# Product Loops and Enum Iteration — Specification

Feature proposal. Two coupled additions:

- **Part A — product clauses.** A `for` header may list several
  `PATTERN in EXPR` clauses separated by commas. The loop runs over every
  combination, exactly as the equivalent nested loops would.
- **Part B — enum iteration.** In the iterable position of a `for` clause
  or comprehension, an enum type whose variants are all unit variants
  denotes the sequence of its values.

Together they let a test matrix, a truth table or a configuration sweep be
written as one loop whose shape is visible in its header:

```
enum Tier { Free | Pro | Enterprise }

for region in regions, tier in Tier:
    run_case(region, tier)
```

Status: proposal. Targets: §13.5 (for-in loops), §13.6 (comprehensions),
§4.4 (enums, new subsection after §4.4a), §30.4 and §30.5 (grammar).

---

## Part A — Product clauses

### A.1 Motivation

Iterating a cartesian product is common: every rule against every input,
every region against every tier, every combination of a handful of flags.
Today it is written as nested loops, one indentation level per dimension:

```
for own in [false, true]:
    for xb in [false, true]:
        for yb in [false, true]:
            for o in [false, true]:
                table.push(entry(own, xb, yb, o))
```

The nesting carries no information. It is one loop over four dimensions,
and the indentation hides that. Comprehensions already have the
multi-generator form (§13.6, `[(x, y) for x in 0..3 for y in 0..3]`);
statements do not.

### A.2 What it looks like

```
for own in [false, true], xb in [false, true], yb in [false, true], o in [false, true]:
    table.push(entry(own, xb, yb, o))

for region in regions, tier in Tier, retries in 0..=3:
    run_case(region, tier, retries)

for user in users, order in user.orders:      // later clauses may use earlier variables
    audit(user.id, order)
```

Each clause is an ordinary `for` clause: any pattern, any iterable, any
element type. Nothing about the clauses has to match.

### A.3 Semantics

A product loop is defined by its expansion into nested loops:

```
for p1 in e1, p2 in e2, ..., pn in en:
    body
```

has exactly the meaning of

```
for p1 in e1:
    for p2 in e2:
        ...
            for pn in en:
                body
```

with the exceptions in A.4 for `break` and `continue`. Every rule below
follows from that expansion.

1. **Order.** The last clause varies fastest. The first clause is the
   outermost loop.
2. **Evaluation.** Clause *k*'s iterable is evaluated each time the loop
   reaches clause *k*: once for the first clause, and once per element of
   clause *k−1* for the others. A clause may therefore refer to variables
   bound by earlier clauses.
3. **Implicit iteration** (§13.5) applies per clause: a collection gets
   `.iter()` inserted, and is observed, not consumed.
4. **Ownership.** Each clause follows the ordinary `for` rules (§13.5,
   D44). A clause whose iterable consumes a binding from outside the loop
   (an iterator value, `move xs`, `.into_iter()`) is consumed again on
   every pass of the enclosing clause, and is rejected as a move inside a
   loop, the same diagnostic the nested form produces. To use a one-shot
   iterator in an inner clause, collect it first.
5. **Patterns.** A refutable pattern in clause *k* skips the elements of
   clause *k* that do not match, exactly as in a single `for`, and
   iteration continues with clause *k*'s next element.
6. **Scope.** A clause's variables are in scope in later clauses and in
   the body. Names must be distinct across clauses (§29.8 shadowing).
7. **Empty clauses.** If any clause yields no elements on a given pass,
   the body does not run for that pass, as with nested loops.

### A.4 Control flow

A product loop is one loop, not *n*:

- `break` exits the whole product loop.
- `continue` advances to the next combination, that is, the next element
  of the last clause (and onward to the outer clauses when it is
  exhausted).
- A label on a product loop labels the whole loop. `break 'outer` and
  `continue 'outer` apply to it as above.
- To break out of only some dimensions, write nested loops; that is what
  they are for.

This is the one place the product form is not a pure abbreviation of the
nested form. It is deliberate: if `break` exited only the innermost
dimension, the header would look like one loop and behave like several.

### A.5 Comprehensions

Comprehensions accept the same comma-separated clauses:

```
[entry(own, xb, yb, o) for own in [false, true], xb in [false, true],
                           yb in [false, true], o in [false, true]]

[(r, t) for r in regions, t in Tier if allowed(r, t)]
```

The `if` filter applies to each combination. The existing repeated-`for`
form (`for x in a for y in b`) means the same thing; see Open question 1.

### A.6 Syntax

```
FOR_STMT      := 'for' FOR_CLAUSE { ',' FOR_CLAUSE } BODY
FOR_CLAUSE    := PATTERN 'in' EXPR

COMPREHENSION := '[' EXPR FOR_CLAUSES [ 'if' EXPR ] ']'
              | '[' EXPR ':' EXPR FOR_CLAUSES [ 'if' EXPR ] ']'
FOR_CLAUSES   := 'for' FOR_CLAUSE { ( ',' | 'for' ) FOR_CLAUSE }
```

A top-level comma ends the iterable expression of a clause. This is
unambiguous because With has no unparenthesized tuple expression and
tuple patterns are parenthesized (§30.6); an iterable that needs a
top-level comma is written in parentheses.

### A.7 Lowering

The compiler emits the nested loops of A.3 with the control-flow targets
of A.4. No iterator object, tuple or allocation is introduced; a product
loop over ranges and arrays compiles to the same code as the hand-written
nested loops.

### A.8 Diagnostics

- A consuming inner clause (rule 4): name the clause, the binding and the
  fix (bind and collect before the loop, or iterate a view).
- A pattern variable repeated across clauses: the §29.8 shadowing error,
  naming both clauses.
- `break` inside a product loop where the intent is ambiguous is not
  diagnosed; the rule in A.4 is the documented meaning.

---

## Part B — Enum iteration

### B.1 Motivation

A program that wants every value of an enum today writes the list by hand:

```
let tiers = [Tier.Free, Tier.Pro, Tier.Enterprise]
```

That list is a fact the compiler already knows, and it goes stale the
moment someone adds a variant, silently: the loop still compiles and
skips the new value. `T.variants()` (§17.2) is compile-time reflection
returning variant metadata, not values, and does not cover this.

### B.2 What it looks like

```
enum Tier { Free | Pro | Enterprise }

for tier in Tier:
    print(tier)                     // Free, Pro, Enterprise

let all = [t for t in Tier]         // List[Tier]
let n = all.len()                   // 3

for region in regions, tier in Tier:
    run_case(region, tier)
```

### B.3 Rule

In the iterable position of a `for` clause or a comprehension clause, an
expression that resolves to an enum type **all of whose variants are unit
variants** denotes the sequence of that enum's values.

1. **Order.** Declaration order, always.
2. **Element type.** The enum itself, by value.
3. **Discriminant enums** (§4.4a) yield their variants, not the integer
   range they span: for `enum Code: u8 { Ok = 0 | NotFound = 4 }`,
   `for c in Code` yields two values.
4. **Qualified names** resolve normally: `for t in billing.Tier`.
5. **Only the iterable position.** This rule does not make types usable
   as values anywhere else. `let x = Tier` remains an error.
6. **No membership test.** `t in Tier` is not defined. It would be
   trivially true for a `Tier` and a type error for anything else.
7. **Data use** needs no second spelling: `[t for t in Tier]` builds the
   list, and its length is the variant count.

### B.4 Errors

- **An enum with a payload variant** in the iterable position is a
  compile error naming the first payload variant: `Shape.Circle` carries
  a payload, so `Shape` has no finite list of values. (This mirrors the
  `from_int` rule in §4.4a.)
- **A type parameter** in the iterable position (`for t in T`) is an
  error in v1. Generic enum iteration needs a bound expressing "an enum
  whose variants are all unit variants"; that bound is deferred (Open
  question 2).
- **A non-enum type** in the iterable position is the ordinary "type used
  as a value" error, with a note that only unit-variant enums are
  iterable by name.

### B.5 Consequences to state in §4.4

- **Variant order is part of a public enum's interface.** Reordering the
  variants of an exported enum changes what `for x in E` yields. It is an
  interface change and belongs in the bundle fingerprint
  (`BundleFingerprint.w`) and the bundle interface row.
- **Adding a variant extends every loop over the type.** This sits next
  to the existing rule that adding a variant breaks non-exhaustive
  `match`es: both are the compiler keeping code that enumerates an enum
  complete.

### B.6 Lowering

A counted loop over the variants in declaration order. For an enum whose
discriminants are `0..N` in declaration order, an integer loop with a
cast; otherwise a loop over a static table of discriminants. Nothing is
allocated, and `[t for t in Tier]` allocates only the list it builds.

---

## Interaction between the parts

The two features are independent and compose without special cases:

```
enum Rule { Xor | East }

for rule in Rule, xb in [false, true], yb in [false, true], o in [false, true]:
    check(rule, xb, yb, o)
```

---

## Non-goals (v1)

- Zip iteration. Walking sequences in lockstep stays
  `for (a, b) in zip(xs, ys)`. The product form puts each variable next to
  its own iterable precisely so it cannot be read as zip.
- Iteration over enums with payloads, including payloads that are
  themselves finite (`bool`, another unit-variant enum).
- Generic iteration over a type parameter (Open question 2).
- A product value (`product(xs, ys)` as an iterator object). The loop and
  comprehension forms cover the use; a library function can be added
  independently.
- Parallel or unordered product iteration.

---

## Open questions for ruling

1. **One separator in comprehensions, or two?** Comprehensions already
   write `for x in a for y in b`. This proposal accepts both that and the
   comma form so existing code keeps compiling. Options: (a) accept both
   permanently; (b) accept both, and have `with fmt` rewrite repeated
   `for` to commas so the codebase converges on one spelling;
   (c) commas only, as a breaking change. Recommended: (b).
2. **Bound for generic enum iteration.** A compiler-derived marker trait
   (name to be chosen) satisfied by every unit-variant enum would let
   `fn every[T: UnitEnum]()` write `for t in T`. Deferred until a program
   needs it.
