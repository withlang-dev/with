//! skip: non-executable spec sketch for Section 18.7 — Freestanding Mode (formerly 25.99); contains pseudo-code for unimplemented feature work
// Spec test: Section 18.7 — Freestanding Mode (formerly 25.99)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: core types available in no_std
// @[cfg(no_std)]
fn test:
    let x: i32 = 42
    let y: bool = true
    let opt: Option[i32] = Some(10)
    let arr: [u8; 4] = [1, 2, 3, 4]
    assert(opt.unwrap() == 10)

// PASS: c_import works in no_std
// @[cfg(no_std)]
fn test:
    use c_import("stdint.h")
    let x: u32 = 0xFF

// PASS: match and ownership work in no_std
// @[cfg(no_std)]
fn test:
    enum Command { Reset | Set(u8) | Get }
    let cmd = Command.Set(42)
    match cmd:
        .Set(val) => assert(val == 42)
        _ => panic("wrong variant")

// FAIL: Vec requires std or alloc
// @[cfg(no_std)]
fn test:
    let v = Vec.new()     // ERROR: Vec requires alloc

// FAIL: print requires std
// @[cfg(no_std)]
fn test:
    print("hello")      // ERROR: print requires std (stdout)

// FAIL: str literal is &str in no_std (no allocator for owned str)
// @[cfg(no_std)]
fn test:
    let s = "hello"       // s: &str (not str) in no_std
    let owned: str = "x"  // ERROR: str requires alloc

// PASS: &str works in no_std
// @[cfg(no_std)]
fn test:
    let s: &str = "hello"
    assert(s.len() == 5)

// PASS: alloc tier gives back Vec and str
// @[cfg(no_std, alloc)]
fn test:
    let v = Vec.from([1, 2, 3])
    let s = "hello"       // s: str (owned, allocator available)
    assert(v.len() == 3)

// FAIL: missing panic handler in no_std
// @[cfg(no_std)]
// ERROR: no_std requires @[panic_handler]
