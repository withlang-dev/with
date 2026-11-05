//! expect-error: returned ephemeral value borrows a temporary that dies when this function returns

// #3004 (§21.1): returning an ephemeral iterator adapter built over a
// temporary collection in the callee's body cannot outlive the call.

fn bad(): [1, 2] |> map(x => x * 2)

fn main:
    var d = bad()
    print(d.next().unwrap())
