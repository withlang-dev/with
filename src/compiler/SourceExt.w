// With source files are named `.with`. `.w` is the retired spelling, which
// the toolchain still finds while the tree and its users change over. The
// extension governs what the toolchain discovers (a module from `use`, the
// tests in a directory, the sources a build names by pattern), never a file
// the user names on the command line.

/// The length of `path`'s source extension, dot included; 0 when it has none.
fn source_ext_len(path: &str) -> isize:
    if path.ends_with(".with"): 5 else if path.ends_with(".w"): 2 else: 0

/// Whether the toolchain discovers `path` as a With source file.
fn source_ext_is_source(path: &str) -> bool: source_ext_len(path) > 0

/// `path` without its source extension.
fn source_ext_stem(path: &str) -> str: path.slice(0, path.len() - source_ext_len(path))
