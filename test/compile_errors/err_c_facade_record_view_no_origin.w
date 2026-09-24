//! expect-check-fail: fn 'rec_of': 'returns borrow rec from param 0' names param 0: i32 age, which receives no modeled resource; a borrowed record is a view of the resource its origin parameter receives, or of a domain ('from domain <name>') — With does not invent an origin (§16.2b.6, §16.2b.7)

// D66 (spec §16.2b.7): "Borrowed foreign memory always has a real origin
// … With does not invent a lifetime".
use c_import("../behavior/c_facade_record.h")

c facade records:
    fn rec_of
        returns borrow rec from param 0

fn main:
    print("unreached")
