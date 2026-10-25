//! expect-check-fail: err_2270_fstring_hole_escaped_quote_span.w:9:39
// #2270: a hole holding escaped quotes is reparsed with one escape layer
// stripped; its nodes kept offsets into the stripped text, so each `\"`
// before a node put the node one byte early. The undefined name is at
// column 39.
fn count_all(xs: List[str]) -> isize: xs.len()

fn main:
    print(f"{count_all([\"a\", \"b\", undefined_name_2270])}")
