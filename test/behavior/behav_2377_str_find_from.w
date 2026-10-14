//! expect-stdout: 1 4 -1
//! expect-stdout: 4 -1 -1
//! expect-stdout: 2 6 6
//! expect-stdout: 1 4
//! expect-stdout: 3 11
//! expect-stdout: 7

// #2377 (D129): `find(needle, from = 0)` searches from a byte offset, so a
// tool finds the next occurrence with `s.find(x, first + 1)` and no slice
// arithmetic. `from` past `len()` finds nothing; an empty needle is found
// at `from`; the one-argument form is unchanged; it runs at compile time
// through the std body (D104); `rfind` on text with a multibyte character
// no longer panics inside the character.

comptime fn ct_next() -> isize:
    let s = "abcabc"
    s.find("b", s.find("b") + 1)

comptime fn ct_first() -> isize:
    let s = "abcabc"
    s.find("c")

fn main:
    let s = "abcabc"
    let first = s.find("b")
    let next = s.find("b", first + 1)
    print(f"{first} {next} {s.find("b", next + 1)}")

    print(f"{s.find("bc", 2)} {s.find("bc", 5)} {s.find("bc", 6)}")

    // An empty needle is found where the search starts; `from == len()`
    // is an empty tail, still a position; past it, nothing.
    print(f"{s.find("", 2)} {s.find("", 6)} {s.find("", 6)}")
    print(f"{ct_next() - 3} {ct_next()}")
    print(f"{"héllo wörld".find("l", 1)} {"héllo wörld".rfind("l")}")
    print(f"{s.find("", 7) + 8}")
