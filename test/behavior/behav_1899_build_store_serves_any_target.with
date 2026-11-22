//! expect-stdout: ok

// #1899: the machine-wide build store serves every cacheable target whose
// outputs are the same in every worktree, not only the ones that name a
// compiler: a second worktree's `:dev` restored 25 targets and ran 39 more
// (sysroots, generated sources, placeholder objects), four minutes of work.
// A served target is exactly a fresh one (the freshness check verifies it
// after the restore), a changed input misses, an output that names the
// worktree it was made in is never stored, and an argument naming a path in
// the tree is the same argument in every worktree.

use BuildGraphCache
use BuildGraphModel
use BuildGraphOps
use std.fs
use std.process

fn action(name: str, output: str, arg: str) -> BuildGraphTarget:
    var target = empty_build_graph_target()
    target.kind = 23
    target.name = name
    target.output = output
    target.inputs.push("in.txt")
    if arg.len() > 0: target.args.push(arg)
    target

fn worktree(base: &str, name: &str, input: &str) -> str:
    let root = base ++ "/" ++ name
    assert(mkdir_p(root ++ "/out") == 0)
    assert(write_file(root ++ "/in.txt", input) == 0)
    root

// What the action makes in `root`, recorded there (and so published).
fn run(root: &str, target: &BuildGraphTarget, text: &str):
    let empty: List[str] = List.new()
    assert(write_file(root ++ "/" ++ target.output, text) == 0)
    build_cache_record(root, target, empty, empty)
    assert(build_cache_freshness_reason(root, target, false) == "fresh")

fn main:
    let base = f"out/tmp/build-store-{pid()}"
    assert(set_env("WITH_BUILD_CACHE_DIR", base ++ "/store") == 0)
    let a = worktree(base, "a", "input\n")

    // An action that names no compiler, made in a and served to b.
    let plain = action("gen-text", "out/gen.txt", "")
    run(a, &plain, "generated\n")
    let b = worktree(base, "b", "input\n")
    assert(build_cache_freshness_reason(b, &plain, false) == "stale: no cache state")
    assert(build_cache_store_restore(b, &plain))
    assert(read_file(b ++ "/out/gen.txt").unwrap() == "generated\n")
    assert(build_cache_freshness_reason(b, &plain, false) == "fresh")

    // A changed input misses.
    let c = worktree(base, "c", "other input\n")
    assert(not build_cache_store_restore(c, &plain))

    // An output that names the worktree it was made in is not stored.
    let naming = action("names-root", "out/names.txt", "")
    run(a, &naming, "made in " ++ a ++ "/out\n")
    assert(not build_cache_store_restore(b, &naming))

    // An argument naming a path in the tree is the same argument in b.
    let in_a = action("rooted-arg", "out/rooted.txt", "prefix=" ++ a ++ "/sdk")
    run(a, &in_a, "rooted\n")
    let in_b = action("rooted-arg", "out/rooted.txt", "prefix=" ++ b ++ "/sdk")
    assert(build_cache_store_restore(b, &in_b))
    assert(build_cache_freshness_reason(b, &in_b, false) == "fresh")

    // An embed target's assembly names its blobs from the root, so it is the
    // same text in every worktree. (Assembling it, which resolves the names
    // against the root, needs the LLVM bridge a test program does not link;
    // every `:dev` assembles bootstrap-embedded-objects-asm this way.)
    assert(write_file(a ++ "/blob.bin", "blob bytes") == 0)
    var embed = empty_build_graph_target()
    embed.kind = 17
    embed.name = "embed-asm"
    embed.output = "out/embedded.s"
    embed.inputs.push("blob.bin")
    embed.args.push("blob_bin")
    assert(build_graph_embed_object_files(a, &embed) == 0)
    let text = read_file(a ++ "/out/embedded.s").unwrap()
    assert(text.contains(".incbin \"blob.bin\"") and not text.contains(a))

    assert(remove_tree(base) == 0)
    print("ok")
