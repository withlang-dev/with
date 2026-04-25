//! skip
// Spec test: Section 10.3 — Optional Chaining (formerly 25.37)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

type Address { city: Option[str], zip: Option[str] }
type Profile { address: Option[Address] }

// PASS: optional chaining on Option
fn test:
    let profile = Profile { address: Some(Address { city: Some("NYC"), zip: None }) }
    let city = profile.address?.city
    assert(city == Some("NYC"))

// PASS: chained optional access
fn test:
    let profile = Profile { address: None }
    let city = profile.address?.city
    assert(city == None)

// PASS: optional chaining with ?? default
fn test:
    let profile = Profile { address: None }
    let city = profile.address?.city ?? "unknown"
    assert(city == "unknown")
