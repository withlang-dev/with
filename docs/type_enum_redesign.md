# Enum & Type Syntax — Migration Plan

*Tracks the syntax redesign from §type-enum-syntax-redesign.md plus blocking bugs.*

---

## Blocking Bugs

### BUG-1: Match patterns don't support qualified enum variants (`Type.VARIANT`)

**Status:** Open — blocks all disc enum match conversions.

**Symptom:** Parser rejects `Color.RED` as a match pattern. The parser sees `Color` as an identifier, expects `=>` after it, and chokes on the `.`.

```
enum Color: i32:
    Red = 0
    Green = 1
    Blue = 2

fn describe(c: i32) -> str:
    match c
        Color.Red => "red"       // error: expected '=>'
        Color.Green => "green"
        _ => "unknown"
```

**Root cause:** `Parser.parse_pattern` (src/Parser.w:~3232) handles `TK_IDENT` but does not check for `TK_DOT` following. It falls through to `NK_PAT_IDENT` (variable binding), then `.Red` is unexpected.

**Fix:** In the `TK_IDENT` branch of `parse_pattern`, after parsing the identifier, check for `TK_DOT TK_IDENT`:

```
if self.peek() == TK_DOT:
    self.advance()  // consume dot
    let variant_name = self.expect_ident()
    if self.peek() == TK_L_PAREN:
        // Qualified variant with payload: Type.Variant(x, y)
        ...
    return self.pool.add_node(NK_PAT_VARIANT, start, self.prev_end(), variant_name, 0, 0)
```

Simplest approach: emit `NK_PAT_VARIANT` with just the variant symbol. Sema already resolves variant names against the match subject type, so the qualifying type prefix is redundant but self-documenting.

Better approach: add `NK_PAT_QUALIFIED_VARIANT` storing both type and variant symbols. Sema verifies the type matches the subject and gives better error messages for mismatches.

**Files:** `src/Parser.w` (parse_pattern), possibly `src/Ast.w` (new node kind), `src/Sema.w` (validation).

**Test:**
```
enum Color: i32:
    Red = 0
    Green = 1

fn test(c: i32) -> str:
    match c
        Color.Red => "red"
        _ => "other"

fn main:
    assert(test(0) == "red")
    assert(test(1) == "other")
```

---

## Phase 0: Bug Fixes (do first)

- [ ] **P0-1.** Fix qualified enum variant match patterns (BUG-1 above).
- [ ] **P0-2.** Test: qualified patterns with payloads (`Type.Variant(x, y) =>`).
- [ ] **P0-3.** Test: qualified patterns in nested match and if-let.

## Phase 1: Add `enum` keyword (additive, no breaking changes)

Parser accepts `enum` as a new keyword alongside existing `type` syntax. Both old and new forms produce the same AST nodes. This is the bootstrap step.

- [ ] **P1-1.** Add `TK_ENUM` to the lexer/token list.
- [ ] **P1-2.** Add `parse_enum_decl` to the parser: handles `enum Name:` (block) and `enum Name { }` (inline).
- [ ] **P1-3.** Simple enum inline: `enum Direction { North, South, East, West }`.
- [ ] **P1-4.** Simple enum block:
  ```
  enum Direction:
      North
      South
      East
      West
  ```
- [ ] **P1-5.** ADT enum inline: `enum Result[T, E] { Ok(T) | Err(E) }`.
- [ ] **P1-6.** ADT enum block:
  ```
  enum Shape:
      Circle(radius: f64)
      Rectangle(w: f64, h: f64)
  ```
- [ ] **P1-7.** ADT enum block with optional leading `|`:
  ```
  enum Shape:
      | Circle(radius: f64)
      | Rectangle(w: f64, h: f64)
  ```
- [ ] **P1-8.** Discriminant enum: `enum Color: i32 { Red = 1, Green = 2, Blue = 4 }`.
- [ ] **P1-9.** Discriminant enum block with backing type (double colon):
  ```
  enum OpCode: u8:
      Add = 0x01
      Sub = 0x02
  ```
- [ ] **P1-10.** Auto-increment: variants without `= N` increment from previous.
- [ ] **P1-11.** `@[flags]` attribute works with `enum` keyword.
- [ ] **P1-12.** Discriminant enum with payloads:
  ```
  enum Msg: i32:
      Quit = 0
      Move(i32, i32) = 1
      Write(str) = 2
  ```
- [ ] **P1-13.** Generic enums: `enum Option[T] { Some(T) | None }`.
- [ ] **P1-14.** Sema: `enum` declarations go through the same type-checking path as `type` enums.
- [ ] **P1-15.** All existing tests still pass (old `type` syntax unchanged).
- [ ] **P1-16.** Build, install as seed. Fixpoint.

## Phase 2: Add brace-less `type` block form (additive)

Parser accepts `type Name:` with indented body as alternative to `type Name { }`.

- [ ] **P2-1.** Parse `type Name:` followed by indented field lines.
- [ ] **P2-2.** Block form:
  ```
  type Player:
      name: str
      pos: Point
      health: u8
  ```
- [ ] **P2-3.** Block form with default values:
  ```
  type Config:
      host: str = "127.0.0.1"
      port: u16 = 8080
  ```
- [ ] **P2-4.** Drop `=` from inline form: `type Point { x: f64, y: f64 }` (no `=`).
- [ ] **P2-5.** Keep `type Point = { x: f64, y: f64 }` working during migration (deprecated).
- [ ] **P2-6.** All existing tests still pass.
- [ ] **P2-7.** Build, install as seed. Fixpoint.

## Phase 3: Migrate compiler source

Convert all enum and struct declarations in the compiler source from old syntax to new syntax. The seed from Phases 1-2 accepts both forms.

- [ ] **P3-1.** Migrate disc enums in `src/Ast.w` (NK_*, TK_*, OP_* constants → proper enums).
- [ ] **P3-2.** Migrate disc enums in `src/Mir.w` (MIR_INTRINSIC_*, RK_*, SK_* constants).
- [ ] **P3-3.** Migrate disc enums in `src/Sema.w` (TY_* type kinds).
- [ ] **P3-4.** Migrate disc enums in `src/Token.w` (token kinds).
- [ ] **P3-5.** Migrate struct types across all compiler sources.
- [ ] **P3-6.** Convert disc enum if-chains to match expressions (depends on BUG-1 fix).
- [ ] **P3-7.** Remove `SK_` / `TK_` / `NK_` / `OP_` prefixes from variant names — use PascalCase.
- [ ] **P3-8.** All tests pass. Build, fixpoint.

## Phase 4: Remove old syntax

- [ ] **P4-1.** Remove `type Name = | Variant | ...` enum parsing (require `enum` keyword).
- [ ] **P4-2.** Remove `type Name: i32 = Variant = N` parsing (require `enum` keyword).
- [ ] **P4-3.** Remove `type Name = { }` with `=` (require `type Name { }` without `=`).
- [ ] **P4-4.** Old syntax produces compile error with migration hint:
  ```
  type Color: i32 = Red = 1
  // error: use `enum` keyword for enum declarations
  //   help: enum Color: i32 { Red = 1, ... }
  ```
- [ ] **P4-5.** Update spec document §4.3, §4.4, §4.4a.
- [ ] **P4-6.** All tests pass. Build, fixpoint.

## Phase 5: Tests

- [ ] **P5-1.** Test inline enum: simple, ADT, discriminant, flags, generic.
- [ ] **P5-2.** Test block enum: all the above in block form.
- [ ] **P5-3.** Test inline type: with and without defaults.
- [ ] **P5-4.** Test block type: with and without defaults.
- [ ] **P5-5.** Test mixed: block enum with inline type fields, etc.
- [ ] **P5-6.** Test qualified match patterns: `Type.Variant =>`, `Type.Variant(x) =>`.
- [ ] **P5-7.** Test error messages: old syntax gives helpful migration hints.
- [ ] **P5-8.** Test edge cases: empty enum, single-variant enum, empty struct.

---

## Dependencies

```
BUG-1 (qualified patterns) ──→ P3-6 (if-chain to match conversion)
P1 (enum keyword) ──→ P3 (migrate source)
P2 (type block form) ──→ P3 (migrate source)
P3 (migrate source) ──→ P4 (remove old syntax)
```

Phase 0 and Phases 1-2 can proceed in parallel. Phase 3 requires both. Phase 4 requires Phase 3. Phase 5 tests should be written alongside each phase.

---

*Enum & type syntax migration plan — v1.0*