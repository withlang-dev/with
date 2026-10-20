//! expect-stdout: ok

use compiler.BundleInterfaces

// D30 R3: the runtime is a bundle whose corpus is the embedded runtime tree,
// `rt` naming `<embedded-rt>/rt`, as a migrated corpus's `std/re` names
// `<embedded-std>/std/re`; a runtime module's dotted name is `rt.<module>`.
fn main:
    assert(bundle_corpus_contains("rt", "<embedded-rt>/rt/rt_core.w"))
    assert(bundle_corpus_contains("rt", "<embedded-rt>/rt/fiber_core_darwin.w"))
    assert(not bundle_corpus_contains("rt", "<embedded-std>/std/rt.w"))
    assert(not bundle_corpus_contains("rt", "rt/rt_core.w"))
    assert(bundle_corpus_contains("std/re", "<embedded-std>/std/re/defs.w"))
    assert(not bundle_corpus_contains("std/re", "<embedded-rt>/rt/rt_core.w"))
    assert(bundle_module_dotted_name("<embedded-rt>/rt/rt_core.w") == "rt.rt_core")
    assert(bundle_module_dotted_name("<embedded-std>/std/re/defs.w") == "std.re.defs")
    assert(bundle_module_dotted_name("src/main.w") == "")
    print("ok")
