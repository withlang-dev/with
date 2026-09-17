//! expect-stdout: ok

use compiler.ConanClient
use compiler.Runtime
use std.fs
use std.process

fn set_temp(path: &str):
    assert(set_env("TMPDIR", path) == 0)
    assert(set_env("TMP", path) == 0)
    assert(set_env("TEMP", path) == 0)

fn main:
    var base = env("TMPDIR")
    if base.len() == 0: base = env("TMP")
    if base.len() == 0: base = env("TEMP")
    if base.len() == 0: base = "/tmp"
    let root = base.replace("\\", "/") ++ f"/with conan transport {pid()}"
    assert(mkdir_p(root) == 0)
    let payload = "{\"results\":[\"bzip2/1.0.8@_/_\"]}\n"
    assert(write_file(root ++ "/payload.json", payload) == 0)
    set_temp(root)
    let prefix = if root.starts_with("/"): "file://" else: "file:///"
    let url = prefix ++ root.replace(" ", "%20")
    assert(conan_http_get(url ++ "/payload.json") == payload)
    assert(not list_files_text(root).contains("with-conan-http-"))
    assert(conan_http_get(url ++ "/absent.json") == "")
    assert(not list_files_text(root).contains("with-conan-http-"))
    // A configured directory that is actually a file must fail loudly,
    // never silently fall back to another directory or report not-found.
    set_temp(root ++ "/payload.json")
    assert(conan_http_get(url ++ "/payload.json") == "")
    if runtime_sysinfo_os() == "Windows":
        set_temp("")
        assert(conan_http_get(url ++ "/payload.json") == "")
    assert(remove_tree(root) == 0)
    print("ok")
