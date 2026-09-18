// ── ASN.1 DER parser ───────────────────────────────────────────────

// DER tag classes
let ASN1_SEQUENCE: u8 = 0x30u8
let ASN1_SET: u8 = 0x31u8
let ASN1_INTEGER: u8 = 0x02u8
let ASN1_BIT_STRING: u8 = 0x03u8
let ASN1_OCTET_STRING: u8 = 0x04u8
let ASN1_NULL: u8 = 0x05u8
let ASN1_OID: u8 = 0x06u8
let ASN1_UTF8_STRING: u8 = 0x0Cu8
let ASN1_PRINTABLE_STRING: u8 = 0x13u8
let ASN1_IA5_STRING: u8 = 0x16u8
let ASN1_UTC_TIME: u8 = 0x17u8
let ASN1_GENERALIZED_TIME: u8 = 0x18u8

// Parse a DER tag+length at position pos in buf.
// Returns: content_start (offset past tag+length), content_length.
// On error returns content_start = -1.
unsafe fn der_read_tl(buf: *const u8, buf_len: i32, pos: i32, out_tag: *mut u8, out_content_start: *mut i32, out_content_len: *mut i32):
    if pos >= buf_len:
        *(out_content_start + 0u64) = -1
        return

    let tag = *(buf + pos as u64)
    *(out_tag + 0u64) = tag
    var p = pos + 1
    if p >= buf_len:
        *(out_content_start + 0u64) = -1
        return

    let len_byte = *(buf + p as u64)
    p = p + 1

    if (len_byte as u32 & 0x80u32) == 0u32:
        // Short form: length is len_byte itself
        *(out_content_start + 0u64) = p
        *(out_content_len + 0u64) = len_byte as i32
    else:
        // Long form: len_byte & 0x7F = number of length bytes
        let num_len_bytes = (len_byte as u32 & 0x7Fu32) as i32
        if num_len_bytes > 4 or p + num_len_bytes > buf_len:
            *(out_content_start + 0u64) = -1
            return
        var length: i32 = 0
        var li = 0
        while li < num_len_bytes:
            let lb = *(buf + p as u64)
            length = (length << 8) | (lb as i32)
            p = p + 1
            li = li + 1
        *(out_content_start + 0u64) = p
        *(out_content_len + 0u64) = length

// Parsed certificate info (offsets into the original DER buffer)
type X509Cert  {
    // tbsCertificate: the signed portion
    tbs_start: i32,
    tbs_len: i32,
    // Signature algorithm
    sig_alg: i32,
    // Signature value (BIT STRING content, skipping unused-bits byte)
    sig_start: i32,
    sig_len: i32,
    // Subject public key info
    key_type: i32,
    // For RSA: modulus n
    key_n_start: i32,
    key_n_len: i32,
    // For RSA: exponent e
    key_e_start: i32,
    key_e_len: i32,
    // For EC: uncompressed point (0x04 || x || y)
    key_point_start: i32,
    key_point_len: i32,
}

fn X509Cert.new() -> X509Cert:
    X509Cert {
        tbs_start: 0, tbs_len: 0,
        sig_alg: 0,
        sig_start: 0, sig_len: 0,
        key_type: 0,
        key_n_start: 0, key_n_len: 0,
        key_e_start: 0, key_e_len: 0,
        key_point_start: 0, key_point_len: 0,
    }
unsafe fn ecdsa_verify_der_sig(
    cert_buf: *const u8, cert: *const X509Cert,
    issuer_buf: *const u8, issuer: *const X509Cert,
    hash: *const u8,
) -> i32:
    var tag: u8 = 0u8
    var cs: i32 = 0
    var cl: i32 = 0
    let tp = &raw mut tag as *mut u8
    let csp = &raw mut cs as *mut i32
    let clp = &raw mut cl as *mut i32

    let sig_start = cert.sig_start
    let sig_end = sig_start + cert.sig_len

    // SEQUENCE
    der_read_tl(cert_buf, sig_end, sig_start, tp, csp, clp)
    if cs < 0 or tag != ASN1_SEQUENCE:
        return 0

    // r INTEGER
    der_read_tl(cert_buf, sig_end, cs, tp, csp, clp)
    if cs < 0 or tag != ASN1_INTEGER:
        return 0
    var r_start = cs
    var r_len = cl
    if r_len > 0 and *(cert_buf + r_start as u64) == 0x00u8:
        r_start = r_start + 1
        r_len = r_len - 1
    var r_bytes: [u8; 32] = [0u8; 32]
    let r_off = 32 - r_len
    var ri = 0
    while ri < r_len and ri < 32:
        let rv = *(cert_buf + (r_start + ri) as u64)
        r_bytes[r_off + ri] = rv
        ri = ri + 1

    // s INTEGER (starts after r)
    let s_pos = cs + cl
    der_read_tl(cert_buf, sig_end, s_pos, tp, csp, clp)
    if cs < 0 or tag != ASN1_INTEGER:
        return 0
    var s_start = cs
    var s_len = cl
    if s_len > 0 and *(cert_buf + s_start as u64) == 0x00u8:
        s_start = s_start + 1
        s_len = s_len - 1
    var s_bytes: [u8; 32] = [0u8; 32]
    let s_off = 32 - s_len
    var si = 0
    while si < s_len and si < 32:
        let sv = *(cert_buf + (s_start + si) as u64)
        s_bytes[s_off + si] = sv
        si = si + 1

    // Get EC public key point (skip 0x04 prefix for uncompressed)
    let pt_start = issuer.key_point_start
    let pt_len = issuer.key_point_len
    if pt_len != 65 or *(issuer_buf + pt_start as u64) != 0x04u8:
        return 0

    ecdsa_p256_verify(
        issuer_buf + (pt_start + 1) as u64,
        issuer_buf + (pt_start + 33) as u64,
        hash,
        &r_bytes[0] as *const u8,
        &s_bytes[0] as *const u8,
    )
unsafe fn ecdsa_p256_verify(px: *const u8, py: *const u8, hash: *const u8, r: *const u8, s: *const u8) -> i32:
    0

use std.builtins.print_i32
fn main -> i32:
    var cert = X509Cert.new()
    cert.sig_start = 0
    cert.sig_len = 40
    var issuer = X509Cert.new()
    issuer.key_point_start = 0
    issuer.key_point_len = 65
    var sig: [u8; 40] = [0u8; 40]
    sig[0] = 48u8
    sig[1] = 38u8
    sig[2] = 2u8
    sig[3] = 33u8
    sig[4] = 0u8
    sig[5] = 17u8
    sig[6] = 17u8
    sig[7] = 17u8
    sig[8] = 17u8
    sig[9] = 17u8
    sig[10] = 17u8
    sig[11] = 17u8
    sig[12] = 17u8
    sig[13] = 17u8
    sig[14] = 17u8
    sig[15] = 17u8
    sig[16] = 17u8
    sig[17] = 17u8
    sig[18] = 17u8
    sig[19] = 17u8
    sig[20] = 17u8
    sig[21] = 17u8
    sig[22] = 17u8
    sig[23] = 17u8
    sig[24] = 17u8
    sig[25] = 17u8
    sig[26] = 17u8
    sig[27] = 17u8
    sig[28] = 17u8
    sig[29] = 17u8
    sig[30] = 17u8
    sig[31] = 17u8
    sig[32] = 17u8
    sig[33] = 17u8
    sig[34] = 17u8
    sig[35] = 17u8
    sig[36] = 17u8
    sig[37] = 2u8
    sig[38] = 1u8
    sig[39] = 1u8
    var pt: [u8; 65] = [0u8; 65]
    pt[0] = 4u8
    var h: [u8; 32] = [0u8; 32]
    var r = 0
    unsafe:
        r = ecdsa_verify_der_sig(&sig[0] as *const u8, &cert as *const X509Cert, &pt[0] as *const u8, &issuer as *const X509Cert, &h[0] as *const u8)
    print_i32(r)
    0
