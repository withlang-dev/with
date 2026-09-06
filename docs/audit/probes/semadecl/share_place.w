// SemaDecl probe: share-place ABI — mut self mutates caller (fn_param_uses_value_ref_abi L1144)
type Counter {
    n: i32,
}

extend Counter:
    fn bump(mut self: Self):
        self.n = self.n + 1

fn main:
    var c = Counter { n: 0, }
    c.bump()
    assert(c.n == 1)
    print("share-place ok")
