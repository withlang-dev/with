//! expect-stdout: ok

use pre_d_build_runner

// D51 stage 5: a producer the renderer does not give a constructor says so
// at its resource, and the program still checks. A producer that receives a
// resource's representation, or a resource that `borrows`, produces a
// dependent resource (spec §16.2b.6: unknown independence means dependency);
// a constructor that dropped the dependency could outlive its parent, and
// dependency is modeled by the plan's stage 6. Every other producer has its
// constructor — `Database.db_new`, and `Database.db_open`, whose `ok`
// projection is `Result[Database, DatabaseError]` — and draws no warning;
// the positional reason prints the resolved C parameter (§57).
fn main:
    let case_dir = p7_prepare_case("c_facade_pending_producer_warns", "pendwarn")
    p7_write(case_dir, "main.w", "use c_import(\"typedef struct db db;
typedef struct st st;
typedef struct tk tk;
#define DB_OK 0
db* db_new(int flags);
int db_open(const char* path, db** out);
void db_close(db* d);
st* st_new(db* d, int n);
int st_open(db* d, st** out);
void st_free(st* s);
tk* tk_new(const char* text);
void tk_free(tk* t);
\")

c facade dep:
    resource Database wraps *mut db
        from db_new
        from db_open(out param 1)
        drop db_close
        ok DB_OK
    resource Statement wraps *mut st
        from st_new
        from st_open(out param 1)
        drop st_free
    resource Tokens wraps *mut tk
        from tk_new
        drop tk_free
        borrows param 0

fn main:
    let d = Database.db_new(0)
    print(\"ok\")
")
    let checked = p7_run(case_dir, "pending-warn", "check\0main.w\0")
    p7_assert_success(checked, "with check")
    assert(checked.stderr.contains("resource 'Statement': no constructor is rendered for producer 'st_new': it receives a resource's representation (param 0: *mut db d), so what it produces depends on it"))
    assert(checked.stderr.contains("resource 'Statement': no constructor is rendered for producer 'st_open': it receives a resource's representation (param 0: *mut db d)"))
    assert(checked.stderr.contains("resource 'Tokens': no constructor is rendered for producer 'tk_new': the resource borrows from param 0: *const i8 text"))
    assert(not checked.stderr.contains("producer 'db_open'"))
    assert(not checked.stderr.contains("producer 'db_new'"))
    print("ok")
