# Explicit Unit review trigger

Explicit `-> Unit` is legal, but a new annotation is a reason to investigate.
Commit `212e42b0` invented a public-function restriction, then added hundreds
of annotations to accommodate it. Tests must exercise the intended language;
changing their declarations to appease a compiler error defeats that purpose.

`with build :unit-return-review` is part of `:test` and is never cached. It
compares tracked working-tree sources (including staged new files) against
`origin/main`. Set `WITH_UNIT_RETURN_BASE` to the target branch or an explicit
pre-change commit when reviewing a different stack boundary. Fetch the target
branch before recording review evidence. A missing base fails the check.
Untracked `.w` files fail the build gate until staged, so new source cannot
silently escape the diff.

The lexer compares function declarations, including methods and externs.
It ignores comments, strings and nested callback return types, normalizes
whitespace, and counts duplicate signatures. Existing annotations are not
new violations; their continued presence is not an endorsement either.

For each new annotation, remove it if inference suffices. Otherwise add the
exact path and normalized signature printed by the check to
`unit-return-reviews.tsv`, with the semantic reason. Examples include a D43
choice to discard incompatible branch values, an explicit foreign contract,
or a test specifically exercising explicit annotation syntax. The reviewer
must verify that reason; the gate ensures the decision is visible, not that
arbitrary prose proves it. A compiler demand is a bug investigation trigger,
never a reason to add ceremony. There are no directory-wide exemptions.

For focused iteration on already tracked files:

```
with run tools/unit_return_review.w <base>
```

`test/internals/unit_return_review_test.w` verifies detection and review
matching. `test/behavior/behav_public_private_return_inference.w` generates
private and public declarations from the same source, checks their runtime
results, and requires the same D43 rejection for mixed branch types. This
prevents an annotation-only rewrite of the public half from hiding a bug.
