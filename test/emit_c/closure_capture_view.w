//! expect-stdout: 3 3
//! expect-stdout: 3
//! expect-stdout: 42 42

// #1766, D62 (§12.4): a non-move closure captures by place: the body reads
// the outer binding through a pointer to its storage, the binding stays
// usable, and a reading closure may be called repeatedly.
type Resource { id: i32 }

fn main:
    let s = "abc"
    let len = () => s.len() as i32
    print(f"{len()} {len()}")
    print(s.len())
    let r = Resource { id: 42 }
    let read_id = () => r.id
    print(f"{read_id()} {r.id}")
