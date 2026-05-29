//! expect-check-fail: cannot implement Copy because it implements Drop

type CopySafetyHandle { fd: i32 }

impl Drop for CopySafetyHandle:
    fn drop(self) -> void:
        let _ = self.fd

impl Copy for CopySafetyHandle
