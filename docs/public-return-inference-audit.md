# Audit of 212e42b0

`212e42b0a208ab00e0ab5ca0297d21ff66423d71` added a parser rejection for
public declarations without return annotations, a negative test enforcing
that rejection, and 232 annotated declarations. It changed no specification
or decision. Section 9.1 and D43 do not make visibility an inference boundary.

The unsupported parser branch is removed. Its negative test is replaced by
inference tests, including imports, generics, methods and branching tails.
A generated public/private matrix passes with the corrected compiler and
fails against the old pinned seed at the exact unsupported diagnostic. The
explicit-spelling positive test remains: explicit annotations are legal.

## Historical annotation inventory

The token-based inventory found 216 surviving Unit declarations, four that
now explicitly return Never, and twelve retired declarations/files. Of the
216, retain six for concrete reasons:

| Declaration | Reason |
| --- | --- |
| Explicit-return positive test | Tests that explicit spelling is legal. |
| `migrate_add_define` | D43: the complete branching tail joins Unit with the value of a string assignment. Unit expresses the discard choice. |
| `Workspace.set_migrate_options` | Driver interpretation returns normally; native unsupported-operation failure is not the public return contract. |
| `Workspace.begin_intercept` | Same comptime/native distinction. |
| `Workspace.end_intercept` | Same comptime/native distinction. |
| `Workspace.set_link_command` | Same comptime/native distinction. |

Remove the other 210 annotations. The native/comptime distinction above was
caught by comparing Sema signatures, not by declaring every Unit redundant.
The four already-Never declarations (`rt_exit` on three platforms and
`with_panic`) are retained. Retired code is not resurrected.

The retired declarations are `with_fiber_stack_overflow_handler` in the
Windows fiber core; `with_regex_code_free` with the retired regex runtime;
`with_eprintln`, `with_assert`, `with_fmt_buf_write_str`,
`with_fmt_buf_write_str_spec`, `with_fmt_buf_write_debug`, `with_sb_append`,
`with_str_split`, `with_lines_out`, and `with_str_split_vec` in rt_core;
and `wl_di_insert_declare_at_end` in LlvmBridge.

## Consequences hidden by Unit

`Diagnostics.error` and `__driver_exit` infer Never. Unlike the Workspace
operations above, both their native and interpreted paths terminate. The
build API documents `Diagnostics.error` as fatal. Its explicit Unit return
hid unreachable caller code: fallback returns and literal tails after fatal
diagnostics, and a temporary-download deletion after a checksum failure's
fatal diagnostic. Remove the dead returns and move that deletion before
the diagnostic. A negative regression checks that callers cannot continue
after `Diagnostics.error`.

Counted validation loops now emit each error detail and retain their existing
nonzero aggregate outcome; they no longer abort before incrementing the count.
Consecutive fatal diagnostics are combined so the first cannot hide the
remaining context or recovery instruction. The parallel test runner reports
failed workers and reaps every child before returning failure.

LLDB stopped at `Sema.check_block`, `SemaCheck.w:9894`, with
`block_diverged = 1`, `reported_unreachable = 0`, and statement index 1.
This is the rejection of the statement after the now-Never call, not an
inference failure to work around. The native implementation calls `exit(1)`;
`eval_diagnostics_capability_method` calls `self.fail` on the interpreted path.

## Verification status

The parser fix and prevention gate have targeted passing evidence. The
annotation cleanup was self-compiled with a local compiler containing the
parser fix (138.7s compiler stage, 205.4s build wall time). The pinned seed
predates that fix and cannot compile the
cleaned public declarations; the cleanup therefore requires a parser-fix
reseed before its canonical pinned-seed chain can be declared green.

The direct per-file signature sweep passed 25 of 30 files. Four of its
standalone failures require the actual compiler-module context or runtime
`--no-prelude` configuration; the full compiler source check and configured
Windows runtime check pass. `std.string` must be checked as embedded stdlib,
where its types are not duplicated by another imported copy. After the local
self-compile, all three affected embedded StringBuilder signatures remain
Unit. The fresh compiler checks `build.w`; scanner tests pass; the fatal-call
negative test rejects its unreachable continuation. The libc surface,
runtime domain, spec inventory and user-programs-safe gates pass. A temporary
runtime file missing two foreign domain rows produces both errors and exit 1;
removing it restores the green gate. No error was downgraded to a warning.
This is not a completed pinned-seed battery or a merge-ready claim.

The standing prevention is documented in [unit-return-review.md](unit-return-review.md).
