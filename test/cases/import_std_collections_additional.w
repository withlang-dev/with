// Test: std.collections additional SlotMap/Handle/BTreeMap APIs
use std.collections

fn main() -> i32 =
    var sm = slotmap_new()
    assert(slotmap_len(sm) == 0)

    let ins1 = slotmap_insert(sm, 10)
    sm = ins1.0
    let h1 = ins1.1

    let ins2 = slotmap_insert(sm, 20)
    sm = ins2.0
    let h2 = ins2.1
    assert(h1.key == "0")
    assert(h2.key == "1")
    assert(h1.generation == 1)
    assert(h2.generation == 1)
    assert(slotmap_len(sm) == 2)

    assert(slotmap_contains(sm, h1))
    assert(slotmap_get(sm, h1).unwrap() == 10)
    assert(slotmap_get(sm, h2).unwrap() == 20)

    let rm1 = slotmap_remove(sm, h1)
    sm = rm1.0
    assert((rm1.1))
    assert(not slotmap_contains(sm, h1))
    assert(slotmap_get(sm, h1).is_none())
    let rm2 = slotmap_remove(sm, h1)
    sm = rm2.0
    assert(not (rm2.1))
    assert(slotmap_len(sm) == 1)

    let ins3 = slotmap_insert(sm, 30)
    sm = ins3.0
    let h3 = ins3.1
    assert(h3.key == "2")
    assert(h3.generation == 1)
    assert(slotmap_get(sm, h3).unwrap() == 30)
    assert(slotmap_len(sm) == 2)

    var bt = btree_new()
    assert(btree_len(bt) == 0)
    assert(not btree_contains(bt, "a"))

    bt = btree_insert(bt, "a", 7)
    bt = btree_insert(bt, "b", 9)
    assert(btree_len(bt) == 2)
    assert(btree_contains(bt, "a"))
    assert(btree_get(bt, "a").unwrap() == 7)
    assert(btree_get(bt, "b").unwrap() == 9)
    assert(not btree_contains(bt, "z"))
    assert(btree_get(bt, "z").is_none())

    let brm1 = btree_remove(bt, "a")
    bt = brm1.0
    assert((brm1.1))
    let brm2 = btree_remove(bt, "a")
    bt = brm2.0
    assert(not (brm2.1))
    assert(not btree_contains(bt, "a"))
    assert(btree_len(bt) == 1)

    0
