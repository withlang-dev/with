//! expect-error: cannot infer generic type for 'never'; add a type annotation

// #2103: a bare variant of a generic enum that nothing ever settles has no
// type: Sema says so (it used to say ok, and codegen failed).

fn main:
    var never = None
    print("x")
