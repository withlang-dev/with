//! expect-stdout: own 7 std 42
// #750: a user type named Option shadows std's for the user's own code
// and must not break std's own Option (its `?`, its variant payloads,
// its patterns). Before the fix this failed inside <embedded-std>
// std/string.w with "? operator requires an Option, Result, or a type
// implementing Try": the generic-inst template decl was fetched by bare
// name and found this alias instead of std's enum.
type Option = i32

fn main:
    let own: Option = 7
    let parsed: i32 = "42".parse() ?? 0
    print(f"own {own} std {parsed}")
