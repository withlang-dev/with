// Spec test: Section 3.7 — Auto-Dereferencing (formerly 25.90)

type AutoDerefUser { name: str, score: i32 }

impl AutoDerefUser:
    fn label(self: &Self) -> str:
        self.name

type AutoDerefHandle { ptr: *const AutoDerefUser }

impl Deref[AutoDerefUser] for AutoDerefHandle:
    fn deref(self: &Self) -> &AutoDerefUser:
        unsafe { self.ptr as &AutoDerefUser }

type AutoDerefBox[T] { ptr: *const T }

impl[T] Deref[T] for AutoDerefBox[T]:
    fn deref(self: &Self) -> &T:
        unsafe { self.ptr as &T }

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

fn test_auto_deref_field_through_user_deref:
    let user = AutoDerefUser { name: "Lin", score: 13 }
    let handle = AutoDerefHandle { ptr: &raw const user as *const AutoDerefUser }
    assert(handle.name == "Lin")

fn test_auto_deref_method_receiver_through_user_deref:
    let user = AutoDerefUser { name: "Barbara", score: 17 }
    let handle = AutoDerefHandle { ptr: &raw const user as *const AutoDerefUser }
    assert(handle.label() == "Barbara")

fn test_auto_deref_user_deref_plus_references:
    let user = AutoDerefUser { name: "Katherine", score: 19 }
    let handle = AutoDerefHandle { ptr: &raw const user as *const AutoDerefUser }
    let r = &handle
    let rr = &r
    assert(rr.name == "Katherine")
    assert(rr.label() == "Katherine")

fn test_auto_deref_generic_wrapper:
    let user = AutoDerefUser { name: "Edsger", score: 23 }
    let wrapped: AutoDerefBox[AutoDerefUser] = AutoDerefBox { ptr: &raw const user as *const AutoDerefUser }
    assert(wrapped.name == "Edsger")
    assert(wrapped.label() == "Edsger")

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
