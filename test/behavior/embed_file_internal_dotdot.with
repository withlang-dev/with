//! expect-stdout: inner-dotdot-ok
// #585: a '..' segment whose NORMALIZED path stays inside the package root is
// legal — embed_file resolves relative to the source file, normalizes, and
// only rejects paths that actually leave the root.
const DATA: str = embed_file("lib/embed_dotdot/../embed_dotdot/data.txt")

fn main:
    print(DATA)
