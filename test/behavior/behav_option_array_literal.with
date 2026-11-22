//! expect-stdout: ok

// #586: Option-valued array literals — elements must lower under the ARRAY'S
// ELEMENT type, not the ambient expected type. The annotated form failed
// codegen; the UN-annotated form compiled and ran with silently corrupted
// values (§4.3c expected-type-driven literals).

fn main:
    let sized: [?i32; 3] = [Some(1), None, Some(4)]
    assert(sized.len() == 3)
    match sized[0]:
        Some(v) => assert(v == 1)
        None => assert(false)
    match sized[1]:
        Some(v) => assert(false)
        None => ()
    match sized[2]:
        Some(v) => assert(v == 4)
        None => assert(false)
    let inferred = [Some(10), None, Some(40)]
    var total = 0
    for o in inferred:
        match o:
            Some(v) => total = total + v
            None => total = total + 1
    assert(total == 51)
    print("ok")
