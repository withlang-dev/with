use std.sysinfo

fn valid_os(s: str) -> bool:
    s == "Macos" or s == "Linux" or s == "Windows"

fn valid_arch(s: str) -> bool:
    s == "armv8" or s == "x86_64"

fn main:
    let os_name = os()
    let arch_name = arch()
    let host = hostname()
    assert(valid_os(os_name), "unexpected sysinfo.os(): " ++ os_name)
    assert(valid_arch(arch_name), "unexpected sysinfo.arch(): " ++ arch_name)
    assert(host.len() > 0, "hostname should not be empty")
