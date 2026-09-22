//! skip-on: windows #799: POSIX strdup/fdopen/<dirent.h> are absent from MSVCRT; the libc facade's rendering is covered on Windows by behav_c_import_owning_wrapper_strdup
//! expect-stdout: string ok
//! expect-stdout: line ok
//! expect-stdout: file closed 1
//! expect-stdout: dir ok
//! expect-stdout: dir closed 1
//! expect-stdout: ok

// D51 §16.2b / ruling §5: a program that c_imports the real libc headers
// gets the toolchain libc facade (compiler/LibcFacade.w) for what they
// declare — `CHeapStr` from <string.h> + <stdlib.h>, `CFile` from <stdio.h>,
// `CDir` with its readdir/rewinddir lends from <dirent.h> — with no facade
// of its own and no `unsafe` on the resources. A c_import keeps `FILE *` and
// `DIR *` as pointers to FILE and DIR (Darwin `struct __sFILE`, glibc
// `struct _IO_FILE` / `struct __dirstream`); only a migration spells them
// `*mut c_void` (ClangBridge.w CImportSession.migration). The witness for
// fclose/closedir running exactly once is the descriptor, closed after the
// resource drops. `fileno`/`dirfd` are this program's own lends; fputs,
// rewind and fgets are not described, so they stay raw.

use c_import("string.h")
use c_import("stdlib.h")
use c_import("stdio.h")
use c_import("dirent.h")
use c_import("unistd.h")

c facade probes:
    fn fileno
        lend
    fn dirfd
        lend

fn closed(fd: c_int) -> i32:
    let probe = dup(fd)
    if probe < 0: return 1
    close(probe)
    0

fn read_back() -> c_int:
    let f = CFile.tmpfile().unwrap()
    let fd = f.fileno()
    unsafe { fputs("with-libc-facade\n", f.repr) }
    unsafe { rewind(f.repr) }
    var buf: [64]u8 = [0u8; 64]
    let got = unsafe { fgets(&raw mut buf[0] as *mut i8, 64, f.repr) }
    let same = got != null and strncmp(&raw const buf[0] as *const i8, "with-libc-facade\n", 17) == 0
    print(f"line {if same: \"ok\" else: \"bad\"}")
    fd

fn main:
    match CHeapStr.strdup("hello"):
        Some(s) => print(f"string {if s.repr != null: \"ok\" else: \"bad\"}")
        None => print("string none")
    let ffd = read_back()
    print(f"file closed {closed(ffd)}")
    let d = CDir.opendir(".").unwrap()
    var n = 0
    while d.readdir() != null:
        n = n + 1
    d.rewinddir()
    print(f"dir {if n >= 2: \"ok\" else: \"bad\"}")
    let dfd = d.dirfd()
    drop(d)
    print(f"dir closed {closed(dfd)}")
    print("ok")
