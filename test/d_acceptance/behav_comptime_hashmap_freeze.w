//! expect-stdout: ok

comptime fn build_table() -> HashMap[str, i32]:
    var table = HashMap[str, i32].new()
    table.insert("alpha", 1)
    table.insert("beta", 2)
    table.insert("alpha", 3)
    table

comptime fn count_table() -> i64:
    var table = HashMap[str, i32].new()
    table.insert("left", 10)
    table.insert("right", 20)
    table.len()

const TABLE: HashMap[str, i32] = comptime build_table()
const TABLE_COUNT: i64 = comptime count_table()

fn main:
    assert(TABLE_COUNT == 2)
    assert(TABLE.get("alpha").unwrap() == 3)
    assert(TABLE.get("beta").unwrap() == 2)
    assert(TABLE.get("missing").is_none())
    print("ok")
