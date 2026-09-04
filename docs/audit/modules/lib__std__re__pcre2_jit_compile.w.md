# Primary verification — `lib/std/re/pcre2_jit_compile.w`

Status: **COMPLETE — JIT is a documented stub** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 134 lines (single complete read).

## Scope examined

Every public entry is a no-JIT stub, consistently: `pcre2_jit_compile_8`
(`:32-45`) → `-45` (JIT_BADOPTION); `_pcre2_jit_match_8` (`:46-60`) sets
`md.rc=-45` then → `-45`; `_pcre2_jit_get_target_8` (`:61-72`) →
`"JIT is not supported"`; `_pcre2_jit_get_size_8` → `0`;
`pcre2_jit_stack_create_8` → `null`; `pcre2_jit_stack_assign_8` /
`pcre2_jit_free_unused_memory_8` (`:84-87`) → no-op `Unit`. Consistent
with `pcre2_config_8(PCRE2_CONFIG_JIT)` → `0` and the auto_possess
report's `jit → -45` observation.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r1_misc.w` (`output_r1.txt`):
  `jittarget=JIT is not supported jitsize=0 stacknull=1`. PASS.
- `docs/audit/probes/re_support/r9_jit_maketables.w` (`output_r9.txt`) on a
  live compiled `a+b`: `jitcompile=-45 jitmatch=-45 mdrc=-45`
  (matches C `PCRE2_ERROR_JIT_BADOPTION`), then `plain rc=1` — the stubs
  neither crash nor corrupt the code block. PASS.
- `with-stage1 check lib/std/re/pcre2_jit_compile.w` → `ok` (exit 0).

## Findings

None. In-report notes (not filed):
- JIT is intentionally unimplemented: any `jitcompile`/`jitmatch` use
  fails loudly with `-45`, never silently. Revisit only if a JIT backend
  lands (then `pcre2_config` JIT/TARGET/expensive-flags must change with
  it).

Verdict: COMPLETE (stub, declared)
