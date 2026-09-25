//! expect-stdout: written: true
//! expect-stdout: fetched: true
//! expect-stdout: ok
//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows

// D66 retained variadic pairs (#1652, spec §16.2b.5, §16.2b.9) against the
// real library: the write callback and its userdata are set through the
// facade's callback case — `setopt(CURLOPT_WRITEFUNCTION, on_data)` typed
// over the userdata's type, `setopt(CURLOPT_WRITEDATA, sink)` implied by
// the pairing, taking the borrow the handle then holds — and a transfer of
// a local file (`file://`, no network) drives the callback with every
// chunk. The sink is a capturing callable declared before the handle: it
// outlives the handle, whose Drop runs curl_easy_reset (the abandonment
// path) before curl_easy_cleanup. Each setter's status is checked against
// CURLE_OK, which is what proves the pair compatible at `perform`.
use facades.libcurl
use c_import("curl/curl.h", link: "curl")
use std.fs

fn on_data(ptr: *mut c_char, size: u64, nmemb: u64, sink: &fn(i32) -> Unit) -> u64:
    sink((size * nmemb) as i32)
    size * nmemb

// The number of bytes libcurl handed the write callback, or -1.
fn fetch(path: &str) -> i32:
    var total = 0
    let sink = n => total = total + n
    let made = Easy.new()
    if made.is_none(): return -1
    var easy = made.unwrap()
    if easy.setopt(CURLOPT_URL, "file://" ++ path) != CURLE_OK: return -1
    if easy.setopt(CURLOPT_WRITEFUNCTION, on_data) != CURLE_OK: return -1
    if easy.setopt(CURLOPT_WRITEDATA, sink) != CURLE_OK: return -1
    if easy.perform() != CURLE_OK: return -1
    total

fn main:
    if curl_global_init(CURL_GLOBAL_DEFAULT) != CURLE_OK:
        print("libcurl global init failed")
        return 1
    let path = "/tmp/with-behav-libcurl-callback-pair.txt"
    let body = "hello, callback pair\n"
    print(f"written: {write_file(path, body) == 0}")
    print(f"fetched: {fetch(path) == body.len() as i32}")
    curl_global_cleanup()
    print("ok")
