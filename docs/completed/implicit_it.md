# Spec Addition: Implicit Closure Parameter `it`

## Summary

When a closure has exactly one parameter, the identifier `it` is
implicitly bound to that parameter. The closure argument list may
be omitted entirely.

```
items |> filter(it % 2 == 0)
```

is equivalent to:

```
items |> filter(|n| n % 2 == 0)
```

## Design

### Syntax

Any expression passed in a closure position that references `it`
and has no explicit parameter list is treated as an implicit
single-parameter closure.

```
// Grammar addition:
//
// closure_expr = '|' param_list '|' expr        // explicit (existing)
//              | expr_containing_it              // implicit (new)
//
// The compiler detects the implicit form when:
//   1. An expression appears in a position expecting fn(T) -> U
//   2. The expression references the identifier `it`
//   3. No explicit parameter list is present
```

### Type Inference

`it` receives its type from the expected parameter type at the call
site, exactly as explicit closure parameters do today.

```
// filter expects fn(i32) -> bool → it: i32
items |> filter(it % 2 == 0)

// map expects fn(User) -> str → it: User
users |> map(it.name)
```

### Scope

`it` is scoped to the implicit closure expression. It does not leak
into surrounding scope. Nested implicit closures are not permitted —
the inner closure must use explicit parameters to avoid ambiguity.

```
// OK — single level
items |> map(it * 2)

// OK — explicit inner, implicit outer
items |> map(it.children |> filter(|c| c.active))

// ERROR — nested implicit closures, ambiguous it
items |> map(it.children |> filter(it.active))
//                                 ^^ error: nested implicit closure
//                                    use explicit parameter: |c| c.active
```

### `it` Is A Reserved Keyword

`it` is a keyword, the same as `if`, `for`, `match`, `fn`. It cannot
be used as a variable name, function name, parameter name, field name,
or any other identifier.

```
let it = 42            // ERROR: `it` is a reserved keyword
fn it():               // ERROR: `it` is a reserved keyword
|it| it + 1            // ERROR: `it` is a reserved keyword, use a different name

// The ONLY valid use of `it`:
items |> filter(it > 0)    // implicit closure parameter
```

### `_` Is Not A Closure Placeholder

The `_` placeholder syntax (e.g., `items |> filter(_.age > 21)`) was
previously specified as a closure shorthand. This has been removed from
the language. `it` is the sole implicit closure parameter. `_` is
exclusively a discard/wildcard:

- `_` in patterns: wildcard/discard (unchanged)
- `_` in partial application: placeholder for curried argument (unchanged)
- `_.field` as closure shorthand: **REMOVED** — use `it.field` instead
- `it` in expressions: implicit single closure parameter (the one way)

### Where `it` Is NOT Available

- **Multi-parameter closures.** If the expected function type has more
  than one parameter, `it` is not available. Use explicit parameters.
- **Ambiguous closure position.** If the compiler cannot determine
  that the expression is in a closure position, `it` is a normal
  identifier lookup and follows standard resolution.
- **Nested implicit closures.** The inner closure must use explicit
  parameters.

### Desugaring

The compiler desugars implicit closures early, during parsing or
immediately after:

```
// Source
items |> filter(it % 2 == 0)

// Desugared
items |> filter(|__it| __it % 2 == 0)
```

The desugared parameter name is internal. The user always writes `it`.

**Detection algorithm:**

1. Walk the expression tree.
2. If `it` appears anywhere in the expression:
   a. Verify the expected type is `fn(T) -> U` (single parameter).
   b. If yes: wrap the expression as a closure with one parameter
      bound to `it`.
   c. If the expected type has 0 or 2+ parameters: error.
3. If `it` does not appear, treat the expression normally
   (not a closure).

Since `it` is a reserved keyword, it can never appear as a local
variable or other binding. Any occurrence of `it` in an expression
unambiguously signals an implicit closure.

### Error Messages

Three dedicated error codes:

```
error[E0901]: nested implicit closure is ambiguous
  --> src/main.w:12:42
   |
12 |     groups |> map(it.items |> filter(it.active))
   |                                      ^^ which `it`?
   |
   = help: use an explicit parameter for the inner closure
   = suggestion: groups |> map(it.items |> filter(|x| x.active))
```

```
error[E0902]: `it` used in context expecting 2 parameters
  --> src/main.w:8:30
   |
 8 |     pairs |> reduce(0, it + 1)
   |                        ^^ `reduce` expects fn(Acc, T) -> Acc
   |
   = help: use explicit parameters: |acc, x| acc + x
```

```
error[E0903]: `it` is a reserved keyword
  --> src/main.w:3:9
   |
 3 |     let it = 42
   |         ^^ cannot use `it` as a variable name
   |
   = note: `it` is the implicit closure parameter keyword
   = help: choose a different name
```

---

## Implementation Checklist

### 1. Spec (`docs/with-specification.md`)
- [x] Remove `_.field` closure shorthand from spec. `it.field` is the one way.
      Done: `_.active` → `it.active` in §feature summary and intro.md;
      "Placeholder syntax" → "Implicit `it` parameter (see §9.3.1)";
      added full §9.3.1 subsection defining `it` keyword, scoping,
      nested prohibition, and clarifying `_` is not a closure placeholder.
- [ ] Add `it` to the keyword list in the lexical grammar section.
- [ ] Add the implicit closure grammar production to §9.3 (closure expressions).
- [ ] Document the desugaring algorithm in the spec.
- [ ] Add error code definitions for E0901, E0902, E0903.

### 2. Tokenizer / Parser (`src/Token.w`, `src/Parser.w`)
- [ ] Add `it` as a reserved keyword token (e.g., `TK_IT`).
- [ ] Reject `it` as an identifier in let bindings, fn declarations, parameter lists, and field names.
- [ ] Detect implicit closure form: when parsing a call argument in a closure-expected position, check if the expression contains `it` with no explicit `|...|` parameter list.
- [ ] Desugar to an explicit closure AST node with a synthetic parameter bound to `it`.
- [ ] Handle nested detection: if an implicit closure body contains another `it` reference at a nested closure-expected position, emit E0901.

### 3. Sema (`src/Sema.w`)
- [ ] Type-check desugared implicit closures the same as explicit closures (no special path needed if desugaring is complete before sema).
- [ ] Validate arity: if `it` appears in a context expecting `fn(A, B, ...) -> R` with arity != 1, emit E0902.
- [ ] Validate keyword: if `it` appears as a binding name (let, fn, param, field), emit E0903.

### 4. Codegen
- [ ] No changes expected — implicit closures are desugared to standard closure AST nodes before codegen. Verify this holds.

### 5. Docs
- [ ] Update `docs/with-idiomatic-guide.md` with `it` usage examples and guidance (when to use `it` vs explicit params).
- [ ] Update `docs/with-migration-guide.md` with mappings from Rust closure patterns to `it`.
- [ ] Update `docs/intro.md` examples to use `it` where appropriate (partially done: `filter(it.active)` already there).

### 6. Tests
- [ ] Parser test: `it > 0` in closure position desugars to `|__it| __it > 0`.
- [ ] Parser test: `it.name` field access desugars correctly.
- [ ] Parser test: `it.is_active()` method call desugars correctly.
- [ ] Parser test: nested `it` in nested closure position → E0901 error.
- [ ] Parser test: `it` in multi-param context → E0902 error.
- [ ] Parser test: `let it = 42` → E0903 error.
- [ ] Parser test: `fn it():` → E0903 error.
- [ ] Parser test: `|it| it + 1` → E0903 error (cannot use keyword as param name).
- [ ] Sema test: `it` receives correct type from expected parameter type.
- [ ] Sema test: chained pipelines — each `it` gets its step's type.
- [ ] Integration test: `items |> filter(it > 0) |> map(it * 2)` produces correct output.
- [ ] Integration test: explicit inner closure with implicit outer works (`it.children |> filter(|c| c.active)`).
- [ ] Integration test: `it` works with method call syntax (`items.filter(it > 0)`).

### 7. Bootstrap Compatibility
- [ ] `it` implementation goes into the self-host compiler only. Bootstrap (Zig) is unchanged.
- [ ] Self-host source (`src/`) must NOT use `it` syntax — bootstrap cannot compile it.
- [ ] Self-host compiler must be able to compile user code that uses `it`.

### 8. Validation Gates
- [ ] All parser tests pass.
- [ ] All sema tests pass.
- [ ] All integration tests pass.
- [ ] Stage3 chain passes with `it` support compiled in.
- [ ] No regressions in existing closure tests.
