// HTTP/1.1 client over TLS.
//
// This is intentionally small: HTTPS GET, response parsing, and redirects.

use std.tls
use std.net
use std.internal.str_abi

extern fn with_fs_write_file(path: str, data: str) -> i32

pub type HttpUrl { host: str, path: str, port: i32 }

pub type HttpResponse {
    status: i32,
    headers: str,
    body: str,
    location: str,
}

fn http_empty_response(status: i32) -> HttpResponse:
    HttpResponse { status, headers: "", body: "", location: "" }

fn http_parse_url(url: str) -> HttpUrl:
    var host: str = ""
    var path: str = "/"
    let port = 443
    if not url.starts_with("https://"):
        return HttpUrl { host, path, port }

    var start = 8
    let url_len = url.len() as i32
    var host_end = start
    while host_end < url_len:
        if url.byte_at(host_end as i64) == 47:
            break
        host_end = host_end + 1

    host = url.slice(start as i64, host_end as i64)
    if host_end < url_len:
        path = url.slice(host_end as i64, url_len as i64)
    HttpUrl { host, path, port }

fn http_build_get(host: str, path: str) -> str:
    "GET " ++ path ++ " HTTP/1.1\r\n" ++
        "Host: " ++ host ++ "\r\n" ++
        "User-Agent: with-stdlib-http/1\r\n" ++
        "Accept: */*\r\n" ++
        "Connection: close\r\n\r\n"

fn http_find_header_end(data: str) -> i32:
    let len = data.len() as i32
    var i = 0
    while i < len - 3:
        if data.byte_at(i as i64) == 13 and data.byte_at((i + 1) as i64) == 10 and data.byte_at((i + 2) as i64) == 13 and data.byte_at((i + 3) as i64) == 10:
            return i + 4
        i = i + 1
    -1

fn http_status(headers: str) -> i32:
    if headers.len() < 12:
        return -1
    var i = 0
    while i < headers.len() as i32 and headers.byte_at(i as i64) != 32:
        if headers.byte_at(i as i64) == 10:
            return -1
        i = i + 1
    if i + 3 >= headers.len() as i32:
        return -1
    i = i + 1
    let c1 = headers.byte_at(i as i64)
    let c2 = headers.byte_at((i + 1) as i64)
    let c3 = headers.byte_at((i + 2) as i64)
    if c1 < 48 or c1 > 57 or c2 < 48 or c2 > 57 or c3 < 48 or c3 > 57:
        return -1
    ((c1 - 48) as i32 * 100) + ((c2 - 48) as i32 * 10) + (c3 - 48) as i32

fn http_ascii_lower(ch: i32) -> i32:
    if ch >= 65 and ch <= 90:
        return ch + 32
    ch

fn http_name_matches(line: str, name: str) -> bool:
    if line.len() < name.len() + 1:
        return false
    for i in 0..name.len() as i32:
        if http_ascii_lower(line.byte_at(i as i64)) != http_ascii_lower(name.byte_at(i as i64)):
            return false
    line.byte_at(name.len()) == 58

fn http_trim_header_value(value: str) -> str:
    var start = 0
    var end = value.len() as i32
    while start < end:
        let ch = value.byte_at(start as i64)
        if ch != 32 and ch != 9:
            break
        start = start + 1
    while end > start:
        let ch = value.byte_at((end - 1) as i64)
        if ch != 32 and ch != 9 and ch != 13 and ch != 10:
            break
        end = end - 1
    value.slice(start as i64, end as i64)

fn http_header_value(headers: str, name: str) -> str:
    var line_start = 0
    var i = 0
    while i <= headers.len() as i32:
        let at_end = i == headers.len() as i32
        if at_end or headers.byte_at(i as i64) == 10:
            var line = headers.slice(line_start as i64, i as i64)
            if line.len() > 0 and line.byte_at(line.len() - 1) == 13:
                line = line.slice(0, line.len() - 1)
            if http_name_matches(line, name):
                return http_trim_header_value(line.slice((name.len() + 1) as i64, line.len()))
            line_start = i + 1
        i = i + 1
    ""

fn http_is_chunked(headers: str) -> bool:
    let value = http_header_value(headers, "Transfer-Encoding")
    value.contains("chunked") or value.contains("Chunked")

fn http_decode_chunked(data: str) -> str:
    var result = StringBuilder.new()
    let dlen = data.len() as i32
    var pos = 0
    while pos < dlen:
        var chunk_size = 0
        while pos < dlen:
            let c = data.byte_at(pos as i64) as i32
            if c >= 48 and c <= 57:
                chunk_size = chunk_size * 16 + (c - 48)
            else if c >= 97 and c <= 102:
                chunk_size = chunk_size * 16 + (c - 97 + 10)
            else if c >= 65 and c <= 70:
                chunk_size = chunk_size * 16 + (c - 65 + 10)
            else:
                break
            pos = pos + 1
        while pos < dlen and data.byte_at(pos as i64) != 10:
            pos = pos + 1
        if pos < dlen:
            pos = pos + 1
        if chunk_size == 0:
            break
        let end = if pos + chunk_size > dlen: dlen else: pos + chunk_size
        result.push_str(data.slice(pos as i64, end as i64))
        pos = end
        if pos < dlen and data.byte_at(pos as i64) == 13:
            pos = pos + 1
        if pos < dlen and data.byte_at(pos as i64) == 10:
            pos = pos + 1
    result.to_str()

fn http_resolve_redirect(current_url: str, location: str) -> str:
    if location.starts_with("https://"):
        return location
    if location.starts_with("/"):
        let parsed = http_parse_url(current_url)
        if parsed.host.len() == 0:
            return ""
        return "https://" ++ parsed.host ++ location
    ""

fn http_is_redirect(status: i32) -> bool:
    status == 301 or status == 302 or status == 303 or status == 307 or status == 308

fn https_get_once(url: str) -> HttpResponse:
    let parsed = http_parse_url(url)
    if parsed.host.len() == 0:
        return http_empty_response(-1)

    var conn = tls_connect(parsed.host, parsed.port)
    if conn.fd < 0:
        return http_empty_response(-1)

    let req = http_build_get(parsed.host, parsed.path)
    let req_len = req.len() as i32
    let sent = unsafe:
        let req_bytes = str_copy_bytes(req)
        let n = tls_send(&raw mut conn, req_bytes as *const u8, req_len)
        str_free_bytes(req_bytes)
        n
    if sent < 0:
        socket_close(conn.fd)
        return http_empty_response(-1)

    var response = StringBuilder.new()
    var done = false
    while not done:
        var buf: [u8; 16640] = [0u8; 16640]
        let n = unsafe { tls_recv(&raw mut conn, &raw mut buf[0], 16640) }
        if n <= 0:
            done = true
        else:
            var chunk: str = ""
            let sp = &raw mut chunk as *mut u8
            unsafe:
                *(sp as *mut u64) = &buf[0] as u64
                *((sp + 8u64) as *mut i64) = n as i64
            response.push_str(chunk)
    socket_close(conn.fd)

    let raw = response.to_str()
    let hdr_end = http_find_header_end(raw)
    if hdr_end < 0:
        return http_empty_response(-1)

    let headers = raw.slice(0, hdr_end as i64)
    let status = http_status(headers)
    var body = raw.slice(hdr_end as i64, raw.len())
    if http_is_chunked(headers):
        body = http_decode_chunked(body)
    HttpResponse { status, headers, body, location: http_header_value(headers, "Location") }

pub fn https_get_response(url: str, max_redirects: i32) -> HttpResponse:
    var current = url
    var redirects = 0
    while true:
        let response = https_get_once(current)
        if not http_is_redirect(response.status):
            return response
        if redirects >= max_redirects:
            return http_empty_response(-1)
        let next = http_resolve_redirect(current, response.location)
        if next.len() == 0:
            return http_empty_response(-1)
        current = next
        redirects = redirects + 1
    http_empty_response(-1)

pub fn https_get(url: str) -> str:
    let response = https_get_response(url, 5)
    if response.status != 200:
        return ""
    response.body

pub fn https_download(url: str, dest_path: str) -> i32:
    let response = https_get_response(url, 5)
    if response.status != 200:
        return -1
    with_fs_write_file(dest_path, response.body)
