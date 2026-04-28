//! expect-stdout: ok

// docs/mut.md Rev 8 P1 syntax smoke test.
// Exercises new surface accepted in P1 (additive; no semantic enforcement yet):
//   - `global` (stable global place) and `global var` (rebindable global)
//   - `mut self: Self` receiver-place mode tag
//   - `&raw const P` / `&raw mut P` raw-address-of forms
// Bridge phase: these forms parse and behave as their let/var/&mut self/&P
// equivalents until P11. P2 will refine raw-refs to type as *const T / *mut T.

global G_STABLE: i32 = 7
global var g_counter: i32 = 0

type Counter { value: i32 }

extend Counter:
    fn bump(mut self: Counter):
        self.value = self.value + 1

    fn read(self: &Counter) -> i32:
        self.value

fn test_globals:
    assert(G_STABLE == 7)
    g_counter = g_counter + 1
    g_counter = g_counter + 2
    assert(g_counter == 3)

fn test_mut_self_receiver:
    var c = Counter { value: 0 }
    c.bump()
    c.bump()
    c.bump()
    assert(c.read() == 3)

fn test_raw_addr_of_const:
    let x: i32 = 5
    // §13 — `&raw const x` produces *const i32. Forming is safe;
    // dereferencing requires unsafe.
    let p: *const i32 = &raw const x
    let v = unsafe *p
    assert(v == 5)

fn test_raw_addr_of_mut:
    var y: i32 = 7
    // §13 — `&raw mut y` produces *mut i32. Forming is safe;
    // dereferencing/writing requires unsafe.
    let q: *mut i32 = &raw mut y
    let w = unsafe *q
    assert(w == 7)
    unsafe *q = 11
    assert(y == 11)

fn main:
    test_globals()
    test_mut_self_receiver()
    test_raw_addr_of_const()
    test_raw_addr_of_mut()
    print("ok")
