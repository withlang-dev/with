# Primary verification — `lib/std/encoding.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read)
Source revision: `450733e5`
Source examined: all 8 lines (single complete read — the file is
only the shared error surface, no logic)

## Scope examined

`pub error DecodeError` with variants `InvalidLength`,
`InvalidByte`, `InvalidPadding`, `NonCanonicalBits`. Consumed by
`lib/std/encoding/*` codecs (base16/32/64). No behavior to probe;
compiles as part of every dependent build.

## Behavioral matrix

Read-only: declaration well-formed, variant payloads typed
(`i64`/`u8`). No execution applicable.

## Findings

None.

Verdict: COMPLETE
