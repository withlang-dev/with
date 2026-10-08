//! expect-debug-alloc: leak count=0
//! expect-stdout: -1 5 -1 7 -1 9 -1 11
//! expect-stdout: drops 5
//! expect-stdout: ok

// #1750 (§9.7, §2.4): the success path of `let PAT = subject else` keeps the
// subject's cleanup: bound parts belong to the bindings, what the pattern
// ignores is dropped, and each owned value is released exactly once on each
// path. W counts its drops; each case runs its failing path (an `Err`/`None`
// whose W, if any, drops before the else diverges) and its success path.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8)

type W { ptr: *mut u8, drops: *mut i32, n: i32 }

impl Drop for W:
    move fn drop():
        unsafe:
            with_free(self.ptr)
            *self.drops = *self.drops + 1

fn new_w(drops: *mut i32, n: i32) -> W:
    unsafe { W { ptr: with_alloc(24), drops, n } }

fn copy_or(k: i32) -> Result[i32, str]:
    if k == 0: return Err("none")
    k

fn w_or(drops: *mut i32, k: i32) -> Result[W, W]:
    if k == 0: return Err(new_w(drops, 0))
    Ok(new_w(drops, k))

fn pair_or(drops: *mut i32, k: i32) -> Option[(W, i32)]:
    if k == 0: return None
    Some((new_w(drops, 100), k))

// Copy payload: nothing owned on the success variant.
fn copy_payload(k: i32) -> i32:
    let Ok(v) = copy_or(k) else: return -1
    v

// Owned payload: the binding owns it and drops it at scope exit.
fn owned_payload(drops: *mut i32, k: i32) -> i32:
    let Ok(w) = w_or(drops, k) else: return -1
    w.n

// Ignored owned part: `_` drops the W; the i32 is bound.
fn ignored_part(drops: *mut i32, k: i32) -> i32:
    let Some((_, n)) = pair_or(drops, k) else: return -1
    n

// Named subject: the local is the subject.
fn named(drops: *mut i32, k: i32) -> i32:
    let r = w_or(drops, k)
    let Ok(w) = r else: return -1
    w.n

fn main:
    var drops = 0
    let d = &raw mut drops
    print(f"{copy_payload(0)} {copy_payload(5)} {owned_payload(d, 0)} {owned_payload(d, 7)} {ignored_part(d, 0)} {ignored_part(d, 9)} {named(d, 0)} {named(d, 11)}")
    // Err(W) on owned_payload(0) and named(0); W on owned_payload(7),
    // named(11); the ignored W on ignored_part(9) — five, each once. The
    // runtime was already right (#1750 is the MIR stating it); this pins
    // that keeping the success-path drop frees nothing twice.
    print(f"drops {drops}")
    print("ok")
