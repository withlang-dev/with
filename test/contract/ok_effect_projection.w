//! expect-contract: violations=0 ok
//! expect-contract-not: #1674

// #1674 (ruling §63, spec §16.2b.14): every view invalidation a rendered
// call carries names one of that call's own parameters, and one holding a
// modeled resource. Two projections are checked: a byte buffer's length
// leaves `touch(values, count, owner)` presented as `touch(values, owner)`,
// so the owner's C bit 2 is presented bit 1; and a producer rendered on its
// parent loses its out slot, so `st_new(d, out, flags, o)` presented as
// `d.st_new(flags, o)` touches its self (bit 0) and `o` (bit 2). The audit
// printed `ok` over both when the rendered masks kept the C indices.
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
int touch(const unsigned char *values, int count, other *o);
")

c facade proj:
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
    fn touch
        buffer param values len param count

fn main:
    let d = Database.new().unwrap()
    let o = Other.new().unwrap()
    let values: [u8; 2] = [1, 2]
    let _ = touch(values, o)
    let s = d.st_new(1, o)
    let v = o.view().unwrap()
    print(f"{v.n}")
