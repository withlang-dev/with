//! expect-stdout: ok

use pre_d_build_runner

// D51 stage 8 (ruling §55, spec §16.2b.11): an ambiguous presentation
// omits the sugar and says so. `db_get` would shorten to `get`, the
// imported name of another lend of the same resource; `db_drop` to
// `drop`, the resource's Drop. Each keeps its imported name, and the
// warning names the candidates and the `rename` that settles it. The
// program itself is behav_c_facade_presentation_ambiguous.w.
fn main:
    let case_dir = p7_prepare_case("c_facade_presentation_ambiguous_warns", "presamb")
    p7_write(case_dir, "main.w", "use c_import(\"typedef struct db db;
db* db_new(int n);
void db_close(db* d);
int db_get(db* d);
int get(db* d);
int db_drop(db* d);
int db_count(db* d);
\")

c facade dbf:
    resource Database wraps *mut db
        from db_new
        drop db_close
    fn db_get
    fn get
    fn db_drop
    fn db_count

fn main:
    let d = Database.new(3).unwrap()
    print(f\"{d.db_get()} {d.get()} {d.db_drop()} {d.count()}\")
")
    let checked = p7_run(case_dir, "presentation-ambiguous", "check\0main.w\0")
    p7_assert_success(checked, "with check")
    assert(checked.stderr.contains("warning: resource 'Database': 'db_get' would be presented as 'get', the name of 'get' (a lend method); the compiler never picks, so 'db_get' keeps its imported name on 'Database' — state 'rename' on an fn item describing it to settle the spelling (§16.2b.11)"))
    assert(checked.stderr.contains("warning: resource 'Database': 'db_drop' would be presented as 'drop', the name of the resource's Drop; the compiler never picks, so 'db_drop' keeps its imported name on 'Database'"))
    assert(not checked.stderr.contains("'db_count'"))
    print("ok")
