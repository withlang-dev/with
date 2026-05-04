# Bug: Disc Enum Constant Miscompilation

## Two bugs with one root cause

Both Bug 1 (f-string method call produces empty result) and Bug 2
(disc enum variant name collision SIGTRAP) stem from the same
root cause: **disc enum constants are miscompiled by the seed**.

---

## Evidence

### Bug 1: F-string method calls produce empty result

```
fn double(x: i32) -> i32: x * 2
fn main:
    println(f"r={double(21)}")  // prints "r=" (empty)
```

**Five Whys:**

1. **Why is the expression empty?** The MIR for main shows
   `println(const "r=")` — the function call `double(21)` and the
   fmt_to_str intrinsic are completely absent.

2. **Why is the MIR missing the expression?** `lower_fstring` reads
   segment kind from `ast.get_extra(pos)`. For the EXPR segment, it
   gets `10` instead of `1` (the value of `FStringSegmentKind.EXPR`).
   So it falls to the `else` branch which skips the segment.

3. **Why does get_extra return 10 instead of 1?** The parser wrote
   `pool.add_extra(FStringSegmentKind.EXPR)` which should write `1`.
   But the seed compiled the parser code such that
   `FStringSegmentKind.EXPR` evaluates to `10` at runtime.

4. **Why does the seed compile EXPR as 10?** The disc enum
   `FStringSegmentKind` has `EXPR = 1`. But the seed's codegen for
   disc enum constant access produces the wrong value. The value `10`
   corresponds to `NodeKind.NK_EXTERN_VAR` — a variant from a
   DIFFERENT enum with the same integer value in a completely
   unrelated enum type.

5. **Why does the seed confuse enum values across types?** The seed's
   codegen for disc enum variant access does not fully qualify the
   variant lookup — it may resolve `EXPR` by scanning all known enum
   variants and returning the first match, or it may have a symbol
   collision in the variant name resolution table.

### Bug 2: Disc enum variant name collision SIGTRAP

```
enum A: i32:
    X = 1
    SHARED = 2

enum B: i32:
    Y = 1
    SHARED = 7

fn main:
    assert(A.SHARED == 2)  // SIGTRAP crash
```

Same root cause: the codegen for `A.SHARED` finds `B.SHARED` (or
vice versa) because variant names are resolved globally without
qualifying by the parent enum type.

---

## Root Cause

The seed's codegen resolves disc enum variant constants by variant
NAME, not by (enum_type, variant_name) pair. When two enums share
a variant name, the wrong value is returned. Even when names don't
collide, the variant resolution may still be incorrect if the
codegen's symbol table has stale or incorrectly scoped entries.

## Fix Location

The fix is in `src/Codegen.w` — the function that generates LLVM
constant values for disc enum variant access (e.g., `EnumType.Variant`
as a constant expression). It must qualify the lookup by both the
enum type and the variant name.

Look for where `NK_FIELD_ACCESS` on an enum type is handled in
codegen — the path that resolves `FStringSegmentKind.EXPR` to an
LLVM integer constant. The resolution must use the enum type's
registered variant table, not a global variant name scan.

## Repro

```
// File: /tmp/bug_disc_repro.w
enum A: i32:
    FOO = 42
    BAR = 99

enum B: i32:
    FOO = 1
    BAZ = 2

fn main:
    println(f"A.FOO={A.FOO}")  // should print 42
    println(f"B.FOO={B.FOO}")  // should print 1
```

If the seed has the bug, `A.FOO` may print `1` (from `B.FOO`) or
`B.FOO` may print `42` (from `A.FOO`).

## Impact

This bug affects ALL disc enum constant usage at compile time.
It manifests as:
- F-string expressions silently producing empty results
- Incorrect enum values in match arms
- SIGTRAP crashes from impossible enum values
- Miscompilation of any code that uses disc enum constants
