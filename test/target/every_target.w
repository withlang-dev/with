// Checked as every target by `with build :every-target-check` (D91, §17.5):
// `with check --target <t>` for each target With compiles for. It holds
// what must type-check on all of them: the standard library's per-target
// values, and one branch per target that names something only that
// target's branch may name.

use std.os.Target
use std.os.OsKind

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

fn main:
    let os: OsKind = Target.os
    print(f"{NEWLINE.len()} {family()} {os == .Wasi}")
