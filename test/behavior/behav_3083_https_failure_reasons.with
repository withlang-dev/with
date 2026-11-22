//! expect-stdout: no TLS connection to 127.0.0.1:1 within 1000 ms
//! expect-stdout: not an https URL: file:///x
//! expect-stdout: ok
//! skip-on: windows #800: std.tls rides std.net, which has no Windows backend
// #3083: a failed download names the step that failed. Every failure used
// to be status -1 and nothing else, so a seed fetch that "failed after 5
// attempts" could not say whether the host, the TLS handshake, a redirect
// or a short body was at fault.
use std.http

fn main:
    print(https_download_reason("https://127.0.0.1:1/seed", "/tmp/behav_3083_never", 1000, 1000))
    print(https_download_reason("file:///x", "/tmp/behav_3083_never", 1000, 1000))
    let response = https_get_response_timeout("https://127.0.0.1:1/seed", 5, 1000, 1000)
    assert(response.status == -1)
    assert(response.reason.len() > 0)
    print("ok")
