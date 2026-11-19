# D222 — One-liners read files and edit them in place

**Laws:** 1 (the file is named on the command line: nothing else needs
writing), the toolchain rule that a text transform is a With one-liner.

**Date:** 2026-11-18. **Status:** delegated (D98): a CLI surface, not C
interop, ownership or safety; easy to reverse; prediction 80%. Eric vetoes
by revert.

**Context.** #958: `sed -i 's/a/b/' file` and `awk '…' f1 f2` had no With
spelling. Every `-n`/`-p` read stdin only, and an operand was refused by
§18.5b's sentence "One-liner code cannot be combined with a source file
argument". The workarounds were `< file` (one file, no name) and a script.

**Decision.**

- Operands after `-n` or `-p` code are input files, read in order in place
  of stdin. The one-liner's source is the flag's value, so an operand is
  never the source. `-e` alone still refuses one (it would be read as the
  program's argument or its source).
- `filename` (the path as given, empty for stdin) and `fnr` (the line's
  number within its file) are bound when the code names them and does not
  declare its own, as `last` is. `nr` counts across all files; `last` is
  the final line of the last file.
- `-i` with `-p` writes each file back: the new text goes to a sibling
  (`<file>.with-tmp`) and is renamed over the file. A file that ended
  without a newline still does. `-i` with `-n`, with `-e` alone or with no
  file is an error. `-p -i CODE` and `-i -p CODE` are both accepted.
- A file that cannot be read stops the program: an error on stderr and
  exit 2, before any later file is touched.

**Alternatives.** A separate flag for input files: longer than awk for no
gain, since the position already says it. Truncating in place: loses the
file if the program stops halfway.

**Reopen if** an operand after `-n` code is wanted as the program's own
argument; `--` already separates those.
