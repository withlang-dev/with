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

// The one rule for linking a .wo bundle against this compiler (D38, #761):
// a stamped identity refuses a bundle built for another ABI; an unstamped
// image — linked as a program (`with build main.w`, the failure-diagnostics
// probe), not by build.w's compiler link, which stamps the slot post-link —
// has no identity to compare, so it links an explicit --link-bundle and
// the bundles it embeds unchecked (#1330), as a hand-linked compiler keeps
// no generation (#1815). Both link paths (Compilation.load_link_bundles,
// Link.link_stage_select_embedded_bundles) read this; neither re-derives it.
pub fn abi_identity_refuses_bundle(self_abi: &str, bundle_abi: &str) -> bool:
    not self_abi.starts_with("WITHABISHASTAMP") and bundle_abi != self_abi

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

// #1815 (D30): which compiler generation this binary is, and which generation
// built the runtime objects it embeds. A generation is the tree a compiler is
// built from — sha256 over its src/ and rt/ sources (build/compiler.w
// compiler_generation) — so stage1, stage2 and the release of one tree are
// one generation and the seed that built stage1 is another. Both are patched
// post-link beside the ABI stamp; `with version --generation` and
// `--runtime-generation` print them. The link stage accepts runtime objects
// only from this compiler's generation (Link.w): a runtime object set records
// its producer's generation in `<dir>/.producer`, and a compiler whose
// embedded runtime came from another generation (stage1 carries the seed's)
// never falls back to it.
pub fn compiler_generation() -> str:
    with_str_from_cstr(c"WITHGENSTAMPv1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX".ptr)

pub fn compiler_runtime_generation() -> str:
    with_str_from_cstr(c"WITHRTGENSTAMPv1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX".ptr)

// An unstamped (hand-linked) compiler knows no generation; the link stage then
// keeps its pre-#1815 byte-identity rule.
pub fn compiler_generation_is_stamped() -> bool:
    not compiler_generation().starts_with("WITHGENSTAMP") and not compiler_runtime_generation().starts_with("WITHRTGENSTAMP")
