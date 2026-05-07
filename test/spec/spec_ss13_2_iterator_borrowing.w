//! skip: non-executable spec sketch for Section 13.2 — Iterator Borrowing (formerly 25.75); contains pseudo-code for unimplemented feature work
// Spec test: Section 13.2 — Iterator Borrowing (formerly 25.75)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: stdlib slice iterators work naturally
fn test:
    let names = vec!["alice", "bob", "charlie"]
    let iter = names.iter()
    let a = iter.next().unwrap()    // borrows names, not iter
    let b = iter.next().unwrap()    // OK — no conflict
    assert(a == "alice")
    assert(b == "bob")

// PASS: for loop works with custom iterators too
fn test:
    while let Some(tok) = next_token(&mut parser):
        process(tok)                   // tok drops here, releases &mut parser

// NOTE: custom iterators returning ephemerals may still hit
// conservative borrowing on user-defined types
fn test_custom:
    let tokens = with Vec.new() as mut toks:
        while let Some(tok) = next_owned_token(&mut parser):
            toks.push(tok)             // OwnedToken has no borrows
