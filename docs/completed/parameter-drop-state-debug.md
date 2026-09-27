# Parameter entry storage retains initialization

The strengthened ownership validator reported `Regex.compile_flags` dropping
an uninitialized `_2` in the compiler audit. `--trace-ownership sym477:_2`
showed the actual error: `StorageLive(_2)` changed the input from `Init` to
`Uninit`. The parameter had already received its caller's value.

`test/phase/validate_owned_parameter_storage_live.w` reduces this to a
consuming str parameter and a print. Frozen f97bacfe rejects it as
`fn sym221 stmt2: drop of _1 ... (Uninit)` with the core prelude.
LLDB stopped in `MirDropStateMap.transfer_stmt` for that exact function and
statement 0 at `0x100527154`. The StorageLive branch at `+92` jumps to `+140`,
then passes zero (`Uninit`) to `mark_local` at `+156`. This is the unconditional
assignment at `Mir.w:1754`. Evidence: `/tmp/with-owned-param-lldb.log` and
`/tmp/with-defer-uninit-trace.log`.

StorageLive now models parameters as initialized, matching the dataflow's
entry-state constructor and the physical callee prologue. Ordinary local
storage still begins uninitialized; StorageDead still clears either kind.
Direct MIR tests exercise all three cases without weakening drop validation.
