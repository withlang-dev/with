// X.509 certificate parsing and verification (minimal, for TLS 1.2)
// Parses DER-encoded certificates to extract public keys and signatures.

use std.crypto.bigint
use std.crypto.sha256
use std.crypto.rsa
use std.crypto.ecdsa

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

// Skip over a complete DER element (tag + length + content).
// Returns position after the element, or -1 on error.
unsafe fn der_skip(buf: *const u8, buf_len: i32, pos: i32) -> i32:
    var tag: u8 = 0u8
    var cs: i32 = 0
    var cl: i32 = 0
    der_read_tl(buf, buf_len, pos, &raw mut tag as *mut u8, &raw mut cs as *mut i32, &raw mut cl as *mut i32)
    if cs < 0:
        return -1
    cs + cl

// Check if an OID at (buf+pos, oid_len) matches a known OID.
unsafe fn oid_match(buf: *const u8, pos: i32, oid_len: i32, expected: *const u8, expected_len: i32) -> i32:
    if oid_len != expected_len:
        return 0
    var i = 0
    while i < oid_len:
        if *(buf + (pos + i) as u64) != *(expected + i as u64):
            return 0
        i = i + 1
    1

// ── Known OIDs ─────────────────────────────────────────────────────

// sha256WithRSAEncryption: 1.2.840.113549.1.1.11
// DER: 06 09 2a 86 48 86 f7 0d 01 01 0b
let OID_SHA256_RSA_LEN: i32 = 9

unsafe fn oid_sha256_rsa(dst: *mut u8):
    *(dst + 0u64) = 0x2Au8
    *(dst + 1u64) = 0x86u8
    *(dst + 2u64) = 0x48u8
    *(dst + 3u64) = 0x86u8
    *(dst + 4u64) = 0xF7u8
    *(dst + 5u64) = 0x0Du8
    *(dst + 6u64) = 0x01u8
    *(dst + 7u64) = 0x01u8
    *(dst + 8u64) = 0x0Bu8

// ecdsaWithSHA256: 1.2.840.10045.4.3.2
// DER: 06 08 2a 86 48 ce 3d 04 03 02
let OID_ECDSA_SHA256_LEN: i32 = 8

unsafe fn oid_ecdsa_sha256(dst: *mut u8):
    *(dst + 0u64) = 0x2Au8
    *(dst + 1u64) = 0x86u8
    *(dst + 2u64) = 0x48u8
    *(dst + 3u64) = 0xCEu8
    *(dst + 4u64) = 0x3Du8
    *(dst + 5u64) = 0x04u8
    *(dst + 6u64) = 0x03u8
    *(dst + 7u64) = 0x02u8

// rsaEncryption: 1.2.840.113549.1.1.1
let OID_RSA_ENC_LEN: i32 = 9

unsafe fn oid_rsa_enc(dst: *mut u8):
    *(dst + 0u64) = 0x2Au8
    *(dst + 1u64) = 0x86u8
    *(dst + 2u64) = 0x48u8
    *(dst + 3u64) = 0x86u8
    *(dst + 4u64) = 0xF7u8
    *(dst + 5u64) = 0x0Du8
    *(dst + 6u64) = 0x01u8
    *(dst + 7u64) = 0x01u8
    *(dst + 8u64) = 0x01u8

// ecPublicKey: 1.2.840.10045.2.1
let OID_EC_PUB_LEN: i32 = 7

unsafe fn oid_ec_pub(dst: *mut u8):
    *(dst + 0u64) = 0x2Au8
    *(dst + 1u64) = 0x86u8
    *(dst + 2u64) = 0x48u8
    *(dst + 3u64) = 0xCEu8
    *(dst + 4u64) = 0x3Du8
    *(dst + 5u64) = 0x02u8
    *(dst + 6u64) = 0x01u8

// ── Signature algorithm constants ──────────────────────────────────
let SIG_ALG_UNKNOWN: i32 = 0
let SIG_ALG_SHA256_RSA: i32 = 1
let SIG_ALG_ECDSA_SHA256: i32 = 2

// Key type constants
let KEY_TYPE_UNKNOWN: i32 = 0
let KEY_TYPE_RSA: i32 = 1
let KEY_TYPE_EC: i32 = 2

// ── Certificate parsing ────────────────────────────────────────────

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

// Parse a DER-encoded X.509 certificate.
// Returns 1 on success, 0 on parse error.
unsafe fn x509_parse(cert: *mut X509Cert, buf: *const u8, buf_len: i32) -> i32:
    var tag: u8 = 0u8
    var cs: i32 = 0
    var cl: i32 = 0
    let tp = &raw mut tag as *mut u8
    let csp = &raw mut cs as *mut i32
    let clp = &raw mut cl as *mut i32

    // Outer SEQUENCE
    der_read_tl(buf, buf_len, 0, tp, csp, clp)
    if cs < 0 or tag != ASN1_SEQUENCE:
        return 0

    // tbsCertificate SEQUENCE
    let tbs_outer_start = cs
    der_read_tl(buf, buf_len, cs, tp, csp, clp)
    if cs < 0 or tag != ASN1_SEQUENCE:
        return 0
    let tbs_content_end = cs + cl
    // tbs includes the tag+length header
    cert.tbs_start = tbs_outer_start
    cert.tbs_len = tbs_content_end - tbs_outer_start

    // Parse inside tbsCertificate
    var pos = cs

    // version [0] EXPLICIT (optional)
    der_read_tl(buf, buf_len, pos, tp, csp, clp)
    if cs >= 0 and (tag as u32 & 0xA0u32) == 0xA0u32:
        // Context-specific constructed tag → version wrapper
        pos = cs + cl
        // Read next element
        der_read_tl(buf, buf_len, pos, tp, csp, clp)

    // serialNumber INTEGER
    if cs < 0 or tag != ASN1_INTEGER:
        return 0
    pos = cs + cl

    // signature AlgorithmIdentifier SEQUENCE
    der_read_tl(buf, buf_len, pos, tp, csp, clp)
    if cs < 0 or tag != ASN1_SEQUENCE:
        return 0
    // Parse OID inside
    let sig_alg_end = cs + cl
    var alg_pos = cs
    der_read_tl(buf, buf_len, alg_pos, tp, csp, clp)
    if cs >= 0 and tag == ASN1_OID:
        cert.sig_alg = identify_sig_alg(buf, cs, cl)
    pos = sig_alg_end

    // issuer Name (skip)
    pos = der_skip(buf, buf_len, pos)
    if pos < 0:
        return 0

    // validity (skip)
    pos = der_skip(buf, buf_len, pos)
    if pos < 0:
        return 0

    // subject Name (skip)
    pos = der_skip(buf, buf_len, pos)
    if pos < 0:
        return 0

    // subjectPublicKeyInfo SEQUENCE
    der_read_tl(buf, buf_len, pos, tp, csp, clp)
    if cs < 0 or tag != ASN1_SEQUENCE:
        return 0
    let spki_end = cs + cl
    var spki_pos = cs

    // algorithm AlgorithmIdentifier SEQUENCE
    der_read_tl(buf, buf_len, spki_pos, tp, csp, clp)
    if cs < 0 or tag != ASN1_SEQUENCE:
        return 0
    let alg_id_end = cs + cl
    // Parse key algorithm OID
    der_read_tl(buf, buf_len, cs, tp, csp, clp)
    if cs >= 0 and tag == ASN1_OID:
        cert.key_type = identify_key_type(buf, cs, cl)
    spki_pos = alg_id_end

    // subjectPublicKey BIT STRING
    der_read_tl(buf, buf_len, spki_pos, tp, csp, clp)
    if cs < 0 or tag != ASN1_BIT_STRING:
        return 0
    // Skip unused-bits byte
    let key_bits_start = cs + 1
    let key_bits_len = cl - 1

    if cert.key_type == KEY_TYPE_RSA:
        // RSA public key is a SEQUENCE { INTEGER n, INTEGER e }
        der_read_tl(buf, buf_len, key_bits_start, tp, csp, clp)
        if cs < 0 or tag != ASN1_SEQUENCE:
            return 0
        // n
        der_read_tl(buf, buf_len, cs, tp, csp, clp)
        if cs < 0 or tag != ASN1_INTEGER:
            return 0
        // Skip leading zero byte if present (unsigned encoding)
        var n_start = cs
        var n_len = cl
        if n_len > 0 and *(buf + n_start as u64) == 0x00u8:
            n_start = n_start + 1
            n_len = n_len - 1
        cert.key_n_start = n_start
        cert.key_n_len = n_len
        // e
        der_read_tl(buf, buf_len, cs + cl, tp, csp, clp)
        if cs < 0 or tag != ASN1_INTEGER:
            return 0
        var e_start = cs
        var e_len = cl
        if e_len > 0 and *(buf + e_start as u64) == 0x00u8:
            e_start = e_start + 1
            e_len = e_len - 1
        cert.key_e_start = e_start
        cert.key_e_len = e_len
    else if cert.key_type == KEY_TYPE_EC:
        // EC public key is the raw uncompressed point
        cert.key_point_start = key_bits_start
        cert.key_point_len = key_bits_len

    // Skip to after tbsCertificate
    pos = tbs_content_end

    // signatureAlgorithm (skip, already parsed from tbs)
    pos = der_skip(buf, buf_len, pos)
    if pos < 0:
        return 0

    // signatureValue BIT STRING
    der_read_tl(buf, buf_len, pos, tp, csp, clp)
    if cs < 0 or tag != ASN1_BIT_STRING:
        return 0
    // Skip unused-bits byte
    cert.sig_start = cs + 1
    cert.sig_len = cl - 1

    1

// Identify signature algorithm from OID
unsafe fn identify_sig_alg(buf: *const u8, oid_start: i32, oid_len: i32) -> i32:
    var oid_buf: [u8; 9] = [0u8; 9]
    oid_sha256_rsa(&raw mut oid_buf[0] as *mut u8)
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, OID_SHA256_RSA_LEN) != 0:
        return SIG_ALG_SHA256_RSA
    oid_ecdsa_sha256(&raw mut oid_buf[0] as *mut u8)
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, OID_ECDSA_SHA256_LEN) != 0:
        return SIG_ALG_ECDSA_SHA256
    SIG_ALG_UNKNOWN

// Identify key type from algorithm OID
unsafe fn identify_key_type(buf: *const u8, oid_start: i32, oid_len: i32) -> i32:
    var oid_buf: [u8; 9] = [0u8; 9]
    oid_rsa_enc(&raw mut oid_buf[0] as *mut u8)
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, OID_RSA_ENC_LEN) != 0:
        return KEY_TYPE_RSA
    oid_ec_pub(&raw mut oid_buf[0] as *mut u8)
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, OID_EC_PUB_LEN) != 0:
        return KEY_TYPE_EC
    KEY_TYPE_UNKNOWN

// ── Certificate verification ───────────────────────────────────────

// Verify that cert's signature is valid, signed by issuer_cert's key.
// Both are parsed X509Cert structs referencing the same or different DER buffers.
unsafe fn x509_verify_signature(
    cert_buf: *const u8,
    cert: *const X509Cert,
    issuer_buf: *const u8,
    issuer: *const X509Cert,
) -> i32:
    // Hash the tbsCertificate
    var tbs_hash: [u8; 32] = [0u8; 32]
    sha256_hash(cert_buf + cert.tbs_start as u64, cert.tbs_len, &raw mut tbs_hash[0] as *mut u8)

    let sig_alg = cert.sig_alg

    if sig_alg == SIG_ALG_SHA256_RSA and issuer.key_type == KEY_TYPE_RSA:
        return rsa_pkcs1_sha256_verify(
            issuer_buf + issuer.key_n_start as u64, issuer.key_n_len,
            issuer_buf + issuer.key_e_start as u64, issuer.key_e_len,
            cert_buf + cert.sig_start as u64, cert.sig_len,
            &tbs_hash[0] as *const u8,
        )

    if sig_alg == SIG_ALG_ECDSA_SHA256 and issuer.key_type == KEY_TYPE_EC:
        // ECDSA signature is DER-encoded SEQUENCE { INTEGER r, INTEGER s }
        let sig_pos = cert.sig_start
        let sig_end = cert.sig_start + cert.sig_len
        var stag: u8 = 0u8
        var scs: i32 = 0
        var scl: i32 = 0
        // Outer SEQUENCE
        der_read_tl(cert_buf, sig_end, sig_pos, &raw mut stag as *mut u8, &raw mut scs as *mut i32, &raw mut scl as *mut i32)
        if scs < 0 or stag != ASN1_SEQUENCE:
            return 0
        // r INTEGER
        der_read_tl(cert_buf, sig_end, scs, &raw mut stag as *mut u8, &raw mut scs as *mut i32, &raw mut scl as *mut i32)
        if scs < 0 or stag != ASN1_INTEGER:
            return 0
        var r_start = scs
        var r_len = scl
        // Skip leading zero
        if r_len > 0 and *(cert_buf + r_start as u64) == 0x00u8:
            r_start = r_start + 1
            r_len = r_len - 1
        // Pad to 32 bytes
        var r_bytes: [u8; 32] = [0u8; 32]
        var ri = 0
        while ri < r_len and ri < 32:
            r_bytes[32 - r_len + ri] = *(cert_buf + (r_start + ri) as u64)
            ri = ri + 1

        // s INTEGER
        der_read_tl(cert_buf, sig_end, scs + scl - (scs - r_start - 1), &raw mut stag as *mut u8, &raw mut scs as *mut i32, &raw mut scl as *mut i32)
        // Hmm, need to track position properly. Let me use the end of r.
        let r_der_end = r_start + r_len
        // Actually, r had a leading zero stripped. Go back to original position.
        // This is getting complicated. Let me re-parse from scratch.
        return ecdsa_verify_der_sig(cert_buf, cert, issuer_buf, issuer, &tbs_hash[0] as *const u8)

    0

// Helper to verify ECDSA with DER-encoded signature
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
