//! expect-stdout: ok
use compiler.AbiStamp

// #1330: a compiler image linked as a program (`with build main.w`, the
// failure-diagnostics probe) carries the ABI slot's sentinel while the
// bundles it embeds carry the tree's digest. An unstamped identity has
// nothing to compare, so it links its bundles unchecked; a stamped one
// still refuses another ABI (#761). This test binary is itself unstamped.
fn main:
    let digest = "5f7b970ec04c356505099ebd9f7ef45baba7b9f4763e532f60cf8780b620095a"
    let other = "73e63de016b2d136878a24cb2c519472bd55f0af3357b4e2cc408cf168aee2d3"
    assert(not compiler_abi_sha_is_stamped())
    assert(not abi_identity_refuses_bundle(compiler_abi_sha(), digest))
    assert(not abi_identity_refuses_bundle(digest, digest))
    assert(abi_identity_refuses_bundle(digest, other))
    print("ok")
