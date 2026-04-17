# PCRE2 Integration Diagnostic Findings

GitHub issues: [#134](https://github.com/QuixiAI/with/issues/134)
through [#143](https://github.com/QuixiAI/with/issues/143).

## Bug #1 (#134): Stack overflow / diagnostic recursion on many shadowing errors

**Symptom:** `with build` of a harness that `use`s 10+ PCRE2 modules
silently crashes with SIGSEGV (exit 139). No stderr output.

**Repro (minimal):**
```
// lib/std/re/ must have fresh migrated output from out/pcre2_generated/
use std.re.defs
use std.re.pcre2_ucd
use std.re.pcre2_context
fn main: print("ok\n")
```
`with build bug.w -o /tmp/bug` → exit 139 silently.

With 9 or fewer imports, the compiler prints 500+ shadowing errors
and exits 1 cleanly. At 10 imports it crashes instead.

**LLDB crash site:** `diagnostic_error at main.w:33` (but frame #0
is inside a trivial struct constructor; deeper stack is not printed
by lldb, consistent with deep recursion in diagnostic rendering).

**Classification:** (e) compiler bug — diagnostic renderer can't
survive many shadowing errors.

---

## Bug #2 (#135): Enum members from C headers emitted as `let` in every module

**Symptom:** 636 distinct `let` names duplicated across 2+ modules;
NONE are in defs.w. C3's shared-defs redirection handles only
#define-derived lets (ci_translate_macros), not enum-derived ones
(ci_translate_enum).

**Repro (minimal):**
```
use std.re.defs
use std.re.pcre2_ucd
use std.re.pcre2_tables
fn main: print("ok\n")
```
Produces 500+ errors like:
```
error: shadowing is not allowed for 'ucp_C'
 --> lib/std/re/pcre2_tables.w:100:1
100 | let ucp_C: c_uint = 0
```

**C origin:** `.reference/pcre2/src/pcre2_ucp.h:60: ucp_C,` (anonymous
enum). Every .c file that includes this header sees the enum, and the
migrator translates each enum member to `let NAME: c_uint = VALUE`
in that module. ucp_C, ucp_L, …, OP_END, OP_BRA, etc. — all 636.

**Classification:** (b) duplicate declaration / migrator gap — shared
enum-member redirection was never built.

---

## Bug #3 (#136): Struct/typedef types duplicated across every module

**Symptom:** 89 distinct `type` names declared identically in all 30
modules. Every module that sees `pcre2.h` re-emits its public types.

**Repro (minimal):**
```
use std.re.defs
use std.re.pcre2_context
use std.re.pcre2_match
fn main: print("ok\n")
```
Same shadowing errors as Bug #2, but for types like `BOOL`,
`PCRE2_UCHAR8`, `PCRE2_SPTR8`, `pcre2_general_context_8`,
`pcre2_callout_block_8`.

**Classification:** (b) duplicate declaration / migrator gap — no
type-dedup into defs.w.

---

## Bug #4 (#137): `fn` declarations from function-like macros duplicated across modules

**Symptom:** 136 `fn` names duplicated across modules (ACROSSCHAR,
BACKCHAR, BYTES2CU, etc.). These come from #define macros that
expand to expressions and get translated to fn wrappers in every
translation unit.

**Classification:** (b) duplicate declaration / migrator gap —
fn-like macro translation doesn't dedup (only the `let` path does,
and only partially via C3).

---

## Bug #5 (#138): `extern fn` declarations duplicated across modules

**Symptom:** 112 extern fn names declared in all 30 modules (e.g.,
pcre2_jit_compile_8, pcre2_jit_match_8, every pcre2_* public fn).
With's linker refuses duplicate extern declarations across modules.

**Classification:** (b) duplicate declaration — header-sourced
extern fn declarations should go to defs.w once.

---

## Bug #6 (#139): `extern let` / `extern var` duplicated across modules

**Symptom:** 29 extern let declarations and 4 extern var declarations
appear in 29-30 modules (only one module defines each one).
Examples: `_pcre2_utt_8`, `_pcre2_default_compile_context_8`.

**Classification:** (b) duplicate declaration — every consumer file
re-emits the extern declaration. C1's CiProject handles var owner
for definitions but doesn't dedup the extern declarations in
consumer modules.

---

## Bug #7 (#143): Missing pcre2_init_op_lengths_8()

**Symptom:** test/pcre2_smoke.w calls `pcre2_init_op_lengths_8()` on
line 50 to set up the PRIV(OP_lengths) table. This function doesn't
exist in the fresh migration output. It was a hand-added helper
in the pre-C1 lib/std/re/ snapshot.

**Repro:**
```
grep pcre2_init_op_lengths_8 out/pcre2_generated/*.w  # no matches
```

**Classification:** (d) missing migrated code — the OP_lengths array
IS migrated (pcre2_tables.w:712), so this helper may no longer be
needed, OR the smoke test needs to be updated to not call it. But
regardless, the harness fails to compile against fresh migration.

---

## Bug #8 (#140): EBCDIC tables externed but never defined

**Symptom:** 2 extern lets have no definition anywhere:
- `_pcre2_ascii_to_ebcdic_1047_8`
- `_pcre2_ebcdic_1047_to_ascii_8`

**Classification:** (d) missing migrated code — EBCDIC support
tables live in pcre2_chartables.c but either aren't migrated or
the migrator omitted static-array initializer translation (#102).

---

## Bug #9 (#141): 10 JIT functions externed but never defined (linker will fail)

**Symptom:** pcre2_jit_compile_8, pcre2_jit_match_8, and 8 others
are declared `extern fn` everywhere but no module defines them
(we excluded pcre2_jit_compile.c during migration).

**Classification:** (d) missing migrated code / (a) missing
declaration handling — these need stubs in defs.w that return
"JIT not supported" error codes, or the extern declarations need
to be elided.

---

## Bug #10 (#142): Context struct field default initializers not translated

**Symptom:** test/pcre2_smoke.w lines 64-70 manually set context
defaults (max_pattern_length, parens_nest_limit, etc.) because
`pcre2_compile_context_create_8` doesn't initialize them. The C
source constructs these in `pcre2_set_compile_context_defaults`
which the migrator apparently couldn't translate.

**Classification:** (e) runtime correctness — even if everything
links, regex compilation will fail without manual field setup.

---

## Summary of findings

| # | Issue | Class | Description | Impact |
|---|-------|-------|-------------|--------|
| 1 | #134 | (e) | Compiler crash on many shadowing errors | Blocks all multi-module builds |
| 2 | #135 | (b) | Enum members duplicated (636 names) | 500+ shadowing errors |
| 3 | #136 | (b) | Types duplicated (89 names)          | Shadowing errors |
| 4 | #137 | (b) | fn-macros duplicated (136 names)     | Shadowing errors |
| 5 | #138 | (b) | extern fn duplicated (112 names)     | Linker errors |
| 6 | #139 | (b) | extern let/var duplicated (33 names) | Linker errors |
| 7 | #143 | (d) | pcre2_init_op_lengths_8 missing      | Smoke test won't build |
| 8 | #140 | (d) | EBCDIC tables undefined              | Linker error |
| 9 | #141 | (d) | JIT fns undefined                    | Linker error |
| 10| #142 | (e) | Context struct defaults missing      | Runtime failure |

Bugs 2-6 share a root cause: the migrator emits shared-header
declarations into every translation unit without deduplication.
C1 handles non-static var ownership. C3 handles #define-derived
lets. Neither handles types, enum constants, fn-like macros, or
extern declarations.
