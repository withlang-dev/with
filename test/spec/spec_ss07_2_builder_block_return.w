// Spec test: Section 7.2 - Builder Block Return

type Config {
    timeout: i32,
    retries: i32,
}

fn Config.default() -> Config:
    Config { timeout: 0, retries: 0 }

fn test_assignment_tail_returns_builder:
    let c = with Config { timeout: 0, retries: 0 } as mut c:
        c.timeout = 30
        c.retries = 3
    assert(c.timeout == 30)
    assert(c.retries == 3)

fn test_unit_call_tail_returns_builder:
    let v = with Vec.new() as mut v:
        v.push(1)
        v.push(2)
        v.push(3)
    assert(v.len() == 3)
    assert(v.get(0) == 1)
    assert(v.get(2) == 3)

fn test_non_unit_tail_returns_tail_value:
    let len = with Vec.new() as mut v:
        v.push(1)
        v.push(2)
        v.len()
    assert(len == 2)

fn test_non_unit_hashmap_tail_returns_tail_value:
    let len = with HashMap[str, i32].new() as mut m:
        m.insert("a", 1)
        m.insert("b", 2)
        m.len()
    assert(len == 2)

fn test_builder_expression_as_return_value() -> Config:
    with Config.default() as mut c:
        c.timeout = 30

fn test_returned_builder_value:
    let c = test_builder_expression_as_return_value()
    assert(c.timeout == 30)
    assert(c.retries == 0)
