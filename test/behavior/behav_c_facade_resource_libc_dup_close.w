//! skip-on: windows POSIX dup/close
//! expect-stdout: live 1
//! expect-stdout: closed 1
//! expect-stdout: ok

// D51 §16.2b.3 stage 4a over real libc, by-value form: `int dup(int)`
// produces a descriptor resource that `close` drops. Whether the descriptor
// is still open is read back with `dup` itself (it fails on a closed fd), so
// the numbers prove Drop ran close after the resource left scope. The
// prototypes are spelled here and link against the real libc. No `unsafe`.

use c_import("int dup(int fd);
int close(int fd);
")

c facade posix:
    resource Fd wraps c_int
        from dup
        drop close
    fn dup
        lend

fn open_and_forget() -> c_int:
    let fd = Fd.dup(1)
    let probe = dup(fd.repr)
    close(probe)
    print(f"live {if probe >= 0: 1 else: 0}")
    fd.repr

fn main:
    let raw = open_and_forget()
    let again = dup(raw)
    print(f"closed {if again < 0: 1 else: 0}")
    print("ok")
