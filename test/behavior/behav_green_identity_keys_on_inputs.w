//! expect-stdout: ok

// D49 keyed a green on the whole git tree, so a docs-only commit produced a
// tree with no green record and `:install-user` refused a compiler whose
// sources had passed. D50: key on what the output is made from. The identity
// is now the git object name of the battery's inputs: `git ls-tree HEAD`
// without the `docs` entry and without top-level `*.md`, plus the three docs
// files lanes read. build/retention.w mirrors this rule; the listing here is
// what both hand to `git hash-object`.
use compiler.GreenEvidence

fn main:
    let top = "100644 blob aaaa\tAGENTS.md\n100644 blob aaaa\tCLAUDE.md\n100644 blob bbbb\tREADME.md\n100644 blob cccc\tbuild.w\n040000 tree dddd\tbuild\n040000 tree eeee\tdocs\n040000 tree ffff\texamples\n100644 blob 1111\tfix_windows.md\n040000 tree 2222\tlib\n040000 tree 3333\tsrc\n040000 tree 4444\ttest\n"
    let docs = "100644 blob 5555\tdocs/with-abi.sha256\n100644 blob 6666\tdocs/with-specification.md\n"
    let inputs = green_identity_inputs(top, docs)
    // Prose is not an input.
    assert(not inputs.contains("\tdocs\n") and not inputs.contains("CLAUDE.md") and not inputs.contains("README.md") and not inputs.contains("fix_windows.md"))
    // Everything a lane compiles or tests is.
    for kept in ["build.w", "\tbuild\n", "\texamples\n", "\tlib\n", "\tsrc\n", "\ttest\n"]:
        assert(inputs.contains(kept))
    // The docs files lanes read are appended, and order is git's.
    assert(inputs.ends_with(docs))
    assert(inputs.find("\tbuild.w") < inputs.find("\tsrc\n"))
    // A change under docs/ alone changes nothing the identity sees.
    let top_after_docs_edit = top.replace("040000 tree eeee\tdocs", "040000 tree 9999\tdocs")
    assert(green_identity_inputs(top_after_docs_edit, docs) == inputs)
    // A change to the specification does.
    assert(green_identity_inputs(top, docs.replace("6666", "7777")) != inputs)
    assert(GREEN_DOCS_INPUTS.contains("docs/with-specification.md"))
    print("ok")
