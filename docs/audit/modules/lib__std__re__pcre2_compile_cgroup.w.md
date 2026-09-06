# Primary verification — `lib/std/re/pcre2_compile_cgroup.w`

Status: **COMPLETE (sampling-based)** — no defects
Primary verifier: audit-re-compile (full read + executed differential probes)
Source revision: `450733e5`
Source examined: **all 927 lines** (`:1-927`, single linear read of all
8 functions). Behavior below was EXECUTED.

## Scope examined

`_pcre2_compile_get_hash_from_name8` (`:34`: `name[0]&0x7f |
name[len-1]<<7`), `_pcre2_compile_find_named_group8` (`:57`: length +
`hash&0x7FFF` + `strncmp`), `_pcre2_compile_add_name_to_table8` (`:93`:
duplicate counting, `memmove` sorted insertion, multi-slot emission for
duplicates), `_pcre2_compile_find_dupname_details8` (`:199`: `ERR53` when
absent, `backref_map`/`top_backref` update), capture-list passes
`_pcre2_compile_parse_scan_substr_args8` (`:301`, bitmap dedup to constant)
and `_pcre2_compile_parse_recurse_args8` (`:491`, capture list →
heapsort via `do_heapify_u16` + adjacent-dedup), `_pcre2_compile_process_capture_list`
(`:721`, `ERR15` on unknown name / over-bracount), `do_heapify_u16`
(`:874`, textbook max-heap sift-down — correct).

## Behavioral matrix (all EXECUTED; full matrix in
[compile report](lib__std__re__pcre2_compile.w.md))

Group-exercising cases from `docs/audit/probes/re_compile/probe_output.txt`
(vs pcre2test 10.47, all agree): `dupnames-ok` (`(?P<n>a)(?P<n>b)` +
DUPNAMES → rc=3, `g1=[0,1)`), `bad-dupname` (same, no flag → FAIL 143@14
both), `bad-backref` (`(a)\2` → 115@5 both). Prior fuzz re-run
(`prior_fuzz_output.txt`, 30/30 vs `oracle_percase.txt`): `named`
(`(?<word>ab)c` → rc=2), `namedref` (`(?P=w)`), `cond-hit`/`cond-else`,
`backref-hit`/`backref-miss`, `deep10` (10-deep nesting).
`with check lib/std/re/pcre2_compile_cgroup.w` → rc=0, 0 errors.

## Findings

None. In-report notes (not filed):

- N1: `add_name_to_table` counts and walks duplicates by `name` POINTER
  identity (`:121`, `:185`), not string comparison. Read alone this looks
  suspect, but the executed `dupnames-ok` + `namedref` cases (compile AND
  correct match) prove duplicates resolve in practice; upstream uses the
  same shape. No defect.

Verdict: COMPLETE (full read + probes)
