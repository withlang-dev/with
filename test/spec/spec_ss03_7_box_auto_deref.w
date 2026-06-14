// Spec test: Section 3.7 — Box auto-dereferencing.

type BoxAutoDerefUser { name: str, score: i32 }

impl BoxAutoDerefUser:
    fn label(self: &Self) -> str:
        self.name

fn test_box_auto_deref_field:
    let user: Box[BoxAutoDerefUser] = Box.new(BoxAutoDerefUser { name: "Ada", score: 9 })
    assert(user.name == "Ada")

fn test_box_auto_deref_method:
    let user: Box[BoxAutoDerefUser] = Box.new(BoxAutoDerefUser { name: "Grace", score: 11 })
    assert(user.label() == "Grace")

fn test_box_auto_deref_through_reference:
    let user: Box[BoxAutoDerefUser] = Box.new(BoxAutoDerefUser { name: "Barbara", score: 13 })
    let r = &user
    let rr = &r
    assert(rr.name == "Barbara")
    assert(rr.label() == "Barbara")
