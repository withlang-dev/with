//! expect-check-fail: field move inside drop cannot be conditional

type ConditionalDropFieldFile { id: str }
impl Drop for ConditionalDropFieldFile:
    fn drop(move self: Self):
        let _ = self.id

type ConditionalDropFieldWrapper { fd: ConditionalDropFieldFile, enabled: bool }
impl Drop for ConditionalDropFieldWrapper:
    fn drop(move self: Self):
        if self.enabled:
            let taken = self.fd
