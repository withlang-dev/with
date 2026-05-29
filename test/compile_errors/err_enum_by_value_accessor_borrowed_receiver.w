//! expect-check-fail: by-value enum accessor requires an owned enum receiver

enum BorrowedAccessorToken { Int(i32) | Text(str) }

fn bad_borrowed_receiver_accessor:
    let token = BorrowedAccessorToken.Int(1)
    let borrowed = &token
    let _payload = borrowed.as_int()
