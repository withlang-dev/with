type A = { id: i32 }
type B = { id: i32 }

fn A.drop(self: A) -> void:
    let _id = self.id

fn B.drop(self: B) -> void:
    let _id = self.id

fn early_scope -> i32:
    let a = A { id: 1 }
    let b = B { id: 2 }
    if a.id + b.id == 3 then
        return 0
    else
        1

fn main -> i32:
    early_scope()
