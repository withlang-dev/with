# Regex Engine — Implementation Plan

PCRE2 auto-migrated from C via `with migrate`. 4 phases.

**Spec:** `docs/regex-spec.md`
**Engine source:** `.reference/pcre2/src/` (73K lines, 39 .c files)
**Migration tool:** `with migrate` (src/CImport.w)
**Generated output:** `lib/std/re/` (~160K lines, 32 .w files + defs.w)
**Workflow:** `make test-pcre2` (migrate, prepare, check, verify)

---

## Phase 1: Migrate and Build PCRE2 -- COMPLETE

### Step 1: Migrate PCRE2 source -- DONE

```
with migrate .reference/pcre2/src/ -o out/pcre2_migrate_raw/ \
    --no-c-export \
    --prefer-brace \
    --width-slice 8 \
    --shared-defs std.re.defs \
    --exclude pcre2demo.c --exclude pcre2grep.c \
    --exclude pcre2posix.c --exclude pcre2posix_test.c \
    --exclude pcre2_jit_test.c --exclude pcre2_dftables.c \
    --exclude pcre2_fuzzsupport.c --exclude pcre2_jit_match.c \
    --exclude pcre2_jit_misc.c \
    -I .reference/pcre2/src \
    -D PCRE2_CODE_UNIT_WIDTH=8 \
    -D HAVE_CONFIG_H=1
```

Produces 32 `.w` files + `defs.w` shared definitions. 9 files
are excluded (test harnesses, JIT compiler, fuzzer, POSIX wrapper,
dftables).

**Prerequisites** (handled automatically by Makefile):
- `pcre2.h` generated from `pcre2.h.generic`
- `config.h` generated as an 8-bit wrapper over `config.h.generic`
- `pcre2_chartables.c` generated from `pcre2_chartables.c.dist`

### Step 2: Fix compilation errors -- DONE

All compilation errors resolved to 0 through migrator fixes
(not patches to generated code). Three rounds of fixes:

**Round 1 (978 errors):** Initial migration errors.
- Implicit cast handling via `CXCursor_UnexposedExpr` (kind 100)
- Array-to-pointer decay (`CI_CAST_ARRAY_TO_PTR`)
- Chained assignment decomposition (`a = b++`, `*ptr++ = val`)
- Pointer-to-pointer casts (void* <-> typed*)
- Large integer literals (decimal emission, context-aware casts)
- Zero-initialization (`var x: T` without initializer)
- `--no-c-export` flag for stdlib integration

**Round 2 (893 errors):** Cross-pool string index bug in native
goto emitter — stmts-pool string indices used in exprs-pool ident
expressions.

**Round 3 (3 errors):** Type-aware defaults for hoisted variables —
struct-typed `CT_NAMED` values got `int_lit(0)` instead of no-init.

### Step 3: Prepare and promote -- DONE

The Makefile handles the full pipeline:

1. **migrate** — runs `with migrate` producing raw `.w` files
2. **prepare** — copies raw migration to `out/pcre2_generated/`
3. **stage** — copies to `lib/std/re/` for compilation
4. **verify** — builds test harness, runs 20 pattern/subject cases
   against system `pcre2test`, requires byte-for-byte match

Current status: **32/32 files, 287/287 functions, 0 stubs, 0 errors**

```
make test-pcre2   # full pipeline: migrate -> prepare -> stage -> verify
```

### Step 4: Build as object files -- DONE

The migrated modules are promoted under `lib/std/re/` and linked
through the native With stdlib/runtime paths. Self-host tests cover
module compilation and the regex runtime object is built as part of
`make build`.

### Step 5: Test with pcre2test -- DONE

`make regex-test` builds the migrated `pcre2test` binary and runs
the full PCRE2 corpus (`testdata/testinput1` etc.). The older
`scripts/verify_pcre2_works.sh` smoke harness remains useful for
small byte-for-byte comparisons against system PCRE2.

---

## Phase 2: With Wrapper API -- COMPLETE

### Step 6: Create `lib/std/regex.w` -- DONE

`lib/std/regex.w` wraps the migrated PCRE2 internals:

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

pub fn Regex.compile(pattern: str) -> Result[Regex, RegexError]:
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

### Step 7: Match and capture methods -- DONE

```
pub fn Regex.is_match(self: &Self, text: str) -> bool
pub fn Regex.find(self: &Self, text: str) -> Option[Match]
pub fn Regex.captures(self: &Self, text: str) -> Option[Captures]
pub fn Regex.captures_all(self: &Self, text: str) -> Vec[Captures]
```

### Step 8: Replace and split -- DONE

```
pub fn Regex.replace(self: &Self, text: str, repl: str) -> str
pub fn Regex.replace_all(self: &Self, text: str, repl: str) -> str
pub fn Regex.replace_fn(self: &Self, text: str, f: fn(&Captures) -> str) -> str
pub fn Regex.replace_all_fn(self: &Self, text: str, f: fn(&Captures) -> str) -> str
pub fn Regex.split(self: &Self, text: str) -> Vec[str]
pub fn Regex.splitn(self: &Self, text: str, n: i32) -> Vec[str]
```

---

## Phase 3: Language Integration -- COMPLETE

### Step 9: Lexer — `TK_REGEX_LIT` -- DONE

Add regex literal syntax `/pattern/flags` to the lexer.

### Step 10: Parser — `=~` and capture bindings -- DONE

`NK_REGEX_LIT`, `NK_MATCH_OP`, `NK_NEG_MATCH_OP` AST nodes.
Capture binding injection (`$0`, `$1`, `$name`) in if/match bodies.

### Step 11: Sema — type checking -- DONE

Regex as a builtin struct type. Regex literal validation at
compile time.

### Step 12: Codegen — per-literal static compilation -- DONE

Each regex literal lowers to a module-level static slot that is
unique to that source literal. The slot is initialized lazily on
first use and reused directly after that; there is no pattern-string
cache or deduplication across source locations. `=~` lowers to one
capture-producing match operation when capture bindings are in scope,
so `$0`, `$1`, and `$name` all come from the same successful match
result.

---

## Phase 4: Optimization (future)

### Step 13: Optional JIT compilation

Link PCRE2's sljit JIT compiler as a C object only if future
performance work needs it for hot patterns.

### Step 14: Compile-time validation -- DONE

Run `pcre2_compile_8` at comptime for regex literals. Report
invalid patterns as compile errors with source location.

---

## Dependency Graph

```
Phase 1: Migrate + Build
  Step 1 (migrate)  DONE
  Step 2 (fix)      DONE
  Step 3 (prepare)  DONE
  Step 4 (build)    DONE — promoted under lib/std/re and built by stdlib/runtime paths
  Step 5 (test)     DONE — full pcre2test suite runs through make regex-test

Phase 2: Wrapper API
  Step 6 (Regex type) DONE → Step 7 (match/capture) DONE → Step 8 (replace/split) DONE

Phase 3: Language Integration
  Step 9 (lexer) DONE → Step 10 (parser) DONE → Step 11 (sema) DONE → Step 12 (codegen) DONE

Phase 4: Optimization
  Step 13 (optional JIT) — independent
  Step 14 (comptime) DONE
```

---

## Size Estimates

| Component | Est. LOC | Status |
|---|---|---|
| Migrated PCRE2 | ~160,000 | Done — auto-generated, 0 errors, 287/287 functions |
| Fix-up patches | 0 | Not needed — all fixes in migrator |
| Wrapper API | ~500 | Done |
| Lexer changes | ~80 | Done |
| Parser changes | ~150 | Done |
| Sema changes | ~200 | Done |
| Codegen changes | ~250 | Done |
| **Total new hand-written code** | **~700** | Plus ~160K auto-migrated |

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
