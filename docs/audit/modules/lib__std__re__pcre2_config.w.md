# Primary verification — `lib/std/re/pcre2_config.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 505 lines (single complete read).

## Scope examined

`_pcre2_config_8` (`:32-445`): full value table — version/unicode-version
strings, unicode=1, JIT=0 (no JIT in this port), JITTARGET→-34 with a
live `where` (unsupported), linksize=2, match/depth=10000000,
newline=2 (LF), parens=250, bsr=1, heap=20000000, tableslength=1088,
compile-recursion/Unicode-tables/max-pattern sizes, EBCDIC/JIT
unavailable markers; null `where` returns the size probe (4/8/0/-34 arms);
unknown `what` → -34. `pcre2_config_8` (`:447-505`): null-context→-51,
else forward.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r1_misc.w` (`output_r1.txt`):
  `cfg 0 rc=0 val=1` (BSR — system `pcre2test -C bsr` prints `ANY`,
  i.e. value 1: MATCH), `cfg 1 rc=0 val=0` (JIT unsupported — correct
  divergence from the JIT-enabled system lib, consistent with the JIT
  stub), `cfg 3 rc=0 val=2`, `cfg 4 rc=0 val=10000000`,
  `cfg 5 rc=0 val=2` (system `-C newline` → `LF`: MATCH),
  `cfg 6 rc=0 val=250`, `cfg 9 rc=0 val=1`,
  `cfg 12 rc=0 val=20000000`, `cfg16 tableslen rc=0 val=1088`,
  `cfgbad rc=-34`, `cfgver rc=17 str=10.47 2025-10-21`,
  `cfguni rc=7 str=16.0.0` (both strings byte-identical to
  `pcre2test -C`, which reports `PCRE2 version 10.47 2025-10-21` and
  `Unicode version 16.0.0`). PASS.
- `with-stage1 check lib/std/re/pcre2_config.w` → `ok` (exit 0).

## Findings

None. In-report notes (not filed):
- `val=0` for JIT is a deliberate no-JIT build signal, not a migration
  regression (see `pcre2_jit_compile.w` report).

Verdict: COMPLETE
