//! expect-stdout: ok

type NodeId = distinct i32
type TypeId = distinct i32

extern fn with_eprintln(s: str) -> void

var pass_count: i32 = 0
var fail_count: i32 = 0

fn check(name: str, ok: bool):
    if ok:
        pass_count = pass_count + 1
    else:
        with_eprintln(f"FAIL: {name}")
        fail_count = fail_count + 1

fn main:
    // 1. Construction from literal
    let n = NodeId(42)
    check("construct from literal", true)

    // 2. .value extraction
    let raw: i32 = n.value
    check(".value extraction", raw == 42)

    // 3. as i32 extraction
    let raw2: i32 = n as i32
    check("as i32", raw2 == 42)

    // 4. as i64 for Vec indexing
    let idx: i64 = n as i64
    check("as i64", idx == 42i64)

    // 5. Comparison between two distinct values
    let m = NodeId(42)
    check("== same", n == m)
    let k = NodeId(99)
    check("!= different", n != k)

    // 6. Comparison with zero
    let zero = NodeId(0)
    check("== zero", zero == NodeId(0))
    check("!= zero", n != NodeId(0))

    // 7. Greater than / less than
    check("> comparison", n > NodeId(0))
    check(">= comparison", n >= NodeId(42))
    check("< comparison", NodeId(1) < NodeId(2))

    // 8. Default/zero initialization
    let default_id = NodeId(0)
    check("zero init", default_id == NodeId(0))

    // 9. Store in Vec
    var ids: Vec[NodeId] = Vec.new()
    ids.push(NodeId(10))
    ids.push(NodeId(20))
    ids.push(NodeId(30))
    check("Vec push + len", ids.len() == 3)

    // 10. Vec.get returns NodeId
    let got = ids.get(0)
    check("Vec.get", got == NodeId(10))

    // 11. HashMap with distinct key
    var map: HashMap[NodeId, str] = HashMap.new()
    map.insert(NodeId(1), "one")
    map.insert(NodeId(2), "two")
    check("HashMap insert + contains", map.contains(NodeId(1)))
    let val = map.get(NodeId(2))
    check("HashMap get", val.is_some())

    // 12. Pass to function taking distinct type
    let result = process_node(NodeId(7))
    check("fn taking distinct", result == NodeId(14))

    // 13. Return distinct from function
    let created = make_node(55)
    check("fn returning distinct", created == NodeId(55))

    // 14. Distinct in struct field
    let item = Item { id: NodeId(100), name: "test" }
    check("struct field", item.id == NodeId(100))

    // 15. Negative values
    let neg = NodeId(-1)
    check("negative", neg == NodeId(-1))
    check("negative as i32", neg as i32 == -1)

    println(f"Passed: {pass_count}/{pass_count + fail_count}")
    if fail_count == 0:
        println("ok")
    else:
        println(f"FAILED: {fail_count}")

fn process_node(id: NodeId) -> NodeId:
    NodeId(id as i32 * 2)

fn make_node(raw: i32) -> NodeId:
    NodeId(raw)

type Item { id: NodeId, name: str }
