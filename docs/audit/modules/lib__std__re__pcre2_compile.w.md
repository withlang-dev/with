# Primary verification — `lib/std/re/pcre2_compile.w`

Status: **COMPLETE (sampling-based)** — no defects
Primary verifier: audit-re-compile (source sampling + executed differential probes)
Source revision: `450733e5`
Source examined: sampling — 26,904 lines total; samples below. Full-function
reads: none (largest module in scope). All behavior below was EXECUTED.

## Scope examined

`pcre2_compile_8` (entry point, `:34`): option-bit validation block
(`:280-409`), `find_bracket` call site (`:1719`, group search for numeric
backrefs). Helpers sampled: `_pcre2_check_escape_8` signature (`:2447`),
`read_repeat_counts` head (`:7233-7335`, space skipping, digit scan,
`max=65536` default) and tail (`:7793-7865`, `ERR4` path, min/max writeback),
`check_posix_syntax`/`check_posix_name`/`read_name` signatures
(`:8603/8676/8703`), `parse_regex` signature (`:9754`, main parse loop —
cited, not read). Called-out but out of scope: `pcre2_code_free_8`,
`pcre2_code_copy_8` (`:2349/2403`).

Coverage honesty: the 9k-line `parse_regex`/`compile_branch` core was NOT
read line-by-line. It was verified behaviorally (45-case matrix below) and
is additionally covered by the repo's upstream RunTest corpus
(`build/pcre2.w` `:pcre2-verify`, 8-bit corpus).

## Upstream fidelity tracking

Port declares PCRE2 **10.47** (`defs.w:944` `PACKAGE_STRING`, `defs.w:1309-1310`
`MAJOR=10 MINOR=47`). Oracles are the same version: system `pcre2test 10.47
2025-10-21`, system `libpcre2-8` (brew) + `pcre2.h`. File header:
`// Migrated from C`. Transliterator style throughout (`__local_*__goto_*`
locals, `'__ci_bb_N` blocks) — control flow preserved, not restructured.
Option-mask proof: every bit in the `:353` acceptance mask decoded and
compared against `pcre2.h` compile-option (`/* C */`) defines — sets equal,
only bit 28 (`0x10000000`, unassigned upstream) rejected by both.

## Behavioral matrix (all EXECUTED, oracles independent)

Probes: `docs/audit/probes/re_compile/` — `compile_opts.w` (built with installed
`with`, binary `probe`, output `probe_output.txt`, `with build` rc=0),
`gen_oracle.py` → `oracle_expected.txt` (one pcre2test invocation per case;
modifiers are sticky), `check_messages.py` (rc=0), `optbit_oracle.c` (raw-bit
C oracle vs system libpcre2-8), `prior_fuzz_output.txt` (re-run of the
pre-existing `../pcre2_compile/compile_fuzz` binary; its five modules are
byte-identical `28dcfa7a..HEAD`, so valid at this revision).

- 26 valid/option cases, port vs pcre2test 10.47 — 26/26 agree (accept +
  match outcome; spans recorded): plain, ci on/off, ci-class, ml on/off
  (`^b` on `a\nb` → `[2,3)` vs no-match), ds on/off, ext on/off, ungreedy,
  greedy, utf (`é` → `[0,2)`), utf-ascii, dupnames-ok (rc=3), anchored on/off,
  endonly on/off (`a$` on `a\n`), literal on/off, ucp (`\w+` on `é` → `[0,1)`,
  same single byte as oracle), noucp, no-auto-possess, possessive,
  allow-empty-class (`[]b` compiles, never matches — both).
- 18 invalid cases, code+offset — 18/18 agree: 114@4, 106@4, 109@1, 115@5,
  104@5, 101@4 + 101@1 (trailing backslash; pcre2test cannot express —
  oracle is `pcre2grep`, upstream `Error ... at offset 4/1: \ at end of
  pattern`, rc=2), 125@0, 143@14, 174@0 (UTF|NEVER_UTF), 108@4, 105@10
  (`a{1,100000}`), 134@9 both UTF and non-UTF (`\x{110000}`), 114@3
  (`(?i`), 122@4 (`(a))`), 117@0 (raw bit `0x10000000`; C oracle).
  Accept-case `(?<=a|bb)c` compiles on both (bounded-alternation lookbehind).
- JIT: `pcre2_jit_compile_8(code, JIT_COMPLETE)` → `-45`; matches upstream
  no-JIT build behavior (system lib has JIT, so no differential match run —
  config difference, not a port difference; see note N3).
- Error-message texts: 14/14 byte-exact vs oracle (101,104,105,106,108,
  109,114,115,117,122,125,134,143,174; `check_messages.py` rc=0).
- python3 `re` secondary oracle: accept/reject agrees on all 11 invalid
  patterns probed; `a{1,100000}` accepted by `re`, rejected (105) by both
  PCRE2s — documented dialect delta, not a defect.
- Prior fuzz re-run: 30/30 agree with `oracle_percase.txt` (nested groups
  rc=5 with exact spans, backrefs, lookaround incl. `(?<=ab)c` → `[2,3)`,
  counted repeats, POSIX `[[:alpha:]]`, possessive/atomic/conditional/named;
  8 invalid fail with identical code@off as this probe).
- `with check lib/std/re/pcre2_compile.w` → rc=0, 0 errors (installed
  `with v0.15.1.6`; warnings only). No `with-stage1` binary exists in the
  tree, so the installed compiler was used; the full bundle also built clean
  via `with build` of the probe (rc=0, 1093328-byte binary).

## Findings

None. In-report notes (not filed):

- N1: the `ungreedy` case is a weak discriminator — `(a+)(b)` on `aaab`
  yields `g1=[0,3)` under both settings (backtracking converges); it proves
  the bit is accepted and harmless, not that inversion works. A
  discriminating ungreedy case would need a trailing-optional shape.
- N2: `pcre2test` modifiers are sticky within a file and its line parser
  cannot express a trailing-backslash pattern — the oracle driver isolates
  one pattern per invocation and defers two cases to `pcre2grep`/C.
  Recorded in the probe header so the next auditor does not re-learn it.

Verdict: COMPLETE (sampling-based, samples listed above)
