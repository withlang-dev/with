Automated nightly compiler prerelease.

Source commit: 450733e58a1a
Workflow run: https://github.com/example/with/actions/runs/99999
Compiler version: 1.2.3
Platforms: linux-arm64,macos-arm64

Release contents:

- Fixpoint-verified compiler binaries with SHA-256 sidecars
- Available checksum-pinned LLVM 22.1.6 SDK archives, SHA-256 sidecars, and manifests

Verification gates on each platform:

- `WITH_VERSION=1.2.3 with build`
- `WITH_VERSION=1.2.3 with build :fixpoint`
- Fixpoint-verified `out/release/bin/with` copied to each platform asset with a SHA-256 sidecar
- Available verified SDK inputs attached without rebuilding
