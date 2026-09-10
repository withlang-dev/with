# The zlib facade owns its chunk limit

Removing embedded-header declarations at 9038f2fc exposed six references
to `UINT_MAX` in the handwritten `lib/std/zlib.w` facade. Regeneration had
left the migrated C implementation files byte-identical; the remaining
dependency was the facade's size checks and inflate chunk loop.

Route: failing source diagnostic, demand the affected functions through
`behav_zlib_std.w`, then LLDB on the compiler's diagnostic branch.
`Sema.check_ident` reached `SemaCheck.w:7168`, its unknown-identifier branch,
at return PC 0x1001fa538. `/tmp/with-zlib-facade-limit-lldb.log` records the
backtrace; the full test capture names every unresolved `UINT_MAX` use.
Checking the facade alone did not demand those functions, so it was not
sufficient verification. The existing behavior test caught the defect.

The facade now computes its private maximum from `c_uint`, `(0 as c_uint)
-% 1`, instead of importing an SDK macro from generated definitions.
The input-length check precedes narrowing to the C length type. Redundant
casts and nested unsafe blocks in the touched functions were removed.
The forward-called inflate helper retains its explicit result type because
the current inference pass otherwise assigns Unit at the earlier call site.

The existing zlib behavior source, with only its import redirected to a
local copy of the corrected facade, passes with stage1. That exercises zlib
and gzip round trips, a known gzip fixture, compression levels, malformed
input and output limits. The next compiler build embeds this corrected
facade and runs the original test through its normal `std.zlib` import.
