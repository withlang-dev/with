//! expect-stdout: ok

type Holder { values: List[i32] }

fn Holder.add(mut self: Holder, value: i32):
    self.values.push(value)

fn main:
    let holder = Holder { values: List.new() }
    holder.add(7)
    if holder.values.len() == 1 and holder.values[0] == 7:
        print("ok")
    else:
        print("bad")
