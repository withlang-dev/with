//! expect-stdout: gdi32 linked: true
//! expect-stdout: winmm linked: true
//! expect-stdout: opengl32 linked: true

// #1915 (:no-host-toolchain, Windows): a program whose dependency links
// in-box DLLs the SDK has no import library for, as a `with get` package
// does (glfw links gdi32, raylib winmm and opengl32). The check writes the
// dependency's metadata.json into .with/deps/c/dllstub and generates its
// import libraries from mingw-w64's definitions with
// `with __windows-import-libs`, the step `with get` runs; no Visual Studio
// or Windows SDK is read.

extern fn GetStockObject(which: i32) -> *mut u8
extern fn timeGetTime() -> u32
extern fn wglGetCurrentContext() -> *mut u8

fn main:
    // BLACK_BRUSH (4): a stock object every session has.
    let brush = unsafe { GetStockObject(4) }
    print(f"gdi32 linked: {brush != null}")
    let now = unsafe { timeGetTime() }
    print(f"winmm linked: {now > 0}")
    // No GL context is current on this thread.
    let context = unsafe { wglGetCurrentContext() }
    print(f"opengl32 linked: {context == null}")
