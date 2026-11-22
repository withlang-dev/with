//! expect-stdout: ok

// A migrated C declaration can bind a translated aggregate to the same native
// symbol used by a language intrinsic. The intrinsic must reuse the declaration's
// recorded C ABI and pack its native str value to that physical call shape.
type MigratedStrAbi { ptr: *const i8, len: i64 }
impl Copy for MigratedStrAbi

@[link_name("with_str_byte_at")]
extern fn migrated_str_byte_at(s: MigratedStrAbi, index: i64) -> i32

fn main:
    assert("x".byte_at(0) == 120, "link-name ABI is honored by the intrinsic call")
    print("ok")
