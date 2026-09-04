// T23/#988 negative control: annotated impl return mismatches the trait
// (check_trait_impl_method_signature_contract :2015, contract built by
// trait_impl_method_contract :1976 via name-only method match :1992).
// Expect check FAIL: return type does not match.
trait Getter:
    fn get(self: &Self) -> i32

type Box { x: i32 }

impl Getter for Box:
    fn get(self: &Self) -> str:
        "wrong"

fn main:
    let b = Box { x: 1 }
    print(int_to_string(b.get()))
