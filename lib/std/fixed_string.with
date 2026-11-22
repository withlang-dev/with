// std.fixed_string - stack-owned string storage for core/no_std code.
// FixedString[N] is compiler-known: Sema maps N to [u8; N], and MIR lowers
// the public methods directly so no heap or string runtime is required.

pub type FixedString[Storage] {
    buf: Storage,
    len_value: usize,
}

impl[Storage] Copy for FixedString[Storage]
