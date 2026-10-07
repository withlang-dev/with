# D49 — Green evidence is keyed on what was tested: git tree, pinned seed, host

**Laws:** 10, 8 (docs/mission.md).

*Amended 2026-09-20 (D50 applied):* the identity keys on the battery's
inputs, not the whole tree — `git ls-tree HEAD` without the `docs` entry and
without top-level `*.md`, as the object name `git hash-object` gives that
listing. A docs-only commit produced a tree with no green and `:install-user`
refused a compiler whose sources had passed; Eric: "best fix this
immediately". `GreenEvidence.w` and `build/retention.w` apply one rule;
`behav_green_identity_keys_on_inputs.w` pins it.

*Amended 2026-09-21:* the first amendment kept three docs files in the
identity because lanes read them (the specification, `with-abi.sha256`,
`with_for_ai.md`); a spec-only merge (#1245) then left main with no green
and forced a full battery. Eric: "build measures software not documents."
No file under `docs/` is an input; the lanes that read one still run on a
docs-only change (spec-inventory-check) and record nothing.

**Date:** 2026-09-20. **Status:** ruled (Eric: "it is moronic that we are testing what we already tested"; "proceed").

**Context.** #1222's battery passed in a staging worktree. It was squash-merged; main's tree was byte-identical to the tested head (`git diff` empty). `:install-user` still required a second full battery on main, 25 minutes, because `last-green` and the driver's install gate accept only the exact compiler binary that was tested (`compiler_sha256`), and the binary names its commit (`v0.15.2.1-g<hash>`, a post-link stamp) and, through debug info, its worktree. A squash-merge or another checkout of the same sources is a "different" compiler.

**Decision.** What a battery tests is its inputs. `:last-green` records the source identity — `git rev-parse HEAD^{tree}`, the digest of the pinned seed that drove and seeded the chain, and the host — and publishes it to a store every worktree reads (`$WITH_GREEN_DIR`, else `~/.local/with-green/green.tsv`). `require-last-green` and the driver's `:install-user` gate accept a compiler when either the local manifest names that binary (unchanged) or the worktree is clean, its stage chain was seeded by a compiler `seed.lock` pins, and its source identity has a published green. After a squash-merge of a tested branch the reseed is `git pull`, `build`, `:install-user`.

**What it trusts.** Same tree, same seed, same host: same compiler behavior. `:fixpoint` and the seed-driven battery already enforce that determinism. A dirty worktree has no identity (untracked paths under `examples/` excepted: a user's own programs are not build inputs), so uncommitted edits never borrow a green; any tree change, one byte, is a new identity.

**Alternatives weighed.** Stamping the binary with the tree hash, or keying on the unstamped binary: both still differ across worktrees (debug paths). Keeping the branch worktree until install: relies on a person not cleaning up, and did not survive its first day.

**Not done here.** The test cache is still keyed on the stamped compiler (`0 cached, N ran` after a merge); it needs no re-run for the reseed any more, but a developer who wants `:test` on main after a merge still pays for it.

**Reopen if** a nondeterminism is found that makes two builds of one identity behave differently; fix that, do not re-key on the binary.

---
