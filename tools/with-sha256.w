use std.process
use std.crypto.sha256

// #747 bootstrap note: this tool is seed-built but linked against the
// WORKSPACE runtime objects. Until a reseed carries the str flip, the
// seed's embedded prelude still declares the pre-flip consuming ABI for
// print/with_println_str/with_eprint/with_write, and the frontend's extern
// dedup would marry those decls to the flipped &str runtime — silent
// garbage I/O. So this tool must not touch any runtime symbol the seed
// prelude declares; it uses its own decls below, which match rt/.
// std.internal.str_abi also copies through the borrowed header directly so
// this seed-built tool never enters the legacy consuming byte-at ABI.
extern fn with_write_stdout(s: &str) -> Unit
extern fn with_libc_write(fd: i32, buf: *const u8, count: u64) -> i64
extern fn with_fs_file_exists(path: &str) -> i32
extern fn with_fs_read_file(path: &str) -> str

fn sha256_text(text: str) -> str:
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(text, &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

// stderr without the prelude's with_eprint (see bootstrap note).
fn ewrite(msg: str):
    let p = unsafe *(&msg as *const *mut u8)
    let _ = unsafe { with_libc_write(2, p, msg.len() as u64) }

fn main:
    let argv = args()
    if argv.len() < 2:
        ewrite("usage: with-sha256 <file>...\n")
        exit_code(1)
    for i in 1..argv.len() as i32:
        let path = argv.get(i as i64)
        if unsafe { with_fs_file_exists(path) } == 0:
            ewrite("with-sha256: missing file: " ++ path ++ "\n")
            exit_code(1)
        unsafe { with_write_stdout(sha256_text(unsafe { with_fs_read_file(path) }) ++ "  " ++ path ++ "\n") }
