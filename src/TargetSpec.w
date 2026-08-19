// TargetSpec — the single source of truth for the active build target.
//
// `--target <triple>` (§18.5) selects a target kind: the same 0-6
// numbering `std.build.BuildTarget` and `driver_target_triple_kind`
// use (0 native, 1 linux_x86_64, 2 linux_aarch64, 3 darwin_x86_64,
// 4 darwin_aarch64, 5 windows_x86_64, 6 windows_aarch64). The driver records the active
// kind once per compile; parse-time @[target] guards, comptime
// sysinfo, codegen C-ABI decisions, and the link stage read the
// resolved target from here instead of querying host sysinfo.
// Kind 0 ("native") resolves to the host, so a native build behaves
// exactly as before this module existed.

extern fn with_sysinfo_os() -> str
extern fn with_sysinfo_arch() -> str

var target_spec_active: i32 = 0

pub fn target_spec_set_active(kind: i32) -> Unit:
    target_spec_active = kind

pub fn target_spec_active_kind() -> i32:
    target_spec_active

pub fn target_spec_is_native() -> bool:
    if target_spec_active == 0:
        return true
    target_spec_active == target_spec_host_kind()

// Host kind in the shared 0-5 numbering. Mirrors
// build_graph_host_target_kind (BuildGraphKinds.w); kept extern-only
// here so TargetSpec stays import-free for early pipeline stages.
pub fn target_spec_host_kind() -> i32:
    let os = with_sysinfo_os()
    let arch = with_sysinfo_arch()
    if os == "Macos":
        if arch == "armv8" or arch == "aarch64":
            return 4
        if arch == "x86_64":
            return 3
    if os == "Linux":
        if arch == "armv8" or arch == "aarch64":
            return 2
        if arch == "x86_64":
            return 1
    if os == "Windows":
        if arch == "armv8" or arch == "aarch64":
            return 6
        if arch == "x86_64":
            return 5
    0

// Resolved target OS in host-sysinfo spelling: "Macos"/"Linux"/"Windows".
pub fn target_spec_os() -> str:
    let kind = target_spec_active
    if kind == 1 or kind == 2:
        return "Linux"
    if kind == 3 or kind == 4:
        return "Macos"
    if kind == 5 or kind == 6:
        return "Windows"
    with_sysinfo_os()

// Resolved target arch. Cross targets use the canonical spelling
// ("x86_64"/"aarch64"); native returns the host sysinfo spelling
// unchanged (e.g. "armv8") so native behavior is byte-identical to
// the pre-TargetSpec compiler.
pub fn target_spec_arch() -> str:
    let kind = target_spec_active
    if kind == 1 or kind == 3 or kind == 5:
        return "x86_64"
    if kind == 2 or kind == 4 or kind == 6:
        return "aarch64"
    with_sysinfo_arch()

// LLVM triple for the active target; "" means "use the host default"
// (llvm_object_triple keeps its historical host behavior for that).
pub fn target_spec_llvm_triple() -> str:
    let kind = target_spec_active
    if kind == 1:
        return "x86_64-unknown-linux-gnu"
    if kind == 2:
        return "aarch64-unknown-linux-gnu"
    if kind == 3:
        return "x86_64-apple-macosx11.0.0"
    if kind == 4:
        return "arm64-apple-macosx11.0.0"
    if kind == 5:
        return "x86_64-pc-windows-msvc"
    if kind == 6:
        return "aarch64-pc-windows-msvc"
    ""

// Display name in the build_graph_target_name spelling.
pub fn target_spec_name() -> str:
    let kind = target_spec_active
    if kind == 1:
        return "linux_x86_64"
    if kind == 2:
        return "linux_aarch64"
    if kind == 3:
        return "darwin_x86_64"
    if kind == 4:
        return "darwin_aarch64"
    if kind == 5:
        return "windows_x86_64"
    if kind == 6:
        return "windows_aarch64"
    "native"

// The non-native targets this compiler can actually produce code and
// binaries for today. Gate is checked by the driver; anything else
// non-native must fail loudly (§18.5: never fall back to native).
pub fn target_spec_cross_supported(kind: i32) -> bool:
    kind == 1 or kind == 2 or kind == 5 or kind == 6
