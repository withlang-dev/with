// HTTP/1.1 client over TLS
// Minimal implementation for GET requests (sufficient for package manager).

use std.tls
use std.net
use std.internal.str_abi

extern fn with_eprint(s: str) -> Unit
extern fn with_i32_to_str(n: i32) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32

type HttpUrl { host: str, path: str, port: i32 }

fn http_parse_url(url: str) -> HttpUrl:
    var host: str = ""
    var path: str = "/"
    let port = 443

    // Skip "https://"
    var start = 0
    if url.len() > 8:
        start = 8

    // Find end of host (first / or end of string)
    let url_len = url.len() as i32
    var host_end = start
    while host_end < url_len:
        if url.byte_at(host_end as i64) == 47:  // '/'
            break
        host_end = host_end + 1

    host = url.slice(start as i64, host_end as i64)

    if host_end < url_len:
        path = url.slice(host_end as i64, url_len as i64)

    HttpUrl { host, path, port }

// Build an HTTP GET request string.
fn http_build_get(host: str, path: str) -> str:
    "GET " ++ path ++ " HTTP/1.1\r\nHost: " ++ host ++ "\r\nConnection: close\r\n\r\n"

// Find "\r\n\r\n" in data (header/body boundary).
fn http_find_header_end(data: str) -> i32:
    let len = data.len() as i32
    var i = 0
    while i < len - 3:
        if data.byte_at(i as i64) == 13 and data.byte_at((i+1) as i64) == 10 and data.byte_at((i+2) as i64) == 13 and data.byte_at((i+3) as i64) == 10:
            return i + 4
        i = i + 1
    -1

// Extract Content-Length from headers. Returns -1 if not found.
fn http_content_length(headers: str) -> i32:
    let hlen = headers.len() as i32
    var i = 0
    while i < hlen - 16:
        // Look for "Content-Length: " (case-insensitive would be better but MVP)
        if (headers.byte_at(i as i64) == 67 or headers.byte_at(i as i64) == 99) and headers.byte_at((i+8) as i64) == 76 or headers.byte_at((i+8) as i64) == 108:
            // Find ": ": parse digits
            var j = i
            while j < hlen and headers.byte_at(j as i64) != 58:  // ':'
                j = j + 1
            j = j + 1  // skip ':'
            while j < hlen and headers.byte_at(j as i64) == 32:  // ' '
                j = j + 1
            var val = 0
            while j < hlen and headers.byte_at(j as i64) >= 48 and headers.byte_at(j as i64) <= 57:
                val = val * 10 + (headers.byte_at(j as i64) - 48) as i32
                j = j + 1
            if val > 0:
                return val
        i = i + 1
    -1

// Check if response uses chunked transfer encoding.
fn http_is_chunked(headers: str) -> bool:
    headers.contains("chunked") or headers.contains("Chunked")

// HTTP GET request over TLS. Returns response body or empty string on error.
fn https_get(url: str) -> str:
    let parsed = http_parse_url(url)

    if parsed.host.len() == 0:
        return ""

    var conn = tls_connect(parsed.host, parsed.port)
    if conn.fd < 0:
        return ""

    let req = http_build_get(parsed.host, parsed.path)
    let req_len = req.len() as i32
    let sent = unsafe:
        let req_bytes = str_copy_bytes(req)
        let n = tls_send(&raw mut conn, req_bytes as *const u8, req_len)
        str_free_bytes(req_bytes)
        n
    if sent < 0:
        socket_close(conn.fd)
        return ""

    // Read response into buffer
    var response: str = ""
    var done = false
    while not done:
        var buf: [u8; 4096] = [0u8; 4096]
        let n = unsafe { tls_recv(&raw mut conn, &raw mut buf[0], 4096) }
        if n <= 0:
            done = true
        else:
            // Convert buf to str and append
            var chunk_s: str = ""
            let sp = &raw mut chunk_s as *mut u8
            unsafe:
                *(sp as *mut u64) = &buf[0] as u64
                *((sp + 8u64) as *mut i64) = n as i64
            response = response ++ chunk_s

    socket_close(conn.fd)

    // Parse headers/body
    let hdr_end = http_find_header_end(response)
    if hdr_end < 0:
        return response

    let headers = response.slice(0, hdr_end as i64)
    let raw_body = response.slice(hdr_end as i64, response.len())

    if http_is_chunked(headers):
        return http_decode_chunked(raw_body)

    raw_body

// Decode chunked transfer encoding.
fn http_decode_chunked(data: str) -> str:
    var result: str = ""
    let dlen = data.len() as i32
    var pos = 0
    while pos < dlen:
        // Parse chunk size (hex digits until \r\n)
        var chunk_size = 0
        while pos < dlen:
            let c = data.byte_at(pos as i64) as i32
            if c >= 48 and c <= 57:  // '0'-'9'
                chunk_size = chunk_size * 16 + (c - 48)
            else if c >= 97 and c <= 102:  // 'a'-'f'
                chunk_size = chunk_size * 16 + (c - 97 + 10)
            else if c >= 65 and c <= 70:  // 'A'-'F'
                chunk_size = chunk_size * 16 + (c - 65 + 10)
            else:
                break
            pos = pos + 1
        // Skip \r\n after chunk size
        if pos < dlen and data.byte_at(pos as i64) == 13:
            pos = pos + 1
        if pos < dlen and data.byte_at(pos as i64) == 10:
            pos = pos + 1
        if chunk_size == 0:
            break
        // Extract chunk data
        let end = if pos + chunk_size > dlen: dlen else: pos + chunk_size
        result = result ++ data.slice(pos as i64, end as i64)
        pos = end
        // Skip trailing \r\n
        if pos < dlen and data.byte_at(pos as i64) == 13:
            pos = pos + 1
        if pos < dlen and data.byte_at(pos as i64) == 10:
            pos = pos + 1
    result

// Download a URL to a file. Returns 0 on success, -1 on error.
fn https_download(url: str, dest_path: str) -> i32:
    let body = https_get(url)
    if body.len() == 0:
        return -1
    with_fs_write_file(dest_path, body)
