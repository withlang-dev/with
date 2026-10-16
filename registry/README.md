# The package registry (§16.2b.15 item 3, D121 step 4)

One reviewed facts file per C package, `registry/c/<package>/facts.w`,
shared by every With user: the ownership facts that neither a proof from
the package's source nor an annotation the package ships settles. Nobody
writes one per project. The file is read by the facade proof engine
(`with migrate --facade NAME <dir> --facts registry/c/<package>/facts.w`)
and, through it, by `with get` (step 5), which fetches the file for the
package's version from this repository and pins the commit it read in the
project's `lock.json`.

## What a facts file is

A facade fragment in the facade language's own spelling, the spelling the
engine's draft emits, so a reviewer reads one grammar:

```
c facade zlib:
    resource GzFileS wraps *mut gzFile_s
        drop gzclose    // zlib.h 1.3.2: "gzclose … deallocates all the (de)compression state"
```

Clauses a file may state: on a resource, `from F` (an owned producer),
`drop F` (the destroyer the resource is released with) and `destroys F`
(another function that releases it); on an item, `consumes param N`,
`returns borrow R from param N`, `lend`, `nullable param N`, `text param
N` and `text return, owned, freed by F` (§16.2b.8: what a facade states
about a parameter's or a return's shape, where the proofs reach neither;
libxml2's optional encoding and the text `xmlGetProp` hands back, freed by
`xmlFree`). An item may carry several. At the facade level, `text utf8`
(D134: every text return presents as `Option[str]`, validated at the
boundary; libxml2's `xmlChar` is a byte of UTF-8). The engine applies a
fact only
where a proof and the library's annotations said nothing (§16.2b.2), and
the generated facade records each one with the provenance `registry:` and
its citation.

## The review rule

- **Every fact carries its citation** after `//`: the source file and line,
  or the document, that proves it. The engine refuses a fact without one.
- **A fact lands by pull request**, like a DefinitelyTyped declaration: the
  PR names the package version the facts were read from, and its test
  compiles the fragment, merged into the engine's draft, against the
  package's header.
- **A proof wins over a fact.** A fact the engine's report says DISAGREES
  with a proof is wrong, or the proof is: the PR that finds it fixes the
  one that is wrong; neither is averaged.
- **Facts are versioned by the package**: `c facade NAME:` names the
  package; a fact true of one version and not another is split into two
  files by version range when the second version arrives.
- **Never a name convention.** A fact states what one function does, with
  its citation; `*_free -> drop` for a family of functions is a convention
  profile (§16.2b.12), not a registry fact.
