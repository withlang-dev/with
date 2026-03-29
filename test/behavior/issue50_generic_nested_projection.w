//! expect-stdout: ok

type Entry {
    name: str,
    rank: i32,
}

type Wrapper[T] {
    items: Vec[T],
}

type Outer[T] {
    wrapped: Wrapper[T],
}

fn make_entries(name0: str, rank0: i32, name1: str, rank1: i32) -> Vec[Entry]:
    let items: Vec[Entry] = Vec.new()
    items.push(Entry { name: name0, rank: rank0 })
    items.push(Entry { name: name1, rank: rank1 })
    items

fn make_wrapper(name0: str, rank0: i32, name1: str, rank1: i32) -> Wrapper[Entry]:
    let items = make_entries(name0, rank0, name1, rank1)
    let out: Wrapper[Entry] = Wrapper { items }
    out

fn make_outer(name0: str, rank0: i32, name1: str, rank1: i32) -> Outer[Entry]:
    let wrapped = make_wrapper(name0, rank0, name1, rank1)
    let out: Outer[Entry] = Outer { wrapped }
    out

fn vec_name_eq(w: Wrapper[Entry]) -> bool:
    w.items[0].name == w.items[1].name

fn vec_rank_eq(w: Wrapper[Entry]) -> bool:
    w.items[0].rank == w.items[1].rank

fn nested_name_eq(o: Outer[Entry]) -> bool:
    o.wrapped.items[0].name == o.wrapped.items[1].name

fn nested_rank_eq(o: Outer[Entry]) -> bool:
    o.wrapped.items[0].rank == o.wrapped.items[1].rank

fn loop_find_name(o: Outer[Entry], target: str) -> bool:
    var i: i32 = 0
    while i < o.wrapped.items.len() as i32:
        if o.wrapped.items[i].name == target:
            return true
        i = i + 1
    false

fn loop_find_rank(o: Outer[Entry], target: i32) -> bool:
    var i: i32 = 0
    while i < o.wrapped.items.len() as i32:
        if o.wrapped.items[i].rank == target:
            return true
        i = i + 1
    false

fn main:
    let same_names = make_wrapper("x", 1, "x", 2)
    assert(vec_name_eq(same_names))
    assert(not vec_rank_eq(same_names))

    let same_ranks = make_outer("a", 9, "b", 9)
    assert(not nested_name_eq(same_ranks))
    assert(nested_rank_eq(same_ranks))

    let looped = make_outer("lhs", 3, "target", 7)
    assert(loop_find_name(looped, "target"))
    assert(not loop_find_name(looped, "missing"))
    assert(loop_find_rank(looped, 7))
    assert(not loop_find_rank(looped, 99))

    println("ok")
