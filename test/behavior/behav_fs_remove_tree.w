use std.fs

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
    assert(read_file(copied ++ "/root.txt") == "root")
    assert(read_file(copied ++ "/a/b/leaf.txt") == "leaf")

    assert(symlink("root.txt", link) == 0)
    assert(read_file(link) == "root")

    assert(remove_tree(root) == 0)
    assert(not file_exists(file1))
    assert(not file_exists(file2))
    assert(not file_exists(root))
    assert(remove_tree(copied) == 0)
    print("ok")
