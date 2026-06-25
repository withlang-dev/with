# Deep Debugging Tools

Status: implemented. Audience: compiler/runtime contributors.

These tools exist to stop edit/compile/trace loops. Use them to reduce the
input, inspect the exact MIR place or origin, classify allocator behavior, or
localize fixpoint nondeterminism before changing code.

## Repro Reduction

`with reduce` minimizes a single-file repro by deleting source lines while a
predicate still holds.

```sh
./out/stage/bin/with-stage2 reduce repro.w \
    --contains "undefined variable" \
    -- ./out/stage/bin/with-stage2 check {file}
```

Options:

- `--out <path>` writes the reduced repro somewhere specific.
- `--contains <text>` requires predicate stdout/stderr to contain the text.
- `--exit-code <n|nonzero>` requires an exact exit code or any non-zero exit.

The source path must immediately follow `reduce`. Use `{file}` in the predicate
argv for the candidate path; without it, the candidate path is appended.

## MIR Place Inspection

These run from `with check` after MIR lowering:

```sh
./out/stage/bin/with-stage2 check repro.w --trace-place main:_1
./out/stage/bin/with-stage2 check repro.w --explain-mir-origin main:_1
./out/stage/bin/with-stage2 check repro.w --validate-all
./out/stage/bin/with-stage2 check repro.w --validate-ownership
```

- `--trace-place <fn:place>` prints MIR locals, statements, and terminators in
  matching functions whose text mentions the target place.
- `--explain-mir-origin <fn:item>` prints local/type/span and MIR statement or
  terminator lines that mention the target item.
- `--validate-all` runs all MIR validators and reports `validate-all: ok` or the
  first validator error.
- `--validate-ownership` runs the MIR shape checks plus ownership-specific
  place/type checks and reports `validate-ownership: ok` or the first error.

Use these before adding temporary trace prints to MIR lowering, ownership, or
codegen code.

## Ownership And Cleanup Inspection

These commands focus on deep move/drop bugs, especially partial moves, cleanup
edges, and future runtime drop-flag work:

```sh
./out/stage/bin/with-stage2 check repro.w --trace-ownership main:_1
./out/stage/bin/with-stage2 check repro.w --dump-drop-plan
./out/stage/bin/with-stage2 check repro.w --dump-place-map
./out/stage/bin/with-stage2 check repro.w --trace-cleanup-edge 'main:bb0->bb1'
./out/stage/bin/with-stage2 check repro.w --dump-drop-flags
```

- `--trace-ownership <fn:place>` prints before/after ownership state for the
  selected place whenever MIR statements or terminators move, drop, initialize,
  or otherwise mention it. Use `fn:` with an empty place to trace all tracked
  places in that function.
- `--dump-drop-plan` prints each MIR drop site, the place being dropped, its
  state before cleanup, and whether the static plan drops, conditionally drops,
  or skips it.
- `--dump-place-map` lists each MIR place with its base local, type id, and
  normalized projection list. Use it when `_N.fK` does not mean what the source
  expression seemed to mean.
- `--trace-cleanup-edge <fn:from->to>` prints ownership state across one CFG
  edge. Both `0->1` and `bb0->bb1` are accepted. Quote this argument in shell
  commands because `>` is a redirection operator.
- `--dump-drop-flags` reports runtime drop-flag state. The current compiler has
  no runtime drop flags, so this explicitly reports `<no drop flags>` until that
  substrate is implemented.

Do not infer the root cause from these reports alone. They show what MIR
believes; use `lldb` on the lowering or codegen branch to prove why it believes
that.

## Fixpoint Diff

When `with build :fixpoint` fails, generate a focused byte-level report:

```sh
with build :fixpoint-diff
cat out/fixpoint-diff/report.txt
```

Or run it directly:

```sh
./out/stage/bin/with-stage2 fixpoint-diff \
    out/stage/bin/with-stage2-fixpoint.o \
    out/stage/bin/with-stage3-fixpoint.o
```

The report names file sizes, whether the size differs, the first differing byte
offset, and a small byte window around the mismatch. It does not yet attribute
the difference to an object symbol; use `llvm-nm`, `otool`, or `lldb` after the
byte offset narrows the search.

## Debug Allocator Filters

The native debug allocator remains the first tool for drop, lifetime,
double-free, use-after-free, and leak bugs:

```sh
./out/stage/bin/with-stage2 run --debug-alloc repro.w
./out/stage/bin/with-stage2 run --debug-alloc --debug-alloc-filter=non-root repro.w
```

Leak filters:

- `all` shows every live allocation.
- `non-root` suppresses allocations marked as process-lifetime roots.
- `roots` shows only marked roots.

Runtime code can mark an allocation as an intentional root with
`with_debug_alloc_mark_root(ptr, reason_ptr, reason_len)`. Debug-allocator
fixtures can set `//! debug-alloc-filter: non-root` to assert the non-root leak
view instead of raw process-lifetime noise.

## Verification Targets

```sh
with build :deep-debug-tool-tests
with build :debug-alloc-tests
with build :fixpoint-diff
```

The full `with build :test` target includes `:deep-debug-tool-tests`; run the
focused targets while developing changes to these tools.
