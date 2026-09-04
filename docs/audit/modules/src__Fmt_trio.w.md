# Primary verification — `src/Fmt.w` + `src/InternPool.w` + `src/InitTemplates.w`

Status: **Complete**
Primary verifier: root agent (child complete examination independently verified)
Source revision: `450733e5`
Source SHA-256: Fmt `8b563d39782833c6c040096708a6796e095c17866296bb573ba52af3f47e7532`;
InternPool `f673667250cd653c88b2cd068517ec8793aeafffd17fb7a3957a011d9ea141a1`;
InitTemplates `475253e27dd86eb13720ff59d4f7381114f62b9d7161b5556ff7e2beb0a37e2b`
Source examined: child all three complete; primary: rewrite outputs
(`unary_fmt.txt`, `refparam_fmt.txt` read), round-trip runs below

## Scope examined

Formatter rewrites, interning identity, template surface.

Applicable overview targets examined: T10/T18 (format fidelity), T8 (identity), T23 (rewrite safety).

## Behavioral matrix

- `run_orig.w` vs `run_fmt.w`: identical output (`-1`, `10`), both rc=0 —
  the `- 1` / `& str` / `0 .. n` rewrites are runtime-neutral. Re-run by primary.
- `unary_fmt.txt` checks as valid code (extension aside).

## Verdict: style-only rewrites — noted, not filed

- Splitting `-1`→`- 1`, `&str`→`& str`, `0..n`→`0 .. n` is cosmetically
  noisy but semantically neutral (whitespace-insensitive grammar, proven by
  identical runs). The "contradicts InitTemplates §21" claim is weak (§21.1
  is D22 country, not formatting law). No round-trip break demonstrated.
- Dead `is_unary_prefix`, tabs→spaces, `;`→newline: style internals, notes.

## Notes

- A formatter defect needs a non-round-tripping case; none found. If a
  future probe finds one, it files against this evidence.
