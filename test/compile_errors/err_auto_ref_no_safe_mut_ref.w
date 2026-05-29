//! expect-check-fail: `&mut T` is not part of safe With

fn mutate(s: &mut str):
    let _ = s
