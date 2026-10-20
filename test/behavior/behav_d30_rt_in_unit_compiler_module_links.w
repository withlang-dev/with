//! env: WITH_RT_IN_UNIT=1
//! expect-stdout: ordinary-app
//! expect-stdout: ok

// D30: a program importing the compiler's own modules takes the compiler's
// link path (lld, the LLVM bridges). With the runtime compiled in-unit that
// path still added rt_core.o, and the link refused 20 duplicate rt_*
// definitions; it links no .w-derived runtime object, as every lane link.
use BuildGraphModel
use BuildGraphSupport

fn main:
    let graph = parse_build_graph("WITH_BUILD_GRAPH\t2\npackage\tordinary-app\t0.1.0\ndefault_target\tapp\ntarget\t0\tapp\tsrc/main.w\t0\t0\tout/app\n")
    assert(graph.ok)
    print(graph.package_name)
    print("ok")
