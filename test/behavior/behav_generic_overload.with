//! expect-stdout: 1 2 1 2

// Imported same-name generic declarations remain distinct, and the
// structurally narrower overload wins for both direct and pipeline calls.
use lib.generic_overload

fn main:
    let direct: Result[i32, str] = Ok(7)
    let piped: Result[i32, str] = Ok(7)
    print(f"{classify(7)} {classify(direct)} {7 |> classify} {piped |> classify}")
