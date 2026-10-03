//! only-on: windows
//! expect-stdout: ok

// list_files_text and copy_tree classify an entry as remove_tree does
// (#1952, after #1863): a directory junction or symlink is the link, not
// its target. list_files_text lists the link as a leaf, as the lstat walk
// lists a symlink on POSIX. copy_tree copies a file link as the file it
// names, as open() follows one on POSIX, and refuses a directory link with
// -21 (EISDIR), as the POSIX copy fails on a directory symlink: a tree is
// never duplicated from outside itself. Both walkers asked
// GetFileAttributesW, which calls a junction a directory, and descended
// into its target.
//
// mklink /J makes a junction without privilege (#800); the paths must hold
// no cmd metacharacter (see behav_fs_remove_tree_windows_junctions.w).
use std.fs
use std.process

fn cmd_safe(path: &str) -> bool:
    let specials = " \t&|<>^()%!,;=\""
    for i in 0..path.len():
        for j in 0..specials.len():
            if path[i] == specials[j]:
                return false
    true

fn junction(link: &str, target: &str):
    var argv: Vec[str] = Vec.new()
    argv.push("cmd")
    argv.push("/c mklink /J " ++ link ++ " " ++ target ++ " >nul")
    assert(run(&argv) == 0)

fn contains_line(text: &str, line: &str) -> bool:
    if text == line:
        return true
    text.contains(line ++ "\n") or text.contains("\n" ++ line)

fn main:
    let temp = env("TEMP")
    let id = pid()
    let base = temp ++ f"\\with-behav-1952-{id}"
    if temp.len() == 0 or not cmd_safe(base):
        eprint("this test needs TEMP set to a path cmd.exe takes unquoted: " ++ base)
        exit_code(2)
    let _clean = remove_tree(base)
    let keep = base ++ "\\keep"
    assert(mkdir_p(keep) == 0)
    assert(write_file(keep ++ "\\keep.txt", "must survive") == 0)
    let tree = base ++ "\\tree"
    assert(mkdir_p(tree ++ "\\sub") == 0)
    assert(write_file(tree ++ "\\sub\\plain.txt", "plain") == 0)
    junction(tree ++ "\\link", keep)
    assert(read_file(tree ++ "\\link\\keep.txt").unwrap() == "must survive")

    // The listing holds the junction itself and nothing behind it.
    let listed = list_files_text(tree)
    assert(contains_line(listed, tree ++ "/sub/plain.txt"))
    assert(contains_line(listed, tree ++ "/link"))
    assert(not listed.contains("keep.txt"))
    // A listing of the junction itself is the junction, however the path ends.
    assert(list_files_text(tree ++ "\\link") == tree ++ "\\link\n")
    assert(list_files_text(tree ++ "\\link\\") == tree ++ "\\link\\\n")

    // A copy of the tree refuses the junction and never enters its target.
    let copied = base ++ "\\copy"
    assert(copy_tree(tree, copied) == -21)
    assert(not file_exists(copied ++ "\\link\\keep.txt"))
    assert(not file_exists(copied ++ "\\link"))
    assert(read_file(keep ++ "\\keep.txt").unwrap() == "must survive")
    // A copy of the junction itself is refused the same way.
    assert(copy_tree(tree ++ "\\link", base ++ "\\copy2") == -21)
    assert(not file_exists(base ++ "\\copy2"))
    assert(read_file(keep ++ "\\keep.txt").unwrap() == "must survive")
    // A tree without a link still copies whole.
    let plain = base ++ "\\plain"
    assert(mkdir_p(plain ++ "\\a\\b") == 0)
    assert(write_file(plain ++ "\\a\\b\\leaf.txt", "leaf") == 0)
    assert(copy_tree(plain, base ++ "\\plain-copy") == 0)
    assert(read_file(base ++ "\\plain-copy\\a\\b\\leaf.txt").unwrap() == "leaf")

    assert(remove_tree(base) == 0)
    assert(not file_exists(base))
    assert(read_file(keep ++ "\\keep.txt").is_err())
    print("ok")
