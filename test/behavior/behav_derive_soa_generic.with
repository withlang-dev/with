//! expect-stdout: ok

@[derive(SoA)]
type Column[T] {
    value: T,
    label: str,
}

@[derive(SoA)]
type PairColumn[K, V] {
    key: K,
    value: V,
}

fn main:
    var ints = ColumnSoA[i32].new()
    ints = ints.push(Column { value: 10, label: "ten" })
    ints = ints.push(Column { value: 20, label: "twenty" })

    assert(ints.len() == 2)
    let first = ints.get(0)
    assert(first.value == 10)
    assert(first.label == "ten")
    let second = ints.get(1)
    assert(second.value == 20)
    assert(second.label == "twenty")

    var pairs = PairColumnSoA[str, i32].new()
    pairs = pairs.push(PairColumn { key: "a", value: 1 })
    pairs = pairs.push(PairColumn { key: "b", value: 2 })

    assert(pairs.len() == 2)
    let a = pairs.get(0)
    assert(a.key == "a")
    assert(a.value == 1)
    let b = pairs.get(1)
    assert(b.key == "b")
    assert(b.value == 2)

    print("ok")
