# Deferred expression temporaries escaped their exit edge

Tracked in #1111, including the validator's false-green result.

The seven-line reproduction in `test/phase/validate_all_defer_temporaries.w`
registers a deferred assertion, conditionally returns, then continues. With
specification §2.4 requires deferred cleanup at scope exit. Its assertion-message
temporary must be initialized before its drop on each execution path.

Before the fix, `_2` was initialized only in the return arm (`bb1`) but dropped
in the continuing join (`bb3`). `--validate-all` incorrectly printed `ok`:
the ownership validator rejected `MaybeGarbage` but accepted pure `Uninit`.

The native allocator route exposed this in the streaming gunzip helper after
replacing raw allocation/manual cleanup with scoped ownership. In the actual
test binary, LLDB stopped at `rt_munmap` with `x0=0x116e78000` and
`x1=0x400010`: a string drop unmapped the owned output vector. The stack was
`rt_free_unlocked_with_drop_origin` (`rt_core.w:1353`) ←
`with_str_free_drop_origin` (`rt_core.w:2708`) ← `inflate_gzip` at
`0x100009470`. The next `inflate` write faulted at `0x10000ae80`.
Local evidence: `/tmp/with-gunzip-buffer-unmap-lldb.log` and
`/tmp/with-gunzip-cases-crash-lldb.log`.

LLDB on frozen compiler 519ec35f stopped at
`MirBuilder.emit_defers_for_return+68` (`0x1007f6f54`), the `lower_expr`
call corresponding to `MirLower.w:1132`. Its caller was `lower_return` through
`lower_if`. Continuing to `register_stmt_temp` showed `w1=2` (the local) and
`w2=16` (str), with the deferred expression on the stack. `lower_return`
had already flushed its statement frame, so registration escaped into the
enclosing statement's frame. Evidence: `/tmp/with-defer-lowering-lldb.log`.

Every deferred body now gets its own statement-temporary frame and is lowered
in discard context, on normal, return, loop-control, goto, and error exits.
The minimal MIR now drops `_2` in `bb4` immediately after the deferred call,
before returning; continuing `bb3` has no drop of `_2`.

The ownership validator now rejects reachable whole-local `Uninit` drops as
well as `MaybeGarbage`. Unreachable blocks still receive structural validation
but do not acquire a fictitious entry state for this ownership check. A direct
MIR regression distinguishes uninitialized, initialized, and unreachable drops.
It covers both statement and terminator drops. Drop-plan output now calls an
uninitialized drop `invalid`, rather than misleadingly claiming `skip`.

The stage1 check (without embedded bundles) exposed a second diagnostic defect
in the same dataflow driver: the sweep-bound product overflowed i32 on the large
imported PCRE2 body. LLDB stopped at `mir_drop_state_compute_blocks+276`
(`0x1004ee618`), the overflow branch after `smull`, with
`x8=0x128f58d20`, `w9=0xa35b`, `w22=0xa35a`, and `w0=0x9b1f`.
This is the multiplication at `Mir.w:2044`, before the first sweep. The bound
and sweep counter now use i64; a direct regression checks the 50,000-local,
50,000-block bound without allocating a huge state table. Evidence:
`/tmp/with-defer-validator-bound-lldb.log`.

Iterate evidence: source check and `:dev` passed. The actual scoped gunzip
fixture, compiled with the patched stage1, passes a binary roundtrip larger
than its 4 MiB buffer, empty data, output bounds, corruption, truncation, and
output-open errors with `WITH_DEBUG_ALLOC=1 WITH_ALLOC_NO_REUSE=1`; it prints
`gunzip cases ok` and `debug-alloc: leak count=0`.
Local log: `/tmp/with-gunzip-scoped-fixed-native.log`.

Full battery and cross-platform verification are still required. The Linux
fixture also covers a buffered close failure using `/dev/full`.

The final iterate build passed after the validator repairs. The minimal core
prelude fixture passes `--validate-all` and `audit:all`; the direct MIR tests
pass for both statement and terminator drops and the large sweep bound.
The dynamic-allocation control-flow matrix prints `debug-alloc: leak count=0`.
