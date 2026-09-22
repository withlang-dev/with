//! skip-on: windows #799: opendir/telldir/closedir are POSIX <dirent.h>, absent from MSVCRT
//! expect-stdout: cwd ok
//! expect-stdout: tell ok
//! expect-stdout: ok

// D51 stage 4c (docs/modeled-c-implementation-plan.md: "`owns:`/`borrows:`
// become deprecated spellings with a diagnostic naming the facade clause").
// Like `retains:` (spec §16.3c), each is accepted as a spelling of the facade
// clause it names — `owns: ["cwd_owned -> free"]` is the resource
// `CwdOwned` (`from cwd_owned`, `drop free`), `borrows: ["telldir(0) ->
// opendir"]` is `fn telldir` / `lend`, the method `d.telldir()` of the
// libc facade's `CDir` — with a warning naming the clauses to write
// (err_c_import_owns_deprecated_warns.w pins the wording).

use c_import("char *getcwd(char *buf, unsigned long size);
void free(void *p);
static inline char *cwd_owned(void) { return getcwd(0, 0); }
typedef struct __dirstream DIR;
DIR *opendir(const char *name);
long telldir(DIR *dirp);
int closedir(DIR *dirp);
", owns: ["cwd_owned -> free"], borrows: ["telldir(0) -> opendir"])

fn main:
    match CwdOwned.cwd_owned():
        Some(c) => print(f"cwd {if c.repr != null: \"ok\" else: \"bad\"}")
        None => print("cwd none")
    let d = CDir.opendir(".").unwrap()
    print(f"tell {if d.telldir() >= 0: \"ok\" else: \"bad\"}")
    print("ok")
