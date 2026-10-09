//! only-on: windows
//! expect-stdout: ok

// remove_tree removes a tree, and a directory junction inside it is an entry
// of that tree: the directory it points to is not (#1798). The Windows walk
// asked GetFileAttributesW, which calls a junction a directory, so it listed
// the junction's target, deleted everything in it and only then removed the
// junction: removing a folder that held a junction emptied a folder outside
// it, and still returned 0. The POSIX walks lstat, and unlink a symlink
// without entering it.
//
// mklink /J makes a junction without privilege (a symlink needs Developer
// Mode or elevation, #800). std.process quotes every argument, and cmd.exe
// runs a quoted command name as a program, so the command is one argument
// that starts with /c, which cmd takes as written: the paths in it cannot be
// quoted, so they must hold no space or cmd metacharacter. The tree is under
// TEMP, not out/tmp, because a junction needs NTFS and a checkout may be on
// another file system.
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
    var argv: List[str] = List.new()
    argv.push("cmd")
    argv.push("/c mklink /J " ++ link ++ " " ++ target ++ " >nul")
    assert(run(&argv) == 0)

fn main:
    let temp = env("TEMP")
    let id = pid()
    let base = temp ++ f"\\with-behav-remove-tree-junctions-{id}"
    if temp.len() == 0 or not cmd_safe(base):
        eprint("this test needs TEMP set to a path cmd.exe takes unquoted: " ++ base)
        exit_code(2)
    let _clean = remove_tree(base)
    let keep = base ++ "\\keep"
    assert(mkdir_p(keep) == 0)
    assert(write_file(keep ++ "\\keep.txt", "must survive") == 0)

    // A junction inside the tree: the tree goes, the target's files stay.
    let tree = base ++ "\\tree"
    assert(mkdir_p(tree ++ "\\sub") == 0)
    assert(write_file(tree ++ "\\sub\\plain.txt", "plain") == 0)
    junction(tree ++ "\\link", keep)
    assert(read_file(tree ++ "\\link\\keep.txt").unwrap() == "must survive")
    assert(remove_tree(tree) == 0)
    assert(not file_exists(tree))
    assert(read_file(keep ++ "\\keep.txt").unwrap() == "must survive")

    // remove_tree on a junction itself removes only the junction, however
    // the path ends.
    let link = base ++ "\\link"
    junction(link, keep)
    assert(remove_tree(link) == 0)
    assert(not file_exists(link))
    assert(read_file(keep ++ "\\keep.txt").unwrap() == "must survive")
    junction(link, keep)
    assert(remove_tree(link ++ "\\") == 0)
    assert(not file_exists(link))
    assert(read_file(keep ++ "\\keep.txt").unwrap() == "must survive")

    // Nested: a junction two levels down points at a directory that holds a
    // junction of its own. The walk enters neither target.
    let inner = base ++ "\\inner"
    assert(mkdir_p(inner) == 0)
    assert(write_file(inner ++ "\\inner.txt", "inner") == 0)
    let outer = base ++ "\\outer"
    assert(mkdir_p(outer) == 0)
    assert(write_file(outer ++ "\\outer.txt", "outer") == 0)
    junction(outer ++ "\\to-inner", inner)
    let nested = base ++ "\\nested"
    assert(mkdir_p(nested ++ "\\a\\b") == 0)
    assert(write_file(nested ++ "\\a\\b\\leaf.txt", "leaf") == 0)
    junction(nested ++ "\\a\\b\\to-outer", outer)
    assert(read_file(nested ++ "\\a\\b\\to-outer\\to-inner\\inner.txt").unwrap() == "inner")
    assert(remove_tree(nested) == 0)
    assert(not file_exists(nested))
    assert(read_file(outer ++ "\\outer.txt").unwrap() == "outer")
    assert(read_file(outer ++ "\\to-inner\\inner.txt").unwrap() == "inner")
    assert(remove_tree(outer) == 0)
    assert(not file_exists(outer))
    assert(read_file(inner ++ "\\inner.txt").unwrap() == "inner")

    assert(remove_tree(base) == 0)
    assert(not file_exists(base))
    print("ok")
