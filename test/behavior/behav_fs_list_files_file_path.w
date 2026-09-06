//! expect-stdout: ok
// #1081: list_files_text on a path that is a FILE, not a directory, takes
// the walk's append branch with the caller-owned C path buffer. The str the
// runtime built over that buffer (with_str_from_cstr) used to be a view of
// it, so the view's scope-exit drop freed the buffer and with_fs_list_files
// then freed it again: "invalid free: pointer is not an allocated payload
// start". Native Windows hit it in the compiler's own temp-archive cleanup
// (out/lib is absent during the .wo bundle build); latent on unix for any
// file path. An owned str owns its bytes -- the runtime now copies.
use std.fs

fn main:
    let dir = "out/tmp/behav_fs_list_files_file_path"
    let file = dir ++ "/leaf.txt"
    let _clean = remove_tree(dir)
    assert(mkdir_p(dir) == 0)
    assert(write_file(file, "leaf") == 0)
    let listed = list_files_text(file)
    assert(listed == file ++ "\n")
    print("ok")
