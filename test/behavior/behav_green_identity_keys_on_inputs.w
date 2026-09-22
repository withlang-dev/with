//! expect-stdout: ok

// D49 keyed a green on the whole git tree, so a docs-only commit produced a
// tree with no green record and `:install-user` refused a compiler whose
// sources had passed. D50: key on what the output is made from. The identity
// is the git object name of the battery's inputs: `git ls-tree HEAD` without
// the `docs` entry and without top-level `*.md`. The build measures software,
// not documents (Eric, 2026-09-21): the specification is prose too, so a
// spec-only merge keeps its green. build/retention.w mirrors this rule; the
// listing here is what both hand to `git hash-object`.
use compiler.GreenEvidence

fn main:
    let top = "100644 blob aaaa\tAGENTS.md\n100644 blob aaaa\tCLAUDE.md\n100644 blob bbbb\tREADME.md\n100644 blob cccc\tbuild.w\n040000 tree dddd\tbuild\n040000 tree eeee\tdocs\n040000 tree ffff\texamples\n100644 blob 1111\tfix_windows.md\n040000 tree 2222\tlib\n040000 tree 3333\tsrc\n040000 tree 4444\ttest\n"
    let inputs = green_identity_inputs(top)
    // Prose is not an input.
    assert(not inputs.contains("\tdocs\n") and not inputs.contains("CLAUDE.md") and not inputs.contains("README.md") and not inputs.contains("fix_windows.md"))
    // Everything a lane compiles or tests is, in git's order.
    for kept in ["build.w", "\tbuild\n", "\texamples\n", "\tlib\n", "\tsrc\n", "\ttest\n"]:
        assert(inputs.contains(kept))
    assert(inputs.find("\tbuild.w") < inputs.find("\tsrc\n"))
    assert(inputs.ends_with("\ttest\n"))
    // A change under docs/ alone — the specification included — changes
    // nothing the identity sees.
    let top_after_docs_edit = top.replace("040000 tree eeee\tdocs", "040000 tree 9999\tdocs")
    assert(green_identity_inputs(top_after_docs_edit) == inputs)
    // A change to a source tree does.
    assert(green_identity_inputs(top.replace("040000 tree 3333\tsrc", "040000 tree 7777\tsrc")) != inputs)
    // The clean check applies the same rule to untracked paths: a document or
    // a user's program cannot dirty a tree whose identity does not see it
    // (an untracked docs/feature_plans/ draft refused main's reseed 2026-09-22).
    for harmless in ["?? docs/feature_plans/with-ui.md", "?? examples/spiral/", "?? NOTES.md"]:
        assert(green_untracked_is_not_input(harmless))
    for input in ["?? src/New.w", "?? build/x.w", "?? lib/std/notes.md", " M src/Sema.w", "?? test/behavior/t.w"]:
        assert(not green_untracked_is_not_input(input))
    print("ok")
