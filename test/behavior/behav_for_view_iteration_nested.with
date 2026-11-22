//! expect-stdout: ok

fn main:
    var rows: List[List[i32]] = List.new()
    var r1: List[i32] = List.new()
    r1.push(1)
    r1.push(2)
    rows.push(move r1)
    var r2: List[i32] = List.new()
    r2.push(3)
    rows.push(move r2)
    var total = 0
    for row in rows:
        for v in row:
            total = total + v
    assert(total == 6)
    assert(rows.len() == 2)
    print("ok")
