//! expect-stdout: 2
//! expect-stdout: 12

// #2220 step 2 (D22 §7.4): a view of a view of a Copy value satisfies an
// owned-value demand the same way a view does. A list iterator that yields
// `&T` hands `filter`'s predicate a `&&i64`; `it % 2 == 1` reads the i64
// through both layers, as `for x in …: total + x` already reads through one.
type ViewIter[T] ephemeral { list: &List[T], idx: isize }

impl[T] Iter[&T] for ViewIter[T]:
    mut fn next() -> Option[&T]:
        if self.idx >= self.list.len(): return None
        let i = self.idx
        self.idx = self.idx + 1
        Some(&self.list[i])

fn view_iter[T](list: &List[T]) -> ViewIter[T]: ViewIter { list, idx: 0 }

fn main:
    var nums: List[i64] = List.new()
    nums.push(3)
    nums.push(4)
    nums.push(5)
    let odd = view_iter(&nums) |> filter(it % 2 == 1) |> count()
    print(f"{odd}")
    var total: i64 = 0
    for x in view_iter(&nums): total = total + x
    print(f"{total}")
