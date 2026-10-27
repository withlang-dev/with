// X.509 certificate parsing and verification (minimal, for TLS 1.2)
// Parses DER-encoded certificates to extract public keys and signatures.

use std.crypto.bigint
use std.crypto.sha256
use std.crypto.sha512
use std.crypto.rsa
use std.crypto.ecdsa
use std.internal.str_abi
use rt.rt_core

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
// On error returns content_start = -1: the header does not fit, or the
// content it claims runs past buf_len (#1056: a truncated certificate gave
// offsets past its buffer, and every reader of them read past it too).
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
        if len_byte as i32 > buf_len - p:
            *(out_content_start + 0u64) = -1
            return
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
        if length < 0 or length > buf_len - p:
            *(out_content_start + 0u64) = -1
            return
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

// sha{256,384,512}WithRSAEncryption: 1.2.840.113549.1.1.{11,12,13}
// DER content: 2a 86 48 86 f7 0d 01 01 {0b,0c,0d}
let OID_SHA_RSA_LEN: i32 = 9

unsafe fn oid_sha_rsa(dst: *mut u8, last: u8):
    *(dst + 0u64) = 0x2Au8
    *(dst + 1u64) = 0x86u8
    *(dst + 2u64) = 0x48u8
    *(dst + 3u64) = 0x86u8
    *(dst + 4u64) = 0xF7u8
    *(dst + 5u64) = 0x0Du8
    *(dst + 6u64) = 0x01u8
    *(dst + 7u64) = 0x01u8
    *(dst + 8u64) = last

// ecdsa-with-SHA{256,384,512}: 1.2.840.10045.4.3.{2,3,4}
// DER content: 2a 86 48 ce 3d 04 03 {02,03,04}
let OID_ECDSA_SHA_LEN: i32 = 8

unsafe fn oid_ecdsa_sha(dst: *mut u8, last: u8):
    *(dst + 0u64) = 0x2Au8
    *(dst + 1u64) = 0x86u8
    *(dst + 2u64) = 0x48u8
    *(dst + 3u64) = 0xCEu8
    *(dst + 4u64) = 0x3Du8
    *(dst + 5u64) = 0x04u8
    *(dst + 6u64) = 0x03u8
    *(dst + 7u64) = last

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
let SIG_ALG_SHA384_RSA: i32 = 3
let SIG_ALG_ECDSA_SHA384: i32 = 4
let SIG_ALG_SHA512_RSA: i32 = 5
let SIG_ALG_ECDSA_SHA512: i32 = 6

// Digest length a signature algorithm hashes with; 0 when unknown.
fn sig_alg_digest_len(sig_alg: i32) -> i32:
    if sig_alg == SIG_ALG_SHA256_RSA or sig_alg == SIG_ALG_ECDSA_SHA256: return 32
    if sig_alg == SIG_ALG_SHA384_RSA or sig_alg == SIG_ALG_ECDSA_SHA384: return 48
    if sig_alg == SIG_ALG_SHA512_RSA or sig_alg == SIG_ALG_ECDSA_SHA512: return 64
    0

fn sig_alg_is_rsa(sig_alg: i32) -> bool:
    sig_alg == SIG_ALG_SHA256_RSA or sig_alg == SIG_ALG_SHA384_RSA or sig_alg == SIG_ALG_SHA512_RSA

fn sig_alg_is_ecdsa(sig_alg: i32) -> bool:
    sig_alg == SIG_ALG_ECDSA_SHA256 or sig_alg == SIG_ALG_ECDSA_SHA384 or sig_alg == SIG_ALG_ECDSA_SHA512

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
    // For EC: the named curve's bit size (256 or 384); 0 otherwise.
    // Named curves only — explicit parameters are refused at verify.
    key_curve: i32,
    // Issuer and subject Name elements (whole DER elements, header
    // included) for byte-exact chain linking (#1061).
    issuer_start: i32,
    issuer_len: i32,
    subject_start: i32,
    subject_len: i32,
    // Validity window as Unix seconds; -1 when unparseable.
    not_before: i64,
    not_after: i64,
    // subjectAltName extnValue content (the GeneralNames SEQUENCE's
    // content bytes), or length 0 when the extension is absent.
    san_start: i32,
    san_len: i32,
    // basicConstraints cA: 1 true, 0 false or extension absent.
    bc_ca: i32,
}

fn X509Cert.new() -> X509Cert:
    X509Cert {
        tbs_start: 0, tbs_len: 0,
        sig_alg: 0,
        sig_start: 0, sig_len: 0,
        key_type: 0,
        key_n_start: 0, key_n_len: 0,
        key_e_start: 0, key_e_len: 0,
        key_point_start: 0, key_point_len: 0, key_curve: 0,
        issuer_start: 0, issuer_len: 0,
        subject_start: 0, subject_len: 0,
        not_before: -1, not_after: -1,
        san_start: 0, san_len: 0,
        bc_ca: 0,
    }

// Days from civil date (Howard Hinnant's algorithm), days since 1970-01-01.
fn der_days_from_civil(y_in: i64, m: i64, d: i64) -> i64:
    var y = y_in
    if m <= 2: y = y - 1
    let era = if y >= 0: y / 400 else: (y - 399) / 400
    let yoe = y - era * 400
    let mp = (m + 9) % 12
    let doy = (153 * mp + 2) / 5 + d - 1
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
    era * 146097 + doe - 719468

// Two decimal digits at buf[pos..pos+2], or -1.
unsafe fn der_two_digits(buf: *const u8, pos: i32) -> i64:
    let a = *(buf + pos as u64) as i64 - 48
    let b = *(buf + (pos + 1) as u64) as i64 - 48
    if a < 0 or a > 9 or b < 0 or b > 9: return -1
    a * 10 + b

// A DER UTCTime ("YYMMDDHHMMSSZ") or GeneralizedTime
// ("YYYYMMDDHHMMSSZ") as Unix seconds; -1 when the form is anything else.
unsafe fn der_time_unix(buf: *const u8, start: i32, len: i32, tag: u8) -> i64:
    var pos = start
    let end = start + len
    var year: i64 = 0
    if tag == ASN1_UTC_TIME:
        if len < 13: return -1
        let yy = der_two_digits(buf, pos)
        if yy < 0: return -1
        year = if yy >= 50: 1900 + yy else: 2000 + yy
        pos = pos + 2
    else if tag == ASN1_GENERALIZED_TIME:
        if len < 15: return -1
        let hi = der_two_digits(buf, pos)
        let lo = der_two_digits(buf, pos + 2)
        if hi < 0 or lo < 0: return -1
        year = hi * 100 + lo
        pos = pos + 4
    else:
        return -1
    let month = der_two_digits(buf, pos)
    let day = der_two_digits(buf, pos + 2)
    let hour = der_two_digits(buf, pos + 4)
    let minute = der_two_digits(buf, pos + 6)
    let second = der_two_digits(buf, pos + 8)
    if month < 1 or month > 12 or day < 1 or day > 31 or hour < 0 or hour > 23 or minute < 0 or minute > 59 or second < 0 or second > 60:
        return -1
    if pos + 10 >= end or *(buf + (pos + 10) as u64) != 0x5Au8:
        return -1
    der_days_from_civil(year, month, day) * 86400 + hour * 3600 + minute * 60 + second

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

    // issuer Name: record the whole element for chain linking.
    cert.issuer_start = pos
    pos = der_skip(buf, buf_len, pos)
    if pos < 0:
        return 0
    cert.issuer_len = pos - cert.issuer_start

    // validity SEQUENCE { notBefore, notAfter }
    der_read_tl(buf, buf_len, pos, tp, csp, clp)
    if cs < 0 or tag != ASN1_SEQUENCE:
        return 0
    let validity_end = cs + cl
    der_read_tl(buf, buf_len, cs, tp, csp, clp)
    if cs < 0:
        return 0
    cert.not_before = der_time_unix(buf, cs, cl, tag)
    der_read_tl(buf, buf_len, cs + cl, tp, csp, clp)
    if cs < 0:
        return 0
    cert.not_after = der_time_unix(buf, cs, cl, tag)
    pos = validity_end

    // subject Name: record the whole element for chain linking.
    cert.subject_start = pos
    pos = der_skip(buf, buf_len, pos)
    if pos < 0:
        return 0
    cert.subject_len = pos - cert.subject_start

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
        // An EC key's parameters name its curve (an OID element inside
        // the same AlgorithmIdentifier). Anything else — absent,
        // explicit parameters, an unrecognized curve — leaves
        // key_curve 0 and verification refuses it.
        if cert.key_type == KEY_TYPE_EC and cs + cl < alg_id_end:
            der_read_tl(buf, buf_len, cs + cl, tp, csp, clp)
            if cs >= 0 and tag == ASN1_OID:
                cert.key_curve = identify_ec_curve(buf, cs, cl)
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

    // Optional [1]/[2] unique identifiers, then [3] extensions: walk the
    // remaining tbs elements for subjectAltName and basicConstraints.
    var ext_pos = spki_end
    while ext_pos < tbs_content_end:
        der_read_tl(buf, buf_len, ext_pos, tp, csp, clp)
        if cs < 0:
            return 0
        if tag == 0xA3u8:
            // Extensions SEQUENCE inside the explicit wrapper.
            der_read_tl(buf, buf_len, cs, tp, csp, clp)
            if cs < 0 or tag != ASN1_SEQUENCE:
                return 0
            let exts_end = cs + cl
            var ep = cs
            while ep < exts_end:
                der_read_tl(buf, buf_len, ep, tp, csp, clp)
                if cs < 0 or tag != ASN1_SEQUENCE:
                    return 0
                let one_end = cs + cl
                // extnID OID
                der_read_tl(buf, buf_len, cs, tp, csp, clp)
                if cs < 0 or tag != ASN1_OID:
                    return 0
                let oid_start = cs
                let oid_len = cl
                var value_pos = cs + cl
                // optional critical BOOLEAN, then extnValue OCTET STRING
                der_read_tl(buf, buf_len, value_pos, tp, csp, clp)
                if cs < 0:
                    return 0
                if tag == 0x01u8:
                    value_pos = cs + cl
                    der_read_tl(buf, buf_len, value_pos, tp, csp, clp)
                    if cs < 0:
                        return 0
                if tag != ASN1_OCTET_STRING:
                    return 0
                if oid_len == 3 and *(buf + oid_start as u64) == 0x55u8 and *(buf + (oid_start + 1) as u64) == 0x1Du8:
                    let kind = *(buf + (oid_start + 2) as u64)
                    if kind == 0x11u8:
                        // subjectAltName: record the OCTET STRING content
                        cert.san_start = cs
                        cert.san_len = cl
                    else if kind == 0x13u8:
                        // basicConstraints: SEQUENCE { BOOLEAN cA ... }
                        der_read_tl(buf, buf_len, cs, tp, csp, clp)
                        if cs >= 0 and tag == ASN1_SEQUENCE and cl >= 3:
                            der_read_tl(buf, buf_len, cs, tp, csp, clp)
                            if cs >= 0 and tag == 0x01u8 and cl == 1 and *(buf + cs as u64) != 0u8:
                                cert.bc_ca = 1
                ep = one_end
            break
        ext_pos = cs + cl

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
    oid_sha_rsa(&raw mut oid_buf[0] as *mut u8, 0x0Bu8)
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, OID_SHA_RSA_LEN) != 0:
        return SIG_ALG_SHA256_RSA
    oid_sha_rsa(&raw mut oid_buf[0] as *mut u8, 0x0Cu8)
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, OID_SHA_RSA_LEN) != 0:
        return SIG_ALG_SHA384_RSA
    oid_sha_rsa(&raw mut oid_buf[0] as *mut u8, 0x0Du8)
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, OID_SHA_RSA_LEN) != 0:
        return SIG_ALG_SHA512_RSA
    oid_ecdsa_sha(&raw mut oid_buf[0] as *mut u8, 0x02u8)
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, OID_ECDSA_SHA_LEN) != 0:
        return SIG_ALG_ECDSA_SHA256
    oid_ecdsa_sha(&raw mut oid_buf[0] as *mut u8, 0x03u8)
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, OID_ECDSA_SHA_LEN) != 0:
        return SIG_ALG_ECDSA_SHA384
    oid_ecdsa_sha(&raw mut oid_buf[0] as *mut u8, 0x04u8)
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, OID_ECDSA_SHA_LEN) != 0:
        return SIG_ALG_ECDSA_SHA512
    SIG_ALG_UNKNOWN

// Identify a named EC curve from its parameters OID: the bit size
// (256 or 384), or 0. prime256v1 is 1.2.840.10045.3.1.7
// (2a 86 48 ce 3d 03 01 07); secp384r1 is 1.3.132.0.34
// (2b 81 04 00 22).
unsafe fn identify_ec_curve(buf: *const u8, oid_start: i32, oid_len: i32) -> i32:
    var oid_buf: [u8; 8] = [0u8; 8]
    oid_buf[0] = 0x2Au8
    oid_buf[1] = 0x86u8
    oid_buf[2] = 0x48u8
    oid_buf[3] = 0xCEu8
    oid_buf[4] = 0x3Du8
    oid_buf[5] = 0x03u8
    oid_buf[6] = 0x01u8
    oid_buf[7] = 0x07u8
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, 8) != 0:
        return 256
    oid_buf[0] = 0x2Bu8
    oid_buf[1] = 0x81u8
    oid_buf[2] = 0x04u8
    oid_buf[3] = 0x00u8
    oid_buf[4] = 0x22u8
    if oid_match(buf, oid_start, oid_len, &oid_buf[0] as *const u8, 5) != 0:
        return 384
    0

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
    // Hash the tbsCertificate with the signature algorithm's digest.
    let sig_alg = cert.sig_alg
    let digest_len = sig_alg_digest_len(sig_alg)
    if digest_len == 0:
        return 0
    var tbs_hash: [u8; 64] = [0u8; 64]
    let tbs_ptr = cert_buf + cert.tbs_start as u64
    if digest_len == 32:
        sha256_hash(tbs_ptr, cert.tbs_len, &raw mut tbs_hash[0] as *mut u8)
    else if digest_len == 48:
        sha384_hash(tbs_ptr, cert.tbs_len, &raw mut tbs_hash[0] as *mut u8)
    else:
        sha512_hash(tbs_ptr, cert.tbs_len, &raw mut tbs_hash[0] as *mut u8)

    if sig_alg_is_rsa(sig_alg) and issuer.key_type == KEY_TYPE_RSA:
        return rsa_pkcs1_verify(
            issuer_buf + issuer.key_n_start as u64, issuer.key_n_len,
            issuer_buf + issuer.key_e_start as u64, issuer.key_e_len,
            cert_buf + cert.sig_start as u64, cert.sig_len,
            &tbs_hash[0] as *const u8, digest_len,
        )

    if sig_alg_is_ecdsa(sig_alg) and issuer.key_type == KEY_TYPE_EC:
        return ecdsa_verify_der_sig(cert_buf, cert, issuer_buf, issuer, &tbs_hash[0] as *const u8, digest_len)

    0

// Extract r and s from a DER ECDSA-Sig-Value into width-byte,
// right-aligned buffers. Returns 1 on success.
// #1057: a scalar is at most `width` bytes once its sign byte is
// stripped; a longer INTEGER is not a signature (it indexed below 0).
unsafe fn ecdsa_der_components(
    sig: *const u8, sig_len: i32, width: i32,
    r_out: *mut u8, s_out: *mut u8,
) -> i32:
    var tag: u8 = 0u8
    var cs: i32 = 0
    var cl: i32 = 0
    let tp = &raw mut tag as *mut u8
    let csp = &raw mut cs as *mut i32
    let clp = &raw mut cl as *mut i32
    der_read_tl(sig, sig_len, 0, tp, csp, clp)
    if cs < 0 or tag != ASN1_SEQUENCE:
        return 0
    var which = 0
    var pos = cs
    while which < 2:
        der_read_tl(sig, sig_len, pos, tp, csp, clp)
        if cs < 0 or tag != ASN1_INTEGER:
            return 0
        var v_start = cs
        var v_len = cl
        if v_len > 0 and *(sig + v_start as u64) == 0x00u8:
            v_start = v_start + 1
            v_len = v_len - 1
        if v_len > width or v_len <= 0:
            return 0
        let dst = if which == 0: r_out else: s_out
        let off = width - v_len
        var i = 0
        while i < v_len:
            *(dst + (off + i) as u64) = *(sig + (v_start + i) as u64)
            i = i + 1
        pos = cs + cl
        which = which + 1
    1

// Verify an ECDSA signature against an uncompressed point on the named
// curve (256 or 384 bits). The message integer is the digest's leftmost
// field-width bytes, or the whole digest when shorter (FIPS 186-4).
unsafe fn ecdsa_verify_point(
    point: *const u8, point_len: i32, curve_bits: i32,
    hash: *const u8, hash_len: i32,
    sig_r: *const u8, sig_s: *const u8,
) -> i32:
    let width = curve_bits / 8
    if point_len != 1 + 2 * width or *(point + 0u64) != 0x04u8:
        return 0
    let x_ptr = point + 1u64
    let y_ptr = point + (1 + width) as u64
    if curve_bits == 256:
        // ecdsa_p256_verify reads a 32-byte digest.
        if hash_len < 32:
            return 0
        return ecdsa_p256_verify(x_ptr, y_ptr, hash, sig_r, sig_s)
    if curve_bits == 384:
        return ecdsa_p384_verify(x_ptr, y_ptr, hash, hash_len, sig_r, sig_s)
    0

// Helper to verify a certificate's ECDSA signature under its issuer.
unsafe fn ecdsa_verify_der_sig(
    cert_buf: *const u8, cert: *const X509Cert,
    issuer_buf: *const u8, issuer: *const X509Cert,
    hash: *const u8, hash_len: i32,
) -> i32:
    let curve_bits = issuer.key_curve
    if curve_bits != 256 and curve_bits != 384:
        return 0
    var r_bytes: [u8; 48] = [0u8; 48]
    var s_bytes: [u8; 48] = [0u8; 48]
    if ecdsa_der_components(cert_buf + cert.sig_start as u64, cert.sig_len, curve_bits / 8, &raw mut r_bytes[0] as *mut u8, &raw mut s_bytes[0] as *mut u8) == 0:
        return 0
    ecdsa_verify_point(
        issuer_buf + issuer.key_point_start as u64, issuer.key_point_len, curve_bits,
        hash, hash_len,
        &r_bytes[0] as *const u8,
        &s_bytes[0] as *const u8,
    )

// ── Chain and hostname verification (#1061) ────────────────────────

// Byte equality of two DER Name elements.
unsafe fn x509_name_equal(a_buf: *const u8, a_start: i32, a_len: i32, b_buf: *const u8, b_start: i32, b_len: i32) -> i32:
    if a_len <= 0 or a_len != b_len:
        return 0
    var i = 0
    while i < a_len:
        if *(a_buf + (a_start + i) as u64) != *(b_buf + (b_start + i) as u64):
            return 0
        i = i + 1
    1

// Whether `cert` is inside its validity window at `now` (Unix seconds).
fn x509_valid_at(cert: &X509Cert, now: i64) -> i32:
    if cert.not_before < 0 or cert.not_after < 0:
        return 0
    if now < cert.not_before or now > cert.not_after:
        return 0
    1

// Verify a presented chain (leaf first) against trust anchors. Each
// certificate on the built path must be in its validity window, each
// link's signature must verify under its issuer, and every non-anchor
// issuer must be a CA (basicConstraints). The path anchors as soon as
// a root in the store names the current certificate's issuer and its
// key verifies the signature — servers routinely present cross-signed
// certificates above the anchor point (an old root's cross-sign of a
// newer root the store holds directly), and those are not on the path.
// Only the signature algorithms x509_verify_signature knows verify;
// anything else fails the chain — a refusal, never a silent accept.
unsafe fn x509_verify_chain_at(
    chain_buf: *const u8, chain_starts: *const i32, chain_lens: *const i32, chain_count: i32,
    roots_buf: *const u8, roots_starts: *const i32, roots_lens: *const i32, roots_count: i32,
    now: i64,
) -> i32:
    if chain_count <= 0 or roots_count <= 0:
        return 0
    var cert = X509Cert.new()
    var issuer = X509Cert.new()
    var idx = 0
    while idx < chain_count:
        let start = *(chain_starts + idx as u64)
        let len = *(chain_lens + idx as u64)
        if x509_parse(&raw mut cert as *mut X509Cert, chain_buf + start as u64, len) == 0:
            return 0
        if x509_valid_at(cert, now) == 0:
            return 0
        let cert_buf_at = chain_buf + start as u64
        // Anchor here if a stored root issued this certificate.
        var r = 0
        while r < roots_count:
            let rstart = *(roots_starts + r as u64)
            let rlen = *(roots_lens + r as u64)
            if x509_parse(&raw mut issuer as *mut X509Cert, roots_buf + rstart as u64, rlen) != 0:
                if x509_name_equal(cert_buf_at, cert.issuer_start, cert.issuer_len, roots_buf + rstart as u64, issuer.subject_start, issuer.subject_len) != 0:
                    if x509_verify_signature(cert_buf_at, &cert as *const X509Cert, roots_buf + rstart as u64, &issuer as *const X509Cert) != 0:
                        return 1
            r = r + 1
        // Otherwise the next presented certificate must issue this one.
        if idx + 1 >= chain_count:
            return 0
        let istart = *(chain_starts + (idx + 1) as u64)
        let ilen = *(chain_lens + (idx + 1) as u64)
        if x509_parse(&raw mut issuer as *mut X509Cert, chain_buf + istart as u64, ilen) == 0:
            return 0
        if issuer.bc_ca != 1:
            return 0
        if x509_name_equal(cert_buf_at, cert.issuer_start, cert.issuer_len, chain_buf + istart as u64, issuer.subject_start, issuer.subject_len) == 0:
            return 0
        if x509_verify_signature(cert_buf_at, &cert as *const X509Cert, chain_buf + istart as u64, &issuer as *const X509Cert) == 0:
            return 0
        idx = idx + 1
    0

// Case-insensitive equality of a SAN dNSName against the host, with
// one left-most wildcard label ("*.example.com" matches
// "a.example.com", not "example.com" or "a.b.example.com").
unsafe fn x509_dns_match(pat: *const u8, pat_len: i32, host: *const u8, host_len: i32) -> i32:
    if pat_len <= 0 or host_len <= 0:
        return 0
    var poff = 0
    var hoff = 0
    if pat_len > 2 and *(pat + 0u64) == 0x2Au8 and *(pat + 1u64) == 0x2Eu8:
        // Wildcard: host's first label stands in for "*".
        var dot = 0
        while dot < host_len and *(host + dot as u64) != 0x2Eu8:
            dot = dot + 1
        if dot == 0 or dot >= host_len:
            return 0
        poff = 1
        hoff = dot
    if pat_len - poff != host_len - hoff:
        return 0
    var i = 0
    while poff + i < pat_len:
        var pc = *(pat + (poff + i) as u64)
        var hc = *(host + (hoff + i) as u64)
        if pc >= 0x41u8 and pc <= 0x5Au8: pc = pc + 32
        if hc >= 0x41u8 and hc <= 0x5Au8: hc = hc + 32
        if pc != hc:
            return 0
        i = i + 1
    1

// Whether `host` is a dotted-quad IPv4 literal; fills out4 when it is.
unsafe fn x509_parse_ipv4(host: *const u8, host_len: i32, out4: *mut u8) -> i32:
    var part = 0
    var value = 0
    var digits = 0
    var i = 0
    while i <= host_len:
        let c = if i < host_len: *(host + i as u64) else: 0x2Eu8
        if c == 0x2Eu8:
            if digits == 0 or value > 255 or part >= 4:
                return 0
            *(out4 + part as u64) = value as u8
            part = part + 1
            value = 0
            digits = 0
        else if c >= 0x30u8 and c <= 0x39u8:
            value = value * 10 + (c as i32 - 48)
            digits = digits + 1
            if digits > 3:
                return 0
        else:
            return 0
        i = i + 1
    if part == 4: 1 else: 0

// Whether the certificate names `host` in subjectAltName (dNSName or
// iPAddress). No SAN extension, no match: the CN is not consulted.
unsafe fn x509_verify_hostname(buf: *const u8, cert: *const X509Cert, host: *const u8, host_len: isize) -> i32:
    // A DNS name is at most 253 bytes; the DER walk below is i32.
    if cert.san_len <= 0 or host_len <= 0 or host_len > 253:
        return 0
    let hlen = host_len as i32
    var tag: u8 = 0u8
    var cs: i32 = 0
    var cl: i32 = 0
    let tp = &raw mut tag as *mut u8
    let csp = &raw mut cs as *mut i32
    let clp = &raw mut cl as *mut i32
    let san_end = cert.san_start + cert.san_len
    der_read_tl(buf, san_end, cert.san_start, tp, csp, clp)
    if cs < 0 or tag != ASN1_SEQUENCE:
        return 0
    var ipv4: [u8; 4] = [0u8; 4]
    let is_ip = x509_parse_ipv4(host, hlen, &raw mut ipv4[0] as *mut u8)
    let names_end = cs + cl
    var pos = cs
    while pos < names_end:
        der_read_tl(buf, san_end, pos, tp, csp, clp)
        if cs < 0:
            return 0
        if tag == 0x82u8 and is_ip == 0:
            if x509_dns_match(buf + cs as u64, cl, host, hlen) != 0:
                return 1
        else if tag == 0x87u8 and is_ip != 0 and cl == 4:
            var same = 1
            var i = 0
            while i < 4:
                if *(buf + (cs + i) as u64) != ipv4[i]:
                    same = 0
                i = i + 1
            if same == 1:
                return 1
        pos = cs + cl
    0

// ── PEM certificate bundles ────────────────────────────────────────

fn x509_b64_value(c: u8) -> i32:
    if c >= 0x41u8 and c <= 0x5Au8: return c as i32 - 65
    if c >= 0x61u8 and c <= 0x7Au8: return c as i32 - 71
    if c >= 0x30u8 and c <= 0x39u8: return c as i32 + 4
    if c == 0x2Bu8: return 62
    if c == 0x2Fu8: return 63
    -1

// Whether pem[at..at+marker.len] is the marker text.
unsafe fn x509_pem_at(pem: *const u8, at: isize, marker: &str) -> bool:
    var i: i64 = 0
    while i < marker.len():
        if *(pem + (at as i64 + i) as u64) != marker[i]:
            return false
        i = i + 1
    true

// Decode every PEM CERTIFICATE block in `pem` into `out_buf`, recording
// each DER's start/length. Returns the certificate count, or -1 when a
// block is malformed or the buffers are too small.
unsafe fn x509_pem_parse_certs(pem: *const u8, pem_len: isize, out_buf: *mut u8, buf_cap: i32, starts: *mut i32, lens: *mut i32, max_certs: i32) -> i32:
    let begin = "-----BEGIN CERTIFICATE-----"
    let endmark = "-----END CERTIFICATE-----"
    var count = 0
    var out_len = 0
    var pos: isize = 0
    while pos + begin.len() <= pem_len:
        if not x509_pem_at(pem, pos, begin):
            pos = pos + 1
            continue
        if count >= max_certs:
            return -1
        var p = pos + begin.len()
        let cert_start = out_len
        var acc: i32 = 0
        var acc_bits = 0
        var done = 0
        while p < pem_len:
            if p + endmark.len() <= pem_len and x509_pem_at(pem, p, endmark):
                done = 1
                break
            let c = *(pem + p as u64)
            p = p + 1
            if c == 0x3Du8:
                continue
            let v = x509_b64_value(c)
            if v < 0:
                continue
            acc = (acc << 6) | v
            acc_bits = acc_bits + 6
            if acc_bits >= 8:
                acc_bits = acc_bits - 8
                if out_len >= buf_cap:
                    return -1
                *(out_buf + out_len as u64) = (acc >> acc_bits) as u8
                out_len = out_len + 1
        if done == 0 or out_len == cert_start:
            return -1
        *(starts + count as u64) = cert_start
        *(lens + count as u64) = out_len - cert_start
        count = count + 1
        pos = p + endmark.len()
    count

/// Verify a PEM certificate chain (leaf first) against PEM trust
/// anchors for `hostname` at `now_unix`: signatures link to an anchor,
/// every presented certificate is in its validity window, non-anchor
/// issuers are CAs, and the leaf names the host in subjectAltName.
/// Signature algorithms the verifier does not know are false.
pub fn x509_verify_chain_pem(chain_pem: &str, roots_pem: &str, hostname: &str, now_unix: i64) -> bool:
    unsafe:
        let chain_text = str_copy_bytes(chain_pem)
        let roots_text = str_copy_bytes(roots_pem)
        let host_text = str_copy_bytes(hostname)
        let chain_buf = with_alloc(65536)
        let roots_buf = with_alloc(1048576)
        var chain_starts: [i32; 8] = [0; 8]
        var chain_lens: [i32; 8] = [0; 8]
        var roots_starts: [i32; 512] = [0; 512]
        var roots_lens: [i32; 512] = [0; 512]
        let chain_count = x509_pem_parse_certs(chain_text, chain_pem.len(), chain_buf, 65536, &raw mut chain_starts[0] as *mut i32, &raw mut chain_lens[0] as *mut i32, 8)
        let roots_count = x509_pem_parse_certs(roots_text, roots_pem.len(), roots_buf, 1048576, &raw mut roots_starts[0] as *mut i32, &raw mut roots_lens[0] as *mut i32, 512)
        var ok = false
        if chain_count > 0 and roots_count > 0:
            if x509_verify_chain_at(chain_buf, &chain_starts[0] as *const i32, &chain_lens[0] as *const i32, chain_count, roots_buf, &roots_starts[0] as *const i32, &roots_lens[0] as *const i32, roots_count, now_unix) != 0:
                var leaf = X509Cert.new()
                if x509_parse(&raw mut leaf as *mut X509Cert, chain_buf, chain_lens[0]) != 0:
                    ok = x509_verify_hostname(chain_buf, &leaf as *const X509Cert, host_text, hostname.len()) != 0
        with_free(chain_buf)
        with_free(roots_buf)
        str_free_bytes(chain_text)
        str_free_bytes(roots_text)
        str_free_bytes(host_text)
        ok

// Verify a DER ECDSA-Sig-Value against a point and hash (the TLS
// ServerKeyExchange form; x509_verify_signature's path above reads the
// signature from a certificate instead).
unsafe fn x509_ecdsa_verify_der_bytes(
    point: *const u8, point_len: i32, curve_bits: i32,
    sig: *const u8, sig_len: i32,
    hash: *const u8, hash_len: i32,
) -> i32:
    if curve_bits != 256 and curve_bits != 384:
        return 0
    var r_bytes: [u8; 48] = [0u8; 48]
    var s_bytes: [u8; 48] = [0u8; 48]
    if ecdsa_der_components(sig, sig_len, curve_bits / 8, &raw mut r_bytes[0] as *mut u8, &raw mut s_bytes[0] as *mut u8) == 0:
        return 0
    ecdsa_verify_point(
        point, point_len, curve_bits, hash, hash_len,
        &r_bytes[0] as *const u8, &s_bytes[0] as *const u8,
    )
