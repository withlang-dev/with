//! expect-stdout: [1, 2, 3, 4, 5] [1, 2] [3, 4, 5]
//! expect-stdout: [1, 2, 10, 20] [1, 2, 3]
//! expect-stdout: [1, 2, 4, 5] [7, 8, 1, 2]
//! expect-stdout: ["a", "b", "c"] ["a", "b"]
//! expect-stdout: [9, 1, 2, 3, 4, 5] xyz
//! expect-stdout: 3
//! expect-stdout: abcd
//! expect-stdout: drop 1
//! expect-stdout: drop 2
//! expect-stdout: drop 3

// D116 (§15.4.9): `a ++ b` concatenates two sequences of one element type
// into a new List; a List, a slice, a fixed array and a list literal all
// take part, in either position, and both operands are left untouched.
// `++=` extends in place and `v ++= [x]` appends. Elements that are not
// Copy move (the Tok operands are at their last use), each dropped once.
// A str element is a value (D111): the result holds its own copies and
// the operand keeps its own. Two `str` still give a `str`.
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): print(f"drop {self.id}")

fn fmt(xs: &List[i32]) -> str: f"{xs:?}"

fn main:
    let xs = [1, 2]
    let ys = [3, 4, 5]
    let all = xs ++ ys
    print(f"{fmt(all)} {fmt(xs)} {fmt(ys)}")
    let lit = xs ++ [10, 20]
    let lits = [1, 2] ++ [3]
    print(f"{fmt(lit)} {lits:?}")
    let part = xs ++ ys[1..3]
    let arr: [i32; 2] = [7, 8]
    let from_arr = arr ++ xs
    print(f"{fmt(part)} {fmt(from_arr)}")
    var names = ["a", "b"]
    let more = names ++ ["c"]
    print(f"{more:?} {names:?}")
    var acc: List[i32] = List.new()
    acc ++= [9]
    acc ++= xs
    acc = acc ++ ys
    var words = ["x"]
    words ++= ["y", "z"]
    print(f"{fmt(acc)} {words.join("")}")
    let toks = [Tok { id: 1 }, Tok { id: 2 }]
    let joined = toks ++ [Tok { id: 3 }]
    print(f"{joined.len()}")
    print("ab" ++ "cd")
