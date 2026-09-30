//! only-on: darwin
//! expect-stdout: ok

// Foreign libraries built by Clang call this compiler-runtime ABI for
// @available checks. Compare its result with the supported system API.
@[repr(C)]
type Version { platform: u32, version: u32 }
extern fn __isPlatformVersionAtLeast(platform: u32, major: u32, minor: u32, subminor: u32) -> i32
extern fn _availability_version_check(count: u32, versions: *const Version) -> bool

fn check_version(platform: u32, major: u32, minor: u32, subminor: u32):
    let version = Version { platform, version: ((major & 65535) << 16) | ((minor & 255) << 8) | (subminor & 255) }
    let expected = unsafe { _availability_version_check(1, &raw const version) }
    let actual = unsafe { __isPlatformVersionAtLeast(platform, major, minor, subminor) }
    assert(actual == (if expected: 1 else: 0))

fn main:
    assert(unsafe { __isPlatformVersionAtLeast(1, 11, 0, 0) } == 1)
    assert(unsafe { __isPlatformVersionAtLeast(1, 65535, 255, 255) } == 0)
    check_version(1, 10, 0, 0)
    check_version(1, 26, 0, 0)
    check_version(1, 65535, 255, 255)
    check_version(2, 17, 0, 0)
    check_version(6, 17, 0, 0)
    check_version(1, 65547, 256, 256)
    print("ok")
