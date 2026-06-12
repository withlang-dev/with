use c_import("openssl/evp.h")

fn main:
    let input = "abc"
    var digest: [u8; 32] = [0 as u8; 32]
    var digest_len: c_uint = 0 as c_uint

    let ctx = unsafe { EVP_MD_CTX_new() }
    if ctx == null:
        print("openssl ctx failed")
        return 1

    let md = unsafe { EVP_sha256() }
    if md == null:
        print("openssl sha256 failed")
        unsafe { EVP_MD_CTX_free(ctx) }
        return 1

    if unsafe { EVP_DigestInit_ex(ctx, md, null) } != 1:
        print("openssl digest init failed")
        unsafe { EVP_MD_CTX_free(ctx) }
        return 1
    if unsafe { EVP_DigestUpdate(ctx, input as *const c_void, input.len() as c_ulong) } != 1:
        print("openssl digest update failed")
        unsafe { EVP_MD_CTX_free(ctx) }
        return 1
    if unsafe { EVP_DigestFinal_ex(ctx, &raw mut digest[0] as *mut u8, &raw mut digest_len as *mut c_uint) } != 1:
        print("openssl digest final failed")
        unsafe { EVP_MD_CTX_free(ctx) }
        return 1
    unsafe { EVP_MD_CTX_free(ctx) }

    if digest_len != 32 as c_uint:
        print("openssl digest length mismatch")
        return 1
    if digest[0] != 0xba as u8 or digest[1] != 0x78 as u8 or digest[2] != 0x16 as u8 or digest[3] != 0xbf as u8:
        print("openssl digest prefix mismatch")
        return 1
    if digest[28] != 0xf2 as u8 or digest[29] != 0x00 as u8 or digest[30] != 0x15 as u8 or digest[31] != 0xad as u8:
        print("openssl digest suffix mismatch")
        return 1
    write("openssl UAT passed\n")
