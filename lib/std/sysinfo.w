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
// "aarch64" on ARM64, "x86_64" on Intel/AMD 64-bit. One spelling per
// architecture on every platform -- notably "aarch64" on Apple Silicon
// too, matching the target kinds (darwin_aarch64), the runtime sources
// (rt/darwin_aarch64.w) and the published asset names.
pub fn arch() -> str:
    with_sysinfo_arch()

// Returns the system hostname.
pub fn hostname() -> str:
    with_sysinfo_hostname()
