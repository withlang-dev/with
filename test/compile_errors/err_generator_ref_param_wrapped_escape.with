//! expect-check-fail: returned ephemeral value may outlive its origin 'values'

type Holder[T] {
    value: T,
}

gen fn values_from(source: &List[i32]) -> i32:
    yield source.len() as i32

fn bad:
    let values: List[i32] = [1, 2, 3]
    return Holder { value: values_from(&values) }
