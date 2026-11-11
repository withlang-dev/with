# With Contract Language: implementation plan, draft

Status: draft (2026-11-11), for Eric's go. It follows the order he set: the
claims proposal (docs/proposals/claims.md), the formal specification draft
(docs/proposals/wcl-spec.md), this plan, then the keyword migration. Nothing
below has been started except the three counts and the seed probe.

## What was measured first

Taken on main at 36ced4302, before any edit.

**Published programs that use the old spelling.**

| Where | `use facades.…` | a `c facade` block |
|---|---|---|
| `uat/` | 6 files | 0 |
| `examples/` | 4 files | 2 files |
| `README.md` | 1 | 0 |
| `build/release_uat_fixtures/`, `docs/blog/`, `docs/with_for_ai.md` | 0 | 0 |

These are contracts with Eric and everyone who read them. Under the ruling
their edit is his: each file is listed in the migration PR with its diff, and
nothing else in them changes.

**Files the pinned seed compiles that use it.** Twelve sources hold a
`c facade` block, all under `rt/` (the runtime's own libc contracts); none
under `src/`, `build/`, `build.w`, `lib/std` or `tools/`. Probe, run rather
than reasoned: with `c facade` respelled `c contract` in `rt/darwin_aarch64.w`
and `rt/rt_core.w`, `WITH=$PWD/src/main src/main build :stage1` is green.
The seed reads the runtime through its own embedded interface and never
parses the tree's `rt/` sources. **No dual-spelling period is needed for the
seed.** The compiler built from the tree parses `rt/` when it builds the
runtime bundle, with the new parser.

**`c facts` is not a keyword today.** The ruling says `c facts` "already
has the right name". The file is named `facts.w`, and claims.md writes
`c facts stc:`, but the three registry files on main are headed
`c facade NAME:` and the facts reader requires that line (`CiFacts.w`: "`c
facade NAME:` must come first"). So the registry's header changes too, and
there are two candidates: `c facts NAME:` (the ruling's word, and what the
file is) or `c contract NAME:`. This plan assumes `c facts NAME:`; it is a
question for Eric (A2). Either way a released compiler refuses the
respelled file and falls back to the facts its own release published
(D199), with its note, on every fetch until the user upgrades.

**Prose uses by meaning.** Not yet classified. Raw counts of the word, any
meaning: `src/` 4582, `lib/std` 1439, `test/` 1091, `docs/meetings` 387,
`docs/spec` 269, `docs/proposals` 234, `build/` 195, `docs/completed` 173,
`tools/` 125, `lib/facades` 39, `rt/` 21. Step 1 below produces the
classification, and it is reported before any prose is touched.

## Stack A: the keyword migration

Its own stack, separate from the formal specification. One battery.

**A1. Classify.** A With tool (`tools/wcl_classify.w`, Lexer-based) walks
every `.w` file and lists each occurrence of the word by kind:

- *code, contract meaning*: the contextual word at a declaration start
  (`c facade`), a `use facades.x` path, an identifier of the compiler's own
  (`NK_C_FACADE`, `FACADE_CLAUSE_*`, `SemaFacade`, `facade_render_*`,
  `CiFacadeDraft`, `fd_*` are prefixes, not the word; listed separately);
- *code, library meaning*: none expected in code tokens;
- *string*: a diagnostic or a test expectation;
- *comment*: prose, to be read.

For Markdown and comments the tool prints each line with two lines of
context; a person assigns contract or library layer. The rule of thumb the
classifier applies first and a reader confirms: a use beside `lib/std`,
`engines`, D37, D148, "migrated engine", "collections" is the library layer;
a use beside `c_import`, a C library's name, §16.2b, D51, D121, D198,
"clause", "resource", "registry" is a contract. Output: a table of counts by
directory and meaning, and the list of ambiguous lines. **Stop here and
report.**

**A2. The parser accepts `c contract` and refuses `c facade`.**
`Parser.w`: `c contract name:` at a declaration start (three sites that test
`token_text_is(p + 1, "facade")`). The old spelling is a parse error:
"`c facade` is now `c contract` (the With Contract Language); run
`with fix-contracts`". No period in which both are accepted: the seed does
not need one, and two spellings of one meaning are a defect (law 9).
The facts reader (`CiFacts.w`) takes `c facts NAME:` as its header and
refuses `c facade NAME:` the same way. **Question for Eric:** `c facts` or
`c contract` for a registry file's header.

**A3. The rewrite tool.** `with fix-contracts [--apply] [path…]`, built in
(Lexer-based, the shape of `with migrate-receivers`): rewrites `c facade` at
a declaration start to `c contract` and `use facades.` paths to
`use contracts.`, and nothing inside a string or a comment. `--list` prints
what it would change. It is what a user runs on their own files, and what
this stack runs on the tree.

**A4. Run it on the tree.** `rt/` (12 files), `lib/facades/` (5),
`registry/c/` (4), `test/` (411 files), then the published programs (13
files), listed. Generated corpora under `lib/std/engines` and
`test/corpora` hold no contract blocks; if the tool finds one there, stop
(D112: a corpus is never edited).

**A5. Paths.** `lib/facades/` becomes `lib/contracts/`; the module path
`facades.<name>` becomes `contracts.<name>` (`Resolve.w`: the path
recognizers at lines 1435, 1600, 1642 on main; `Frontend.w` 3444). Derived
from the ruling, needing a yes each: a fetch writes `contract.w`,
`contract-report.txt`, `contract.json`; a project's override directory is
`contracts/`. An existing `.with/deps` tree written by an older compiler has
`facade.w`: the resolver reads the old name with a note for one release, or
`with get` rewrites it on the next fetch. Recommended: the fetch rewrites
it, and a build that finds only `facade.w` says "run `with get`".

**A6. Commands and flags.** `with facade report` (not yet merged) lands as
`with contract report`. `with migrate --facade <name>` becomes
`--contract <name>`; the old flag is refused, naming the new one.

**A7. Diagnostics and expectations.** Every diagnostic string that says
"facade" for a contract says "contract": 228 `emit_error` sites in
`SemaFacade.w`, the parser's, the drafter's report, the contract view. The
test expectations that quote them move with them (`test/compile_errors`,
`build/selfhost.w`). Done with the classifier's *string* list, each string
read once; a string that means the library layer stays.

**A8. Compiler identifiers.** `NK_C_FACADE`, `FACADE_CLAUSE_*`,
`SemaFacade.w`, `FacadeRender.w`, `CiFacadeDraft.w`, `facade_render_*`,
`fd_*`. These name the contract machinery. Renaming them is a large
mechanical diff with no behavior in it. Recommended: a second PR in the same
stack, by a compiler-driven rename, so the first PR's diff stays readable.
Two spellings of one meaning inside the compiler is the same defect as
outside it; this is not optional, only separate.

**A9. Specification text.** §16.2b's title and prose: "facade" for a
modeled-C block becomes "contract". Spec words are Eric's: the stack brings
the diff, classified, and lands it on his word. D51's own text and the dated
meeting records are untouched; the decision log gets one entry for this
ruling.

**A10. Gate and battery.** New tests: `c facade` refused with the message;
`with fix-contracts` on a fixture with the word in code, in a string and in
a comment (only the code changes); a project with an old `.with/deps` tree.
The UAT runs on the edited fixtures. Before the battery, sweep every textual
expectation of the old spelling (never a head-truncated search).

**Order inside the stack.** A1 (report, stop) → A2 + A3 + A4 + A5 + A6 + A7
as one PR (the tree does not build between them) → A8 → A9 on its own PR.

## Stack B: the formal specification

Docs only. After Eric answers the questions in wcl-spec.md section 11:

- B1. The normative home (question 1): a chapter, a rewrite in place, or a
  companion.
- B2. The row-by-row check of section 6 against §16.2b, each disagreement
  listed.
- B3. The provenance words (question 2) and whether a stated grant counts
  as a claim (question 3). If the words change, the contract view's text
  and its fixtures change in a compiler PR that follows.
- B4. Land the blessed words; `spec-inventory-check`.

## Stack C: what the vocabulary makes cheap

Each is its own decision; listed so they are not lost.

- C1. **Provenance in the contract view as the ruling names it**: `stated`,
  `proof`, `annotation`, `claim`, `profile`, `default`, and a count line:
  "N clauses: P proven, A annotated, C claimed, S stated".
- C2. **`with contract report` prints the claims a program rests on**: one
  query, with citations.
- C3. **Tier 1 of claims.md**: `c facts` for a migrated corpus, `nonnull` on
  a return, the `:registry` provenance in the migrator's contracts artifact.
- C4. **The `callback` field role** (#3124).
- C5. **Tier 2 of claims.md** (`claim <fact>` in With code): spec words
  first.

## What is in flight and where it lands

- `with facade report` (branch `facade-report-cmd`, §18.5 line blessed): it
  lands inside stack A as `with contract report`, so the command is never
  released under a name the ruling retires.
- Established domains (D200, §16.2b.7 landed): its new clauses are written
  after the keyword migrates, so its fixtures and registry lines are born
  with the new spelling.
- #3129 (every refusal names the accepted spelling): the same 228 strings
  A7 touches. Done together, each string is read once.

## Risks

- **A blind replace.** The library layer keeps the word (1439 uses in
  `lib/std`). Mitigation: no text replace anywhere; code by the Lexer,
  prose by classification.
- **A published program edited beyond the ruling.** Mitigation: the tool
  changes two token shapes; the PR lists each published file's diff.
- **Users' existing projects.** Their own `c facade` blocks stop parsing.
  Mitigation: the refusal names the fix and the tool applies it.
- **The registry.** The three `registry/c/*/facts.w` files are headed
  `c facade NAME:` and are respelled. Every released compiler then refuses
  main's file and uses the facts its release published (D199), so a fact
  reviewed after the rename reaches only compilers built after it. That is
  D199 working as ruled, and it is a cost: the rename should land close to
  a release, not long before one.
