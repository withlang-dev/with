// std.os — Layer 1 platform wrapper boundary.
//
// This module intentionally stays thin. It presents safe wrappers around the
// compiler-owned platform ABI that backs libc/POSIX/Win32 operations. Ordinary
// application code should prefer layer-2 modules such as std.fs, std.process,
// and std.sysinfo.

use c_import("int getpid(void); int isatty(int);")

extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str
extern fn with_sysinfo_hostname() -> str
extern fn with_getpid() -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_setenv_str(name: str, value: str) -> i32
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_str_len(s: str) -> i64

pub enum OsKind: i32:
    Macos
    Linux
    Windows
    Unknown

pub enum ArchKind: i32:
    Armv8
    X86_64
    Unknown

/// Return the host operating system name reported by the platform layer.
pub fn os() -> str:
    with_sysinfo_os()

/// Return the host operating system as a closed tag for platform switches.
pub fn os_kind() -> OsKind:
    let name = os()
    if name == "Macos":
        return OsKind.Macos
    if name == "Linux":
        return OsKind.Linux
    if name == "Windows":
        return OsKind.Windows
    OsKind.Unknown

/// Return the host CPU architecture name reported by the platform layer.
pub fn arch() -> str:
    with_sysinfo_arch()

/// Return the host CPU architecture as a closed tag for platform switches.
pub fn arch_kind() -> ArchKind:
    let name = arch()
    if name == "armv8" or name == "aarch64":
        return ArchKind.Armv8
    if name == "x86_64":
        return ArchKind.X86_64
    ArchKind.Unknown

/// Return the system hostname.
pub fn hostname() -> str:
    with_sysinfo_hostname()

/// Return the current process id.
pub fn process_id() -> i32:
    with_getpid()

/// POSIX getpid wrapper. Prefer process_id() in cross-platform code.
pub fn posix_process_id() -> i32:
    getpid()

/// POSIX isatty wrapper. Prefer layer-2 terminal APIs once available.
pub fn posix_fd_is_terminal(fd: i32) -> bool:
    isatty(fd) != 0

/// Return an environment variable, or "" when it is not set.
pub fn env(name: str) -> str:
    with_getenv_str(name)

/// Set an environment variable. Returns 0 on success.
pub fn set_env(name: str, value: str) -> i32:
    with_setenv_str(name, value)

/// True if the environment variable is present and non-empty.
pub fn has_env(name: str) -> bool:
    with_str_len(with_getenv_str(name)) > 0

/// True if a filesystem entry exists at the path.
pub fn path_exists(path: str) -> bool:
    with_fs_file_exists(path) != 0
