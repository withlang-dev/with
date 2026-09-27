# With Language Design

This is where the With language is specified, where changes to it are
proposed, and where the decisions that shaped it are recorded. The
compiler in `src/` implements what is written here; the specification
leads the implementation (see [Design-Process.md](Design-Process.md)).

You can find:

- The language specification, one file per chapter, in the
  [spec folder](spec) ([table of contents](spec/README.md)).
- Reference material that is not language semantics, next to the
  specification: the [standard library](spec/stdlib), the
  [ABI](spec/abi), the [toolchain](spec/toolchain), the
  [implementation notes](spec/implementation) and the
  [guides](spec/guide).
- Live plans and design proposals in the [proposals folder](proposals)
  (superseded ones under [proposals/inactive](proposals/inactive)).
- The decision log — one file per ruling, plus Eric's canonical rulings
  — in the [meetings folder](meetings).
- A summary of the [language version history](Language-Version-History.md).
- The [mission](mission.md).
- Completed phase documents, debug logs and handoffs, kept as history, in
  [completed](completed).

The complete design process is described in
[Design-Process.md](Design-Process.md).

## Layout

```
docs/
  README.md                     this map
  Design-Process.md             how a change to the language happens
  Language-Version-History.md   one entry per specification version
  mission.md                    the mission statement
  spec/                         the specification, one file per chapter
    README.md                   front matter, changelogs, table of contents
    stdlib/                     standard library specifications
    abi/                        ABI and calling-convention documents
    toolchain/                  CLI, build, bundles, debugging tools, runbooks
    implementation/             implementation notes and internal designs
    guide/                      idioms, examples, migration guides
  proposals/                    live plans and proposals
    inactive/                   superseded plans, kept for the record
  meetings/                     the decision log, one file per decision
  completed/                    finished phases, debug logs, handoffs
```

## Authority

`docs/spec/` is normative. Where a proposal, a plan, a meeting note, a
comment, a test or the compiler disagrees with it, the specification wins,
and the implementation is non-compliant until it conforms. Two rulings in
`meetings/` are canonical in their own right and are never edited:
[d22-Eric-Ruling.md](meetings/d22-Eric-Ruling.md) and
[Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md](meetings/Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md).

The build reads the specification: `with build :spec-inventory-check`
compares the keywords, attributes and CLI commands the chapter files
document with the ones the compiler implements.

## Maintenance

The tree was given this shape by `tools/docs_restructure.w`, which moves
text and never rewords it; the same tool reassembles the split documents
and proves them byte-identical to their sources (`verify-spec`,
`verify-decisions`).
