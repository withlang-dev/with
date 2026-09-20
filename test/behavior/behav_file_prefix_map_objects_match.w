//! skip-on: windows issue #800: action/capability/net/process/fs OS-surface fails on native Windows
//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.process

// WITH_FILE_PREFIX_MAP=<from>=<to> (clang's -ffile-prefix-map): the same
// sources compile to the same bytes from every directory. A module's private
// symbols are named `__with_mod_<hash of its path>__`, and the DWARF compile
// unit names the root, so two checkouts of one tree used to give two
// different objects, and nothing built in one worktree could be shared with
// another. Mapped, the objects are identical; unmapped, they differ, which is
// what makes the first half mean something.
fn build_object(case_dir: &str, label: &str, mapped: bool) -> str:
    p7_write(case_dir, "src/helper.w", "pub fn triple(x: i32) -> i32: x * 3\nfn hidden(x: i32) -> i32: x + 1\npub fn bump(x: i32) -> i32: hidden(x)\n")
    p7_write(case_dir, "src/main.w", "use helper\nfn local_only(x: i32) -> i32: x - 2\nfn main:\n    print(f\"{bump(triple(local_only(9)))}\")\n")
    var mapping = ""
    if mapped: mapping = case_dir ++ "=/with-src"
    assert(set_env("WITH_FILE_PREFIX_MAP", mapping) == 0)
    let built = p7_run(case_dir, label, "build\0src/helper.w\0--emit-obj\0-o\0out/helper.o\0")
    p7_assert_success(built, label)
    read_file(p7_join(case_dir, "out/helper.o")).unwrap()

fn main:
    let previous = env("WITH_FILE_PREFIX_MAP").clone()
    let first = p7_prepare_case("file_prefix_map_first", "prefixmap")
    let second = p7_prepare_case("file_prefix_map_second_longer_name", "prefixmap")

    let mapped_first = build_object(first, "prefix_map_first", true)
    let mapped_second = build_object(second, "prefix_map_second", true)
    assert(mapped_first.len() > 0)
    assert(mapped_first == mapped_second)
    assert(not mapped_first.contains("file_prefix_map_first"))

    let plain_first = build_object(first, "prefix_plain_first", false)
    let plain_second = build_object(second, "prefix_plain_second", false)
    assert(plain_first != plain_second)

    assert(set_env("WITH_FILE_PREFIX_MAP", previous) == 0)
    print("ok")
