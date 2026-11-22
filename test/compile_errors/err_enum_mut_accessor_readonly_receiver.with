//! expect-check-fail: cannot call mutable enum accessor through a read-only place

enum MutAccessorReadonlyToken { Num(i32) | Text(str) }

fn bad_mut_accessor_readonly_receiver:
    let token = MutAccessorReadonlyToken.Num(1)
    let borrowed = &token
    let _payload = borrowed.as_num_mut()
