//! expect-stdout: ok
use compiler.ConanClient

// sdl/3.4.14's Linux binary requires egl/system and libudev/system, and its
// pulseaudio requires flac pinned by recipe revision and package id. `with get
// c.sdl` failed on both: no binary exists for a system recipe, and the pin was
// read as part of the version.
fn main:
    assert(conan_ref_version("zlib/1.3.Z") == "1.3.Z")
    assert(conan_ref_version("egl/system") == "system")
    assert(conan_ref_version("pkg/1.0@user/channel") == "1.0")
    assert(conan_ref_version("flac/1.4.2#a903f1a261e796e4a1061fdfd48927a3:1b252067c54dbd5ce363a3b7c47740b75476f478") == "1.4.2")
    assert(conan_ref_version("flac/1.4.2:1b252067c54d") == "1.4.2")
    assert(conan_ref_version("noversion") == "")
    assert(conan_system_package_lib("egl") == "EGL")
    assert(conan_system_package_lib("libudev") == "udev")
    assert(conan_system_package_lib("zlib") == "")
    print("ok")
