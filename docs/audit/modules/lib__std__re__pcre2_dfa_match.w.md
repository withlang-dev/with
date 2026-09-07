# Primary verification — `lib/std/re/pcre2_dfa_match.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (source sampling + probe execution,
including a C-oracle workspace comparison)
Source revision: `450733e5`
Source examined: sampling-based — entry, helper inventory, and
`internal_dfa_match` head (~100 of 17,390 lines read); full
behavioral coverage via executed differential probes down to raw
workspace bytes.

## Scope examined

DFA engine: `pcre2_dfa_match_8` (`:32`, pub entry),
`do_callout_dfa` (`:2156`), `more_workspace` (`:2208`),
`internal_dfa_match` (`:2263`, core to EOF). Sample read:
`:2263–2322` (state-block setup: active/new/temp states,
`dfa_recursion_info`, match counters — faithful port structure).
Ovector/return semantics were settled behaviorally, not by reading.

## Upstream fidelity tracking

Same as the engine audit: PCRE2 10.47 pin (`build.w:2865`,
sha `build/pcre2.w:8`), `:pcre2-test` RunTest lane, `wo-drift`.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_engines/dfa_next_matrix.w` (`run_dfa`) +
  `docs/audit/probes/re_engines/dfa_ov.w` (raw ovector + workspace dump,
  zero-initialized workspace, in-bounds pairs only):
  - `a|ab`/`ab` → RC 0, pair0 `0:2`, WS `1 1 5 0 0 10 0 0`.
  - `foo|foobar`/`xfoobarx` → RC 0, pair0 `1:7`, WS `1 1 22 0 0 18 0 0`.
  - `(ab|a)(c)`/`abc` → RC 1, pairs `0:3, 0:0, 0:0`,
    WS `0 1 27 0 0 30 0 0`.
  - `a+`/`bbb` → NOMATCH `-1`.
- Oracles: (1) system pcre2test 10.47 `-dfa` runs — longest-match
  texts agree in all 4 cases; (2) `docs/audit/probes/re_engines/
  dfa_oracle.c` linked against system libpcre2-8 — RC, every
  in-bounds ovector pair, and all 8 workspace ints **byte-identical**
  in all 4 cases. (The C library reports 10.46, one release behind
  the 10.47 port; the same-version pcre2test display oracle covers
  the gap. C-oracle out-of-bounds ovector reads are uninitialized
  heap in both implementations and were correctly excluded.)
- Two apparent anomalies investigated and cleared as genuine
  upstream semantics, confirmed identical in the C oracle:
  - RC 0 with a valid group-0 pair for zero-capture-group patterns
    (DFA return counts extra pairs, not "match/no-match").
  - DFA-captured-but-unset groups read `(0,0)`, not `PCRE2_UNSET`
    (the backtracker marks unset; DFA does not).

## Findings

None. In-report notes (not filed):
- Coverage is sampling-based for this 17k-line file: entry/helper
  inventory plus behavioral identity down to workspace bytes on 4
  DFA cases (longest-match alternation ×2, groups, no-match).
  Line-level fidelity of unreviewed DFA opcode arms rests on the
  upstream RunTest lane, not on this audit.

Verdict: COMPLETE
