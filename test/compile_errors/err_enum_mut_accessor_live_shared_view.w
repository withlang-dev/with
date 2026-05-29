//! expect-check-fail: cannot borrow mutably: already borrowed

enum MutAccessorBorrowToken { Num(i32) | Text(str) }

fn bad_mut_accessor_live_shared_view:
    let token = MutAccessorBorrowToken.Num(1)
    let view = &token
    let _payload = token.as_num_mut()
    assert((*view).is_num())
