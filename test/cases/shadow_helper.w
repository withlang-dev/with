// Helper module for prelude_shadow_explicit test.
// Provides a map function with a different signature than std.iter.map.
// When explicitly imported, this should shadow the prelude's map.

pub fn map(x: i32) -> i32:
    x * 10
