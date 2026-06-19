use std.fs
use std.net
use std.process

const ZLIB_MAX_DOWNLOAD_BYTES: i64 = 16 * 1024 * 1024

fn zlib_index_of(text: str, needle: str) -> i32:
    if needle.len() == 0:
        return 0
    if needle.len() > text.len():
        return -1
    var i: i32 = 0
    while i <= text.len() as i32 - needle.len() as i32:
        var j: i32 = 0
        var matched = true
        while j < needle.len() as i32:
            if text.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
            j = j + 1
        if matched:
            return i
        i = i + 1
    -1

fn http_host(url: str) -> str:
    if not url.starts_with("http://"):
        return ""
    let rest = url.slice(7, url.len())
    let slash = zlib_index_of(rest, "/")
    if slash < 0:
        return rest
    rest.slice(0, slash as i64)

fn http_path(url: str) -> str:
    if not url.starts_with("http://"):
        return ""
    let rest = url.slice(7, url.len())
    let slash = zlib_index_of(rest, "/")
    if slash < 0:
        return "/"
    rest.slice(slash as i64, rest.len())

fn http_get_body(url: str) -> Result[str, str]:
    let host = http_host(url)
    let path = http_path(url)
    if host.len() == 0 or path.len() == 0:
        return Err("only plain http:// URLs are supported")
    let fd = tcp_connect(host, 80)
    if fd < 0:
        return Err("could not connect to " ++ host)
    let req = "GET " ++ path ++ " HTTP/1.0\r\nHost: " ++ host ++ "\r\nUser-Agent: with-build-zlib/1\r\nConnection: close\r\n\r\n"
    if send(fd, req) < req.len():
        let _close_send = socket_close(fd)
        return Err("could not send HTTP request")
    var response = ""
    while response.len() < ZLIB_MAX_DOWNLOAD_BYTES:
        let chunk = recv(fd, 65536)
        if chunk.len() == 0:
            break
        response = response ++ chunk
    let _close = socket_close(fd)
    if response.len() >= ZLIB_MAX_DOWNLOAD_BYTES:
        return Err("HTTP response exceeded maximum size")
    if not response.starts_with("HTTP/1.1 200") and not response.starts_with("HTTP/1.0 200"):
        return Err("HTTP server did not return 200")
    let header_end = zlib_index_of(response, "\r\n\r\n")
    if header_end < 0:
        return Err("HTTP response did not contain a header terminator")
    Ok(response.slice((header_end + 4) as i64, response.len()))

fn main -> i32:
    let argv = args()
    if argv.len() < 3:
        print("usage: zlib_http_fetch <url> <output>")
        return 2
    match http_get_body(argv.get(1)):
        Ok(body) => {
            if body.len() == 0:
                print("HTTP response body was empty")
                return 1
            if write_file(argv.get(2), body) != 0:
                print("could not write output archive")
                return 1
        }
        Err(message) => {
            print(message)
            return 1
        }
    0
