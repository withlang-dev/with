//! expect-stdout: y
//! expect-stdout: x
//! expect-stdout: none
//! expect-stdout: 2
//! expect-stdout: b
//! expect-stdout: y
//! expect-stdout: 2

// #1297 / §3.4, §21.1 rule 10: projecting a field out of a view keeps the
// view's origin set. `entry` bound by `for entry in entries` or by
// `let entry = entries.get(i)` over a borrowed parameter's collection is a
// view whose origin is that parameter, so `&entry.value` may be returned —
// exactly as `entries.get(i)` itself may. The checker used to pin the field
// view to the binding (`may outlive its origin 'entry'`).

use std.collections

enum JV { Null | Str(str) | Object(Vec[KV]) }
type KV { key: str, value: JV }
type Bag { items: Vec[KV], counts: HashMap[str, KV] }

fn get_for(val: &JV, key: str) -> Option[&JV]:
    match val:
        .Object(entries) =>
            for entry in entries:
                if entry.key == key:
                    return Some(&entry.value)
            None
        _ => None

fn get_idx(val: &JV, key: str) -> Option[&JV]:
    match val:
        .Object(entries) =>
            for i in 0..entries.len():
                let entry = entries.get(i)
                if entry.key == key:
                    return Some(&entry.value)
            None
        _ => None

fn key_for(v: &Vec[KV], i: i32) -> &str:
    for e in v:
        if e.key == v.get(i).key:
            return &e.key
    panic("missing")

fn count_of(m: &HashMap[str, KV], key: str) -> &JV:
    for (k, kv) in m:
        if k == key:
            return &kv.value
    panic("missing")

extend Bag:
    fn first_value() -> &JV:
        for e in self.items:
            return &e.value
        panic("empty")
    fn value_of(key: str) -> Option[&JV]:
        for i in 0..self.items.len():
            let e = self.items.get(i)
            if e.key == key:
                return Some(&e.value)
        None

fn show(v: Option[&JV]):
    match v:
        Some(jv) => match jv:
            .Str(s) => print(s)
            .Object(kvs) => print(f"{kvs.len()}")
            .Null => print("null")
        None => print("none")

fn main:
    var kvs: Vec[KV] = Vec.new()
    kvs.push(KV { key: "a".clone(), value: .Str("x".clone()) })
    kvs.push(KV { key: "b".clone(), value: .Str("y".clone()) })
    let jv = JV.Object(kvs)
    show(get_for(jv, "b"))
    show(get_idx(jv, "a"))
    show(get_idx(jv, "c"))
    var inner: Vec[KV] = Vec.new()
    inner.push(KV { key: "p".clone(), value: .Null })
    inner.push(KV { key: "q".clone(), value: .Null })
    var items: Vec[KV] = Vec.new()
    items.push(KV { key: "obj".clone(), value: .Object(inner) })
    items.push(KV { key: "b".clone(), value: .Str("y".clone()) })
    var counts: HashMap[str, KV] = HashMap.new()
    counts.insert("two".clone(), KV { key: "two".clone(), value: .Str("2".clone()) })
    let bag = Bag { items: items, counts: counts }
    show(Some(bag.first_value()))
    print(key_for(bag.items, 1))
    show(bag.value_of("b"))
    show(Some(count_of(bag.counts, "two")))
