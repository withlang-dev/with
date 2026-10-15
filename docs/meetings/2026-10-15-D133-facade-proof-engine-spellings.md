# D133 — The facade proof engine is `with migrate --facade NAME`; a proven resource is named by its C record in CamelCase (delegated)

**Laws:** 1 (docs/mission.md): the programmer never writes what the
compiler can prove; §16.2b.2: a name is presentation sugar only.

**Date:** 2026-10-15. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Context:** D121 step 2, the
proof engine over a package's C source.

**Decision.** The engine is a mode of the migrator, `with migrate --facade
NAME <dir|file.c>`, taking every migrator option (`-I`, `-D`, `--exclude`,
`--c-target`/`--c-sysroot`, `-o`). The draft names a proven resource after
its C record in CamelCase (`xmlDoc` → `XmlDoc`, `z_stream_s` → `ZStreamS`,
`sqlite3` → `Sqlite3`); a record whose CamelCase is its own name takes
`Handle` (`Foo` → `FooHandle`) so the resource never shadows the imported
type. `with get` (step 5) consumes the same engine; the flag is how a
reviewer, a registry author and the selfhost test reach it directly.

**Why.** The proofs are the migrator's own body analysis (D107's walkers,
the same `CiProject` fixed point), and the C model a package needs (include
paths, defines, a target sysroot) is exactly what `with migrate` already
takes; a separate command would duplicate its option surface. The resource
name is presentation: the facade language lets a project rename it, and a
name derived from the record is deterministic, collision-free and
recognizable (`XmlDoc` wraps `*mut xmlDoc`), where a name derived from the
producer (`doc_new` → `Doc`) is neither unique nor stable across producers.

**What the others do.** Swift derives imported type names from the C
declaration (`xmlDoc` stays `xmlDoc`; `.apinotes` renames); Rust's bindgen
keeps C names and offers `--rustified-enum`-style presentation options;
neither proves ownership from bodies, so neither has a resource to name.

**What the spec says.** §16.2b.15 names the evidence order and that `with
get` writes the facade and the report; it does not name the engine's
command or how a resource is spelled. §16.2b.11: presentation never
establishes ownership. This entry adds only spellings.

**Mission fit.** A user runs `with get libxml2` and reads a report; a
maintainer runs `with migrate --facade` on a tree and reads the draft. No
one writes a facade for a package (D121).

**Prediction.** Eric accepts both spellings (80%): the engine's home follows
from reusing the migrator, and the name is overridable sugar. The likelier
veto is on the suffix `Handle` (a short word such as `Res` or a leading
`C`); that is a one-line change in `fd_resource_name`.
