//! expect-debug-alloc: leak count=0
//! expect-stdout: true 34 34
//! expect-stdout: 34 34 34
// A tuple's owned field takes a copy of a view element: `(true,
// self.val[n])` into `(bool, str)` is one more holder of the str. MIR judged
// the field by the element's own type (`&str`, the D27 element view), never
// retained, and the tuple and the list each freed the buffer once (found in
// the OpenSSL template expander's trie; the field type is Sema's tuple
// type's, D65).
type T { val: List[str] }

impl T:
    fn get(n: i32) -> (bool, str):
        if n >= 0: return (true, self.val[n])
        (false, "")
    fn both(n: i32) -> (str, str): (self.val[n], self.val[n])

fn main:
    let t = T { val: ["OSSL_PKEY_PARAM_RSA_DERIVE_FROM_PQ".replace("x", "y")] }
    let (found, s) = t.get(0)
    print(f"{found} {s.len()} {t.val[0].len()}")
    let (a, b) = t.both(0)
    print(f"{a.len()} {b.len()} {t.val[0].len()}")
