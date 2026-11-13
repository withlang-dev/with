//! expect-check-fail: a profile states a destroyer as a resource rule, '<name>: destroys <pattern>', not as an fn rule

// §31.8.2: the resource owns "f destroys N", in a convention profile too.
c convention things.v1:
    dispose: fn *_dispose destroys

fn main:
    print("unreachable")
