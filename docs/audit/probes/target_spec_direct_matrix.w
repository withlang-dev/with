use TargetSpec

fn expect_target(kind: i32, os_name: &str, arch_name: &str, triple: &str, name: &str, native: bool, cross_supported: bool):
    target_spec_set_active(kind)
    assert(target_spec_active_kind() == kind)
    assert(target_spec_os() == os_name)
    assert(target_spec_arch() == arch_name)
    assert(target_spec_llvm_triple() == triple)
    assert(target_spec_name() == name)
    assert(target_spec_is_native() == native)
    assert(target_spec_cross_supported(kind) == cross_supported)

fn main:
    assert(target_spec_host_kind() == 1)
    expect_target(0, "Linux", "x86_64", "", "native", true, false)
    expect_target(1, "Linux", "x86_64", "x86_64-unknown-linux-gnu", "linux_x86_64", true, true)
    expect_target(2, "Linux", "aarch64", "aarch64-unknown-linux-gnu", "linux_aarch64", false, true)
    expect_target(3, "Macos", "x86_64", "x86_64-apple-macosx11.0.0", "darwin_x86_64", false, false)
    expect_target(4, "Macos", "aarch64", "arm64-apple-macosx11.0.0", "darwin_aarch64", false, false)
    expect_target(5, "Windows", "x86_64", "x86_64-pc-windows-msvc", "windows_x86_64", false, true)
    expect_target(6, "Windows", "aarch64", "aarch64-pc-windows-msvc", "windows_aarch64", false, true)
    assert(not target_spec_cross_supported(-1))
    assert(not target_spec_cross_supported(0))
    assert(not target_spec_cross_supported(3))
    assert(not target_spec_cross_supported(4))
    assert(not target_spec_cross_supported(7))
    target_spec_set_active(0)
    print("target-spec-direct-matrix: ok")
