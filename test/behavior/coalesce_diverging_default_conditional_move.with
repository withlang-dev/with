//! expect-stdout: 3
//! expect-stdout: a
//! expect-stdout: drop a

// §18.2 / D86 (#1864): a move inside the right operand of `??` is a
// conditional move. When that operand does not return, the value is still
// owned after the `??` on the path that continues: usable, and dropped
// exactly once.

type Res:
    name: str
impl Drop for Res:
    move fn drop():
        print("drop " ++ self.name)

fn consume(r: Res) -> i32:
    print("consumed")
    1

fn main:
    let r = Res { name: "a" }
    let o: Option[i32] = Some(3)
    let v = o ?? panic(f"{consume(r)}")
    print(v)
    print(r.name)
