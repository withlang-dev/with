//! expect-stdout: ok
use compiler.ConanClient

fn main:
    assert(conan_library_name_from_path("lib/libcrypto.lib") == "libcrypto")
    assert(conan_library_name_from_path("lib/libssl.lib") == "libssl")
    assert(conan_library_name_from_path("lib/libcurl_imp.lib") == "libcurl_imp")
    assert(conan_library_name_from_path("lib/curl.lib") == "curl")
    assert(conan_library_name_from_path("lib/zlibstatic.lib") == "zlibstatic")
    assert(conan_library_name_from_path("lib/lib.lib") == "lib")
    assert(conan_library_name_from_path("lib/libcrypto.a") == "crypto")
    assert(conan_library_name_from_path("lib/libcrypto.so") == "crypto")
    assert(conan_library_name_from_path("lib/libcrypto.so.4") == "crypto")
    assert(conan_library_name_from_path("lib/libcrypto.dylib") == "crypto")
    assert(conan_library_name_from_path("lib/crypto.a") == "crypto")
    assert(conan_library_name_from_path("include/openssl/evp.h") == "")
    print("ok")
