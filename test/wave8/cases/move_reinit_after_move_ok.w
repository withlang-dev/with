type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    var a = Res { v: 3 }
    var b = Res { v: 4 }
    b = a
    if b.v == 3 then 0 else 1
