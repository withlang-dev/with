//! expect-stdout: ok

use compiler.ConanClient

// A recipe's requirement may be a range (`openssl/[>=3 <4]`). It used to be
// read as "the newest release", so libcurl got openssl 4.0.3.
fn main:
    assert(conan_version_in_range("3.5.4", "[>=3 <4]"))
    assert(conan_version_in_range("3.0.0", "[>=3 <4]"))
    assert(not conan_version_in_range("4.0.3", "[>=3 <4]"))
    assert(not conan_version_in_range("4", "[>=3 <4]"))
    assert(not conan_version_in_range("1.1.1w", "[>=3 <4]"))
    assert(conan_version_in_range("1.1.1w", "[>=1.1 <4]"))
    assert(conan_version_in_range("3.0", "[<=3]"))
    assert(not conan_version_in_range("3.0.1", "[<=3]"))
    assert(conan_version_in_range("5.7.2", "[>=5.6.6 <6]"))
    assert(conan_version_in_range("1.2.9", "[~1.2]"))
    assert(not conan_version_in_range("1.3.0", "[~1.2]"))
    assert(conan_version_in_range("1.9", "[^1.2]"))
    assert(not conan_version_in_range("2.0", "[^1.2]"))
    assert(conan_version_in_range("5.1", "[>=1 <2 || >=5]"))
    assert(not conan_version_in_range("3.1", "[>=1 <2 || >=5]"))
    assert(not conan_version_in_range("3.2.0-beta1", "[>=3 <4]"))
    assert(conan_version_in_range("3.2.0-beta1", "[>=3 <4, include_prerelease]"))
    assert(conan_version_in_range("9.9", "[*]"))
    print("ok")
