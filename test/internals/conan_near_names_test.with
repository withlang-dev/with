//! expect-stdout: ok
// #3170: `with get c.nghttp2` could not resolve the package; the recipe is
// libnghttp2. Conan Center's search is a substring match, so its results
// hold the near names: the refusal names them (at most five, distinct, never
// the name itself).
use compiler.ConanClient

fn main:
    let results = ["libnghttp2/1.64.0@_/_", "libnghttp2/1.65.0@_/_", "nghttp2-asio/0.1@_/_", "nghttp2/1.0@_/_"]
    assert(conan_near_names_in(results, "nghttp2") == "`libnghttp2`, `nghttp2-asio`")
    let many = ["a1/1@_/_", "a2/1@_/_", "a3/1@_/_", "a4/1@_/_", "a5/1@_/_", "a6/1@_/_", "a7/1@_/_"]
    assert(conan_near_names_in(many, "a") == "`a1`, `a2`, `a3`, `a4`, `a5` and 2 more")
    assert(conan_near_names_in([], "zlib") == "")
    // #2974: C's `lib` prefix, either way round.
    let curls = ["curlpp/0.8.1@_/_", "libcurl/8.1.0@_/_", "libcurl/8.2.0@_/_"]
    assert(conan_lib_twin_in(curls, "curl") == "libcurl")
    assert(conan_lib_twin_in(["zlib/1.3.2@_/_"], "libzlib") == "zlib")
    assert(conan_lib_twin_in(curls, "png") == "")
    assert(conan_near_names_in(["zlib/1.3.2@_/_"], "zlib") == "")
    print("ok")
