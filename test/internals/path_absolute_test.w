//! expect-stdout: ok

use compiler.Runtime
use BuildGraphSupport
use Resolve

// One absolute-path predicate for POSIX roots, Windows drives, UNC paths and
// a drive-root-relative `\`; every "join onto the root unless absolute" and
// "reject a path that escapes the project" site reads it. The POSIX-only
// test it replaces made every drive path "relative" on Windows: the
// with.toml walk lost [build] settings (#1082) and a test target's
// `compiler=C:/...` was joined onto the project root and could not spawn.

fn main:
    // Absolute.
    assert(runtime_path_is_absolute("/"))
    assert(runtime_path_is_absolute("/usr/bin"))
    assert(runtime_path_is_absolute("C:/src/with"))
    assert(runtime_path_is_absolute("c:\\src\\with"))
    assert(runtime_path_is_absolute("D:/"))
    assert(runtime_path_is_absolute("\\\\server\\share\\x"))
    assert(runtime_path_is_absolute("//server/share"))
    assert(runtime_path_is_absolute("\\Windows"))
    // Relative.
    assert(not runtime_path_is_absolute(""))
    assert(not runtime_path_is_absolute("src/main.w"))
    assert(not runtime_path_is_absolute("C:"))
    assert(not runtime_path_is_absolute("C:src"))
    assert(not runtime_path_is_absolute("1:/x"))
    assert(not runtime_path_is_absolute("./out"))
    assert(not runtime_path_is_absolute("..\\out"))

    // What a normalizer keeps in front of `..`, and the prefix it writes back.
    assert(runtime_path_root_part_count("/a") == 0)
    assert(runtime_path_root_part_count("C:/a") == 1)
    assert(runtime_path_root_part_count("//srv/share/a") == 2)
    assert(runtime_path_root_part_count("a/b") == 0)
    assert(runtime_path_root_prefix("/a") == "/")
    assert(runtime_path_root_prefix("\\a") == "/")
    assert(runtime_path_root_prefix("C:/a") == "")
    assert(runtime_path_root_prefix("\\\\srv\\share") == "//")
    assert(runtime_path_root_prefix("a") == "")

    // The build graph leaves an absolute path alone and joins a relative one.
    assert(build_graph_resolve_project_path("/root", "C:/tools/with.exe") == "C:/tools/with.exe")
    assert(build_graph_resolve_project_path("/root", "/tools/with") == "/tools/with")
    assert(build_graph_resolve_project_path("/root", "out/bin/with") == "/root/out/bin/with")
    assert(not build_graph_path_project_contained("C:/elsewhere/x.w"))
    assert(not build_graph_path_project_contained("/elsewhere/x.w"))
    assert(build_graph_path_project_contained("src/x.w"))

    // Lexical normalization keeps a drive or UNC root under `..`.
    assert(resolve_canonical_module_key("C:/a/b/../c") == "C:/a/c")
    assert(resolve_canonical_module_key("C:\\a\\..\\..") == "C:")
    assert(resolve_canonical_module_key("//srv/share/x/../../..") == "//srv/share")
    assert(resolve_canonical_module_key("/a/../..") == "/")
    assert(resolve_canonical_module_key("\\x\\..\\y") == "/y")
    print("ok")
