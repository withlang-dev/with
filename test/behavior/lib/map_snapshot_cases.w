//! expect-stdout: ok

// D44 / §2.3 (#1158): keys(), values() and items() return independent
// elements. They once byte-copied them, so the Vec and the map owned the same
// string buffers: a plain run passed while WITH_DEBUG_ALLOC_SCRIBBLE=1 showed
// the map corrupted, and the compiler's own `.keys()` call double-freed while
// building the OpenSSL project. A snapshot must survive its map, and the map
// must survive its snapshots. Run under WITH_DEBUG_ALLOC=1
// WITH_DEBUG_ALLOC_SCRIBBLE=1; zero leaks.

use std.collections.HashMap

fn names() -> HashMap[str, str]:
    var m: HashMap[str, str] = HashMap.new()
    m.insert("alpha".to_owned(), "one".to_owned())
    m.insert("beta".to_owned(), "two".to_owned())
    m

fn keys_outlive_map() -> Vec[str]:
    let m = names()
    m.keys()

fn values_outlive_map() -> Vec[str]:
    let m = names()
    m.values()

fn items_outlive_map() -> Vec[(str, str)]:
    let m = names()
    m.items()

fn borrowed_keys(m: &HashMap[str, str]) -> i32:
    let ks = m.keys()
    var n = 0
    for k in ks: n += k.len() as i32
    n

fn total(xs: &Vec[str]) -> i32:
    var n = 0
    for x in xs: n += x.len() as i32
    n

fn main:
    // The snapshot is independent: it outlives the map it came from.
    let ks = keys_outlive_map()
    assert(ks.len() == 2 and total(ks) == 5 + 4)
    let vs = values_outlive_map()
    assert(vs.len() == 2 and total(vs) == 3 + 3)
    let its = items_outlive_map()
    assert(its.len() == 2)
    var item_chars = 0
    for (k, v) in its: item_chars += k.len() as i32 + v.len() as i32
    assert(item_chars == 5 + 3 + 4 + 3)

    // The map is independent too: it survives every snapshot being dropped.
    var m = names()
    if true:
        let a = m.keys()
        let b = m.values()
        let c = m.items()
        assert(a.len() == 2 and b.len() == 2 and c.len() == 2)
    assert(m.len() == 2)
    assert(m.get("alpha").unwrap() == "one")
    assert(m.get("beta").unwrap() == "two")
    assert(borrowed_keys(m) == 5 + 4)
    m.insert("gamma".to_owned(), "three".to_owned())
    assert(m.keys().len() == 3)

    // Copy elements are copied; mixed maps clone only the owning side.
    var squares: HashMap[i32, i32] = HashMap.new()
    for i in 1..4: squares.insert(i, i * i)
    var key_sum = 0
    for k in squares.keys(): key_sum += k
    var value_sum = 0
    for v in squares.values(): value_sum += v
    assert(key_sum == 6 and value_sum == 14)
    assert(squares.items().len() == 3)

    var labels: HashMap[i32, str] = HashMap.new()
    labels.insert(7, "seven".to_owned())
    labels.insert(11, "eleven".to_owned())
    assert(total(labels.values()) == 5 + 6)
    var id_sum = 0
    for (id, label) in labels.items(): id_sum += id + label.len() as i32
    assert(id_sum == 7 + 5 + 11 + 6)
    assert(labels.get(11).unwrap() == "eleven")

    var ages: HashMap[str, i32] = HashMap.new()
    ages.insert("ada".to_owned(), 36)
    assert(total(ages.keys()) == 3)
    assert(ages.get("ada").unwrap() == 36)
    print("ok")
