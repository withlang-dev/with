# ephemerality-and-lowering

Spec-focused example for testing:

- `with` lowering via explicit `Scoped[T]` implementation
- ephemeral values across trait-object and generic boundaries
- async scope tracking with ephemeral tasks
- nested `with` + await + early-return control flow

## Files

- `ephemerality_and_lowering.w` — primary example module (includes `@[test]` cases)
- `test/ephemerality_and_lowering_test.w` — package-style test implementation

## Compile checks

From repo root:

```bash
./bootstrap/zig-out/bin/with check examples/ephemerality-and-lowering/ephemerality_and_lowering.w
./bootstrap/zig-out/bin/with check examples/ephemerality-and-lowering/test/ephemerality_and_lowering_test.w
```

Current first blocker in bootstrap compiler:

- lexer/parser rejects `vec![...]` macro-call syntax (`unexpected character` on `!`)
