//! expect-stdout: ok
use compiler.ConanClient

// #1204: ConanCenter's openssl/4.0.2 listing, in its response order, cut down
// to the settings the choice reads. Matching `os` and `arch` alone took the
// msys2 clang build (libcrypto.a), which a windows-msvc link cannot use:
// "lld-link: could not open 'crypto.lib'".
fn block(id: &str, settings: &str, shared: &str) -> str:
    "  \"" ++ id ++ "\" : {\n    \"settings\" : {\n" ++ settings ++ "\n    },\n    \"options\" : {\n      \"shared\" : \"" ++ shared ++ "\"\n    },\n    \"requires\" : [ ]\n  }"

fn main:
    let win = "      \"os\" : \"Windows\",\n      \"arch\" : \"x86_64\",\n"
    let listing = "{\n" ++
        block("clang19shared", win ++ "      \"compiler\" : \"clang\",\n      \"compiler.runtime\" : \"dynamic\",\n      \"build_type\" : \"Release\"", "True") ++ ",\n" ++
        block("msys2clang", win ++ "      \"compiler\" : \"clang\",\n      \"build_type\" : \"Release\",\n      \"os.subsystem\" : \"msys2\"", "False") ++ ",\n" ++
        block("gcc15", win ++ "      \"compiler\" : \"gcc\",\n      \"build_type\" : \"Release\"", "False") ++ ",\n" ++
        block("msvcdebug", win ++ "      \"compiler\" : \"msvc\",\n      \"compiler.runtime\" : \"dynamic\",\n      \"build_type\" : \"Debug\"", "False") ++ ",\n" ++
        block("msvcrelease", win ++ "      \"compiler\" : \"msvc\",\n      \"compiler.runtime\" : \"dynamic\",\n      \"build_type\" : \"Release\"", "False") ++ ",\n" ++
        block("linuxclang", "      \"os\" : \"Linux\",\n      \"arch\" : \"x86_64\",\n      \"compiler\" : \"clang\",\n      \"build_type\" : \"Release\"", "False") ++ ",\n" ++
        block("headeronly", "      \"os\" : \"Linux\",\n      \"arch\" : \"x86_64\"", "False") ++ "\n}\n"
    let windows = conan_pick_package(listing, "Windows", "x86_64")
    assert(windows.package_id == "msvcrelease")
    assert(not windows.shared)
    // Any C compiler's Release build links on Linux; a package with no
    // build_type (header-only, or built without one) still matches.
    assert(conan_pick_package(listing, "Linux", "x86_64").package_id == "linuxclang")
    assert(conan_pick_package(listing, "Linux", "armv8").package_id == "")
    // Only a shared msvc build: take it rather than a static one we cannot link.
    let shared_only = "{\n" ++ block("msys2clang", win ++ "      \"compiler\" : \"clang\",\n      \"build_type\" : \"Release\"", "False") ++ ",\n" ++ block("msvcshared", win ++ "      \"compiler\" : \"msvc\",\n      \"build_type\" : \"Release\"", "True") ++ "\n}\n"
    let fallback = conan_pick_package(shared_only, "Windows", "x86_64")
    assert(fallback.package_id == "msvcshared")
    assert(fallback.shared)
    print("ok")
