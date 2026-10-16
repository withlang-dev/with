//! check-only
// A function-like macro whose translation calls a raw function is an
// `unsafe fn`; a macro that calls that macro is one too (libxml2's
// `IS_EXTENDER(c)` is `xmlIsExtenderQ(c)`, whose body calls
// `xmlCharInRange`). Before, the second was emitted as a plain `fn` whose
// body did not check, and the header could not be imported at all.
use c_import("int in_range(unsigned int c, const void *group);\nextern const int ext_group;\n#define is_ext_q(c) in_range((c), &ext_group)\n#define IS_EXT(c) is_ext_q(c)\n")
fn main:
    let c: c_uint = 0xb7
    let yes = unsafe { IS_EXT(c) }
    if yes != 0: print("extender")
