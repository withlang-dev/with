//! expect-error: shadowing is not allowed for 'ptr': it names a field of the receiver `Handle`, which this method reaches by its bare name (§9.5)

// §9.5 (#1930), §29.8: a local binding named like a receiver field.

type Handle {
    ptr: i64,
}

impl Handle:
    fn address -> i64:
        let ptr = self.ptr
        ptr + 1

fn main:
    let h = Handle { ptr: 7 }
    print(f"{h.address()}")
