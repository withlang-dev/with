//! expect-stdout: 2
fn main:
    let m: HashMap[str, i64] = HashMap.new()
    m.increment("count")
    m.increment("count")
    let val = m.get("count")
    if val.is_some():
        print(int_to_string(val.unwrap() as i32))
