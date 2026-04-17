use issue67.mod

fn filler_0(x: Result[i32, str]) -> i32:
    let y = match x:
        Ok(v) => v
        Err(_) => 0
    y

fn filler_1(x: Result[i32, str]) -> i32:
    let y = match x:
        Ok(v) => v
        Err(_) => 0
    y

fn filler_2(x: Result[i32, str]) -> i32:
    let y = match x:
        Ok(v) => v
        Err(_) => 0
    y

fn main:
    assert(filler_0(Ok(7)) == 7)
    assert(filler_1(Err("bad")) == 0)
    assert(filler_2(Ok(9)) == 9)

    let xs: Vec[i32] = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(3)
    assert(sum(xs) == 6)
