type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    let r1 = Res { v: 1 }
    let _r2 = r1
    let x = r1.v
    if x == 1 then 0 else 1
