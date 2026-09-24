//! expect-debug-alloc: leak count=0
// D66 under the debug allocator, against the real library: an easy handle
// is cleaned up once — by its Drop at scope end, on an early return, and
// when a Vec of handles drops — and the call-scoped C string a `str` case
// makes (`CURLOPT_URL`) is freed when the presented call returns. A handle
// cleaned up twice is a DOUBLE FREE; one never cleaned up is a LEAK.
use facades.libcurl
use c_import("curl/curl.h", link: "curl")

fn early(fail: bool) -> i32:
    let easy = Easy.new().unwrap()
    let _ = easy.setopt(CURLOPT_URL, "http://example.invalid/" ++ "early")
    if fail:
        return 1
    let _ = easy.setopt(CURLOPT_NOSIGNAL, 1)
    0

fn main:
    let _ = curl_global_init(CURL_GLOBAL_DEFAULT)
    let a = early(true)
    let b = early(false)
    var handles: Vec[Easy] = Vec.new()
    for i in 0..3:
        let easy = Easy.new().unwrap()
        let _ = easy.setopt(CURLOPT_TIMEOUT, 5)
        handles.push(easy)
    print(f"{a} {b} {handles.len()}")
    drop(handles)
    curl_global_cleanup()
