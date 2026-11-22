//! expect-check-fail: mutable enum accessor requires a place receiver

enum MutAccessorTemporaryToken { Num(i32) | Text(str) }

fn bad_mut_accessor_temporary_receiver:
    let _payload = MutAccessorTemporaryToken.Num(1).as_num_mut()
