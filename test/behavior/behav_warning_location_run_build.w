//! expect-stdout: ok

use pre_d_build_runner

// #1498 (§16.2b.2, ruling §8: a diagnostic points at the facade clause that
// states the fact): a warning names the line it is about under `run` and
// `build` exactly as under `check`. The backend and the MIR-phase Sema took
// the root file's text out of the compilation (a move, not a copy), so the
// warnings printed after a build rendered against an empty file, at 1:1.
// One facade warning (§16.2b.11 presentation ambiguity) and one ordinary
// Sema warning (a loop concatenation). The core prelude keeps the case off
// the std.re corpus, which the case directory's own project cannot see from
// a compiler that does not embed it.
fn check_located(case_dir: &str, command: &str):
    let r = p7_run(case_dir, "warning-location-" ++ command, command ++ "\0--prelude=core\0main.w\0")
    p7_assert_success(r, "with " ++ command)
    let located = r.stderr.contains(" --> main.w:12:5\n12 |     fn db_get") and r.stderr.contains(" --> main.w:18:9\n18 |         acc = \"x\" ++ acc") and not r.stderr.contains("main.w:1:1")
    if not located:
        print(f"FAILED [with {command}]: warnings not at their lines\n" ++ r.stderr)
    assert(located)

fn main:
    let case_dir = p7_prepare_case("warning_location_run_build", "warnloc")
    p7_write(case_dir, "main.w", "use c_import(\"typedef struct db db;
db* db_new(int n);
void db_close(db* d);
int db_get(db* d);
int get(db* d);
\")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_get
    fn get

fn main:
    var acc = \"\"
    for i in 0..3:
        acc = \"x\" ++ acc
    print(acc)
")
    check_located(case_dir, "check")
    check_located(case_dir, "run")
    check_located(case_dir, "build")
    print("ok")
