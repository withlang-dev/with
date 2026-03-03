type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    var a = Res { v: 2 }
    var b = Res { v: 3 }
    b = a
    let y = a.v
    if y == 2 then 0 else 1
