// The compiler's ABI identity (docs/spec/toolchain/wo_bundles.md, decisions.md D38).
//
// sha256 of docs/with-abi.sha256 — the recorded hashes of the ABI-defining
// sources — patched into this fixed-width slot POST-LINK by
// build/compiler.w (run_patch_version_action), exactly as the version stamp
// is. Keeping it out of the compiled source keeps the build cache warm across
// unrelated commits (D13); reading it null-terminated keeps slot padding out.
// `with version --abi-sha` prints it; a .wo bundle's key and manifest carry
// the building compiler's value, and the link stage refuses a bundle whose
// value differs from this one (#761: never a silent mixed-ABI link).
extern fn with_str_from_cstr(p: *const u8) -> str

pub fn compiler_abi_sha() -> str:
    with_str_from_cstr(c"WITHABISHASTAMPv1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX".ptr)

// True once the slot has been patched (an unstamped binary still carries the
// sentinel). Bundle keys must never be computed from an unstamped compiler.
pub fn compiler_abi_sha_is_stamped() -> bool:
    not compiler_abi_sha().starts_with("WITHABISHASTAMP")

// The compiler's own identity: the sha256 of its unstamped image, patched in
// post-link by build/compiler.w (comp_patch_version_binary) like the version
// and ABI stamps. The build cache keys on it (build_cache_current_compiler_
// fingerprint) instead of hashing the running 100+ MB binary on every
// invocation, which cost every `with build`, no-op included, most of a
// second. The version stamp is provenance, not semantics (D13), so it is
// taken before the version is patched in.
pub fn compiler_self_id() -> str:
    with_str_from_cstr(c"WITHSELFIDSTAMPv1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX".ptr)

// True once the slot has been patched. An unstamped binary (a compile's
// intermediate, or a compiler older than the slot) is fingerprinted by
// hashing the file, as before.
pub fn compiler_self_id_is_stamped() -> bool:
    not compiler_self_id().starts_with("WITHSELFIDSTAMP")
