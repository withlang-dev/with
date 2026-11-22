//! expect-stdout: 3
//! expect-stdout: 13

// §18.1 (#1930): a stem that is not an identifier names the module with each
// character that cannot appear in an identifier replaced by `_`
// (`behav-self-name-hyphen` → `behav_self_name_hyphen`). Its own function,
// shadowed by a receiver field, is reached through it.

fn f -> i32: 3

type Box2 {
    f: i32,
}

impl Box2:
    fn sum -> i32: self.f + behav_self_name_hyphen.f()

fn main:
    print(f"{behav_self_name_hyphen.f()}")
    print(f"{Box2 { f: 10 }.sum()}")
