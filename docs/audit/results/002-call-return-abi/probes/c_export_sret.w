//! expect-stdout: c-export-sret-ok

@[repr(C)]
type CBig { a: i64, b: i64, c: i64, d: i64 }

@[c_export("audit_make_c_big")]
fn make_c_big(seed: i64) -> CBig:
    CBig { a: seed, b: seed + 1, c: seed + 2, d: seed + 3 }

fn main:
    let value = make_c_big(20)
    assert(value.a == 20 and value.d == 23)
    print("c-export-sret-ok")
