// Checked as every target by `with build :every-target-check` (D91, §17.5):
// `with check --target <t>` for each target With compiles for. It holds
// what must type-check on all of them: the standard library's per-target
// values, and one branch per target that names something only that
// target's branch may name.

use std.os.Target
use std.os.OsKind
use std.libc

const NEWLINE: str = comptime match Target.os:
    .Windows => "\r\n"
    .Macos => "\n"
    .Linux => "\n"
    .Wasi => "\n"

fn only_on_windows() -> i32: 1
fn only_on_posix() -> i32: 2

fn family() -> i32:
    comptime if Target.os == .Windows:
        only_on_windows()
    else:
        only_on_posix()

// std.libc's per-target constants (D90) have a value on every target.
fn libc_values() -> i64:
    (libc.EAGAIN + libc.EWOULDBLOCK + libc.CLOCKS_PER_SEC + libc.LC_CTYPE) as i64 + (libc.RLIM_INFINITY % 7) as i64 + (libc.ULONG_MAX % 7) as i64

fn main:
    let os: OsKind = Target.os
    print(f"{NEWLINE.len()} {family()} {os == .Wasi} {libc_values()}")
