use std.http
use std.process

fn main -> i32:
    let argv = args()
    if argv.len() < 3:
        print("usage: https_fetch <url> <output>")
        return 2
    let rc = https_download(argv.get(1), argv.get(2))
    if rc != 0:
        print("HTTPS download failed: " ++ argv.get(1))
        return 1
    0
