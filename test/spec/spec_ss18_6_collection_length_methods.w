// Spec test: Section 18.6 — Collection Length Methods (formerly 25.47)
//
// Collections expose four length accessors that differ only in return type:
//   .len()    -> usize   (natural width)
//   .len32()  -> i32     (panics if the length exceeds i32 range)
//   .len64()  -> i64
//   .ulen32() -> u32     (panics if the length exceeds u32 range)

fn make_vec -> Vec[i32]:
    var items: Vec[i32] = Vec.new()
    items.push(10)
    items.push(20)
    items.push(30)
    items.push(40)
    items.push(50)
    items

// PASS: .len() returns usize
fn test_vec_len_usize:
    let items = make_vec()
    let count: usize = items.len()
    assert(count == 5)

// PASS: .len32() returns i32
fn test_vec_len32_i32:
    let items = make_vec()
    let count: i32 = items.len32()
    assert(count == 5)

// PASS: .len64() returns i64
fn test_vec_len64_i64:
    let items = make_vec()
    let count: i64 = items.len64()
    assert(count == 5)

// PASS: .ulen32() returns u32
fn test_vec_ulen32_u32:
    let items = make_vec()
    let count: u32 = items.ulen32()
    assert(count == 5)

// PASS: str carries the same length family
fn test_str_len_family:
    let s = "hello"
    let n: usize = s.len()
    let n32: i32 = s.len32()
    let n64: i64 = s.len64()
    let un32: u32 = s.ulen32()
    assert(n == 5)
    assert(n32 == 5)
    assert(n64 == 5)
    assert(un32 == 5)

// PASS: HashMap exposes the length family too
fn test_map_len_family:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("a", 1)
    m.insert("b", 2)
    m.insert("c", 3)
    let n: usize = m.len()
    let n32: i32 = m.len32()
    let n64: i64 = m.len64()
    assert(n == 3)
    assert(n32 == 3)
    assert(n64 == 3)

// PASS: the narrowing accessors compose in expressions
fn test_len32_in_expression:
    let items = make_vec()
    let doubled: i32 = items.len32() * 2
    assert(doubled == 10)
