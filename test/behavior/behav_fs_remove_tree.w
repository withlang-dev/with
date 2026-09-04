//! skip-on: windows #800: symlink() needs Developer Mode or elevation on Windows (CreateSymbolicLinkW fails ERROR_PRIVILEGE_NOT_HELD); rt_symlink already passes ALLOW_UNPRIVILEGED_CREATE, so this is an environment privilege gap, not a code bug
use std.fs

fn contains_line(text: &str, line: &str) -> bool:
    if text == line:
        return true
    text.contains(line ++ "\n") or text.contains("\n" ++ line)

fn main:
    let root = "out/tmp/behav_fs_remove_tree"
    let copied = "out/tmp/behav_fs_remove_tree_copy"
    let link = root ++ "/link.txt"
    let nested = root ++ "/a/b"
    let file1 = root ++ "/root.txt"
    let file2 = nested ++ "/leaf.txt"

    let _clean_start = remove_tree(root)
    let _clean_copy = remove_tree(copied)
    assert(mkdir_p(nested) == 0)
    assert(write_file(file1, "root") == 0)
    assert(write_file(file2, "leaf") == 0)
    assert(file_exists(file1))
    assert(file_exists(file2))

    assert(copy_tree(root, copied) == 0)
    assert(read_file(copied ++ "/root.txt").unwrap() == "root")
    assert(read_file(copied ++ "/a/b/leaf.txt").unwrap() == "leaf")
    let listed = list_files_text(copied)
    assert(contains_line(listed, copied ++ "/root.txt"))
    assert(contains_line(listed, copied ++ "/a/b/leaf.txt"))

    assert(symlink("root.txt", link) == 0)
    assert(read_file(link).unwrap() == "root")

    assert(remove_tree(root) == 0)
    assert(not file_exists(file1))
    assert(not file_exists(file2))
    assert(not file_exists(root))
    assert(remove_tree(copied) == 0)
    print("ok")
