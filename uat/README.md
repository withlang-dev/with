# Release UAT scenarios

Each `*.uat` file is a scenario a user runs: a fresh project, `with get`,
`with run`. The release runs every scenario on every platform its
`platforms:` line names (all of them when it has none). The scenarios and
their fixtures are contracts: a change to one is Eric's (CLAUDE.md,
"Editing a user program to make it pass").

## Which scenarios, on which platforms (D171)

A scenario plays a **user**, and a user's action may use the host's system
tools. But the UAT measures the toolchain, so it selects only what the
toolchain can do: **a scenario uses only dependencies `with get` provides
cleanly on that platform** —

- a Conan Center binary for the platform, or
- a CMake source build through the compiler's own `cmake`, `ninja` and
  `with cc`.

A package whose dependency chain needs a host tool on a platform — Perl
(openssl's `Configure`), autotools (`sh` and `make`: libiconv) — is not a
scenario for that platform. Take the platform off the scenario's
`platforms:` line and say why in the scenario's comment. Never port,
migrate or substitute the user's C dependency to make it fit: our compiler
and our build never call `with get`, and the migrated corpora (pcre2, zlib,
…) serve the standard library and the compiler, not `with get`.

Where `with get` builds from source today: every package on Windows; every
package on linux-aarch64 (Conan Center publishes no armv8 Linux binaries).
That is where a chain's build system decides.

| Scenario | Platforms | Why |
|---|---|---|
| `libcurl.uat` | darwin, linux-x86_64 | openssl's build needs Perl wherever it is built from source |
| `libxml2.uat` | darwin, linux-x86_64 | libiconv's build is autotools wherever it is built from source |
| `sdl.uat` | darwin, windows, linux-x86_64 | dbus (SDL's Linux chain) is a meson build, Python, where it is built from source: linux-aarch64 (#2903) |
