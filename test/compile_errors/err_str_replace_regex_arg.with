//! expect-error: regex replacement is a Regex method: `/a/.replace(text, replacement)`

// #2434: passing a Regex to `str.replace` (or a non-str argument to any `&str`
// parameter of a str intrinsic or `List.join`) must be rejected by Sema with a
// hint to `Regex.replace` rather than reaching codegen and aborting in
// `Codegen.str_view_arg`.
fn main:
    let line = "ab"
    print(line.replace(/a/, "x"))
