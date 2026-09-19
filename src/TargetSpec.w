// TargetSpec — the single source of truth for the active build target.
//
// `--target <triple>` (§18.5) selects a target kind: the same 0-8
// numbering `std.build.BuildTarget` and `driver_target_triple_kind`
// use (0 native, 1 linux_x86_64, 2 linux_aarch64, 3 darwin_x86_64,
// 4 darwin_aarch64, 5 windows_x86_64, 6 windows_aarch64, 7 wasm32,
// 8 wasm64). The driver records the active
// kind once per compile; parse-time @[target] guards, comptime
// sysinfo, codegen C-ABI decisions, and the link stage read the
// resolved target from here instead of querying host sysinfo.
// Kind 0 ("native") resolves to the host, so a native build behaves
// exactly as before this module existed.
//
// wasm32/wasm64 are freestanding WebAssembly targets: no libc, the
// platform runtime (rt/wasm.w) speaks WASI preview1 to whatever host
// serves the imports (the emitted JS host, wasmtime, node:wasi). The
// two differ only in pointer width; wasm32 is the first target where
// a pointer is not 8 bytes, so layout code asks target_spec_ptr_bytes.

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

// True for both WebAssembly kinds; the wasm-specific branches in the
// link stage, the entry wrapper, and the runtime object selection key
// on this rather than on a kind number.
pub fn target_spec_is_wasm() -> bool:
    target_spec_active == 7 or target_spec_active == 8

// Bytes in a pointer on the active target. Every host today is 64-bit;
// wasm32 is the one 32-bit target.
pub fn target_spec_ptr_bytes() -> i64:
    if target_spec_active == 7: 4 else: 8

// Host kind in the shared 0-8 numbering. Mirrors
// build_graph_host_target_kind (BuildGraphKinds.w); kept extern-only
// here so TargetSpec stays import-free for early pipeline stages.
pub fn target_spec_host_kind() -> i32:
    let os = with_sysinfo_os()
    let arch = with_sysinfo_arch()
    if os == "Macos":
        if arch == "aarch64":
            return 4
        if arch == "x86_64":
            return 3
    if os == "Linux":
        if arch == "aarch64":
            return 2
        if arch == "x86_64":
            return 1
    if os == "Windows":
        if arch == "aarch64":
            return 6
        if arch == "x86_64":
            return 5
    0

// Resolved target OS in host-sysinfo spelling: "Macos"/"Linux"/"Windows"/"Wasi".
pub fn target_spec_os() -> str:
    let kind = target_spec_active
    if kind == 1 or kind == 2:
        return "Linux"
    if kind == 3 or kind == 4:
        return "Macos"
    if kind == 5 or kind == 6:
        return "Windows"
    if kind == 7 or kind == 8:
        return "Wasi"
    with_sysinfo_os()

// Resolved target arch. Cross targets and the host now share one canonical
// spelling ("x86_64"/"aarch64"/"wasm32"/"wasm64"), so a native target
// returns exactly what the host sysinfo reports.
pub fn target_spec_arch() -> str:
    let kind = target_spec_active
    if kind == 1 or kind == 3 or kind == 5:
        return "x86_64"
    if kind == 2 or kind == 4 or kind == 6:
        return "aarch64"
    if kind == 7:
        return "wasm32"
    if kind == 8:
        return "wasm64"
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
    if kind == 7:
        return "wasm32-unknown-unknown"
    if kind == 8:
        return "wasm64-unknown-unknown"
    ""

// Display name in the build_graph_target_name spelling.
// The active target's name; "native" for kind 0 (a native build names no
// platform). A .wo bundle is keyed by the platform it was compiled for, so
// its manifest and fingerprint spell the resolved name instead.
pub fn target_spec_name() -> str:
    target_spec_kind_name(target_spec_active)

pub fn target_spec_resolved_name() -> str:
    target_spec_kind_name(if target_spec_active == 0: target_spec_host_kind() else: target_spec_active)

fn target_spec_kind_name(kind: i32) -> str:
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
    if kind == 7:
        return "wasm32"
    if kind == 8:
        return "wasm64"
    "native"

// The non-native targets this compiler can actually produce code and
// binaries for today. Gate is checked by the driver; anything else
// non-native must fail loudly (§18.5: never fall back to native).
// wasm64 (kind 8) is modeled but has no runtime yet (rt/wasm.w is the
// wasm32 flavour), so it stays refused here rather than failing later.
pub fn target_spec_cross_supported(kind: i32) -> bool:
    kind == 1 or kind == 2 or kind == 5 or kind == 6 or kind == 7
