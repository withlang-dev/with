//! expect-error: `@[c_export]` needs the C name it exports
// #2554 (§16.5): the exported C name is required; a bare `@[c_export]`
// exported nothing and said nothing.

@[c_export]
pub fn exported_without_a_name(x: i32) -> i32: x

fn main:
    print(exported_without_a_name(1))
