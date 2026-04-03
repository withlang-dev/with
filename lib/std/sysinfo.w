// std.sysinfo — System information (OS, architecture, hostname)
//
// Pure With module backed by runtime exports.
// No direct external dependencies.

extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str
extern fn with_sysinfo_hostname() -> str

// Returns the operating system name.
// "Macos" on macOS, "Linux" on Linux, "Windows" on Windows.
pub fn os() -> str:
    with_sysinfo_os()

// Returns the CPU architecture.
// "armv8" on Apple Silicon/ARM64, "x86_64" on Intel/AMD 64-bit.
pub fn arch() -> str:
    with_sysinfo_arch()

// Returns the system hostname.
pub fn hostname() -> str:
    with_sysinfo_hostname()
