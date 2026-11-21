# D225 — windows-aarch64 is not a supported platform until someone asks for it

**Date:** 2026-11-20. **Status:** ruled (Eric). **Supersedes:** D137 (the
lane was non-gating; it is now not built at all).

**Ruling (Eric, 2026-11-20).** "anything specific to windows-aarch64 should
be labeled as held until I hear of anyone, ever, using With on
windows-aarch64. The windows-aarch64 builds should be disabled.
windows-aarch64 is not supported until i hear of someone somewhere who wants
to use it."

**Decision.**

- **Not supported.** The supported platforms are darwin-aarch64,
  linux-x86_64, linux-aarch64 and windows-x86_64. A seed cut and a release
  are those four.
- **Not built.** The nightly's `build-windows-aarch64` job and the release's
  `sdk-windows-aarch64` job are disabled (`if: false`), kept in place so
  turning the platform back on is one line each. The two dedicated workflows
  (`seed-windows-aarch64`, `selfhost-windows-aarch64`) run only when a
  person dispatches them. The release badge and the README no longer list
  the platform.
- **Its issues are held.** An issue specific to windows-aarch64 carries the
  `held` label and is not worked. The label means "not worked until someone
  asks for it"; it is not `blocked` (waiting on another issue) and not
  `human attn needed`.
- **The code stays.** The cross target, the runtime backend and the build
  rules for windows-aarch64 are not deleted. They are not kept green either:
  a change that breaks only that target is not a defect to fix now.

**Reopen when** anyone asks to use With on windows-aarch64. The first work
then is a seed (#2893: the pinned one predates `c_char`).
