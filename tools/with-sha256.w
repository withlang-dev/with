use std.crypto.sha256
use std.process

extern fn with_eprint(s: str) -> Unit
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_fs_read_file(path: str) -> str

fn sha256_text(text: str) -> str:
    var digest: [32]u8 = [0 as u8; 32]
    sha256_hash_str(text, &raw mut digest[0] as *mut u8)
    sha256_hex(&digest[0] as *const u8)

fn main:
    let argv = args()
    if argv.len() < 2:
        with_eprint("usage: with-sha256 <file>...\n")
        exit_code(1)
    for i in 1..argv.len() as i32:
        let path = argv.get(i as i64)
        if with_fs_file_exists(path) == 0:
            with_eprint("with-sha256: missing file: " ++ path ++ "\n")
            exit_code(1)
        print(sha256_text(with_fs_read_file(path)) ++ "  " ++ path)
