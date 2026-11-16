//! expect-exit: 134
//! expect-stderr: internal compiler error: BUG: codegen built a call whose target is undefined (#1119)

// #1119 (no silent fallback): every call codegen emits is built by
// `wl_build_call`, and a call with no target stops the compiler there. LLVM's
// verifier accepts `call undef(…)`; one reached a binary when a default
// method was skipped, and no audit said so.
use compiler.LlvmBridge

fn main:
    wl_build_call(0, 0, 0, 0, 0)
    print("a call with no target was built")
