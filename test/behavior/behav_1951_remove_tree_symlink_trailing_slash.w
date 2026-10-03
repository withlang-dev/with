//! skip-on: windows #800: symlink() needs Developer Mode or elevation on Windows; the Windows case is behav_fs_remove_tree_windows_junctions.w
//! expect-stdout: ok

// remove_tree on a symlink removes the link and never enters its target,
// however the path ends (#1951). The POSIX walk classifies the top path with
// lstat, and lstat("link/") resolves the link: with a trailing separator the
// walk saw a directory, emptied the target and then failed to rmdir the
// link, so the target's files were gone. Windows strips the separator before
// its reparse-point query (#1863); the POSIX entry now strips it too.
use std.fs

fn main:
    let base = "out/tmp/behav_1951"
    let _clean = remove_tree(base)
    let keep = base ++ "/keep"
    assert(mkdir_p(keep) == 0)
    assert(write_file(keep ++ "/keep.txt", "must survive") == 0)

    // A symlink to a directory, removed with and without a trailing slash.
    let link = base ++ "/link"
    assert(symlink("keep", link) == 0)
    assert(read_file(link ++ "/keep.txt").unwrap() == "must survive")
    assert(remove_tree(link ++ "/") == 0)
    assert(not file_exists(link))
    assert(read_file(keep ++ "/keep.txt").unwrap() == "must survive")

    assert(symlink("keep", link) == 0)
    assert(remove_tree(link ++ "//") == 0)
    assert(not file_exists(link))
    assert(read_file(keep ++ "/keep.txt").unwrap() == "must survive")

    assert(symlink("keep", link) == 0)
    assert(remove_tree(link) == 0)
    assert(not file_exists(link))
    assert(read_file(keep ++ "/keep.txt").unwrap() == "must survive")

    // A symlink inside a tree, the tree removed with a trailing slash: the
    // link goes with the tree, the target stays.
    let tree = base ++ "/tree"
    assert(mkdir_p(tree ++ "/sub") == 0)
    assert(write_file(tree ++ "/sub/plain.txt", "plain") == 0)
    assert(symlink("../keep", tree ++ "/link") == 0)
    assert(remove_tree(tree ++ "/") == 0)
    assert(not file_exists(tree))
    assert(read_file(keep ++ "/keep.txt").unwrap() == "must survive")

    // A trailing slash on a plain directory still removes the directory.
    assert(remove_tree(keep ++ "/") == 0)
    assert(not file_exists(keep))
    assert(remove_tree(base) == 0)
    assert(not file_exists(base))
    print("ok")
