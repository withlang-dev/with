//! expect-stdout: ok

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
    assert(item.tags.get(0) == 11)

fn result_direct_no_crash:
    let res: Result[Inner, str] = Ok(make_inner("result-direct"))
    res.unwrap().tags.push(2)

fn result_binding:
    let res: Result[Inner, str] = Ok(make_inner("result-binding"))
    let item = res.unwrap()
    item.tags.push(22)
    assert(item.tags.len() == 1)
    assert(item.tags.get(0) == 22)

fn iter_direct_no_crash:
    let items: Vec[Inner] = Vec.new()
    items.push(make_inner("iter-direct"))
    items.iter().next().unwrap().tags.push(3)

fn iter_binding:
    let items: Vec[Inner] = Vec.new()
    items.push(make_inner("iter-binding"))
    let iter = items.iter()
    let item = iter.next().unwrap()
    item.tags.push(33)
    assert(item.tags.len() == 1)
    assert(item.tags.get(0) == 33)

fn hashmap_direct_no_crash:
    let lookup: HashMap[str, Inner] = HashMap.new()
    lookup.insert("alpha", make_inner("hashmap-direct"))
    lookup.get("alpha").unwrap().tags.push(4)

fn hashmap_binding:
    let lookup: HashMap[str, Inner] = HashMap.new()
    lookup.insert("beta", make_inner("hashmap-binding"))
    let item = lookup.get("beta").unwrap()
    item.tags.push(44)
    assert(item.tags.len() == 1)
    assert(item.tags.get(0) == 44)

fn main:
    option_direct_no_crash()
    option_binding()

    result_direct_no_crash()
    result_binding()

    iter_direct_no_crash()
    iter_binding()

    hashmap_direct_no_crash()
    hashmap_binding()

    print("ok")
