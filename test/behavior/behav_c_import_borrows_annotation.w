//! skip-on: windows #799: opendir/telldir/closedir are POSIX <dirent.h>, absent from MSVCRT (link-undefined on Windows); the borrows: annotation / &COwned wrapper mechanism is already covered on Windows by behav_c_import_overlay_strchr_borrowed and behav_c_import_owning_wrapper_strdup
//! expect-stdout: ok

// [Phase8] #357 increment 4: the borrows: annotation marks a parameter as
// borrowing an owned handle — telldir is not in the curated tables, so the
// annotation is what generates its safe &COwned_opendir wrapper.

use c_import("typedef struct __dirstream DIR;\nDIR *opendir(const char *name);\nlong telldir(DIR *dirp);\nint closedir(DIR *dirp);\nstatic inline const char *dot357b(void){return \".\";}\n", borrows: ["telldir(0) -> opendir"])

fn main:
    unsafe:
        let d = opendir(dot357b())
        if d.handle() == null:
            print("bad-open")
            return
        let pos = telldir(&d)
        if pos >= 0:
            print("ok")
        else:
            print("bad-tell")
