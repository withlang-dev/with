//! expect-check-fail: ephemeral references cannot be stored in generic containers
// §3.3: a struct field holds no container of views (§22.1 rule 4; a
// local `List[&T]` is an ephemeral container, D142).
type Holder { refs: List[&i32] }

fn bad:
    let x = 42
    var refs: List[&i32] = List.new()
    refs.push(&x)
    let h = Holder { refs: refs }
    print(f"{h.refs.len()}")
