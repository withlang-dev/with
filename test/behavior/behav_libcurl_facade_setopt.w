//! expect-stdout: nosignal: true
//! expect-stdout: url: true
//! expect-stdout: timeout: true
//! expect-stdout: maxfilesize: true
//! expect-stdout: useragent: true
//! expect-stdout: version_num: true
//! expect-stdout: version text: true
//! expect-stdout: strerror: No error
//! expect-stdout: libcurl UAT passed
//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows

// D66 (spec §16.2b.5, §16.2b.6) against the real library: the libcurl
// facade's surface as the release UAT program uses it, plus every case
// kind — a long (`CURLOPT_NOSIGNAL`, `CURLOPT_TIMEOUT`), a copied string
// (`CURLOPT_URL`, `CURLOPT_USERAGENT`; the storage is the presented call's
// own, discarded on return) and a curl_off_t (`CURLOPT_MAXFILESIZE_LARGE`)
// — each set through `easy.setopt(OPTION, value)` with the C declaration
// still variadic and the argument lowered as the case's C type. libcurl
// answers CURLE_OK to each without a transfer, so this needs no network.
// The version record is read through a scalar field of its borrowed view
// (its domain is preserved by every presented operation, so the view
// survives them; the refused shape is
// err_libcurl_facade_version_view_invalidated); the printable text is
// `curl_version()`, static; `curl_easy_strerror`'s text for CURLE_OK is
// "No error" in every libcurl.
use facades.libcurl
use c_import("curl/curl.h", link: "curl")

fn configure_handle() -> i32:
    let made = Easy.new()
    if made.is_none():
        print("libcurl easy init failed")
        return 1
    let easy = made.unwrap()
    print(f"nosignal: {easy.setopt(CURLOPT_NOSIGNAL, 1) == CURLE_OK}")
    let url = "http://example.invalid/" ++ "path"
    print(f"url: {easy.setopt(CURLOPT_URL, url) == CURLE_OK}")
    print(f"timeout: {easy.setopt(CURLOPT_TIMEOUT, 5) == CURLE_OK}")
    print(f"maxfilesize: {easy.setopt(CURLOPT_MAXFILESIZE_LARGE, 1048576) == CURLE_OK}")
    print(f"useragent: {easy.setopt(CURLOPT_USERAGENT, "with-uat/1.0") == CURLE_OK}")
    0

fn main:
    if curl_global_init(CURL_GLOBAL_DEFAULT) != CURLE_OK:
        print("libcurl global init failed")
        return 1
    let handle_rc = configure_handle()
    if handle_rc != 0:
        curl_global_cleanup()
        return handle_rc
    let info = curl_version_info(CURLVERSION_NOW)
    let version_num = if info.is_none(): 0 else: info.unwrap().version_num
    print(f"version_num: {version_num > 0}")
    let text = curl_version()
    print(f"version text: {text.is_some() and text.unwrap().len() > 0}")
    print(f"strerror: {curl_easy_strerror(CURLE_OK).unwrap().to_str().unwrap()}")
    curl_global_cleanup()
    print("libcurl UAT passed")
