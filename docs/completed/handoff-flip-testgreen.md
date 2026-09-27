# Flip test-green campaign — state at 2026-08-15 08:10

## Where :test stands (battery take 22 lineage)

Green on every take since take 16: build, :fixpoint, :move-audit,
:drop-audit, :debug-alloc-tests. All nine test-file suites green
(943 behavior / 733 compile-errors / 16 codegen / 210 spec / 51 phase /
6 comptime-diff / 13 internals / 7 lexer / 9 parser). Action targets
green through: deep-debug, smoke, one-liner, fmt, object-symbol,
build-w (all cases), project-tests (all cases), edge-tests up to
emit_c_receiver_abi.

## The ONE remaining red

cli-selfhost-edge-tests → emit_c_receiver_abi: now a LOUD cc type error
(was: silent empty output). #785 has the full map — the emit-c call
marshaller must take addresses for &str params on the direct-extern
path (`with_print_str(WITH_STR_LIT("ok"))` needs `&((with_str){...})`),
ideally via one FnAbi descriptor (D6) instead of per-path classification.
Start at src/CCodegen.w ~5720 (gen_call args) + callee_sig_from_operand.
Verify: rerun the emit→cc→run cycle in
out/test-graph/cli-selfhost-edge-tests/emit_c_receiver_abi_case, then
`with build :test` (everything else is cached green).

## After full green — reseed chain (BLOCKED on a ruling)

`with build :test-green` → `:last-green` → `:update-seed` →
`:install-user`, verify with `:dev` + shasum equality. HOLD: #783 (a
live layout-sensitive UAF lottery in the flip compiler — full dossier
in docs/handoff-783-uaf.md) should be weighed by Eric before installing
this compiler as the seed. The #783 TRIGGER (spurious lowering_failed
from the dyn-dispatch branch) is fixed; the stale-handle flag write it
exposed is not.

## Open issues filed this campaign

#777 leak (pre-existing), #780 borrow-clone residue (non-str types),
#781 fixed (str-view materialization under explicit owned demand),
#782 partial-move-then-borrow diagnostic gap (two instances fixed by
cloning; class remains), #783 UAF lottery, #784 sidecar-key phase test
runs at ~43s vs its timeout, #785 emit-c marshalling.

## Post-green queue (unchanged)

Reseed → remove BOOTSTRAP INTERIM `++ ""` dodges → #777 → D30 runtime
retirement → PR #611 merge on Eric's word.
