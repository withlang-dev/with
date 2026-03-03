@[derive(Copy)]
type Res = { v: i32 }

fn Res.drop(self: Res) -> void:
    let _cleanup = self.v

fn main -> i32:
    0
