//! only-on: windows
//! expect-stdout: ok

// Windows names files in UTF-16; a With path is UTF-8 (spec §15.1). The
// runtime's converters widened each UTF-8 byte into one UTF-16 unit on the
// way in and wrote `?` for every non-ASCII unit on the way out, so
// write_file("café.txt") created "cafÃ©.txt", a real "café.txt" could not be
// opened, and list_files_text silently dropped every entry whose name was
// not ASCII (the walk re-opened it as "caf?.txt"). The names below hold é
// (2 UTF-8 bytes), an en dash (3) and U+1F600 (4; a surrogate pair in
// UTF-16), inside a directory whose own name is not ASCII either.
use std.fs

fn main:
    let root = "out/tmp/behav_fs_windows_unicode_names"
    let _clean = remove_tree(root)
    let dir = root ++ "/dir é–😀"
    let name = "café – 😀.txt"
    assert(name == "caf\xc3\xa9 \xe2\x80\x93 \xf0\x9f\x98\x80.txt")
    assert(mkdir_p(dir) == 0)
    let path = dir ++ "/" ++ name
    assert(write_file(path, "unicode") == 0)
    assert(file_exists(path))
    assert(read_file(path).unwrap() == "unicode")
    // The listing names the file by its exact UTF-8 bytes.
    assert(list_files_text(root) == path ++ "\n")
    // Rename, copy and remove carry the names back into Windows.
    let renamed = dir ++ "/naïve–😀.txt"
    assert(rename_file(path, renamed) == 0)
    assert(not file_exists(path))
    let copied = root ++ "/copy ü"
    assert(copy_tree(dir, copied) == 0)
    assert(read_file(copied ++ "/naïve–😀.txt").unwrap() == "unicode")
    assert(list_files_text(copied) == copied ++ "/naïve–😀.txt\n")
    // Bytes that are not UTF-8 name no file: the call fails and creates
    // nothing, rather than guessing which name was meant.
    assert(write_file(dir ++ "/bad-\xff.txt", "x") != 0)
    assert(list_files_text(dir) == renamed ++ "\n")
    assert(remove_tree(root) == 0)
    assert(not file_exists(root))
    print("ok")
