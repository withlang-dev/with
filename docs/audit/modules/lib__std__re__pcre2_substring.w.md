# Primary verification — `lib/std/re/pcre2_substring.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 575 lines (single complete read).

## Scope examined

`length_byname/bynumber` (`:32-149`: ovector-unset → length 0 — the
documented C quirk; DFA-matched → -41; over-top_bracket → -49),
`copy_byname/bynumber` (`:150-237`: small-buffer → -48 with required
length stored), `get_byname/bynumber` (`:237-328`: `with_alloc`'d NUL-
terminated copy), `list_get/list_free` (`:329+`: count+1 vector + lengths
array), `number_from_name` passthrough, `free` null-safe. The
`get(control, stringlength)` length-vs-capacity check
(`:297-300`) matches C (returns -48 when the ovector slice exceeds the
block).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r4_substring.w` (`output_r4.txt`),
  pattern `(?<word>\w+)!(?<opt>\d*)?(?<unset>x)?` on `hello!123`,
  oracle python3 `re` (groups `('hello','123',None)`):
  `match rc=3`, `copy[0]=hello!123 copy[1]=hello copy[2]=123`,
  `get word=hello len=5`, `len opt=3`,
  `copy unset rc=-55 get unset rc=-55` (unset group, both paths),
  `copy badname rc=-49 copy badnum rc=-49 len badnum rc=-49`
  (99 > top_bracket → NOSUBSTRING, per C),
  `list rc=0 l0=hello!123 l1=hello l2=123` — all exact. PASS.
- `with-stage1 check lib/std/re/pcre2_substring.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
