//! expect-check-fail: ephemeral references cannot be stored in structs

type BadReferenceHolder {
    data: &i32,
}

fn bad:
    let x = 42
    let _ = BadReferenceHolder { data: &x }
