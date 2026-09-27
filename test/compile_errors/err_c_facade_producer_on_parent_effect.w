//! expect-check-fail: view `v` borrows from `o`, which `st_new` may have invalidated

// #1674 (§16.2b.7, §16.2b.14): a producer rendered as a method of its parent
// (`d.st_new(flags, o)` for `st_new(db *, st **out, int, other *)`)
// invalidates views of the resources it receives, projected past the out
// slot. With an fn item describing st_new, the hosted-method pass registered
// the method's effect first, projecting only fixed, buffer and destruction
// parameters: `o` kept its C index 3 on a three-parameter method, bit 1 fell
// on `flags`, and a view of `o` survived the call. audit:contract reported
// `ok` over it until it checked each rendered effect against its signature.
use c_import("typedef struct db db;
typedef struct st st;
typedef struct Value { int n; } Value;
typedef struct other { Value v; } other;
db *db_new(void);
void db_close(db *d);
other *other_new(void);
void other_close(other *o);
const Value *other_view(other *o);
int st_new(db *d, st **out, int flags, other *o);
void st_free(st *s);
")

c facade stp:
    resource Database wraps *mut db
        from db_new
        drop db_close
    resource Other wraps *mut other
        from other_new
        drop other_close
    resource Statement wraps *mut st
        from st_new(out param out)
        drop st_free
        borrows param d
    fn st_new
        preserves param d
    fn other_view
        returns borrow Value from param 0

fn main:
    let d = Database.new().unwrap()
    let o = Other.new().unwrap()
    let v = o.view().unwrap()
    let s = d.st_new(1, o)
    print(f"{v.n}")
