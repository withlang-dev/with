# Regex Engine — Implementation Plan

PCRE2 auto-migrated from C via `with migrate`. 4 phases.

**Spec:** `docs/regex-spec.md`
**Engine source:** `.reference/pcre2/src/` (73K lines, 38 .c files)
**Migration tool:** `with migrate` (implemented, Steps 1-10 complete)

---

## Phase 1: Migrate and Build PCRE2

### Step 1: Migrate PCRE2 source

Already done. The command:

```
with migrate .reference/pcre2/src/ -o lib/std/pcre2/ \
    -I .reference/pcre2/src \
    -D PCRE2_CODE_UNIT_WIDTH=8 \
    -D HAVE_CONFIG_H=1 \
    -D SUPPORT_PCRE2_8=1
```

Produces 37 `.w` files (72K lines). 2 files fail (fuzzer +
variadic test — not needed).

**Prerequisites:**
- `pcre2.h` generated from `pcre2.h.generic`
- `config.h` generated from `config.h.generic`
- `pcre2_chartables.c` generated from `pcre2_chartables.c.dist`

### Step 2: Fix compilation errors

The migrated output compiles via `with migrate` but may not
compile via `with build` due to:
- With type system differences (pointer casts, struct init)
- Name collisions with With keywords
- System header noise (TARGET_OS_* macros)
- Missing type definitions from unexpanded macros

Work through compilation errors file by file. Start with the
smallest files (utilities, tables) and work up to the core
match engine.

**Priority order:**
1. `pcre2_tables.w`, `pcre2_ucd.w` — pure data, no logic
2. `pcre2_chartables.w` — generated lookup tables
3. `pcre2_string_utils.w`, `pcre2_ord2utf.w` — small utilities
4. `pcre2_error.w`, `pcre2_config.w` — simple functions
5. `pcre2_context.w`, `pcre2_match_data.w` — memory management
6. `pcre2_newline.w`, `pcre2_valid_utf.w` — validation
7. `pcre2_find_bracket.w`, `pcre2_extuni.w` — helpers
8. `pcre2_study.w`, `pcre2_auto_possess.w` — optimization passes
9. `pcre2_compile.w` — the big one (6K lines, 57 gotos)
10. `pcre2_match.w` — the core engine (14K lines)
11. `pcre2_dfa_match.w` — DFA engine
12. `pcre2_substitute.w` — replacement

### Step 3: Build as a With module

Create `lib/std/pcre2/mod.w` that re-exports the public API:

```
pub use pcre2_compile
pub use pcre2_match
pub use pcre2_match_data
// etc.
```

Build with `with build lib/std/pcre2/`.

### Step 4: Test with pcre2test

`pcre2test` stays as C. Build it linking against the migrated
With library via `@[c_export]`:

```
cc -o pcre2test .reference/pcre2/src/pcre2test.c \
    -L out/lib -lpcre2 \
    -I .reference/pcre2/src
```

Run PCRE2's test suite:

```
./pcre2test .reference/pcre2/testdata/testinput1
./pcre2test .reference/pcre2/testdata/testinput2
// ... all test inputs
```

### Step 5: Fix test failures

Iterate between fixing translation bugs and running tests until
all PCRE2 tests pass. Common issues to expect:
- Pointer arithmetic off-by-one in migrated code
- Missing `unsafe` blocks around pointer dereferences
- Integer width mismatches (C `int` vs With `c_int`)
- Switch fallthrough edge cases
- Goto state machine bugs in deeply nested functions

---

## Phase 2: With Wrapper API

### Step 6: Create `lib/std/regex.w`

~300 lines wrapping the migrated PCRE2 C API:

```
use std.pcre2

pub type Regex = {
    code: *mut pcre2_real_code_8,
    pattern: str,
    num_captures: i32,
    capture_names: Vec[str],
}

impl Drop for Regex:
    fn drop(self: &mut Self):
        if self.code as i64 != 0:
            pcre2_code_free_8(self.code)

pub fn Regex.compile(pattern: &str) -> Result[Regex, RegexError]:
    var error_code: c_int = 0
    var error_offset: c_ulong = 0
    let code = pcre2_compile_8(
        pattern as *const u8,
        pattern.len() as c_ulong,
        0 as c_uint,  // options
        &mut error_code,
        &mut error_offset,
        null  // compile context
    )
    if code as i64 == 0:
        return Err(RegexError { code: error_code, offset: error_offset as i32 })
    // Extract capture info
    // ...
    Ok(Regex { code, pattern: pattern.to_owned(), ... })
```

### Step 7: Match and capture methods

```
pub fn Regex.is_match(self: &Self, text: &str) -> bool:
    let match_data = pcre2_match_data_create_from_pattern_8(self.code, null)
    let rc = pcre2_match_8(self.code, text as *const u8, text.len() as c_ulong,
                            0, 0, match_data, null)
    pcre2_match_data_free_8(match_data)
    rc >= 0

pub fn Regex.find(self: &Self, text: &str) -> Option[Match]:
    // ... call pcre2_match_8, extract ovector ...

pub fn Regex.captures(self: &Self, text: &str) -> Option[Captures]:
    // ... call pcre2_match_8, build Captures from ovector ...
```

### Step 8: Replace and split

```
pub fn Regex.replace_all(self: &Self, text: &str, repl: &str) -> str:
    // ... call pcre2_substitute_8 ...

pub fn Regex.split(self: &Self, text: &str) -> Vec[str]:
    // ... iterative find + substring collection ...
```

---

## Phase 3: Language Integration

### Step 9: Lexer — `TK_REGEX_LIT`

Add regex literal syntax `/pattern/flags` to the lexer.

- `TK_REGEX_LIT` token kind
- `/` disambiguation based on previous token
- Handle `[...]` character classes, `\/` escapes
- Consume flag characters after closing `/`

### Step 10: Parser — `=~` and capture bindings

- `NK_REGEX_LIT`, `NK_MATCH_OP`, `NK_NEG_MATCH_OP` AST nodes
- `=~` and `!~` at equality precedence
- Capture binding injection (`$0`, `$1`, `$name`) in if/match bodies
- Regex patterns in match arms

### Step 11: Sema — type checking

- Regex as a builtin struct type (resolved via module system)
- `=~`: lhs must be `str`, rhs must be `Regex`, result `bool`
- Regex literal validation at compile time (call `pcre2_compile_8`
  in sema, report errors with source location)

### Step 12: Codegen — lazy statics

- Each regex literal → module-level lazy-initialized `Regex`
- `=~` desugars to `Regex.captures()` + Option check
- `$N` bindings → `Captures.get(N).text`

---

## Phase 4: Optimization (future)

### Step 13: JIT compilation

Link PCRE2's sljit JIT compiler as a C object:

```
cc -c .reference/pcre2/src/pcre2_jit_compile.c -o out/lib/pcre2_jit.o \
    -I .reference/pcre2/src -DPCRE2_CODE_UNIT_WIDTH=8 -DHAVE_CONFIG_H
```

Add `pcre2_jit_compile_8` call after `pcre2_compile_8` for hot
patterns.

### Step 14: Compile-time validation

Run `pcre2_compile_8` at comptime for regex literals. Report
invalid patterns as compile errors with source location pointing
to the literal.

---

## Dependency Graph

```
Phase 1: Migrate + Build
  Step 1 (migrate) → Step 2 (fix errors) → Step 3 (build) → Step 4 (test) → Step 5 (fix)

Phase 2: Wrapper API
  Step 6 (Regex type) → Step 7 (match/capture) → Step 8 (replace/split)

Phase 3: Language Integration
  Step 9 (lexer) → Step 10 (parser) → Step 11 (sema) → Step 12 (codegen)

Phase 4: Optimization
  Step 13 (JIT) — independent
  Step 14 (comptime) — depends on Phase 3
```

Phase 1 is the critical path. Phases 2 and 3 can proceed in
parallel once the migrated library builds and passes tests.

---

## Size Estimates

| Component | Est. LOC | Notes |
|---|---|---|
| Migrated PCRE2 | 72,000 | Auto-generated by `with migrate` |
| Fix-up patches | ~500 | Compilation fixes for migrated code |
| Wrapper API | ~300 | `lib/std/regex.w` |
| Lexer changes | ~80 | `TK_REGEX_LIT`, disambiguation |
| Parser changes | ~150 | `=~`/`!~`, capture bindings |
| Sema changes | ~80 | Type checking, compile-time validation |
| Codegen changes | ~100 | Lazy statics, `=~` desugaring |
| **Total new hand-written code** | **~1,200** | Plus 72K auto-migrated |

Compare with the Go RE2 port plan: ~4,400 lines of hand-written
code, 4-6 weeks, no backreferences, no lookahead.

---

## Verification

After Phase 1:
```
./pcre2test .reference/pcre2/testdata/testinput1
./pcre2test .reference/pcre2/testdata/testinput2
# All PCRE2 tests must pass
```

After Phase 2:
```
let re = Regex.compile("^(\\w+)\\s+(\\w+)$").unwrap()
assert(re.is_match("hello world"))
let caps = re.captures("hello world").unwrap()
assert(caps.get(1).unwrap().text == "hello")
assert(caps.get(2).unwrap().text == "world")
```

After Phase 3:
```
if "hello world" =~ /^(\w+)\s+(\w+)$/:
    assert($1 == "hello")
    assert($2 == "world")
```
