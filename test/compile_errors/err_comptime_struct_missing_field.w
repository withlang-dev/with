//! expect-check-fail: missing comptime struct field

type Config {
    name: str,
    value: i32,
    enabled: bool,
}

comptime fn incomplete_struct() -> Config:
    Config { name: "test", value: 42 }

fn main:
    let bad: Config = comptime incomplete_struct()
    print(bad.name)
