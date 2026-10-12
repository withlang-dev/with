//! expect-stdout: 7

// Emit-C must declare a struct type reached only as a List element: the
// emitted C names it in the element-access cast (`(*((Entry*)
// with_vec_get_ptr_es(...)))`) and in `sizeof(Entry)`. The struct-type
// collector descended into fixed arrays but returned early for
// List/HashMap/HashSet, so a type no local, parameter, or field carries
// directly was never declared and the emitted C did not compile
// ("use of undeclared identifier"). D119's migrator rule made this the
// common shape: a C local array of records is a List fill whose element
// type may appear nowhere else (pcre2's `recurse_cache`, reached only
// through a `[recurse_cache.zeroed(); 8]` hoisted local, in the
// battery's emit-c-smoke).

use std.collections

type Entry { key: i64 = 0, val: i64 = 0 }

fn first_key(entries: &List[Entry]) -> i64:
    if entries.len() == 0: return 7
    entries[0].key

fn main:
    let entries: List[Entry] = []
    print(f"{first_key(&entries)}")
