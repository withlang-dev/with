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
