use std.http

fn main -> i32:
    // T23/T10 offline: non-https scheme -> parse yields empty host -> status -1, body ""
    let r1 = https_get_response("http://example.com/", 5)
    print("http_scheme status=" ++ r1.status.to_string() ++ " body_empty=" ++ (r1.body == "").to_string())
    // empty host
    let r2 = https_get_response("https://", 5)
    print("empty_host status=" ++ r2.status.to_string())
    // T10: https_get conflates every failure mode into ""
    print("get_http empty=" ++ (https_get("http://example.com/") == "").to_string())
    print("get_empty_host empty=" ++ (https_get("https://") == "").to_string())
    // T23: refused on loopback https port? offline-safe only via bad-scheme path; also bad port via URL has no port support (always 443) so use unroutable-as-parseable:
    // https_download with bad scheme must return -1 without writing
    let dl = https_download("http://example.com/", "/tmp/with_audit_std_net_dl.txt")
    print("download_badscheme=" ++ dl.to_string())
    // T10: max_redirects=0 with non-redirect response still returns the response (no redirect involved)
    let r3 = https_get_response("http://example.com/", 0)
    print("maxredir0 status=" ++ r3.status.to_string())
    print("p3-done")
    0
