//! only-on: darwin
//! expect-stdout: string ok
//! expect-stdout: dir ok
//! expect-stdout: ok

// D51 §16.2b / ruling §5: a program that c_imports the system libc headers
// gets the toolchain libc facade (compiler/LibcFacade.w) for what those
// headers declare in libc's shape — `CHeapStr` from <string.h> + <stdlib.h>,
// `CDir` with its readdir/rewinddir lends from <dirent.h> — with no facade
// of its own and no `unsafe`. (Darwin's <stdio.h> translation hands `FILE *`
// through as `*mut c_void` — the bridge types a pointer to a reserved system
// record (`struct __sFILE`; glibc's `struct __dirstream` DIR likewise, hence
// Darwin only) as `void *` — not libc's shape, so `CFile` is not described
// there and fopen stays the raw surface; behav_c_import_owning_wrapper_fopen
// covers CFile over a `FILE *` declaration.)

use c_import("string.h")
use c_import("stdlib.h")
use c_import("dirent.h")

fn main:
    match CHeapStr.strdup("hello"):
        Some(s) => print(f"string {if s.repr != null: \"ok\" else: \"bad\"}")
        None => print("string none")
    match CDir.opendir("."):
        Some(d) =>
            var n = 0
            while d.readdir() != null:
                n = n + 1
            d.rewinddir()
            print(f"dir {if n >= 2: \"ok\" else: \"bad\"}")
        None => print("dir none")
    print("ok")
