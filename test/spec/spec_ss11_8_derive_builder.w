//! expect-stdout: ok

@[derive(Builder)]
type Config {
    host: str,
    port: i32 = 8080,
}

@[derive(Builder)]
type GenericConfig[T] {
    value: T,
    label: str = "default",
}

fn test_required_and_default_fields:
    let c = Config.builder().host("localhost").build().unwrap()
    assert(c.host == "localhost")
    assert(c.port == 8080)

fn test_override_default:
    let c = Config.builder().host("prod.example.com").port(443).build().unwrap()
    assert(c.port == 443)

fn test_missing_required_field:
    let builder = Config.builder()
    let missing = builder.build()
    match missing:
        Err(.MissingField(field)) => assert(field == "host")
        _ => assert(false)

fn test_generic_builder:
    let c = GenericConfig[i32].builder().value(7).build().unwrap()
    assert(c.value == 7)
    assert(c.label == "default")

fn main:
    test_required_and_default_fields()
    test_override_default()
    test_missing_required_field()
    test_generic_builder()
    print("ok")
