# D202 — The facade language is the With Contract Language

**Laws:** 9 (one spelling of one meaning), 12 (the programmer has the last
word on what the compiler cannot see).

**Date:** 2026-11-11. **Status:** ruled by Eric. The keyword, the file names
and the tree are respelled in the change that carries this record; §31
(v7.50) specifies the language under its name.

**Context.** "Facade" named two things: the modeled-C block D51 specifies
(`c facade name:`), and the hand-written With layer that presents a migrated
engine as the standard library (D37, D148). A reader could not tell from the
word which was meant, and the claims proposal needed a name for a clause
that rests on a person's word.

**Decision.** Eric's ruling:

> **With Contract Language (WCL).** The language D51 calls the facade
> language is named the With Contract Language. A block of it is a contract,
> a line is a clause, and a clause that rests on a person's word rather than
> a proof is a claim. The keyword `facade` in `c facade name:` is respelled
> `contract`. D51 is unchanged: where it says "facade" for a modeled-C
> block, read "contract".
>
> "Facade" from here on means one thing: the hand-written With layer that
> presents a migrated engine as the standard library (D37).

Added to the ruling the same day, so they are stated and not derived:

- The file a fetch writes, `.with/deps/c/<name>/<version>/facade.w`, with
  `facade-report.txt` and `facade.json` beside it, becomes `contract.w`,
  `contract-report.txt`, `contract.json`.
- A project's own `facades/<name>.w` directory becomes `contracts/`, with
  `use contracts.<name>`. `lib/facades/` becomes `lib/contracts/`. A
  directory that holds the library layer keeps its name.
- `with migrate --facade` becomes `--contract`.
- A registry file is headed `c facts NAME:`. The registry's own files are
  respelled with the release; until then the facts reader accepts both
  headers on a registry file.

**What does not change.** "Facade" wherever it means the library layer. The
D51 ruling's text and the dated meeting records: they are history, and this
entry is the pointer from them.

**How a program moves.** The compiler refuses `c facade`, naming `with
fix-contracts`, which respells `c facade` and `use facades.` in the paths it
is given (§18.5). There is no period in which both keywords are accepted:
the pinned seed does not parse `rt/`, so nothing needed one.

**Would reopen it.** A second meaning arriving for "contract" in the
language that a reader could confuse with this one.
