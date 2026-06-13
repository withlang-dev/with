//! expect-check-fail: wrong argument type

type UserId = distinct i32
type Account { salt: i32 }

fn Account.take(self: &Self, id: UserId) -> i32:
    self.salt + id.value

fn main:
    let account = Account { salt: 1 }
    let raw: i32 = 41
    let value = account.take(raw)
    print(int_to_string(value))
