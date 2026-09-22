# ephemerality-and-lowering

Spec-focused example for testing:

- `with` lowering via explicit `Scoped[T]` implementation
- ephemeral values across trait-object and generic boundaries
- async scope tracking with ephemeral tasks
- nested `with` + await + early-return control flow

## Files

- `ephemerality_and_lowering.w` — primary example module (includes `@[test]` cases)
- `test/ephemerality_and_lowering_test.w` — package-style test implementation

## Run

From this directory:

```bash
with run ephemerality_and_lowering.w
with test test/ephemerality_and_lowering_test.w
```
