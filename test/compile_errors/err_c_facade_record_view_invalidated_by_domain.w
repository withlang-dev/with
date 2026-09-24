//! expect-check-fail: view `lc` borrows from foreign-state domain `locale`, which `localeconv` may have invalidated (§16.2b.7)

// D66 (spec §16.2b.6, §16.2b.7): a record borrowed from a domain dies at
// the next operation of the library that does not preserve the domain —
// localeconv(3): "may be overwritten by subsequent calls to localeconv or
// setlocale".
use c_import("../behavior/c_facade_record.h")

c facade records:
    domain locale process
    fn localeconv
        returns borrow lconv from domain locale

fn main:
    let lc = localeconv().unwrap()
    let _ = localeconv()
    print(f"{lc.int_frac_digits as i32}")
