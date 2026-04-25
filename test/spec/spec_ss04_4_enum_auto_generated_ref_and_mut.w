//! skip
// Spec test: Section 4.4 — Enum Auto-Generated _ref and _mut (formerly 25.93)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: as_variant_ref returns Option[&T]
enum Value { Str(str) | Num(f64) | Null }

fn test:
    let v = Value.Str("hello")
    assert(v.as_str_ref() == Some(&"hello"))
    assert(v.as_num_ref() == None)

// PASS: as_variant_mut returns Option[&mut T]
fn test:
    var v = Value.Num(42.0)
    if let Some(n) = v.as_num_mut():
        *n = 99.0
    assert(v.as_num_ref() == Some(&99.0))

// PASS: navigating tree structures by reference
enum Json { Null | Bool(bool) | Num(f64) | Str(str) }
         | Array(Vec[Json]) | Object(HashMap[str, Json])

fn test:
    let data = Json.Object(/* ... */)
    let name = data.as_object_ref()?.get("name")?.as_str_ref()
    assert(name.is_some())
