//! expect-stdout: CoreFoundation linked: true

// #1915 (:no-host-toolchain): a program whose dependency links an Apple
// framework, as a `with get` package does (glfw links Cocoa, IOKit, ...).
// The check writes the dependency's metadata.json into .with/deps/c/cfstub
// and generates its CoreFoundation stub from the running OS with
// `with __framework-stubs`, the step `with get` runs; no Apple SDK is read.

extern fn CFAbsoluteTimeGetCurrent() -> f64

fn main:
    let now = unsafe { CFAbsoluteTimeGetCurrent() }
    print(f"CoreFoundation linked: {now > 0.0}")
