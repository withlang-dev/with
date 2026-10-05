// std.os — Layer 1 platform wrapper boundary.
//
// This module intentionally stays thin. It presents safe wrappers around the
// compiler-owned platform ABI that backs libc/POSIX/Win32 operations. Ordinary
// application code should prefer layer-2 modules such as std.fs, std.process,
// and std.sysinfo.

// Compiler-owned modules never c_import: the process id and the terminal
// test come from the runtime's seams. (std.libc imports this module for
// `Target`, so the isatty seam is declared here, not imported from it.)
use std.sysinfo

extern fn with_libc_isatty(fd: i32) -> i32
extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str
extern fn with_getpid() -> i32
extern fn with_getenv_str(name: &str) -> str
extern fn with_setenv_str(name: &str, value: &str) -> i32
extern fn with_fs_file_exists(path: &str) -> i32
extern fn with_str_len(s: &str) -> i64

/// The operating systems With compiles for: one variant per target and no
/// other (§17.5, D91), so a `match` on it is checked against every target.
pub enum OsKind: i32:
    Macos
    Linux
    Windows
    Wasi

/// The architectures With compiles for: one variant per target and no other.
pub enum ArchKind: i32:
    Aarch64
    X86_64
    Wasm32
    Wasm64

/// What `Target` holds.
pub type TargetDescription { os: OsKind, arch: ArchKind }

// Compile-time code that asks the runtime for the OS or the architecture is
// answered with the `--target` value, never the host's (§17.1a: the target
// is a declared build input).
comptime fn target_os_kind() -> OsKind:
    let name = with_sysinfo_os()
    if name == "Macos": return .Macos
    if name == "Linux": return .Linux
    if name == "Windows": return .Windows
    if name == "Wasi": return .Wasi
    comptime_error("std.os: the compiler named a target OS that OsKind does not declare")

comptime fn target_arch_kind() -> ArchKind:
    let name = with_sysinfo_arch()
    if name == "aarch64": return .Aarch64
    if name == "x86_64": return .X86_64
    if name == "wasm32": return .Wasm32
    if name == "wasm64": return .Wasm64
    comptime_error("std.os: the compiler named a target architecture that ArchKind does not declare")

/// The target this program is compiled for, as compile-time constants
/// (§17.5, D91): `Target.os`, `Target.arch`. A per-target value is a
/// `comptime match Target.os:`; a `comptime if Target.os == .Windows:`
/// selects code, and the branch not taken is not compiled.
pub const Target: TargetDescription = comptime TargetDescription { os: target_os_kind(), arch: target_arch_kind() }

/// The operating system's name: `std.sysinfo`'s, the one implementation.
pub fn os() -> str: sysinfo.os()

/// The operating system this program was compiled for.
pub fn os_kind() -> OsKind: Target.os

/// The architecture's name: `std.sysinfo`'s.
pub fn arch() -> str: sysinfo.arch()

/// The architecture this program was compiled for.
pub fn arch_kind() -> ArchKind: Target.arch

/// The system hostname: `std.sysinfo`'s.
pub fn hostname() -> str: sysinfo.hostname()

/// Return the current process id.
pub fn process_id() -> i32:
    with_getpid()

/// POSIX getpid wrapper. Prefer process_id() in cross-platform code.
pub fn posix_process_id() -> i32:
    with_getpid()

/// POSIX isatty wrapper. Prefer layer-2 terminal APIs once available.
pub fn posix_fd_is_terminal(fd: i32) -> bool:
    with_libc_isatty(fd) != 0

/// Return an environment variable, or "" when it is not set.
pub fn env(name: &str) -> str:
    with_getenv_str(name)

/// Set an environment variable. Returns 0 on success.
pub fn set_env(name: &str, value: &str) -> i32:
    with_setenv_str(name, value)

/// True if the environment variable is present and non-empty.
pub fn has_env(name: &str) -> bool:
    with_str_len(with_getenv_str(name)) > 0

/// True if a filesystem entry exists at the path.
pub fn path_exists(path: &str) -> bool:
    with_fs_file_exists(path) != 0
