use std.fs

fn main:
    let root = "out/tmp/behav_fs_remove_tree"
    let nested = root ++ "/a/b"
    let file1 = root ++ "/root.txt"
    let file2 = nested ++ "/leaf.txt"

    let _clean_start = remove_tree(root)
    assert(mkdir_p(nested) == 0)
    assert(write_file(file1, "root") == 0)
    assert(write_file(file2, "leaf") == 0)
    assert(file_exists(file1))
    assert(file_exists(file2))

    assert(remove_tree(root) == 0)
    assert(not file_exists(file1))
    assert(not file_exists(file2))
    assert(not file_exists(root))
    print("ok")
