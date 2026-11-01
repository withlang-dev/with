# D180 — Every platform a release ships a compiler for ships that platform's SDK in the same release

**Laws:** 8 (docs/mission.md).

**Date:** 2026-11-01. **Status:** ruled by Eric ("it is absolutely mandatory
for windows to have a SDK. do not omit that." … "i want every platform to
have an SDK with every release. please canonize that to law."). During the
v0.16.0.0 release.

**Ruling.** A release carries, for every platform it publishes a compiler
binary for, that platform's static LLVM SDK asset
(`with-llvm-sdk-<llvm-ver>-<platform>.tar.gz`) in the same release. A release
is not done while any platform has its compiler asset and not its SDK asset.
The SDK is published by the same host or lane and the same
`:publish-release-asset` as the compiler; a platform whose SDK cannot be
produced or republished does not get its compiler asset either, and the
release is red until it does. A non-gating platform (windows-aarch64, D137)
is held to the same rule once its compiler asset is published: the compiler
asset waits for the SDK, never the reverse. The SDK bytes change only when
`COMPILER_LLVM_VERSION` bumps; republishing the verified SDK asset of the
pinned SDK release under the new tag satisfies the rule, as the Windows lane
already does.

**Why.** Law 8: a build reads only our SDK. A compiler binary without its SDK
cannot build the next compiler on that platform, so the platform cannot
bootstrap, cannot cut a seed and cannot be fixed without going through
another host. v0.15.2.1 shipped both Windows compilers and no Windows SDK;
the only Windows SDK lived on a nightly SDK tag, so a Windows user had a
compiler whose own build was unreproducible from the release. The release
runbook listed three SDK assets against five compiler assets, and the
pre-release triage of 2026-11-01 recommended shipping without the Windows SDK
because no release had ever had one. The status quo was the defect.

**Alternatives.** (a) SDK assets published later, by a separately dispatched
workflow: rejected, the release page is read when it appears, and a platform
without its SDK on day one is the v0.15.2.1 gap again. (b) Gating platforms
only: rejected, a platform we publish a compiler for is a platform we claim.

**What would reopen it.** A platform whose SDK is not an asset at all (an SDK
baked into the compiler binary, or fetched from an immutable store the
compiler names by digest). Then the rule's object changes, not the rule.

**Follow-ups.** `:publish-release-asset` and the post-publish check should
refuse a compiler asset whose SDK asset is absent, mechanically, so the rule
is a gate and not a checklist line; the windows-x86_64 SDK job (#2473) and a
windows-aarch64 SDK job must produce fresh SDKs, since republishing the
pinned SDK release only carries the rule until the LLVM version bumps.
