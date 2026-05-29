// Spec test: Section 3.7 — Auto-Dereferencing (formerly 25.90)

type AutoDerefUser { name: str, score: i32 }

impl AutoDerefUser:
    fn label(self: &Self) -> str:
        self.name

fn test_auto_deref_field_through_references:
    let user = AutoDerefUser { name: "Alice", score: 7 }
    let r = &user
    let rr = &r
    assert(rr.name == "Alice")

fn test_auto_deref_method_receiver_through_references:
    let user = AutoDerefUser { name: "Ada", score: 9 }
    let r = &user
    let rr = &r
    assert(rr.label() == "Ada")

fn test_auto_deref_vec_method_through_references:
    var values = Vec.new()
    values.push(10)
    values.push(20)
    let r = &values
    let rr = &r
    assert(rr.len() == 2)

fn test_explicit_value_deref_through_references:
    let x = 42
    let r = &x
    let rr = &r
    assert(**rr == 42)

unsafe fn auto_deref_raw_pointer_score(p: *mut AutoDerefUser) -> i32:
    p.score

unsafe fn auto_deref_raw_pointer_set_score(p: *mut AutoDerefUser, value: i32):
    p.score = value

fn test_auto_deref_raw_pointer_field_inside_unsafe:
    var user = AutoDerefUser { name: "Grace", score: 11 }
    let p = &raw mut user as *mut AutoDerefUser
    assert(unsafe { auto_deref_raw_pointer_score(p) } == 11)
    unsafe { auto_deref_raw_pointer_set_score(p, 12) }
    assert(user.score == 12)
