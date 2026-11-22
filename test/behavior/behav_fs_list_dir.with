//! expect-stdout: ok

// list_dir_text names a directory's entries, one per line, without a path
// and without descending; a file or a missing path lists nothing. The build
// driver prunes its machine-wide store by its top-level entries alone: the
// recursive listing walked every published output (20,000 files, 8–17 s)
// after each published target (2026-10-14).
use std.fs
use std.process

fn contains_line(text: &str, line: &str) -> bool:
    if text == line:
        return true
    text.contains(line ++ "\n") or text.contains("\n" ++ line)

fn main:
    let tmp = env("TMPDIR")
    let base = (if tmp.len() > 0: tmp else: "/tmp") ++ f"/with-list-dir-{pid()}"
    let _ = remove_tree(base)
    assert(mkdir_p(base ++ "/sub/deep") == 0)
    assert(write_file(base ++ "/a.txt", "a") == 0)
    assert(write_file(base ++ "/sub/b.txt", "b") == 0)
    assert(write_file(base ++ "/sub/deep/c.txt", "c") == 0)

    let names = list_dir_text(base)
    assert(contains_line(names, "a.txt"))
    assert(contains_line(names, "sub"))
    assert(not names.contains("b.txt"))
    assert(not names.contains("deep"))
    assert(not names.contains("/"))
    var count = 0
    for line in names.split("\n"):
        if line.len() > 0: count += 1
    assert(count == 2)

    assert(list_dir_text(base ++ "/a.txt") == "")
    assert(list_dir_text(base ++ "/absent") == "")

    // The recursive listing still reaches every file.
    let files = list_files_text(base)
    assert(contains_line(files, base ++ "/sub/deep/c.txt"))
    assert(contains_line(files, base ++ "/a.txt"))
    assert(remove_tree(base) == 0)
    print("ok")
