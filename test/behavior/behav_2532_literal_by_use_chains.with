//! expect-stdout: 2 1

// #2532 (D93): a binding's literal takes its type from its uses, and a
// use can become typed only once another such binding is decided
// (`files.push(p)` demands of `files` once `p`, an element of
// `site_paths`, has a type). The program is checked until no demand
// changes a binding's type.
fn main:
    var site_paths = []
    site_paths.push("x")
    site_paths.push("y")
    site_paths.push("x")
    var files = []
    for p in site_paths:
        if not files.contains(p): files.push(p)
    // A third link: a list built from `files`.
    var lengths = []
    for f in files: lengths.push(f.len())
    print(f"{files.len()} {lengths[1]}")
