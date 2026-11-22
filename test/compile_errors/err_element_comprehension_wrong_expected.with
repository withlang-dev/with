//! expect-error: element comprehension requires List, HashSet, or BTreeSet expected type

// A comprehension bound to a non-collection expected type is rejected with the
// comprehension-specific diagnostic. (This fixture previously pinned "type
// mismatch in binding" — an accident of the #629 dangling-else parser bug that
// made the intended diagnostic's else-arm dead code in SemaCheck.)
fn main:
    let _bad: i32 = [x for x in 0..3]
