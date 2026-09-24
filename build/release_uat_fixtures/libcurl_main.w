// The libcurl release UAT, written against the facade surface (spec
// §16.2b, ruling §66, D66): the program an application developer writes. It
// initializes libcurl, makes an easy handle, sets one option through the
// discriminated variadic contract, reads the running library's version —
// the record through its scalar field, the text through curl_version — and
// tears down in order: the handle first, then the library.
use facades.libcurl
use c_import("curl/curl.h")

// The handle lives in this scope and is cleaned up when it ends, before
// curl_global_cleanup runs in main.
fn configure_handle() -> i32:
    let made = Easy.new()
    if made.is_none():
        print("libcurl easy init failed")
        return 1
    let easy = made.unwrap()
    let opt_rc = easy.setopt(CURLOPT_NOSIGNAL, 1)
    if opt_rc != CURLE_OK:
        print("libcurl setopt failed")
        return 1
    0

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

    let handle_rc = configure_handle()
    if handle_rc != 0:
        curl_global_cleanup()
        return handle_rc

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
