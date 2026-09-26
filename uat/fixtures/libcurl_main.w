// The libcurl release UAT, written against the facade surface (spec
// §16.2b, ruling §66, D66): the program an application developer writes. It
// initializes libcurl, makes an easy handle, sets options through the
// discriminated variadic contract — a long, a copied string, and the write
// callback with its userdata (the pair configured across two calls, D66
// §16.2b.9) — transfers a local file through that callback, reads the
// running library's version — the record through its scalar field, the
// text through curl_version — and tears down in order: the handle first
// (its Drop resets the handle, the abandonment path, before cleanup), then
// the library.
use facades.libcurl
use c_import("curl/curl.h")
use std.fs

// libcurl calls this once per chunk of the response body; the userdata is
// the program's own sink, typed by the facade over what it passed.
fn on_data(ptr: *mut c_char, size: u64, nmemb: u64, sink: &fn(i32) -> Unit) -> u64:
    sink((size * nmemb) as i32)
    size * nmemb

// The number of bytes the transfer of `path` handed the callback, or -1.
// The sink is declared before the handle: the handle holds it until the
// handle is dropped at the end of this scope.
fn fetch_bytes(path: &str) -> i32:
    var total = 0
    let sink = n => total = total + n
    let made = Easy.new()
    if made.is_none():
        print("libcurl easy init failed")
        return -1
    var easy = made.unwrap()
    if easy.setopt(CURLOPT_NOSIGNAL, 1) != CURLE_OK: return -1
    if easy.setopt(CURLOPT_URL, "file://" ++ path) != CURLE_OK: return -1
    if easy.setopt(CURLOPT_WRITEFUNCTION, on_data) != CURLE_OK: return -1
    if easy.setopt(CURLOPT_WRITEDATA, sink) != CURLE_OK: return -1
    if easy.perform() != CURLE_OK: return -1
    total

// The version number of the running library, read through the borrowed
// version record; 0 when libcurl hands back none.
fn version_number() -> u32:
    let info = curl_version_info(CURLVERSION_NOW)
    if info.is_none(): 0 else: info.unwrap().version_num

fn main:
    let init_rc = curl_global_init(CURL_GLOBAL_DEFAULT)
    if init_rc != CURLE_OK:
        print("libcurl global init failed")
        return 1

    let path = "/tmp/with-libcurl-uat.txt"
    let body = "libcurl UAT body\n"
    if write_file(path, body) != 0:
        print("libcurl UAT could not write its file")
        curl_global_cleanup()
        return 1
    if fetch_bytes(path) != body.len() as i32:
        print("libcurl transfer failed")
        curl_global_cleanup()
        return 1

    if version_number() == 0:
        print("libcurl version info failed")
        curl_global_cleanup()
        return 1
    if curl_version().is_none():
        print("libcurl version missing")
        curl_global_cleanup()
        return 1

    curl_global_cleanup()
    print("libcurl UAT passed")
