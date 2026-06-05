// rt/fiber_core_windows_stub.w -- placeholder fiber core for Windows bootstrap.
//
// Non-async Windows builds link fiber_stubs.o for the public lifecycle surface.
// This object exists so the build graph mirrors Linux/Darwin until the real
// Windows fiber backend is implemented.

pub fn with_windows_fiber_core_stub() -> i32:
    0
