# spiral

A raylib program: a spiral of colored circles that follows the mouse. It
is the interactive cousin of the release scenario
[`uat/raylib_spiral.uat`](../../uat/raylib_spiral.uat), and it is written
the way a With program talks to C: `use c_import("raylib.h")`, then the
header's functions, structs and constants by their own names, with no
bindings, no build file edits and no `unsafe`.

## Get raylib

The dependency is declared in `with.toml`:

```toml
[deps]
c.raylib = "6.0"
```

Fetch it once:

```sh
with get c.raylib
```

`with get c.<name>` resolves the package from
[Conan Center](https://conan.io/center): a prebuilt binary when one fits
your target, otherwise the package's own CMake build run with the Clang,
CMake and Ninja the compiler carries. Neither Conan nor Python is
installed; the compiler evaluates the recipe itself. The package and its
dependencies (glfw, opengl) land in `.with/deps/`, which is not
committed: a fresh clone has `with.toml` and runs the same command.
`.with/lock.json` records the exact Conan revisions that were fetched.

If `with get` fails with a network error, the fetch needs
[conan.io](https://conan.io) and GitHub reachable; run it again once they
are.

## Build and run

```sh
with build          # out/bin/spiral
with run            # build and open the window
with build :test    # the project's tests
```

Move the mouse; close the window to exit.

## What the program shows

- raylib draws in `f32` and `GetTime()` returns an `f64`, so the clock is
  narrowed once (`GetTime() as f32`) and every later expression stays in
  `f32`. With never converts a number silently where precision can be
  lost (specification §4.2.6), so that single `as` is the whole story; a
  loop index used in float arithmetic takes the same spelling.
- `Vector2 { x, y }` is raylib's own struct, built positionally at the
  call; `Color { r: 14, g: 16, b: 26, a: 255 }` by field; `LIGHTGRAY` and
  `PI` are the header's macros.
- `defer: CloseWindow()` and `defer: EndDrawing()` pair each raylib begin
  with its end at the scope's exit, including the loop body's.
