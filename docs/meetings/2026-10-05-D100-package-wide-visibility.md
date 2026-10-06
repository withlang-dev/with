# D100 — Visibility is package-wide: `pub` leaves the package; `internal` paths stay inside

**Date:** 2026-10-05. **Status:** ruled by Eric. **Issues:** #2186.
**Supersedes:** §18.3's "No `pub` = module-private" (initial spec,
2026-02-19; the cross-module error sentence, v7.0, 2026-06-10).

**Decision.**
- A declaration without `pub` is visible throughout its package. `pub` means
  one thing: the declaration leaves the package. That is both the package's
  real API and its safety boundary.
- One more level, Go's `internal`, with no new keyword: a module under an
  `internal` path segment is importable only from inside the tree rooted at
  that segment's parent. The migrated C corpora (`std.re`, `std.zl`,
  `std.tommyds`, `std.c_algorithms`: raw, C-shaped, full of `unsafe`) move
  under `std/internal/…`, so a facade such as `std.zlib` reaches them and
  no user program can. There is no `pub(crate)`, `pub(super)` or file-private
  level: two levels plus `internal` cover what Rust spells five ways.
- Fields follow the same rule: `Vec`'s buffer and length are private to the
  std package, invisible to users and usable across std's own files. Stated
  so that per-type privacy is not proposed later.
- Privacy is not the only guard. An unchecked helper such as
  `BTreeMap.key_at` is also an `unsafe fn`, so code inside std acknowledges
  the risk when it calls one; otherwise the next std contributor, agent or
  human, makes the same mistake from inside the package.
- A file run outside any `with.toml` is its own package, with the modules it
  imports from its own directory tree. Test files inside a package see
  everything, as in Go.

**Why.** Per-file privacy (Zig's rule, and §18.3 until now) made the
compiler need 1,529 `pub`s: `impl Sema`, `impl AstPool` and others are split
across files, and every cross-file call was a cross-module call. Python,
Mojo and Vale show that inside one codebase nobody misses enforcement. No
enforcement at all fails "exactly as safe as Rust": the standard library's
safe API rests on private unchecked helpers, and `BTreeMap.new().key_at(0)`
segfaulted from user code (#2186).

**References** (checked in `.reference/`):
- **Go:** the package, all files in a directory; capitalized names are
  exported; `internal/` directories (`cmd/go/internal/load/pkg.go`,
  `findInternal`).
- **Swift:** `internal` (the whole module) is the default; `private`,
  `fileprivate`, `package`, `public`, `open`.
- **Rust:** private to the module and its children by default;
  `pub(crate)`, `pub(super)`, `pub(in path)`.
- **Zig:** a non-`pub` declaration is visible only in its own file
  (`Sema.zig`, `accessible = src_file == namespace.file_scope`).
- **Scala 3:** public by default; `private` is class-private;
  `private[pkg]` is package-qualified.
- **Mojo:** a `_name` convention only.
- **Vale:** no visibility; `exported` is C FFI export.

**Follow-up.** When the rule lands, a lint removes `pub` from items that
nothing outside the package uses.

**Reopen if** a package grows large enough that its own modules need
protection from each other in practice. `internal` is the first tool for
that; a file-private level would be a new ruling.
