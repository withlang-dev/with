// Spec test: Section 10.3 - Optional Chaining Type-Aware Desugaring (formerly 25.79)

type Address { city: Option[str], zip: str }
type Profile { address: Option[Address] }

fn test_optional_chain_wraps_non_option_field:
    let p = Profile { address: Some(Address { city: Some("NYC"), zip: "10001" }) }
    let zip: Option[str] = p.address?.zip
    assert(zip.is_some())
    assert(zip.unwrap() == "10001")

fn test_optional_chain_flattens_option_field:
    let p = Profile { address: Some(Address { city: Some("NYC"), zip: "10001" }) }
    let city: Option[str] = p.address?.city
    assert(city.is_some())
    assert(city.unwrap() == "NYC")

fn test_optional_chain_flattened_none:
    let p = Profile { address: Some(Address { city: None, zip: "10001" }) }
    let city: Option[str] = p.address?.city
    assert(city.is_none())

fn test_optional_chain_method_wraps_non_option_return:
    let p = Profile { address: Some(Address { city: Some("NYC"), zip: "10001" }) }
    let len: Option[usize] = p.address?.city?.len()
    assert(len.is_some())
    assert(len.unwrap() == 3)
