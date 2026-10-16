//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// §9.1 / D60 with D32: the tail assignment yields a read of `self.items`,
// and a field never moves out implicitly — the error the tail `self.items`
// gets. A List field, not a str: a str field is copied (D111).

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
type Holder { n: i32, items: List[Tok] }
extend Holder:
    mut fn replace(v: List[Tok]) -> List[Tok]: self.items = v

fn main:
    var h = Holder { n: 0, items: List.new() }
    print(h.replace([Tok { id: 1 }]).len())
