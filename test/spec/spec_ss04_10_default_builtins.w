//! expect-stdout: ok

// §4.10: a function whose body falls through returns the default value of its
// return type — 0 for integers, "" for str, empty for List.

fn du32 -> u32:
    ()

fn dusize -> usize:
    ()

fn dstr -> str:
    ()

fn dvec -> List[i32]:
    ()

fn main:
    assert(du32() == 0)
    assert(dusize() == 0)
    assert(dstr() == "")
    assert(dvec().len() == 0)
    print("ok")
