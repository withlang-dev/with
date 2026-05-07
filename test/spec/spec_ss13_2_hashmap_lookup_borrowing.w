//! skip: non-executable spec sketch for Section 13.2 — HashMap Lookup Borrowing (formerly 25.81); contains pseudo-code for unimplemented feature work
// Spec test: Section 13.2 — HashMap Lookup Borrowing (formerly 25.81)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: HashMap::get borrows from the map, not the key
fn test:
    var map = HashMap.new()
    map.insert("admin", User { name: "Alice" })
    let user = {
        let key: str = "admin"
        map.get(key.as_view())    // compiler knows: borrows map, not key
    }                              // key drops here, user still valid
    assert(user.is_some())
