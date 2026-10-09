//! expect-stdout: str ab 2
//! expect-stdout: i32 7 2
//! expect-stdout: pair x 3 | 4 y

// #1647 (D65): one generic body, several instances. Sema keeps one type per
// AST node, so the `xs[i]` and `p.first` nodes of a template carried the
// last instance checked; MIR derived the element type from the indexed
// place instead of reading Sema. The element place type of an index and
// the declaration index of a field projection are now Sema's facts per
// instance (index_element_in_body, field_decl_index_in_body), and
// `with analyze audit:all` judges every specialization body against them
// (deep-debug-tool-tests).

type Pair[A, B] {
    first: A,
    second: B,
}

fn joined[T](xs: &List[T], f: fn(&T) -> str) -> str:
    var out = ""
    for i in 0..xs.len() as i32:
        out = out ++ f(&xs[i])
    out

fn count_of[T](xs: &List[T]) -> i32:
    var n = 0
    for i in 0..xs.len() as i32:
        let _ = &xs[i]
        n += 1
    n

fn describe[A, B](p: &Pair[A, B], fa: fn(&A) -> str, fb: fn(&B) -> str) -> str: fa(&p.first) ++ " " ++ fb(&p.second)

fn main:
    let words: List[str] = ["a", "b"]
    print(f"str {joined(&words, w => w)} {count_of(&words)}")
    let nums: List[i32] = [3, 4]
    print(f"i32 {nums[0] + nums[1]} {count_of(&nums)}")
    let p = Pair { first: "x", second: 3 }
    let q = Pair { first: 4, second: "y" }
    let left = describe(&p, s => s, n => f"{n}")
    let right = describe(&q, n => f"{n}", s => s)
    print(f"pair {left} | {right}")
