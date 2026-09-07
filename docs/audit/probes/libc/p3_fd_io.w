use std.libc

fn main:
    let path = c"/tmp/with_audit_libc_fd.txt".ptr
    // Linux <fcntl.h>: O_RDWR=2 O_CREAT=64 O_TRUNC=512; mode 0644=420
    let fd = open(path, 578, 420)
    assert(fd >= 0)
    assert(write(fd, c"0123456789ABCDEF".ptr as *const c_void, 16 as u64) == 16)
    assert(lseek(fd, 0, 1) == 16)
    assert(lseek(fd, 0, 0) == 0)
    assert(lseek(fd, 4, 0) == 4)
    var buf: [8]i8 = [0 as i8; 8]
    let bp = (&raw mut buf) as *mut [8]i8 as *mut c_void
    assert(read(fd, bp, 8 as u64) == 8)
    var i: i64 = 0
    while i < 8:
        assert(unsafe *((bp as *mut i8) + i) == unsafe *((c"456789AB".ptr) + i))
        i = i + 1
    assert(close(fd) == 0)
    print("ok")
