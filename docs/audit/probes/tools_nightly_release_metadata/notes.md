Automated test compiler prerelease.

Source commit: 450733e58a1a7cce14f9cb2084943fc178815111
Workflow run: https://github.com/example/with/actions/runs/12345
Compiler version: 0.0.0-test
Platforms: linux-arm64

Release contents:

- Fixpoint-verified compiler binaries with SHA-256 sidecars
- Available checksum-pinned LLVM 22.1.6 SDK archives, SHA-256 sidecars, and manifests

Verification gates on each platform:

- `WITH_VERSION=0.0.0-test with build`
- `WITH_VERSION=0.0.0-test with build :fixpoint`
- Fixpoint-verified `out/release/bin/with` copied to each platform asset with a SHA-256 sidecar
- Available verified SDK inputs attached without rebuilding
