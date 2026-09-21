// std.zip - reading ZIP archives, over the migrated minizip reader
// (zlib's contrib/minizip, in the zlib bundle as std.zl.unzip).

use std.collections
use std.result
use std.string
use std.fs
use std.libc
use std.zl.defs
use std.zl.unzip

const ZIP_NAME_MAX: i32 = 4096
const ZIP_CHUNK: i32 = 65536
// The entry's Unix mode is the high half of the external attributes when
// the archive was made on Unix (the "version made by" host byte is 3).
const ZIP_HOST_UNIX: i64 = 3

pub type ZipError {
    code: i32,
    message: str,
}

fn zip_error(code: i32, message: str): ZipError { code: code, message: message }

/// One member of an archive. `mode` is the Unix permission bits, or 0 when
/// the archive does not carry them.
pub type ZipEntry {
    name: str,
    size: i64,
    mode: i32,
    is_dir: bool,
}

/// An open archive; closed when it goes out of scope.
pub type ZipArchive { handle: *mut c_void }

impl Drop for ZipArchive:
    move fn drop() -> Unit:
        if self.handle != null: unsafe { unzClose(self.handle) }

pub fn ZipArchive.open(path: &str) -> Result[ZipArchive, ZipError]:
    let cpath = match path.to_cstring():
        Ok(c) => c
        Err(_) => return Err(zip_error(UNZ_PARAMERROR, "a path cannot hold a NUL byte: " ++ path))
    let handle = unsafe { unzOpen64(cpath.ptr as *const c_void) }
    if handle == null: return Err(zip_error(UNZ_BADZIPFILE, "not a readable ZIP archive: " ++ path))
    Ok(ZipArchive { handle: handle })

// The entry the archive's cursor is on.
fn zip_current_entry(handle: *mut c_void) -> Result[ZipEntry, ZipError]:
    var info = unz_file_info64_s { tmu_date: tm_unz_s {} }
    let name_buf = with_alloc(ZIP_NAME_MAX as i64 + 1) as *mut i8
    let rc = unsafe { unzGetCurrentFileInfo64(handle, &raw mut info, name_buf, ZIP_NAME_MAX as c_ulong, null, 0, null, 0) }
    if rc != UNZ_OK:
        with_free(name_buf as *mut u8)
        return Err(zip_error(rc, "cannot read an entry header"))
    if info.size_filename as i64 > ZIP_NAME_MAX:
        with_free(name_buf as *mut u8)
        return Err(zip_error(UNZ_BADZIPFILE, f"an entry name of {info.size_filename} bytes exceeds {ZIP_NAME_MAX}"))
    let name = with_str_from_bytes(name_buf as *const u8, info.size_filename as i64)
    with_free(name_buf as *mut u8)
    let unix_host = ((info.version as i64) >> 8) == ZIP_HOST_UNIX
    let mode = if unix_host: (((info.external_fa as i64) >> 16) & 0o7777) as i32 else: 0
    Ok(ZipEntry { name: name.clone(), size: info.uncompressed_size as i64, mode: mode, is_dir: name.ends_with("/") })

impl ZipArchive:
    /// Every member, in archive order.
    pub fn entries() -> Result[Vec[ZipEntry], ZipError]:
        var out: Vec[ZipEntry] = Vec.new()
        var rc = unsafe { unzGoToFirstFile(self.handle) }
        while rc == UNZ_OK:
            out.push(zip_current_entry(self.handle)?)
            rc = unsafe { unzGoToNextFile(self.handle) }
        if rc != UNZ_END_OF_LIST_OF_FILE: return Err(zip_error(rc, "cannot walk the archive's directory"))
        out

    /// The bytes of the member named `name`.
    pub fn read(name: &str) -> Result[Vec[u8], ZipError]:
        let cname = match name.to_cstring():
            Ok(c) => c
            Err(_) => return Err(zip_error(UNZ_PARAMERROR, "an entry name cannot hold a NUL byte"))
        let rc = unsafe { unzLocateFile(self.handle, cname.ptr as *const i8, 1) }
        if rc != UNZ_OK: return Err(zip_error(rc, "no entry named " ++ name))
        zip_drain_current(self.handle, null)

    /// Writes every member under `dest` (created if missing) and returns the
    /// number of files written. An entry whose name would land outside
    /// `dest` fails the extraction.
    pub fn extract_all(dest: &str) -> Result[i32, ZipError]:
        if mkdir_p(dest) != 0: return Err(zip_error(UNZ_ERRNO, "cannot create " ++ dest))
        var written = 0
        var rc = unsafe { unzGoToFirstFile(self.handle) }
        while rc == UNZ_OK:
            let entry = zip_current_entry(self.handle)?
            if not zip_name_is_contained(entry.name): return Err(zip_error(UNZ_BADZIPFILE, "an entry escapes the destination: " ++ entry.name))
            let target = dest ++ "/" ++ entry.name
            if entry.is_dir:
                if mkdir_p(target) != 0: return Err(zip_error(UNZ_ERRNO, "cannot create " ++ target))
            else:
                let slash = zip_last_slash(target)
                if slash > 0 and mkdir_p(target.slice(0, slash)) != 0: return Err(zip_error(UNZ_ERRNO, "cannot create the directory of " ++ target))
                zip_write_current(self.handle, target)?
                if (entry.mode & 0o111) != 0: chmod(target, entry.mode)
                written = written + 1
            rc = unsafe { unzGoToNextFile(self.handle) }
        if rc != UNZ_END_OF_LIST_OF_FILE: return Err(zip_error(rc, "cannot walk the archive's directory"))
        written

/// Extracts the archive at `path` under `dest`; the number of files written.
pub fn extract(path: &str, dest: &str) -> Result[i32, ZipError]:
    let archive = ZipArchive.open(path)?
    archive.extract_all(dest)

fn zip_last_slash(path: &str) -> i64:
    var at: i64 = -1
    for i in 0..path.len():
        if path[i] == '/': at = i
    at

// Relative, and no `..` component: the entry stays under the destination.
fn zip_name_is_contained(name: &str) -> bool:
    if name.len() == 0 or name.starts_with("/") or name.contains("\\") or name.contains(":"): return false
    let parts = name.split("/")
    for part in parts:
        if part == "..": return false
    true

fn zip_write_current(handle: *mut c_void, target: &str) -> Result[Unit, ZipError]:
    let ctarget = match target.to_cstring():
        Ok(c) => c
        Err(_) => return Err(zip_error(UNZ_PARAMERROR, "an entry name cannot hold a NUL byte"))
    let stream = fopen(ctarget.ptr as *const i8, c"wb".ptr)
    if stream == null: return Err(zip_error(UNZ_ERRNO, "cannot create " ++ target))
    let drained = zip_drain_current(handle, stream)
    if fclose(stream) != 0: return Err(zip_error(UNZ_ERRNO, "cannot finish writing " ++ target))
    drained?
    Ok(())

// Decompresses the current member: into `stream` when it is set (the
// returned bytes are then empty), else into the returned bytes. Closing the
// member is where minizip checks the CRC-32.
fn zip_drain_current(handle: *mut c_void, stream: *mut c_void) -> Result[Vec[u8], ZipError]:
    let opened = unsafe { unzOpenCurrentFile(handle) }
    if opened != UNZ_OK: return Err(zip_error(opened, "cannot open an entry (an encrypted or unsupported method)"))
    let buf = with_alloc(ZIP_CHUNK as i64) as *mut u8
    var bytes: Vec[u8] = Vec.new()
    var failure = 0
    var n = unsafe { unzReadCurrentFile(handle, buf as *mut c_void, ZIP_CHUNK as c_uint) }
    while n > 0 and failure == 0:
        if stream != null:
            if fwrite(buf as *const c_void, 1, n as u64, stream) != n as u64: failure = UNZ_ERRNO
        else:
            for i in 0..n: bytes.push(unsafe *((buf as i64 + i) as *const u8))
        if failure == 0: n = unsafe { unzReadCurrentFile(handle, buf as *mut c_void, ZIP_CHUNK as c_uint) }
    with_free(buf)
    let closed = unsafe { unzCloseCurrentFile(handle) }
    if failure != 0: return Err(zip_error(failure, "cannot write an extracted entry"))
    if n < 0: return Err(zip_error(n, "corrupt entry data"))
    if closed != UNZ_OK: return Err(zip_error(closed, "an entry failed its CRC-32 check"))
    bytes
