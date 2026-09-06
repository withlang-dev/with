# Primary verification — `lib/std/re/pcre2_xclass.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 1328 lines — class header/escape/range/posix/negation
parsing (`:32-630`: `XCL_END/NOT/SINGLE/RANGE/PROP/NOTPROP` emission,
`&`/`|`/`-`/`^` inside-class operator disambiguation, caseless + UCP
property paths) and `parse_extended_class` (`:631-1328`, the
`--[&&||]` UTS#18 set-operation compiler) fully read.

## Scope examined

Both class syntaxes from the man page (`man pcre2pattern`, verified on
this machine): Perl `(?[...])` (literals/ranges only inside nested
`[...]`, atoms = escapes/types/POSIX/nested classes) and ALT
`PCRE2_ALT_EXTENDED_CLASS` UTS#18 set ops inside ordinary `[...]`.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r8_xclass_uni.w` (`output_r8.txt`),
  oracle direct C programs (`cc … -lpcre2-8`, this machine's 10.47):
  `perl-nested rc=1 span=0..1` (`(?[[a-z]])`/`b`),
  `perl-diff compile-fail ec=209 off=10` (`(?[[a-z]--[aeiou]])` —
  identical code AND offset in C),
  `alt-diff-y rc=1 span=0..1` / `alt-diff-n rc=-1`
  (`[a-z--[aeiou]]` + ALT on `b`/`a` — identical in C),
  `alt-neg rc=1 span=0..1` (`[^x]` + ALT on `y` — identical in C).
  Classic paths: `neg-digit rc=-1 neg-letter rc=1` (== python `re`),
  `uplu rc=1 span=0..2` for U+03A9 (== pcre2test `0: \x{3a9}`).
  PASS — including failure-code parity (216/209 at identical offsets
  for the invalid forms, confirmed against C first since the system
  `pcre2test` build also rejects them).
- `with-stage1 check lib/std/re/pcre2_xclass.w` → `ok` (exit 0).

## Findings

None. In-report notes (not filed):
- Initial probe used bare `(?[a-z])` (invalid in BOTH Perl and ALT
  forms); both the port and the C library reject it with 216/off-4.
  Probe expectations were corrected to the man-page syntax; the module
  was right throughout.

Verdict: COMPLETE
