//! expect-stdout: ok

// D44 / §13.5 (#1187): `for (k, v) in map` observes. The map is intact after
// the loop, a Drop-class key or value binds as a view into the map's slot, a
// Copy-class one binds by value, and a borrowed map iterates like an owned
// one. It once moved the map into a temporary (m.len() was 0 afterwards and
// m.get crashed) and walked a byte-copied items() Vec that shared the map's
// string buffers. Run under WITH_DEBUG_ALLOC=1 WITH_DEBUG_ALLOC_SCRIBBLE=1:
// a plain run passed while the map was being corrupted.

use std.collections.HashMap

fn names() -> HashMap[str, str]:
    var m: HashMap[str, str] = HashMap.new()
    m.insert("alpha".to_owned(), "one".to_owned())
    m.insert("beta".to_owned(), "two".to_owned())
    m.insert("gamma".to_owned(), "three".to_owned())
    m

fn total_len(m: &HashMap[str, str]) -> i32:
    var n = 0
    for (k, v) in m:
        n += k.len() as i32 + v.len() as i32
    n

fn count_long_values(m: &HashMap[str, str]) -> i32:
    var n = 0
    for (k, v) in m:
        if v.len() < 4: continue
        n += 1
    n

fn first_key_len(m: &HashMap[str, str]) -> i32:
    for (k, v) in m:
        return k.len() as i32
    -1

fn main:
    // Drop-class key and value, owned map.
    var m = names()
    var seen = 0
    var chars = 0
    for (k, v) in m:
        seen += 1
        chars += k.len() as i32 + v.len() as i32
    assert(seen == 3)
    assert(chars == 5 + 3 + 4 + 3 + 5 + 5)
    assert(m.len() == 3)
    assert(m.get("alpha").unwrap() == "one")
    assert(m.get("gamma").unwrap() == "three")

    // A second pass over the same map sees the same entries.
    var again = 0
    for (k, v) in m: again += 1
    assert(again == 3)

    // Borrowed map: a parameter and an explicit `&m`.
    assert(total_len(m) == chars)
    assert(count_long_values(m) == 1)
    assert(first_key_len(m) > 0)
    var borrowed = 0
    for (k, v) in &m: borrowed += v.len() as i32
    assert(borrowed == 3 + 3 + 5)
    assert(m.len() == 3)

    // Copy-class key and value bind by value.
    var squares: HashMap[i32, i32] = HashMap.new()
    for i in 1..5: squares.insert(i, i * i)
    var sum = 0
    for (k, v) in squares:
        assert(v == k * k)
        sum += v
    assert(sum == 1 + 4 + 9 + 16)
    assert(squares.len() == 4)
    assert(squares.get(3).unwrap() == 9)

    // Mixed: Copy key, Drop-class value, and the reverse.
    var labels: HashMap[i32, str] = HashMap.new()
    labels.insert(7, "seven".to_owned())
    labels.insert(11, "eleven".to_owned())
    var label_chars = 0
    for (id, label) in labels: label_chars += label.len() as i32 + id
    assert(label_chars == 5 + 7 + 6 + 11)
    assert(labels.get(7).unwrap() == "seven")

    var ages: HashMap[str, i32] = HashMap.new()
    ages.insert("ada".to_owned(), 36)
    ages.insert("alan".to_owned(), 41)
    var age_sum = 0
    for (name, age) in ages:
        assert(name.len() >= 3)
        age_sum += age
    assert(age_sum == 77)
    assert(ages.get("ada").unwrap() == 36)

    // break leaves the map intact; an empty map runs the body zero times.
    var stopped = 0
    for (k, v) in m:
        stopped += 1
        break
    assert(stopped == 1)
    assert(m.len() == 3)
    let empty: HashMap[str, str] = HashMap.new()
    for (k, v) in empty: assert(false)

    // The map is still mutable and correct after being traversed. (`remove`
    // belongs here too once #1189 lands: today it leaks the stored key, and
    // this test asserts zero leaks.)
    m.insert("delta".to_owned(), "four".to_owned())
    assert(m.len() == 4)
    assert(m.get("delta").unwrap() == "four")
    print("ok")
