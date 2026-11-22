# D228 — With source files use the extension `.with`; the extension governs discovery, not what a user names

**Laws:** the mission's "every character the program has already determined
is a compiler failure if the programmer still writes it"; D172 (declare the
guarantees that must remain stable); D112 and D206 (a migrated corpus is
never edited and never re-migrated by anything routine).

**Date:** 2026-11-21. **Status:** ruled by Eric, with an amendment the same
day; the spec sentence is blessed and in v7.79 (§18.1).

**Context.** With source files were named `.w`. The name is the language's;
`.w` says nothing and collides with other uses.

**Ruling.**

- **The extension.** With source files use `.with`. `.w` is retired.
- **Discovery, not naming (the amendment).** A file the user names on the
  command line is With source whatever its name or extension, now and after
  the transition: `with hello.potato`, `with run notes`, a script with a
  `#!` first line. `.with` is what the toolchain uses when it finds files
  itself: a module resolved from `use`, the tests in a directory, the
  sources a build names by pattern, a project's build file and entry, what
  `with init` and `with migrate` write.
- **The bare form.** A first argument that contains a dot or a slash is a
  file. A bare word with neither is a subcommand lookup, and its error
  suggests `./name` or `with run name`.
- **Output names.** An output name is the file's name up to its last dot. A
  name with no dot is the whole name; a leading dot is not a separator.
  Outputs are written under `out/`, so a file never overwrites itself.
- **The transition.** While it lasts the toolchain finds both `.with` and
  `.w`, `.with` first, and a directory holding both spellings of one module
  is an error. After it, `.w` is no longer discovered; when a `use`, a test
  directory or a build pattern finds nothing and a `.w` file of that name
  is there, the error says so and names the one-command rename. A `.w` file
  the user names directly still runs.
- **Migrated corpora.** Renamed and never edited: a rename-only promotion.
  Each module's contents are byte-identical; a corpus's stamp records the
  new module hash, because that hash covers paths, with this decision as
  the reason.
- **Published programs.** In an example or a UAT fixture only a file name
  inside a scenario step, a build file, a comment or a README changes, and
  every such line is listed in the pull request.

**Consequences recorded when the tree was renamed.**

- The text of `src/FnAbi` names file paths, so its hash, and with it the
  ABI record and every `.wo` bundle key, changes. The ABI's rules do not.
  Bundles are rebuilt from the corpora as they stand; nothing is migrated
  again.
- Two seeds: one that finds `.with` (the compiler before the rename), and
  one cut from the renamed tree.

**What would reopen it.** A tool or platform that cannot handle the
five-character extension (an 8.3 file system, an editor that keys on a
one-letter extension and cannot be taught), or a collision with another
language's established use of `.with` that makes editors and code hosts
mislabel With files.
