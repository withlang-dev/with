// SemaDecl probe: uninferable type param (ensure_generic_substitutions L2861)
fn semadecl_only_mentions_ret[T]() -> T:
    0 as T

fn main:
    let x = semadecl_only_mentions_ret()
    print(x)
