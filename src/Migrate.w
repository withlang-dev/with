// Migrate — Source code translator from rust/zig/swift to With.
//
// This is a stub in the self-hosted compiler; the full implementation
// requires file system traversal and language-specific parsing.
// Direct port of bootstrap/src/Migrate.zig to With.

extern fn with_eprint(s: str) -> void

enum MigrateLang: i32:
    Rust = 0
    Zig = 1
    Swift = 2

enum MigrateMode: i32:
    Write = 0
    Check = 1
    Diff = 2

fn run(lang: str, path: str, mode: i32) -> i32:
    with_eprint("migrate: not yet implemented in self-hosted compiler")
    1
