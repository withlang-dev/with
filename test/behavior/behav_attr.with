//! check-only

// Behavior test: @[attribute] annotations (spec SS11.8)
// Tests that @[sealed] and @[flags] attributes parse correctly.
// TODO: @[derive(Eq)], @[repr(C)] not yet implemented.

@[sealed]
enum Shape { Circle | Square | Triangle }

@[flags]
enum Perms: i32 { Read = 1 | Write = 2 | Execute = 4 }

fn main:
    let s: Shape = .Circle
    let p = Perms.Write
    let x = 42
    assert(x == 42)
