//! expect-stdout: ok

use pre_d_build_runner

// D114 (§4.1): `isize` is the target's size width. A literal nothing demands
// a width of is `isize`, and it and comptime arithmetic are checked at the
// target's width, not the host's: on wasm32, 3000000000 and 2147483647 + 1 do
// not fit. A C-layout or serialized struct with an `isize`/`usize` field
// warns, since a value that leaves the process has a fixed width; a plain
// struct does not.
fn main:
    let case_dir = p7_prepare_case("d114_isize_target_width", "d114")
    p7_write(case_dir, "layout.w", "use std.json

@[repr(C)]
type Header { len: isize, tag: i32 }

// No std.json impl serializes `usize`, so the field is written by hand.
type Record { count: usize, id: i64 }

impl Serialize for Record:
    fn serialize(self: &Record, out: JsonWriter) -> JsonWriter: out.value_i64(self.id)

type Plain { len: isize }

fn main:
    let h = Header { len: 3, tag: 1 }
    let p = Plain { len: 4 }
    print(h.len + p.len)
")
    let layout = p7_run(case_dir, "layout-native", "check\0layout.w\0")
    p7_assert_success(layout, "layout native")
    assert(layout.stderr.contains("field `len` of C-layout struct `Header` is `isize`"))
    assert(layout.stderr.contains("field `count` of serialized struct `Record` is `usize`"))
    assert(not layout.stderr.contains("struct `Plain`"))

    p7_write(case_dir, "wide.w", "fn main:
    let big = 3000000000
    print(big)
")
    p7_assert_success(p7_run(case_dir, "wide-native", "check\0wide.w\0"), "wide native")
    p7_assert_failure_contains(p7_run(case_dir, "wide-wasm32", "check\0--target\0wasm32\0wide.w\0"), "integer literal does not fit `isize` on this target (32 bits)", "wide wasm32")

    p7_write(case_dir, "fold.w", "comptime fn past(): 2147483647 + 1

fn main:
    print(past())
")
    p7_assert_success(p7_run(case_dir, "fold-native", "check\0fold.w\0"), "fold native")
    p7_assert_failure_contains(p7_run(case_dir, "fold-wasm32", "check\0--target\0wasm32\0fold.w\0"), "constant arithmetic overflows `isize`", "fold wasm32")
    print("ok")
