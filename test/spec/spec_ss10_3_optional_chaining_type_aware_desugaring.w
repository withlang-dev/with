//! skip: non-executable spec sketch for Section 10.3 — Optional Chaining Type-Aware Desugaring (formerly 25.79); contains pseudo-code for unimplemented feature work
// Spec test: Section 10.3 — Optional Chaining Type-Aware Desugaring (formerly 25.79)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

type Address { city: Option[str], zip: str }
type Profile { address: Option[Address] }

// PASS: field is non-Option → map
fn test:
    let p = Profile { address: Some(Address { city: Some("NYC"), zip: "10001" }) }
    let zip: Option[str] = p.address?.zip    // map → Option[str]

// PASS: field is Option → and_then (flattened)
fn test:
    let p = Profile { address: Some(Address { city: Some("NYC"), zip: "10001" }) }
    let city: Option[str] = p.address?.city  // and_then → Option[str], NOT Option[Option[str]]

// PASS: chaining works correctly
fn test:
    let p = Profile { address: Some(Address { city: Some("NYC"), zip: "10001" }) }
    let len: Option[usize] = p.address?.city?.len()  // chains naturally
