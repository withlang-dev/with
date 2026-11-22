//! expect-error: ephemeral value borrows a temporary that dies at the end of this statement

// #3004 (D142, §13.5, §21.1): `[1, 2] |> map(...)` inserts `.iter()` over the
// statement-scoped `List` temporary; binding the resulting ephemeral iterator
// outlives the temporary and is refused with the same diagnostic as `[1, 2].iter()`.

var doubled = [1, 2] |> map(x => x * 2)
print(doubled.next().unwrap())
