//! expect-stdout: addr 8
//! expect-stdout: dropped
// #750 follow-up: std.collections declares a generic `Handle[T]` with a
// blanket `impl[T] Copy for Handle[T]`. A user's non-generic `Handle` is
// a different type: the blanket must not make it Copy (so Drop is
// allowed), and its inherent methods are not generic templates. The
// flat decl-node map keeps std's generic template after #750, so every
// "is this name generic?" query must judge the declaration the name
// denotes here, not the flat map.
type Handle {
    ptr: i64,
}

impl Handle:
    fn address -> i64:
        self.ptr + 1

impl Drop for Handle:
    move fn drop(): print("dropped")

fn main:
    let h = Handle { ptr: 7 }
    print(f"addr {h.address()}")
