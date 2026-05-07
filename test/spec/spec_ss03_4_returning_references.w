//! skip: non-executable spec sketch for Section 3.4 — Returning References (formerly 25.3); contains pseudo-code for unimplemented feature work
// Spec test: Section 3.4 — Returning References (formerly 25.3)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: return ref, use locally
fn first(xs: &Vec[i32]) -> Option[&i32]:
    if xs.is_empty(): None else: Some(&xs[0])

fn test:
    let v = vec![1, 2, 3]
    match first(&v):
        Some(x) => print(x)
        None    => ()

// PASS: ephemeral to owned conversion
fn get_name(user: &User) -> StrView: user.name.as_view()
fn owned(user: &User) -> String: get_name(user).to_string()
