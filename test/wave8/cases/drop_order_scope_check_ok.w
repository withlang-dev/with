type A = { id: i32 }
type B = { id: i32 }

fn A.drop(self: A) -> void:
    let _id = self.id

fn B.drop(self: B) -> void:
    let _id = self.id

fn scope_drop_order -> i32:
    let a = A { id: 1 }
    let b = B { id: 2 }
    a.id + b.id

fn main -> i32:
    scope_drop_order()
