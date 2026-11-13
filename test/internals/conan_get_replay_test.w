//! expect-stdout: ok
// WITH_GET_REPLAY: an HTTPS URL that has a recording is served from it and
// nobody is asked; a recorded 4xx is the server's answer again; under
// WITH_GET_OFFLINE a URL with no recording is refused, naming why.
use compiler.ConanClient
use std.fs
use std.process

fn main:
    let dir = "out/tmp/conan_get_replay_test"
    assert(mkdir_p(dir) == 0)
    assert(set_env("WITH_GET_REPLAY", dir) == 0)
    assert(set_env("WITH_GET_OFFLINE", "1") == 0)
    let served = "https://replay.invalid/v2/conans/search?q=zlib"
    let absent = "https://replay.invalid/recipes/zlib/all/CMakeLists.txt"
    let unknown = "https://replay.invalid/never-asked"
    let served_key = conan_replay_key(served)
    assert(served_key.starts_with(dir ++ "/"))
    assert(write_file(served_key ++ ".body", "{\"results\": [\"zlib/1.3.1\"]}") == 0)
    assert(write_file(served_key ++ ".meta", "200\t" ++ served ++ "\n") == 0)
    assert(write_file(conan_replay_key(absent) ++ ".meta", "404\t" ++ absent ++ "\n") == 0)
    let out = dir ++ "/out.json"
    assert(conan_https_fetch_to_file(served, out, 1000) == "")
    assert((read_file(out) ?? "") == "{\"results\": [\"zlib/1.3.1\"]}")
    assert(conan_https_fetch_to_file(absent, out, 1000) == "the server answered status 404 (recorded under WITH_GET_REPLAY)")
    assert(conan_https_fetch_to_file(unknown, out, 1000).starts_with("WITH_GET_OFFLINE is set"))
    print("ok")
