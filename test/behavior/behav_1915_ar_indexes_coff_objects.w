//! expect-stdout: ok

// #1915: `with __ar`, the archiver a `with get` source build runs, indexed
// ELF and Mach-O members only. On Windows the members are COFF objects, the
// archive carried no symbol index, and the package's own tool failed to link
// against it ("undefined symbol: BZ2_bzlibVersion" from libbz2.a). A COFF
// object's external definitions are now indexed, GNU-style, as lld reads.

use pre_d_build_runner
use std.fs

fn main:
    let case_dir = p7_prepare_case("ar_indexes_coff_objects", "arcoff")
    p7_write(case_dir, "src/lib.w", "pub fn arcoff_exported_marker() -> i32: 7\n\nfn main:\n    print(f\"{arcoff_exported_marker()}\")\n")
    let obj = p7_run(case_dir, "arcoff_obj", "build\0src/lib.w\0--target=windows_x86_64\0--emit-obj\0-o\0lib.obj\0")
    p7_assert_success(obj, "windows_x86_64 object")
    let ar = p7_run(case_dir, "arcoff_ar", "__ar\0qc\0libarcoff.a\0lib.obj\0")
    p7_assert_success(ar, "__ar of a COFF object")
    let archive = read_file(p7_join(case_dir, "libarcoff.a")) ?? panic("no archive")
    // The GNU symbol table is the first member, named "/".
    assert(archive.starts_with("!<arch>\n/ "))
    var index_end = 8 + 60
    let table = archive.slice(index_end as i64, archive.len())
    assert(table.contains("arcoff_exported_marker"))
    print("ok")
