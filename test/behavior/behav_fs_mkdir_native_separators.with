//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.sysinfo

fn main:
    let root = p7_prepare_case("mkdir_native_separators", "mkdir_native_separators")
    for relative in ["forward/one/two", "back\\one\\two", "mixed\\one/two\\three", "repeated//one\\two"]:
        let path = p7_join(root, relative)
        assert(mkdir_p(path) == 0)
        assert(mkdir_p(path) == 0)
        let file = path ++ "/value.txt"
        assert(write_file(file, "created") == 0)
        assert(read_file(file).unwrap() == "created")
        if os() == "Windows":
            assert(read_file(file.replace("\\", "/")).unwrap() == "created")
        else if relative.contains("\\"):
            assert(not file_exists(file.replace("\\", "/")))
    let obstruction = p7_join(root, "file")
    assert(write_file(obstruction, "not a directory") == 0)
    assert(mkdir_p(obstruction ++ "/child") != 0)
    print("ok")
