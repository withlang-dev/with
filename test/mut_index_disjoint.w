// Test: §8.1 disjoint constant-index borrows

type Item { val: i32 }

fn read_val(r: &Item) -> i32:
    r.val

fn test_disjoint_constant_indices:
    var xs = Vec.new()
    xs.push(10)
    xs.push(20)
    xs.push(30)
    let a = &xs[0]
    let b = &xs[1]
    assert(*a == 10)
    assert(*b == 20)

fn test_borrow_and_assign_disjoint:
    var items = Vec.new()
    items.push(Item { val: 10 })
    items.push(Item { val: 20 })
    items.push(Item { val: 30 })
    let r = &items[0]
    items[1] = Item { val: 99 }
    assert(read_val(r) == 10)
