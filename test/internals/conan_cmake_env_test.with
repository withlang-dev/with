//! expect-stdout: ok
use compiler.ConanClient

// `WITH_GET_CMAKE_<PACKAGE>` carries CMake cache variables into a C package's
// source build (#1375: the darwin release lane builds raylib on its software
// rasterizer with PLATFORM=RGFW;OPENGL_VERSION=Software).
fn main:
    assert(conan_package_cmake_env_name("raylib") == "WITH_GET_CMAKE_RAYLIB")
    assert(conan_package_cmake_env_name("json-c") == "WITH_GET_CMAKE_JSON_C")
    assert(conan_package_cmake_env_name("sqlite3") == "WITH_GET_CMAKE_SQLITE3")
    let parsed = conan_cmake_env_parse("PLATFORM=RGFW; OPENGL_VERSION=Software ;")
    assert(parsed.problem == "")
    assert(parsed.defines.len() == 2)
    assert(parsed.defines[0] == "-DPLATFORM=RGFW")
    assert(parsed.defines[1] == "-DOPENGL_VERSION=Software")
    // A value may hold `=`: the first one splits.
    let flags = conan_cmake_env_parse("CMAKE_C_FLAGS=-DX=1")
    assert(flags.defines[0] == "-DCMAKE_C_FLAGS=-DX=1")
    let empty = conan_cmake_env_parse("")
    assert(empty.defines.len() == 0 and empty.problem == "")
    // An entry that is not NAME=VALUE is named, and nothing is passed.
    let bad = conan_cmake_env_parse("PLATFORM=RGFW;Software")
    assert(bad.problem == "Software")
    assert(bad.defines.len() == 0)
    assert(conan_cmake_env_parse("=x").problem == "=x")
    print("ok")
