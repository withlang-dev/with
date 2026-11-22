//! expect-stdout: ok
// #1166: a UAT `platforms:` entry is an OS, an architecture, or an
// os-arch pair — the test gates' forms — so libcurl.uat can name
// linux-x86_64 without giving up linux everywhere else it works.
use Uat
use TargetSpec

fn main:
    let os = uat_host_platform()
    let arch = target_spec_arch()
    assert(uat_platform_matches(os) == 1)
    assert(uat_platform_matches(arch) == 1)
    assert(uat_platform_matches(os ++ "-" ++ arch) == 1)
    let other_os = if os == "linux": "darwin" else: "linux"
    assert(uat_platform_matches(other_os) == 0)
    assert(uat_platform_matches(other_os ++ "-" ++ arch) == 0)
    let other_arch = if arch == "aarch64" or arch == "arm64": "x86_64" else: "aarch64"
    assert(uat_platform_matches(other_arch) == 0)
    assert(uat_platform_matches(os ++ "-" ++ other_arch) == 0)
    assert(uat_platform_matches("plan9") == -1)
    assert(uat_platform_matches("linux-ppc") == -1)
    print("ok")
