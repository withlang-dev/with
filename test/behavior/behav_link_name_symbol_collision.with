//! expect-stdout: 42
//! expect-stdout: pid ok

// #839: a @[link_name] extern owns its C symbol even when a With fn of the
// same bare name exists (whole-program mode keeps bare names). The With fn
// moves aside in LLVM naming; both resolve correctly — the extern reaches
// the real C function, the With fn resolves by value.
fn getpid(tag: &str) -> i32: tag.len() as i32 + 41

@[link_name("getpid")]
extern fn real_getpid() -> i32

fn main:
    print(f"{getpid(\"x\")}")
    if unsafe { real_getpid() } > 0: print("pid ok")
