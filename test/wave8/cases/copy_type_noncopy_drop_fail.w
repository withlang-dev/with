type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    let r1 = Res { v: 5 }
    let _r2 = r1
    if r1.v == 5 then 0 else 1
