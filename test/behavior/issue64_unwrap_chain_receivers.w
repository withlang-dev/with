//! expect-stdout: ok

// #64: unwrap-chain receivers must lower without crashing. Owned carriers
// (Option/Result by value) yield owned payloads whose methods run on a
// materialized place. Borrowed sources (iter().next() via a bound iterator,
// map get) yield &T views under D22 — reading through them is covered here.
// A direct `.iter().next()` chain is a §15.3 error (next() mutates a
// temporary): test/compile_errors/err_iter_next_rvalue_receiver.w. Mutation
// through a map view is a pending Stage 8 rejection:
// test/non_compliant/d22/err_d22_map_view_mutation.w.

use std.collections.HashMap
type Inner {
    tags: Vec[i32],
    label: str,
}

fn make_inner(label: str) -> Inner:
    Inner { tags: Vec.new(), label }

fn option_direct_no_crash:
    let opt: Option[Inner] = Some(make_inner("option-direct"))
    opt.unwrap().tags.push(1)

fn option_binding:
    let opt: Option[Inner] = Some(make_inner("option-binding"))
    let item = opt.unwrap()
    item.tags.push(11)
    assert(item.tags.len() == 1)
    assert(item.tags[0] == 11)

fn result_direct_no_crash:
    let res: Result[Inner, str] = Ok(make_inner("result-direct"))
    res.unwrap().tags.push(2)

fn result_binding:
    let res: Result[Inner, str] = Ok(make_inner("result-binding"))
    let item = res.unwrap()
    item.tags.push(22)
    assert(item.tags.len() == 1)
    assert(item.tags[0] == 22)

fn iter_view_binding:
    var items: Vec[Inner] = Vec.new()
    items.push(make_inner("iter-binding"))
    var iter = items.iter()
    let item = iter.next().unwrap()
    assert(item.label == "iter-binding")
    assert(item.tags.len() == 0)

fn hashmap_view_read_no_crash:
    let lookup: HashMap[str, Inner] = HashMap.new()
    lookup.insert("alpha", make_inner("hashmap-direct"))
    assert(lookup.get("alpha").unwrap().label == "hashmap-direct")

fn hashmap_view_binding:
    let lookup: HashMap[str, Inner] = HashMap.new()
    lookup.insert("beta", make_inner("hashmap-binding"))
    let item = lookup.get("beta").unwrap()
    assert(item.label == "hashmap-binding")
    assert(item.tags.len() == 0)

fn main:
    option_direct_no_crash()
    option_binding()

    result_direct_no_crash()
    result_binding()

    iter_view_binding()

    hashmap_view_read_no_crash()
    hashmap_view_binding()

    print("ok")
