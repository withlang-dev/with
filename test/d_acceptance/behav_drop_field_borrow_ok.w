//! expect-stdout: ok

// [A5] #607 false-reject guard (floor-blind — no other Vec[Drop] on the floor):
// Path (C) rejects only *consuming moves* of a needs-drop field out of a struct. It
// must NOT reject the legitimate, non-consuming uses of such a field: borrowing it,
// calling a borrowing method on it, or reading a non-Drop (Copy) sibling field. All
// of the below compile and run cleanly.
//
// Iterating the field (`for w in h.items`) likewise must (and does) compile without
// the reject firing — verified separately. It is omitted from this *runtime* probe
// because iterating a Vec[Drop] field hits a distinct, pre-existing double-free under
// the current collapse move model (a #607-family bug, independent of this reject).

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        ()

type Holder { items: Vec[W], count: i32 }

fn borrow_len(h: &Holder) -> i64:
    h.items.len()                 // borrow the struct, borrowing method on the field — OK

fn main:
    let xs: Vec[W] = Vec.new()
    xs.push(W { tag: 3 })
    xs.push(W { tag: 4 })
    let h = Holder { items: xs, count: 9 }
    let n = h.items.len()         // borrowing method call on the field — OK
    let c = h.count               // non-Drop (Copy) sibling field read — OK
    let bl = borrow_len(&h)       // borrow whole struct, use the field — OK
    if n == 2 and c == 9 and bl == 2:
        print("ok")
    else:
        print_i32(c)
