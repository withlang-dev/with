//! expect-check-stdout: ok

// D51 §16.2b.3 stage 4a: a facade's resources are rendered as ordinary With
// — `type R { repr, live }`, `impl Drop for R` calling the `drop` operation,
// each `destroys` operation as a `move fn` method, and a direct-return
// producer as the safe constructor `R.<producer>`, a lend of the pointer
// representation as a `&self` method — over prototype-only C,
// so this test only checks (phase lane). Nothing here is `unsafe`.

use c_import("typedef struct db db;
typedef struct { int a; } Tok;
db* db_new(int flags);
void db_close(db* d);
int db_close_v2(db* d, int how);
int db_count(db* d);
Tok tok_load(const char* path);
void tok_unload(Tok t);
")

c facade dbl:
    resource Database wraps *mut db
        from db_new
        drop db_close
        destroys db_close_v2
    resource Texture wraps Tok
        from tok_load
        drop tok_unload
    fn db_count
        lend
    fn db_close_v2
        destroys

fn main:
    let d = Database.new(3).unwrap()
    let n = d.count()
    let status = d.close_v2(n)
    let t = Texture.load("a.png")
    let held: Vec[Texture] = Vec.new()
    held.push(t)
    print(f"{status}")
