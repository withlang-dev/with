//! expect-stdout: 1
//! expect-stdout: drop 1
//! expect-stdout: drop 9
//! expect-stdout: 9
//! expect-stdout: 5050
//! expect-debug-alloc: leak count=0

// #2351 (§9.7 D115, §2.4): an owned List a match consumed is dropped even
// when the pattern takes nothing out of it (`[..]`) or leaves the
// remainder under a bare `..`: what the pattern leaves is a statement
// temporary that dies at the statement's end. Before, a parameter moved
// into such a match was dropped by nobody. The canonical recursion
// `[h, ..t] => h + sum(t)` ends on `[]` the same way. In `first_tok` the
// remainder (1) dies with the match statement, before `t` (9) leaves scope.
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): print(f"drop {self.id}")

fn take(xs: List[i32]) -> i32:
    match move xs:
        [..] => 1

fn first_tok(toks: List[Tok]) -> i32:
    match move toks:
        [t, ..] => t.id
        [] => 0

fn sum(xs: List[i32]) -> i32:
    match move xs:
        [h, ..t] => h + sum(t)
        [] => 0

fn main:
    print(take([1, 2, 3]))
    print(first_tok([Tok { id: 9 }, Tok { id: 1 }]))
    var big: List[i32] = List.new()
    for i in 1..101: big.push(i)
    print(sum(big))
