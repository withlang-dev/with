// T8 interning identity + T23 duplicates/empty/OOB.
use compiler.foundation.Ids
use compiler.foundation.InternPool

extern fn with_print_str(s: &str) -> Unit

fn main:
    var p = InternPool.init()
    let x1 = p.intern_str("alpha")
    let x2 = p.intern_str("alpha")
    let y = p.intern_str("beta")
    unsafe { with_print_str(f"x1={symbol_raw(x1)} x2={symbol_raw(x2)} same={x1 == x2} y={symbol_raw(y)} distinct={x1 != y}\n") }
    unsafe { with_print_str(f"resolve_x=[{p.resolve_symbol(x1)}] count={p.symbol_count()}\n") }
    // duplicate intern does not grow the pool
    let c0 = p.symbol_count()
    let x3 = p.intern_str("alpha")
    unsafe { with_print_str(f"dup_stable={c0 == p.symbol_count()} x3={symbol_raw(x3)}\n") }
    // empty string edge
    let e = p.intern_str("")
    unsafe { with_print_str(f"empty_raw={symbol_raw(e)} resolve_empty=[{p.resolve_symbol(e)}] count_after_empty={p.symbol_count()}\n") }
    // OOB / invalid resolve directions
    unsafe { with_print_str(f"resolveNeg1=[{p.resolve_symbol(symbol_invalid())}] resolveOOB=[{p.resolve_symbol(symbol_from_raw(9999))}] resolve0=[{p.resolve_symbol(symbol_from_raw(0))}]\n") }
    // copy shares state (heap-indirected handle)
    var q = p
    let z = q.intern_str("gamma")
    unsafe { with_print_str(f"copy_shared={p.resolve_symbol(z) == q.resolve_symbol(z)} count_p={p.symbol_count()} count_q={q.symbol_count()}\n") }
