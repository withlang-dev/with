use std.http
use std.net
use std.process
use std.time

// A source archive fetch is one dropped connection away from failing a
// three-hour lane (main's windows x86_64, 2026-09-22: cmake-4.2.3.tar.gz
// from GitHub, once). Retry with a growing pause; only a persistent failure
// is reported. lib/std/build.w's build_https_fetch_source is the download
// half's twin and must match it.
//
//   https_fetch <url> <output>     download, with retries
//   https_fetch --probe <url>      open and close a TCP connection to the
//                                  URL's host, nothing else
//
// std.net has no connect or receive timeout, so a host that is down holds a
// download for as long as the kernel keeps trying. build/source_fetch.w runs
// the probe under a short process timeout before it starts a download
// (#2062): an unreachable source costs seconds, not the download's deadline.
let ATTEMPTS = 5

// "host:port" of an https URL ("" when it is not one); 443 unless it names one.
fn host_port(url: &str) -> str:
    if not url.starts_with("https://"): return ""
    let rest = url.slice(8, url.len())
    var end = rest.len() as i32
    for i in 0..rest.len() as i32:
        if rest[i] == '/' or rest[i] == '?' or rest[i] == '#':
            end = i
            break
    let authority = rest.slice(0, end)
    if authority.len() == 0: return ""
    if authority.contains(":"): authority else: authority ++ ":443"

fn port_number(text: &str) -> i32:
    var value = 0
    for i in 0..text.len() as i32:
        if text[i] < '0' or text[i] > '9': return -1
        value = value * 10 + (text[i] - '0') as i32
    if text.len() == 0: -1 else: value

fn probe(url: &str) -> i32:
    let target = host_port(url)
    let colon = target.index_of(":")
    if colon <= 0:
        print("not an https URL: " ++ url)
        return 2
    let host = target.slice(0, colon)
    let port = port_number(target.slice(colon + 1, target.len()))
    if port <= 0:
        print("not an https URL: " ++ url)
        return 2
    let fd = tcp_connect(host, port)
    if fd < 0:
        print("could not connect to " ++ target)
        return 1
    let _ = socket_close(fd)
    0

fn main -> i32:
    let argv = args()
    if argv.len() < 3:
        print("usage: https_fetch <url> <output> | https_fetch --probe <url>")
        return 2
    if argv[1] == "--probe": return probe(argv[2])
    let url = argv[1] ++ ""
    let output = argv[2] ++ ""
    for attempt in 1..ATTEMPTS + 1:
        if https_download(url.clone(), output.clone()) == 0: return 0
        if attempt < ATTEMPTS:
            print(f"HTTPS download failed (attempt {attempt} of {ATTEMPTS}), retrying: " ++ url)
            sleep_secs(2 * attempt)
    print(f"HTTPS download failed after {ATTEMPTS} attempts: " ++ url)
    1
