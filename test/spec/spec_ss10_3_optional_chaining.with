// Spec test: Section 10.3 — Optional Chaining (formerly 25.37)

type Address { city: Option[str], zip: Option[str] }
type Profile { address: Option[Address] }

// PASS: optional chaining on Option
fn test_optional_chaining_some:
    let profile = Profile { address: Some(Address { city: Some("NYC"), zip: None }) }
    let city: Option[str] = profile.address?.city
    assert(city.is_some())
    assert(city.unwrap() == "NYC")

// PASS: chained optional access
fn test_optional_chaining_none:
    let profile = Profile { address: None }
    let city: Option[str] = profile.address?.city
    assert(city.is_none())

// PASS: optional chaining with ?? default
fn test_optional_chaining_default:
    let profile = Profile { address: None }
    let city = profile.address?.city ?? "unknown"
    assert(city == "unknown")
