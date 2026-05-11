//! expect-error: compiler hooks are recognized but not implemented yet

@[compiler_hook(after_typecheck)]
fn lint_project:
    0

