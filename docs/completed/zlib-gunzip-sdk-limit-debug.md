# The gunzip build helper also depended on an SDK export

After SDK-origin declarations were removed from the promoted zlib definitions,
`build/zlib_gunzip.w:79` still referenced `UINT_MAX`. This helper is used by
both reference-fetch actions and is covered by `build-helper-programs`.

The failing `zlib-reference` action reported both undefined references on
that line. Running its helper through the actual stage2 compiler under LLDB,
with a breakpoint on `Sema.emit_error_with_suggestion`, stopped in
`Sema.check_ident` at PC `0x100522fb8`. The binary-condition path reached
the ordinary unknown-identifier diagnostic, not a macro expansion or linker
failure. Transcript: `/tmp/with-zlib-gunzip-limit-lldb.log`.

The helper now computes its own private maximum from `c_uint`, matching the
type of zlib's `avail_in` field. The comparison occurs in i64 before narrowing
the selected chunk size. Redundant pointer casts in the touched function
were removed; required unsafe call contexts are retained.

Validation: the macro candidate's release compiler builds the helper. It
decompresses the pinned, SHA-verified zlib 1.3.2 archive successfully, and the
resulting tar contains the library and both test programs. Existing
build-helper and reference-action checks cover this path in the full battery.
Logs: `/tmp/with-gunzip-helper-fixed-{build,run}.log`.
