//! expect-check-fail: view `info` borrows from foreign-state domain `version_info`, which `curl_global_cleanup` may have invalidated (§16.2b.7)

// D66 (spec §16.2b.6, §16.2b.7): the version record is a view of libcurl's
// process-wide state, not `static`; an operation of the library that does
// not preserve the domain ends it.
use facades.libcurl
use c_import("curl/curl.h", link: "curl")

fn main:
    let _ = curl_global_init(CURL_GLOBAL_DEFAULT)
    let info = curl_version_info(CURLVERSION_NOW).unwrap()
    curl_global_cleanup()
    print(f"{info.version_num}")
