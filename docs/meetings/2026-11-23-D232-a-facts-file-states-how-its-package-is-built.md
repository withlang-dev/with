# D232 — A facts file states how its package is built: `build define` and `define`

**Laws:** D51 (a safety fact is stated or proven), D212 (a proof holds for
the build that is linked), the mission's "the programmer never has to become
the build system".

**Date:** 2026-11-22 and 23. **Status:** ruled by Eric; implemented; the
words are in v7.87 (§16.2b.15, §31).

**Context.** Two rulings needed a library built with a known setting.
`reads` on zlib's `next_in` (D231) is worth having the C compiler check on
every build, which `ZLIB_CONST` does. And a fact may hold only under one
configuration of a library; the first case raised was expat's context
bytes. The registry held a facts file per library and nothing about how the
library is built, and `with get` configured each package with its recipe's
defaults.

**Ruling.** A fact is about the package as the pinned recipe builds it. The
facts file states the settings, before its items, each line cited:

- **`build define NAME[=value]`**: the library's build only. It must not
  change the layout, the type or the symbol name of anything the installed
  headers declare. That is checked: each installed header is preprocessed
  with and without it and the two compared; a difference in `const` alone
  passes, as with `ZLIB_CONST`.
- **`define NAME[=value]`**: the build and the program's import. Some
  defines change what the header declares (expat's `XML_UNICODE` changes
  `XML_Char`; zlib's `Z_PREFIX` renames every symbol); building with one and
  importing without it gives a program that disagrees with its library.
- **Set explicitly.** `with get` passes each stated setting to the build; it
  is never left to a default.
- **In the cache key.** A cached build made without a setting is not linked
  where the facts state one: the settings are part of the facts file, whose
  digest is in the key.
- **A library not built with a setting does not get the facts that cite
  it**, and the report names each one dropped. A prebuilt binary, `--binary`
  included, is such a library.

**Rejected.** A clause form for a fact conditional on a define: the facts
are about one build, the one the settings describe. Defining `ZLIB_CONST`
for the import as well: the header would then say what the facts state, and
a preprocessor setting would carry a safety fact (D231).

**Why `ZLIB_CONST` is build-only.** With it the library's own source cannot
compile a write through `next_in`. The program's import does not see it, so
the header still declares the pointer writable and `reads` is the stated,
checked fact that makes the slice `[]u8`.
