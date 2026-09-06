# Primary verification — `src/tools/generate_embedded_stdlib.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + behavior evidence)
Source revision: `450733e5`
Source examined: all 177 lines (two complete reads)

## Scope examined

Build-time embedder: raw-string fence selection (`:9-33`),
CRLF normalization (`:35-47`), path relativization (`:49-55`),
byte comparator + insertion sort (`:57-85`), tree walk with
`re/` exclusion (`:87-99`), module emission + index
(`:125-177`). Runs every build; output
`out/gen/compiler/EmbeddedStdlibData.w`.

## Behavioral matrix

- End-to-end existence proof: every build regenerates the
  bundle successfully (exit 0), and embedded crypto copies
  diff byte-identical vs the working tree (verified during the
  AEAD audit) — fence selection, normalization, and emission
  all correct on real inputs.
- `re/` exclusion verified: 0 `std/re/` paths in the generated
  bundle (grep count 0).
- Candidate finding refuted: `path_compare` `:64`
  `return ac - bc` looked like u8 underflow (u8 `-` panics —
  proven by direct probe), but `str.byte_at` returns `i32`
  (proven: feeds `print_i32` directly, prints 97), so the
  subtraction is safe i32 arithmetic. Not filed.

## Findings

None.

Verdict: COMPLETE
