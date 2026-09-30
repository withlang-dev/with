// Unpacking archives in-process, for `with get` (#1915): Conan packages and
// source archives are unpacked by this compiler, not by the host's tar or
// unzip. gzip is std.zlib (the zlib corpus), zip is std.zip, xz and bzip2
// are compiler.Xz and compiler.Bzip2, and the tar reader is here: ustar, pax `path`/`linkpath` records and GNU
// long names; regular files, directories, symlinks and hard links.

use compiler.Runtime
use std.zlib
use std.zip
use compiler.Xz
use compiler.Bzip2

extern fn with_str_from_bytes(s: *const u8, len: i64) -> str
extern fn with_fs_chmod(path: &str, mode: i32) -> i32
extern fn with_fs_symlink(target: &str, link_path: &str) -> i32

fn te_octal(data: &str, at: i64, width: i64) -> i64:
    var value: i64 = 0
    for i in 0..width:
        let b = data[at + i]
        if b == 0 or b == ' ': continue
        if b < '0' or b > '7': return -1
        value = value * 8 + (b - '0') as i64
    value

fn te_field(data: &str, at: i64, width: i64) -> str:
    var end = at
    while end < at + width and data[end] != 0:
        end = end + 1
    data.slice(at, end)

// The value of `key` in a pax extended header, or "".
fn te_pax_value(text: &str, key: &str) -> str:
    var pos: i64 = 0
    while pos < text.len():
        var space = pos
        while space < text.len() and text[space] != ' ':
            space = space + 1
        var record: i64 = 0
        for i in pos..space:
            record = record * 10 + (text[i] - '0') as i64
        if record <= 0 or pos + record > text.len(): return ""
        let body = text.slice(space + 1, pos + record - 1)
        let eq = body.find("=")
        if eq > 0 and body.slice(0, eq) == key:
            return body.slice(eq + 1, body.len())
        pos = pos + record
    ""

// `name` without its first `strip` components; "" when nothing is left.
fn te_strip(name: &str, strip: i32) -> str:
    var rest = name.to_owned()
    for _ in 0..strip:
        let slash = rest.find("/")
        if slash < 0: return ""
        rest = rest.slice(slash + 1, rest.len())
    while rest.ends_with("/"):
        rest = rest.slice(0, rest.len() - 1)
    rest

fn te_safe(name: &str) -> bool:
    if name.starts_with("/"): return false
    for part in name.split("/"):
        if part == "..": return false
    true

fn te_dirname(path: &str) -> str:
    var last = -1
    for i in 0..path.len() as i32:
        if path[i] == '/': last = i
    if last <= 0: "" else: path.slice(0, last)

// Unpacks the tar image `data` into `dest`, dropping the first `strip`
// components of every name. "" on success, else why not.
pub fn tar_extract_text(data: &str, dest: &str, strip: i32) -> str:
    if runtime_mkdir_p(dest) != 0: return "could not create " ++ dest
    var at: i64 = 0
    var long_name = ""
    var long_link = ""
    while at + 512 <= data.len():
        let header = at
        var zero = true
        for i in 0..512:
            if data[at + i] != 0:
                zero = false
                break
        if zero: return ""
        let size = te_octal(data, at + 124, 12)
        let mode = te_octal(data, at + 100, 8)
        if size < 0 or mode < 0: return f"a malformed tar header at offset {at}"
        let kind = data[at + 156]
        let body = at + 512
        if body + size > data.len(): return f"a tar entry past the end of the archive at offset {at}"
        let payload = data.slice(body, body + size)
        at = body + ((size + 511) / 512) * 512
        if kind == 'x':
            let path = te_pax_value(payload, "path")
            if path.len() > 0: long_name = path
            let link = te_pax_value(payload, "linkpath")
            if link.len() > 0: long_link = link
            continue
        if kind == 'g': continue
        if kind == 'L':
            long_name = te_field(payload, 0, payload.len())
            continue
        if kind == 'K':
            long_link = te_field(payload, 0, payload.len())
            continue
        var name = long_name.clone()
        if name.len() == 0:
            name = te_field(data, header, 100)
            let prefix = te_field(data, header + 345, 155)
            if prefix.len() > 0: name = prefix ++ "/" ++ name
        var link = long_link.clone()
        if link.len() == 0: link = te_field(data, header + 157, 100)
        long_name = ""
        long_link = ""
        if not te_safe(name): return "an unsafe path in the archive: " ++ name
        let rel = te_strip(name, strip)
        if rel.len() == 0: continue
        let out = dest ++ "/" ++ rel
        let parent = te_dirname(out)
        if parent.len() > 0 and runtime_mkdir_p(parent) != 0: return "could not create " ++ parent
        if kind == '5':
            if runtime_mkdir_p(out) != 0: return "could not create " ++ out
        else if kind == '2':
            let _old = runtime_remove_file(out)
            if with_fs_symlink(link, out) != 0: return "could not link " ++ out ++ " to " ++ link
        else if kind == '1':
            let target = te_strip(link, strip)
            if not te_safe(link) or target.len() == 0: return "an unsafe hard link in the archive: " ++ link
            if runtime_write_file(out, runtime_read_file(dest ++ "/" ++ target)) != 0: return "could not write " ++ out
        else if kind == '0' or kind == 0 or kind == '7':
            if runtime_write_file(out, payload) != 0: return "could not write " ++ out
            if mode > 0: let _ = with_fs_chmod(out, (mode % 4096) as i32)
        // Device, fifo and other entries have no place in a package.
    ""

fn te_bytes(text: &str) -> Vec[u8]:
    let out: Vec[u8] = Vec.with_capacity(text.len())
    for i in 0..text.len(): out.push(text[i])
    out

// Unpacks the gzip-compressed tar `archive` into `dest`. "" or why not.
pub fn tar_gz_extract(archive: &str, dest: &str, strip: i32) -> str:
    let packed = runtime_read_file(archive)
    if packed.len() == 0: return "could not read " ++ archive
    match decompress_gzip_with_limit(&te_bytes(packed), 8589934592):
        .Ok(tar) =>
            if tar.len() == 0: return "an empty archive: " ++ archive
            let text = unsafe { with_str_from_bytes(&tar[0] as *const u8, tar.len()) }
            tar_extract_text(text, dest, strip)
        .Err(e) => archive ++ ": " ++ e.message

// Unpacks the xz-compressed tar `archive` into `dest`. "" or why not.
pub fn tar_xz_extract(archive: &str, dest: &str, strip: i32) -> str:
    let packed = runtime_read_file(archive)
    if packed.len() == 0: return "could not read " ++ archive
    let r = xz_decompress(packed)
    if r[1].len() > 0: return archive ++ ": " ++ r[1]
    tar_extract_text(r[0], dest, strip)

// Unpacks the bzip2-compressed tar `archive` into `dest`. "" or why not.
pub fn tar_bz2_extract(archive: &str, dest: &str, strip: i32) -> str:
    let packed = runtime_read_file(archive)
    if packed.len() == 0: return "could not read " ++ archive
    let r = bzip2_decompress(packed)
    if r[1].len() > 0: return archive ++ ": " ++ r[1]
    tar_extract_text(r[0], dest, strip)

// Unpacks the zip `archive` into `dest`. "" or why not.
pub fn zip_extract(archive: &str, dest: &str) -> str:
    match extract(archive, dest):
        .Ok(_) => ""
        .Err(e) => archive ++ ": " ++ e.message

// Unpacks `archive` into `dest` by what its first bytes say it is: a gzip,
// xz or bzip2 tarball, or a zip (a URL's name need not say). "" or why not.
pub fn archive_extract(archive: &str, dest: &str) -> str:
    let head = runtime_read_file(archive)
    if head.len() < 6: return "could not read " ++ archive
    if head[0] == 0x1F and head[1] == 0x8B: return tar_gz_extract(archive, dest, 0)
    if head[0] == 0xFD and head.slice(1, 5) == "7zXZ" and head[5] == 0: return tar_xz_extract(archive, dest, 0)
    if head.slice(0, 3) == "BZh": return tar_bz2_extract(archive, dest, 0)
    if head.slice(0, 4) == "PK\x03\x04": return zip_extract(archive, dest)
    archive ++ ": not a gzip, xz or bzip2 tarball or a zip, the formats this compiler unpacks"
