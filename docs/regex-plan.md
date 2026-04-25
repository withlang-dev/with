# Regex Engine — Implementation Plan

PCRE2 auto-migrated from C via `with migrate`. 4 phases.

**Spec:** `docs/regex-spec.md`
**Engine source:** `.reference/pcre2/src/` (73K lines, 39 .c files)
**Migration tool:** `with migrate` (src/CImport.w)
**Generated output:** `lib/std/re/` (80K lines, 32 .w files)
**Workflow:** `make regex-migrate-raw`, `make regex-prepare`, `make regex-check`, `make regex-promote`

---

## Phase 1: Migrate and Build PCRE2 -- COMPLETE

### Step 1: Migrate PCRE2 source -- DONE

```
with migrate .reference/pcre2/src/ -o out/pcre2_migrate_raw/ \
    --no-c-export \
    --prefer-brace \
    -I .reference/pcre2/src \
    -D PCRE2_CODE_UNIT_WIDTH=8 \
    -D HAVE_CONFIG_H=1
```

Produces 39 `.w` files. 8 files are excluded from the library
subset (test harnesses, JIT compiler, fuzzer).

**Prerequisites** (handled automatically by Makefile):
- `pcre2.h` generated from `pcre2.h.generic`
- `config.h` generated as an 8-bit wrapper over `config.h.generic`
- `pcre2_chartables.c` generated from `pcre2_chartables.c.dist`

### Step 2: Fix compilation errors -- DONE

All 978 initial `with check` errors resolved to 0 through
migrator fixes (not patches to generated code). Key fixes:

- Implicit cast handling via `CXCursor_UnexposedExpr` (kind 100)
- Array-to-pointer decay (`CI_CAST_ARRAY_TO_PTR`)
- Chained assignment decomposition (`a = b++`, `*ptr++ = val`)
- Pointer-to-pointer casts (void* <-> typed*)
- Large integer literals (decimal emission, context-aware casts)
- Zero-initialization (`var x: T` without initializer)
- Variable shadowing prevention in goto state machines
- `--no-c-export` flag for stdlib integration

### Step 3: Prepare and promote -- DONE

The workflow script (`scripts/pcre2_generated_workflow.sh`) handles:

1. **prepare** — copies raw migration, extracts shared preamble
   into `defs.w`, strips 16/32-bit variants, concatenates adjacent
   string literals, expands XSTRING macros, casts `with_alloc`
2. **check** — runs `with check` on each module with combined
   preamble, reports error count
3. **promote** — copies to `lib/std/re/` if 0 errors

Current status: **OK=31, TOTAL_ERRORS=0**

```
make regex-migrate-raw   # migrate .reference/pcre2/src/ -> out/pcre2_migrate_raw/
make regex-prepare       # prepare -> out/pcre2_generated/
make regex-check         # verify 0 errors
make regex-promote       # copy to lib/std/re/
```

### Step 4: Build as object files -- TODO

Compile each module in `lib/std/re/` to `.o` files via
`with build --emit-obj`. Link into a static library.

### Step 5: Test with migrated pcre2test -- TODO

Build migrated `pcre2test`, importing the compiled With modules.
Run PCRE2's test suite:

```
./pcre2test .reference/pcre2/testdata/testinput1
./pcre2test .reference/pcre2/testdata/testinput2
```

Fix any runtime failures (pointer arithmetic, memory layout,
goto state machine correctness).

---

## Phase 2: With Wrapper API

### Step 6: Create `lib/std/regex.w`

~300 lines wrapping the migrated PCRE2 internals:

```
use std.re

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
    var error_code: c_int
    var error_offset: c_ulong
    let code = pcre2_compile_8(
        pattern as *const u8,
        pattern.len() as c_ulong,
        0 as c_uint,
        (&mut error_code as *mut c_int),
        (&mut error_offset as *mut c_ulong),
        null
    )
    if code as i64 == 0:
        return Err(RegexError { code: error_code, offset: error_offset as i32 })
    Ok(Regex { code, pattern: pattern.to_owned(), ... })
```

### Step 7: Match and capture methods

```
pub fn Regex.is_match(self: &Self, text: &str) -> bool
pub fn Regex.find(self: &Self, text: &str) -> Option[Match]
pub fn Regex.captures(self: &Self, text: &str) -> Option[Captures]
```

### Step 8: Replace and split

```
pub fn Regex.replace_all(self: &Self, text: &str, repl: &str) -> str
pub fn Regex.split(self: &Self, text: &str) -> Vec[str]
```

---

## Phase 3: Language Integration

### Step 9: Lexer — `TK_REGEX_LIT`

Add regex literal syntax `/pattern/flags` to the lexer.

### Step 10: Parser — `=~` and capture bindings

`NK_REGEX_LIT`, `NK_MATCH_OP`, `NK_NEG_MATCH_OP` AST nodes.
Capture binding injection (`$0`, `$1`, `$name`) in if/match bodies.

### Step 11: Sema — type checking

Regex as a builtin struct type. Regex literal validation at
compile time.

### Step 12: Codegen — lazy statics

Each regex literal compiles to a module-level lazy-initialized
`Regex`. `=~` desugars to `Regex.captures()` + Option check.

---

## Phase 4: Optimization (future)

### Step 13: JIT compilation

Link PCRE2's sljit JIT compiler as a C object for hot patterns.

### Step 14: Compile-time validation

Run `pcre2_compile_8` at comptime for regex literals. Report
invalid patterns as compile errors with source location.

---

## Dependency Graph

```
Phase 1: Migrate + Build
  Step 1 (migrate)  DONE
  Step 2 (fix)      DONE
  Step 3 (prepare)  DONE
  Step 4 (build)    TODO  <-- next
  Step 5 (test)     TODO

Phase 2: Wrapper API
  Step 6 (Regex type) → Step 7 (match/capture) → Step 8 (replace/split)

Phase 3: Language Integration
  Step 9 (lexer) → Step 10 (parser) → Step 11 (sema) → Step 12 (codegen)

Phase 4: Optimization
  Step 13 (JIT) — independent
  Step 14 (comptime) — depends on Phase 3
```

---

## Size Estimates

| Component | Est. LOC | Status |
|---|---|---|
| Migrated PCRE2 | 80,000 | Done — auto-generated, 0 errors |
| Fix-up patches | 0 | Not needed — all fixes in migrator |
| Wrapper API | ~300 | TODO |
| Lexer changes | ~80 | TODO |
| Parser changes | ~150 | TODO |
| Sema changes | ~80 | TODO |
| Codegen changes | ~100 | TODO |
| **Total new hand-written code** | **~700** | Plus 80K auto-migrated |

---

## Verification

After Phase 1 Steps 4-5:
```
./pcre2test .reference/pcre2/testdata/testinput1
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
