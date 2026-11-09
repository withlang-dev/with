//! expect-stdout: ok
// #3168: a configured tree has not made the headers its build generates,
// so the facade could not read a unit that includes one (libpng's
// pnglibconf.h: 0 functions). `with get` builds exactly the custom-command
// outputs that are headers, read from `ninja -t targets all`. Each output
// is listed twice (relative and absolute); CMake's utilities and the
// non-header outputs are not built.
use compiler.ConanClient

fn main:
    let listing = "CMakeFiles/edit_cache.util: CUSTOM_COMMAND\nCMakeFiles/png_genprebuilt: CUSTOM_COMMAND\n/abs/b/CMakeFiles/png_genprebuilt: CUSTOM_COMMAND\nlibpng.sym: CUSTOM_COMMAND\npnglibconf.c: CUSTOM_COMMAND\npnglibconf.h: CUSTOM_COMMAND\n/abs/b/pnglibconf.h: CUSTOM_COMMAND\npngprefix.h: CUSTOM_COMMAND\nscripts/sym.inc: CUSTOM_COMMAND\npng.c.o: C_COMPILER__png_static_Release\nall: phony\n"
    let headers = conan_generated_header_targets(listing)
    assert(headers.len() == 3, f"{headers.len()}")
    assert(headers[0] == "pnglibconf.h" and headers[1] == "pngprefix.h" and headers[2] == "scripts/sym.inc")
    assert(conan_generated_header_targets("").len() == 0)
    print("ok")
