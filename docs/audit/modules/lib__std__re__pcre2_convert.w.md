# Primary verification — `lib/std/re/pcre2_convert.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 2776 lines — entry/validation/length preflight
fully read (`:32-340`: `CONVERT_GLOB`/`POSIX_BASIC`/`POSIX_EXTENDED`
dispatch, `pattype==0`→-34, null-buffers→-51, `CONVERT_LENGTH`/`NO_UTF`
/UTF-extra flag plumbing, `get_uc` dispatch); glob converter
(`convert_glob`: `*→[^/]*?`, `?→[^/]`, classes with `(*COMMIT)` first-
match fencing, `{a,b}→(?:a|b)` nesting, `NO_SLASH`/`NO_WILDSTAR`
variants) and both POSIX converters (`convert_posix`,
`convert_posix_sp`: BRE `\(...\)`/`*` anchoring, `(*NUL)` markers)
read in full.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r6_convert_serialize.w`
  (`output_r6.txt`), oracle `cc … -lpcre2-8` C program on the same
  inputs — all four conversions byte-exact (lengths included):
  `*.txt → (?s)\A[^/]*?\.txt\z` (19),
  `foo.??? → (?s)\Afoo\.[^/][^/][^/]\z` (25),
  `[a-c]*.txt → (?s)\A[a-c](*COMMIT)[^/]*?\.txt\z` (33),
  `a(b*)c [BRE] → (*NUL)a\(b*\)c` (14).
  Converted patterns compile+match correctly
  (`foo.txt→1`, `foo.dat→-1`; `[a-c]` rejects `foo.txt`;
  BRE literal parens reject `abbbc`).
  `conv-badopt rc=-34 conv-null rc=-51`. PASS.
- `with-stage1 check lib/std/re/pcre2_convert.w` → `ok` (exit 0).

## Findings

None.

Verdict: COMPLETE
