//! expect-stdout: ok
// §29.4: triple-quoted multiline strings strip the optional leading newline,
// dedent by the common indent (the closing delimiter's column), and keep the
// trailing newline before the closing delimiter. Relative indentation is kept.

fn main:
    let s = """
        line one
          indented two
        line three
        """
    let want = "line one\n  indented two\nline three\n"
    if s == want:
        print("ok")
    else:
        print(f"MISMATCH len={s.len()} [{s}]")
