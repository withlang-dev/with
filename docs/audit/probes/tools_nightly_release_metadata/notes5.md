Automated compiler release.

Source commit: 450733e58a1a
Workflow run: https://github.com/example/with/actions/runs/555
Compiler version: 2.0.0
Platforms: x

Release contents:

- Fixpoint-verified compiler binaries with SHA-256 sidecars
- Available checksum-pinned LLVM 22.1.6 SDK archives, SHA-256 sidecars, and manifests

Verification gates on each platform:

- `WITH_VERSION=2.0.0 with build`
- `WITH_VERSION=2.0.0 with build :fixpoint`
- Fixpoint-verified `out/release/bin/with` copied to each platform asset with a SHA-256 sidecar
- Available verified SDK inputs attached without rebuilding
