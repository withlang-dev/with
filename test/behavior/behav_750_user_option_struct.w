//! expect-stdout: own 5 std 11
// #750: a user struct named Option (not an alias) shadows std's enum
// for the user's own code only; std's parse keeps working. Before the
// fix this failed inside <embedded-std> std/string.w.
type Option {
    a: i32,
}

fn main:
    let own = Option { a: 5 }
    let parsed: i32 = "11".parse() ?? 0
    print(f"own {own.a} std {parsed}")
