// NEGATIVE: struct field of type &i32 should be rejected (§3.3)
// Ephemeral references cannot be stored in structs
// EXPECT: check fails with ephemeral reference error
type Bad = { ref_field: &i32 }

fn main -> i32:
    0
