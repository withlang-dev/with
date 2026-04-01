//! expect-stdout: ok

type Inner {
    tags: Vec[i32],
    label: str,
}

type InnerList = Vec[Inner]

fn filled_inner(label: str, value: i32) -> Inner:
    let item = Inner { tags: Vec.new(), label }
    item.tags.push(value)
    item

fn make_items() -> InnerList:
    let items: InnerList = Vec.new()
    items.push(filled_inner("shared", 9))
    items

fn read_vec(items: &Vec[Inner]) -> i64:
    items.get(0).tags.len()

fn read_alias(items: &InnerList) -> i64:
    items.get(0).tags.len()

fn read_map(lookup: &HashMap[str, Inner]) -> i64:
    lookup.get("alpha").unwrap().tags.len()

fn main:
    let items = make_items()
    assert(read_vec(&items) == 1)
    assert(read_alias(&items) == 1)
    assert(items.get(0).tags.get(0) == 9)

    let lookup: HashMap[str, Inner] = HashMap.new()
    lookup.insert("alpha", filled_inner("map", 7))
    assert(read_map(&lookup) == 1)
    assert(lookup.get("alpha").unwrap().tags.get(0) == 7)

    print("ok")
