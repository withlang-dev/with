# Global replacement starts with initialized storage

The compiler ownership audit at 0378d521 rejected the replacement of
`link_stage_temp_archives` in `link_stage_cleanup_current_process_temp_archives`:
`fn sym1987 stmt1: drop of _2 ... (Uninit)`. MIR marks `_2` as `[global]`;
the backend binds it to module storage, whose initialization precedes main.

The phase regression reduces this to replacing a global Vec. The old
validator rejects `clear` as `fn sym225 stmt0: drop of _2 ... (Uninit)`.
LLDB stopped in MirDropStateKeys.initial at `0x10031d9b4` with `w23=2`
(the global proxy) and `w8=0` (parameter count). The branch at `+248`
falls through to `str wzr`, choosing Uninit without checking local_is_global.
This is Mir.w's initial-state branch, not a missing runtime initialization.
Evidence: `/tmp/with-global-drop-branch-lldb.log` and
`/tmp/with-global-drop-verdict.log`.

Global proxies now enter the dataflow initialized. Direct MIR tests distinguish
the same slot with and without its global marker; the ordinary local still
fails. No drop-validation exemption is added.
