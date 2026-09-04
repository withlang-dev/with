# Primary verification — `lib/std/re/pcre2_pattern_info.w`

Status: **COMPLETE** (no defects)
Primary verifier: audit-re-support (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 1471 lines — `pcre2_pattern_info_8` fully
(`:32-297`: 28 query codes); `pcre2_callout_enumerate_8` (`:299-1471`):
entry/exit + every special arm read (119/120 callout arms, sentinel
arms, OP_lengths table stepping for arms 29-92 verified as uniform
`ptr += OP_lengths[...]` steps via arm inventory).

## Scope examined

All 28 info queries: options/BSR/newline (direct fields), backrefmax,
capturecount, first/last codeunit + type (study-computed),
framesize, hasbackslashc/crrorlf/jchanged, matched-empty flags,
maxlookbehind/minlength, namecount/entrysize/table (always returns the
in-struct base even at count 0), heapframes/size/blocksize
(`sizeof` computations), `pcre2_substring_number_from_name_8`
(`:270-297`: first-entry match → number, else -49). Null `where`
returns the size probe (4 for uints, 8 for pointers/sizes); unknown
`what` → -34. The enumerate walker replays compiled bytecode; callback
is caller C code (not executed here — see note).

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/re_support/r3_pattern_info.w` (`output_r3.txt`),
  oracle `pcre2test /info` on the same patterns:
  `(a+)(b)?(?<nm>c*)` → `capcount=3 minlen=1 namecount=1
  nameentrysize=5 firstcu=97('a') firsttype=1 lastcu=0 lasttype=0
  backrefmax=0 hascrrorlf=0 matchempty=0 hasbslashc=0 alloptions=0
  nametable non-null size=195 numfrom nm=3 bad=-49`;
  `abc` → `capcount=0 minlen=3 firstcu=97 lastcu=99('c') lasttype=1`.
  Every value matches the oracle (`Capture group count = 3/0`,
  `lower bound = 1/3`, `First 'a'`, `Last 'c'`, `nm → 3`).
  `badwhat rc=-34 nullcode rc=4`. PASS.
- `with-stage1 check lib/std/re/pcre2_pattern_info.w` → `ok` (exit 0).

## Findings

None. In-report notes (not filed):
- `pcre2_callout_enumerate_8` itself was not executed (needs a C
  callout function pointer); its opcode-step arms are uniform and were
  inventoried, and the info half — the audited surface — is fully
  probed. Study-computed fields (first/last/minlength) passing also
  indirectly verifies `_pcre2_study_8` output encoding.

Verdict: COMPLETE
