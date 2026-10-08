//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// §9.1 / D60 with D32: the tail assignment yields a read of `self.items`,
// and a field never moves out implicitly — the error the tail `self.items`
// gets. A Vec field, not a str: a str field is copied (D111).

type Holder { n: i32, items: Vec[i32] }
extend Holder:
    mut fn replace(v: Vec[i32]) -> Vec[i32]: self.items = v

fn main:
    var h = Holder { n: 0, items: Vec.new() }
    print(h.replace([1]).len())
