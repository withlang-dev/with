//! expect-stdout: hosted: 3 5
//! expect-stdout: after age: 5
//! expect-stdout: none: true
//! expect-stdout: c locale: 127
//! expect-stdout: ok
//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows

// D66 (spec §16.2b.6): `returns borrow T from param N` / `from domain D`
// for an imported record T presents `Option[&T]`, a view whose lifetime is
// its origin's: `hold_rec` lends the record the hold owns (NULL is None),
// readable through its scalar fields and kept inside the hold's life;
// `hold_age` states `preserves param 0`, so the view survives it (the
// refused spellings are err_c_facade_record_view_invalidated_by_lend and
// err_c_facade_record_view_outlives_origin). `localeconv` returns a pointer
// into a process-wide record — a foreign-state domain, never `static`
// (§16.2b.7): the view is borrowed from the domain and dies at the next
// operation of the library (err_c_facade_record_view_invalidated_by_domain).
// A pointer field (`decimal_point`, `version`) stays a raw pointer
// (err_c_facade_record_pointer_field_unsafe). In the "C" locale
// int_frac_digits is CHAR_MAX.

use c_import("c_facade_record.h")

c facade records:
    domain locale process
    resource Hold wraps *mut hold
        from hold_new
        drop hold_free
    fn hold_rec
        returns borrow rec from param 0
    fn hold_bump
        lend
    fn hold_age
        lend
        preserves param 0
    fn localeconv
        returns borrow lconv from domain locale

fn main:
    let h = Hold.new(3).unwrap()
    let r = h.rec().unwrap()
    print(f"hosted: {r.age} {r.version_num}")
    let age = h.age()
    print(f"after age: {r.version_num}")
    let none = Hold.new(-1).unwrap()
    print(f"none: {none.rec().is_none()}")
    let lc = localeconv().unwrap()
    print(f"c locale: {lc.int_frac_digits as i32}")
    print("ok")
