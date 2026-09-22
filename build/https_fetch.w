use std.http
use std.process
use std.time

// A source archive fetch is one dropped connection away from failing a
// three-hour lane (main's windows x86_64, 2026-09-22: cmake-4.2.3.tar.gz
// from GitHub, once). Retry with a growing pause; only a persistent failure
// is reported. lib/std/build.w's build_https_fetch_source is this program's
// twin and must match.
let ATTEMPTS = 5

fn main -> i32:
    let argv = args()
    if argv.len() < 3:
        print("usage: https_fetch <url> <output>")
        return 2
    let url = argv.get(1) ++ ""
    let output = argv.get(2) ++ ""
    for attempt in 1..ATTEMPTS + 1:
        if https_download(url.clone(), output.clone()) == 0: return 0
        if attempt < ATTEMPTS:
            print(f"HTTPS download failed (attempt {attempt} of {ATTEMPTS}), retrying: " ++ url)
            sleep_secs(2 * attempt)
    print(f"HTTPS download failed after {ATTEMPTS} attempts: " ++ url)
    1
