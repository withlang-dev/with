//! expect-stdout: true
//! expect-stdout: 42
//! expect-stdout: true true
//! expect-stdout: 2

// D139 (Eric, 2026-10-20): a view of a view of a Copy value carries no
// information beyond the value, so it meets an owned-value demand at every
// layer. The two fixtures this replaces (err_auto_deref_value_comparison_
// requires_explicit_deref, err_nested_ref_not_auto_copy_call_arg) encoded
// behavior no ruling made; a later ruling that contradicts such a test wins.
fn take_i32(value: i32) -> i32: value

// Generics must agree with concrete code: `==` on a T instantiated with
// `&i32` compares the values, as `r1 == r2` does.
fn same[T](a: T, b: T) -> bool: a == b

fn main:
    let x = 42
    let r = &x
    let rr = &r
    print(f"{rr == 42}")
    let value: i32 = 42
    let first = &value
    print(f"{take_i32(&first)}")
    let y = 42
    let r1 = &x
    let r2 = &y
    print(f"{r1 == r2} {same(r1, r2)}")
    // The case that surfaced the rule: a view iterator hands `filter` a
    // `&&i64`, and the predicate reads the value with no `*it`.
    var nums: List[i64] = List.new()
    nums.push(3)
    nums.push(4)
    nums.push(5)
    let odd = view_iter(&nums) |> filter(it % 2 == 1) |> count()
    print(f"{odd}")

type ViewIter[T] ephemeral { list: &List[T], idx: isize }

impl[T] Iter[&T] for ViewIter[T]:
    mut fn next() -> Option[&T]:
        if self.idx >= self.list.len(): return None
        let i = self.idx
        self.idx = self.idx + 1
        Some(&self.list[i])

fn view_iter[T](list: &List[T]) -> ViewIter[T]: ViewIter { list, idx: 0 }
