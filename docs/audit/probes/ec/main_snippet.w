fn check2(a: u8, b: i32) -> bool:
    (a as i32) == b

fn main:
    var p1: [u8; 32] = [0u8; 32]
    p1[31] = 1u8
    var pub1: [u8; 65] = [0u8; 65]
    unsafe { p256_compute_public(&p1[0] as *const u8, &raw mut pub1[0] as *mut u8) }
    assert((pub1[0] as i32) == 0x04)
    assert((pub1[1] as i32) == 0x6b)
    assert((pub1[2] as i32) == 0x17)
    assert((pub1[32] as i32) == 0x96)
    assert((pub1[33] as i32) == 0x4f)
    assert((pub1[64] as i32) == 0xf5)
    var p2: [u8; 32] = [0u8; 32]
    p2[31] = 2u8
    var pub2: [u8; 65] = [0u8; 65]
    unsafe { p256_compute_public(&p2[0] as *const u8, &raw mut pub2[0] as *mut u8) }
    assert((pub2[1] as i32) == 0x7c)
    assert((pub2[2] as i32) == 0xf2)
    assert((pub2[32] as i32) == 0x78)
    assert((pub2[33] as i32) == 0x07)
    assert((pub2[64] as i32) == 0xd1)
    var d: [u8; 32] = [
        0xC9u8, 0xAFu8, 0xA9u8, 0xD8u8, 0x45u8, 0xBAu8, 0x75u8, 0x16u8,
        0x6Bu8, 0x5Cu8, 0x21u8, 0x57u8, 0x67u8, 0xB1u8, 0xD6u8, 0x93u8,
        0x4Eu8, 0x50u8, 0xC3u8, 0xDBu8, 0x36u8, 0xE8u8, 0x9Bu8, 0x12u8,
        0x7Bu8, 0x8Au8, 0x62u8, 0x2Bu8, 0x12u8, 0x0Fu8, 0x67u8, 0x21u8,
    ]
    var pub3: [u8; 65] = [0u8; 65]
    unsafe { p256_compute_public(&d[0] as *const u8, &raw mut pub3[0] as *mut u8) }
    assert((pub3[1] as i32) == 0x60)
    assert((pub3[5] as i32) == 0x25)
    assert((pub3[32] as i32) == 0xb6)
    assert((pub3[33] as i32) == 0x79)
    assert((pub3[60] as i32) == 0x94)
    assert((pub3[64] as i32) == 0x99)
    var pa: [u8; 32] = [0u8; 32]
    pa[31] = 3u8
    var pb: [u8; 32] = [0u8; 32]
    pb[31] = 5u8
    var pua: [u8; 65] = [0u8; 65]
    var pubb: [u8; 65] = [0u8; 65]
    unsafe {
        p256_compute_public(&pa[0] as *const u8, &raw mut pua[0] as *mut u8)
        p256_compute_public(&pb[0] as *const u8, &raw mut pubb[0] as *mut u8)
    }
    var sa: [u8; 32] = [0u8; 32]
    var sb: [u8; 32] = [0u8; 32]
    unsafe {
        p256_ecdh(&pa[0] as *const u8, &pubb[0] as *const u8, &raw mut sa[0] as *mut u8)
        p256_ecdh(&pb[0] as *const u8, &pua[0] as *const u8, &raw mut sb[0] as *mut u8)
    }
    var i = 0
    while i < 32:
        assert((sa[i] as i32) == (sb[i] as i32))
        i = i + 1
    // openssl pkeyutl -derive oracle for 3*(5G): f0454dc6971abae7...
    var exp: [u8; 32] = [
        0xf0u8, 0x45u8, 0x4du8, 0xc6u8, 0x97u8, 0x1au8, 0xbau8, 0xe7u8,
        0xadu8, 0xfbu8, 0x37u8, 0x89u8, 0x99u8, 0x88u8, 0x82u8, 0x65u8,
        0xaeu8, 0x03u8, 0xafu8, 0x92u8, 0xdeu8, 0x3au8, 0x0eu8, 0xf1u8,
        0x63u8, 0x66u8, 0x8cu8, 0x63u8, 0xe5u8, 0x9bu8, 0x9du8, 0x5fu8,
    ]
    var j = 0
    while j < 32:
        assert((sa[j] as i32) == (exp[j] as i32))
        j = j + 1
    print("ec-probe-pass")
