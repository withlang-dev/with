//! expect-stdout: own 3 f64 1.5
// #750/#2758: a user type named Result shadows std's for the user's own
// code and must not break std's generic machinery. Before the fix this
// ICE'd: BUG: user generic call lacks a concrete contract:
// body=...(f64.parse_text).
type Result = i32

fn main:
    let own: Result = 3
    let f: f64 = "1.5".parse() ?? 0.0
    print(f"own {own} f64 {f}")
