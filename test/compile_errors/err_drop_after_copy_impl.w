//! expect-check-fail: cannot implement Drop because it implements Copy

type DropAfterCopyBad: Copy { x: i32 }

impl Drop for DropAfterCopyBad:
    fn drop(move self: Self):
        let _ = self.x
