// X.509 certificate parsing and verification (minimal, for TLS 1.2)
// Parses DER-encoded certificates to extract public keys and signatures.


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

use std.builtins.print_i32
fn main -> i32:
    var cert_buf: [u8; 771] = [0u8; 771]
    cert_buf[0] = 48u8
    cert_buf[1] = 130u8
    cert_buf[2] = 2u8
    cert_buf[3] = 255u8
    cert_buf[4] = 48u8
    cert_buf[5] = 130u8
    cert_buf[6] = 1u8
    cert_buf[7] = 231u8
    cert_buf[8] = 160u8
    cert_buf[9] = 3u8
    cert_buf[10] = 2u8
    cert_buf[11] = 1u8
    cert_buf[12] = 2u8
    cert_buf[13] = 2u8
    cert_buf[14] = 20u8
    cert_buf[15] = 23u8
    cert_buf[16] = 75u8
    cert_buf[17] = 253u8
    cert_buf[18] = 166u8
    cert_buf[19] = 219u8
    cert_buf[20] = 78u8
    cert_buf[21] = 240u8
    cert_buf[22] = 198u8
    cert_buf[23] = 178u8
    cert_buf[24] = 63u8
    cert_buf[25] = 197u8
    cert_buf[26] = 175u8
    cert_buf[27] = 141u8
    cert_buf[28] = 30u8
    cert_buf[29] = 245u8
    cert_buf[30] = 211u8
    cert_buf[31] = 122u8
    cert_buf[32] = 199u8
    cert_buf[33] = 159u8
    cert_buf[34] = 237u8
    cert_buf[35] = 48u8
    cert_buf[36] = 13u8
    cert_buf[37] = 6u8
    cert_buf[38] = 9u8
    cert_buf[39] = 42u8
    cert_buf[40] = 134u8
    cert_buf[41] = 72u8
    cert_buf[42] = 134u8
    cert_buf[43] = 247u8
    cert_buf[44] = 13u8
    cert_buf[45] = 1u8
    cert_buf[46] = 1u8
    cert_buf[47] = 11u8
    cert_buf[48] = 5u8
    cert_buf[49] = 0u8
    cert_buf[50] = 48u8
    cert_buf[51] = 15u8
    cert_buf[52] = 49u8
    cert_buf[53] = 13u8
    cert_buf[54] = 48u8
    cert_buf[55] = 11u8
    cert_buf[56] = 6u8
    cert_buf[57] = 3u8
    cert_buf[58] = 85u8
    cert_buf[59] = 4u8
    cert_buf[60] = 3u8
    cert_buf[61] = 12u8
    cert_buf[62] = 4u8
    cert_buf[63] = 116u8
    cert_buf[64] = 101u8
    cert_buf[65] = 115u8
    cert_buf[66] = 116u8
    cert_buf[67] = 48u8
    cert_buf[68] = 30u8
    cert_buf[69] = 23u8
    cert_buf[70] = 13u8
    cert_buf[71] = 50u8
    cert_buf[72] = 54u8
    cert_buf[73] = 48u8
    cert_buf[74] = 57u8
    cert_buf[75] = 48u8
    cert_buf[76] = 52u8
    cert_buf[77] = 49u8
    cert_buf[78] = 52u8
    cert_buf[79] = 48u8
    cert_buf[80] = 50u8
    cert_buf[81] = 51u8
    cert_buf[82] = 56u8
    cert_buf[83] = 90u8
    cert_buf[84] = 23u8
    cert_buf[85] = 13u8
    cert_buf[86] = 50u8
    cert_buf[87] = 54u8
    cert_buf[88] = 48u8
    cert_buf[89] = 57u8
    cert_buf[90] = 48u8
    cert_buf[91] = 54u8
    cert_buf[92] = 49u8
    cert_buf[93] = 52u8
    cert_buf[94] = 48u8
    cert_buf[95] = 50u8
    cert_buf[96] = 51u8
    cert_buf[97] = 56u8
    cert_buf[98] = 90u8
    cert_buf[99] = 48u8
    cert_buf[100] = 15u8
    cert_buf[101] = 49u8
    cert_buf[102] = 13u8
    cert_buf[103] = 48u8
    cert_buf[104] = 11u8
    cert_buf[105] = 6u8
    cert_buf[106] = 3u8
    cert_buf[107] = 85u8
    cert_buf[108] = 4u8
    cert_buf[109] = 3u8
    cert_buf[110] = 12u8
    cert_buf[111] = 4u8
    cert_buf[112] = 116u8
    cert_buf[113] = 101u8
    cert_buf[114] = 115u8
    cert_buf[115] = 116u8
    cert_buf[116] = 48u8
    cert_buf[117] = 130u8
    cert_buf[118] = 1u8
    cert_buf[119] = 34u8
    cert_buf[120] = 48u8
    cert_buf[121] = 13u8
    cert_buf[122] = 6u8
    cert_buf[123] = 9u8
    cert_buf[124] = 42u8
    cert_buf[125] = 134u8
    cert_buf[126] = 72u8
    cert_buf[127] = 134u8
    cert_buf[128] = 247u8
    cert_buf[129] = 13u8
    cert_buf[130] = 1u8
    cert_buf[131] = 1u8
    cert_buf[132] = 1u8
    cert_buf[133] = 5u8
    cert_buf[134] = 0u8
    cert_buf[135] = 3u8
    cert_buf[136] = 130u8
    cert_buf[137] = 1u8
    cert_buf[138] = 15u8
    cert_buf[139] = 0u8
    cert_buf[140] = 48u8
    cert_buf[141] = 130u8
    cert_buf[142] = 1u8
    cert_buf[143] = 10u8
    cert_buf[144] = 2u8
    cert_buf[145] = 130u8
    cert_buf[146] = 1u8
    cert_buf[147] = 1u8
    cert_buf[148] = 0u8
    cert_buf[149] = 164u8
    cert_buf[150] = 179u8
    cert_buf[151] = 20u8
    cert_buf[152] = 141u8
    cert_buf[153] = 216u8
    cert_buf[154] = 124u8
    cert_buf[155] = 238u8
    cert_buf[156] = 80u8
    cert_buf[157] = 91u8
    cert_buf[158] = 97u8
    cert_buf[159] = 104u8
    cert_buf[160] = 184u8
    cert_buf[161] = 212u8
    cert_buf[162] = 109u8
    cert_buf[163] = 122u8
    cert_buf[164] = 172u8
    cert_buf[165] = 197u8
    cert_buf[166] = 225u8
    cert_buf[167] = 92u8
    cert_buf[168] = 114u8
    cert_buf[169] = 0u8
    cert_buf[170] = 244u8
    cert_buf[171] = 50u8
    cert_buf[172] = 110u8
    cert_buf[173] = 169u8
    cert_buf[174] = 37u8
    cert_buf[175] = 46u8
    cert_buf[176] = 58u8
    cert_buf[177] = 85u8
    cert_buf[178] = 168u8
    cert_buf[179] = 104u8
    cert_buf[180] = 40u8
    cert_buf[181] = 194u8
    cert_buf[182] = 170u8
    cert_buf[183] = 63u8
    cert_buf[184] = 113u8
    cert_buf[185] = 127u8
    cert_buf[186] = 126u8
    cert_buf[187] = 241u8
    cert_buf[188] = 68u8
    cert_buf[189] = 143u8
    cert_buf[190] = 167u8
    cert_buf[191] = 228u8
    cert_buf[192] = 40u8
    cert_buf[193] = 207u8
    cert_buf[194] = 91u8
    cert_buf[195] = 4u8
    cert_buf[196] = 10u8
    cert_buf[197] = 113u8
    cert_buf[198] = 39u8
    cert_buf[199] = 219u8
    cert_buf[200] = 214u8
    cert_buf[201] = 80u8
    cert_buf[202] = 72u8
    cert_buf[203] = 252u8
    cert_buf[204] = 237u8
    cert_buf[205] = 191u8
    cert_buf[206] = 164u8
    cert_buf[207] = 59u8
    cert_buf[208] = 73u8
    cert_buf[209] = 204u8
    cert_buf[210] = 199u8
    cert_buf[211] = 95u8
    cert_buf[212] = 172u8
    cert_buf[213] = 154u8
    cert_buf[214] = 147u8
    cert_buf[215] = 168u8
    cert_buf[216] = 0u8
    cert_buf[217] = 136u8
    cert_buf[218] = 182u8
    cert_buf[219] = 215u8
    cert_buf[220] = 17u8
    cert_buf[221] = 118u8
    cert_buf[222] = 139u8
    cert_buf[223] = 25u8
    cert_buf[224] = 161u8
    cert_buf[225] = 151u8
    cert_buf[226] = 228u8
    cert_buf[227] = 136u8
    cert_buf[228] = 53u8
    cert_buf[229] = 255u8
    cert_buf[230] = 8u8
    cert_buf[231] = 245u8
    cert_buf[232] = 80u8
    cert_buf[233] = 18u8
    cert_buf[234] = 10u8
    cert_buf[235] = 2u8
    cert_buf[236] = 56u8
    cert_buf[237] = 229u8
    cert_buf[238] = 125u8
    cert_buf[239] = 214u8
    cert_buf[240] = 242u8
    cert_buf[241] = 48u8
    cert_buf[242] = 146u8
    cert_buf[243] = 113u8
    cert_buf[244] = 234u8
    cert_buf[245] = 188u8
    cert_buf[246] = 69u8
    cert_buf[247] = 193u8
    cert_buf[248] = 197u8
    cert_buf[249] = 114u8
    cert_buf[250] = 17u8
    cert_buf[251] = 202u8
    cert_buf[252] = 78u8
    cert_buf[253] = 184u8
    cert_buf[254] = 212u8
    cert_buf[255] = 30u8
    cert_buf[256] = 100u8
    cert_buf[257] = 4u8
    cert_buf[258] = 238u8
    cert_buf[259] = 106u8
    cert_buf[260] = 249u8
    cert_buf[261] = 33u8
    cert_buf[262] = 138u8
    cert_buf[263] = 138u8
    cert_buf[264] = 10u8
    cert_buf[265] = 126u8
    cert_buf[266] = 226u8
    cert_buf[267] = 129u8
    cert_buf[268] = 223u8
    cert_buf[269] = 173u8
    cert_buf[270] = 18u8
    cert_buf[271] = 119u8
    cert_buf[272] = 247u8
    cert_buf[273] = 100u8
    cert_buf[274] = 99u8
    cert_buf[275] = 0u8
    cert_buf[276] = 214u8
    cert_buf[277] = 68u8
    cert_buf[278] = 35u8
    cert_buf[279] = 83u8
    cert_buf[280] = 150u8
    cert_buf[281] = 53u8
    cert_buf[282] = 154u8
    cert_buf[283] = 112u8
    cert_buf[284] = 10u8
    cert_buf[285] = 116u8
    cert_buf[286] = 207u8
    cert_buf[287] = 175u8
    cert_buf[288] = 162u8
    cert_buf[289] = 1u8
    cert_buf[290] = 10u8
    cert_buf[291] = 40u8
    cert_buf[292] = 195u8
    cert_buf[293] = 103u8
    cert_buf[294] = 222u8
    cert_buf[295] = 78u8
    cert_buf[296] = 164u8
    cert_buf[297] = 215u8
    cert_buf[298] = 97u8
    cert_buf[299] = 75u8
    cert_buf[300] = 45u8
    cert_buf[301] = 142u8
    cert_buf[302] = 249u8
    cert_buf[303] = 208u8
    cert_buf[304] = 1u8
    cert_buf[305] = 87u8
    cert_buf[306] = 106u8
    cert_buf[307] = 155u8
    cert_buf[308] = 100u8
    cert_buf[309] = 102u8
    cert_buf[310] = 240u8
    cert_buf[311] = 115u8
    cert_buf[312] = 206u8
    cert_buf[313] = 48u8
    cert_buf[314] = 13u8
    cert_buf[315] = 219u8
    cert_buf[316] = 181u8
    cert_buf[317] = 181u8
    cert_buf[318] = 88u8
    cert_buf[319] = 71u8
    cert_buf[320] = 180u8
    cert_buf[321] = 118u8
    cert_buf[322] = 249u8
    cert_buf[323] = 165u8
    cert_buf[324] = 56u8
    cert_buf[325] = 235u8
    cert_buf[326] = 250u8
    cert_buf[327] = 62u8
    cert_buf[328] = 49u8
    cert_buf[329] = 138u8
    cert_buf[330] = 103u8
    cert_buf[331] = 200u8
    cert_buf[332] = 211u8
    cert_buf[333] = 152u8
    cert_buf[334] = 67u8
    cert_buf[335] = 78u8
    cert_buf[336] = 5u8
    cert_buf[337] = 38u8
    cert_buf[338] = 140u8
    cert_buf[339] = 96u8
    cert_buf[340] = 93u8
    cert_buf[341] = 161u8
    cert_buf[342] = 0u8
    cert_buf[343] = 131u8
    cert_buf[344] = 86u8
    cert_buf[345] = 227u8
    cert_buf[346] = 245u8
    cert_buf[347] = 183u8
    cert_buf[348] = 8u8
    cert_buf[349] = 31u8
    cert_buf[350] = 197u8
    cert_buf[351] = 34u8
    cert_buf[352] = 114u8
    cert_buf[353] = 136u8
    cert_buf[354] = 187u8
    cert_buf[355] = 23u8
    cert_buf[356] = 90u8
    cert_buf[357] = 139u8
    cert_buf[358] = 212u8
    cert_buf[359] = 253u8
    cert_buf[360] = 3u8
    cert_buf[361] = 124u8
    cert_buf[362] = 227u8
    cert_buf[363] = 152u8
    cert_buf[364] = 206u8
    cert_buf[365] = 72u8
    cert_buf[366] = 151u8
    cert_buf[367] = 206u8
    cert_buf[368] = 108u8
    cert_buf[369] = 87u8
    cert_buf[370] = 241u8
    cert_buf[371] = 29u8
    cert_buf[372] = 147u8
    cert_buf[373] = 172u8
    cert_buf[374] = 138u8
    cert_buf[375] = 249u8
    cert_buf[376] = 95u8
    cert_buf[377] = 14u8
    cert_buf[378] = 97u8
    cert_buf[379] = 244u8
    cert_buf[380] = 95u8
    cert_buf[381] = 4u8
    cert_buf[382] = 43u8
    cert_buf[383] = 147u8
    cert_buf[384] = 129u8
    cert_buf[385] = 20u8
    cert_buf[386] = 196u8
    cert_buf[387] = 75u8
    cert_buf[388] = 225u8
    cert_buf[389] = 47u8
    cert_buf[390] = 184u8
    cert_buf[391] = 247u8
    cert_buf[392] = 106u8
    cert_buf[393] = 133u8
    cert_buf[394] = 38u8
    cert_buf[395] = 126u8
    cert_buf[396] = 63u8
    cert_buf[397] = 244u8
    cert_buf[398] = 223u8
    cert_buf[399] = 155u8
    cert_buf[400] = 39u8
    cert_buf[401] = 159u8
    cert_buf[402] = 209u8
    cert_buf[403] = 187u8
    cert_buf[404] = 71u8
    cert_buf[405] = 2u8
    cert_buf[406] = 3u8
    cert_buf[407] = 1u8
    cert_buf[408] = 0u8
    cert_buf[409] = 1u8
    cert_buf[410] = 163u8
    cert_buf[411] = 83u8
    cert_buf[412] = 48u8
    cert_buf[413] = 81u8
    cert_buf[414] = 48u8
    cert_buf[415] = 29u8
    cert_buf[416] = 6u8
    cert_buf[417] = 3u8
    cert_buf[418] = 85u8
    cert_buf[419] = 29u8
    cert_buf[420] = 14u8
    cert_buf[421] = 4u8
    cert_buf[422] = 22u8
    cert_buf[423] = 4u8
    cert_buf[424] = 20u8
    cert_buf[425] = 248u8
    cert_buf[426] = 246u8
    cert_buf[427] = 9u8
    cert_buf[428] = 140u8
    cert_buf[429] = 171u8
    cert_buf[430] = 30u8
    cert_buf[431] = 159u8
    cert_buf[432] = 92u8
    cert_buf[433] = 237u8
    cert_buf[434] = 146u8
    cert_buf[435] = 96u8
    cert_buf[436] = 87u8
    cert_buf[437] = 210u8
    cert_buf[438] = 87u8
    cert_buf[439] = 91u8
    cert_buf[440] = 14u8
    cert_buf[441] = 86u8
    cert_buf[442] = 77u8
    cert_buf[443] = 117u8
    cert_buf[444] = 129u8
    cert_buf[445] = 48u8
    cert_buf[446] = 31u8
    cert_buf[447] = 6u8
    cert_buf[448] = 3u8
    cert_buf[449] = 85u8
    cert_buf[450] = 29u8
    cert_buf[451] = 35u8
    cert_buf[452] = 4u8
    cert_buf[453] = 24u8
    cert_buf[454] = 48u8
    cert_buf[455] = 22u8
    cert_buf[456] = 128u8
    cert_buf[457] = 20u8
    cert_buf[458] = 248u8
    cert_buf[459] = 246u8
    cert_buf[460] = 9u8
    cert_buf[461] = 140u8
    cert_buf[462] = 171u8
    cert_buf[463] = 30u8
    cert_buf[464] = 159u8
    cert_buf[465] = 92u8
    cert_buf[466] = 237u8
    cert_buf[467] = 146u8
    cert_buf[468] = 96u8
    cert_buf[469] = 87u8
    cert_buf[470] = 210u8
    cert_buf[471] = 87u8
    cert_buf[472] = 91u8
    cert_buf[473] = 14u8
    cert_buf[474] = 86u8
    cert_buf[475] = 77u8
    cert_buf[476] = 117u8
    cert_buf[477] = 129u8
    cert_buf[478] = 48u8
    cert_buf[479] = 15u8
    cert_buf[480] = 6u8
    cert_buf[481] = 3u8
    cert_buf[482] = 85u8
    cert_buf[483] = 29u8
    cert_buf[484] = 19u8
    cert_buf[485] = 1u8
    cert_buf[486] = 1u8
    cert_buf[487] = 255u8
    cert_buf[488] = 4u8
    cert_buf[489] = 5u8
    cert_buf[490] = 48u8
    cert_buf[491] = 3u8
    cert_buf[492] = 1u8
    cert_buf[493] = 1u8
    cert_buf[494] = 255u8
    cert_buf[495] = 48u8
    cert_buf[496] = 13u8
    cert_buf[497] = 6u8
    cert_buf[498] = 9u8
    cert_buf[499] = 42u8
    cert_buf[500] = 134u8
    cert_buf[501] = 72u8
    cert_buf[502] = 134u8
    cert_buf[503] = 247u8
    cert_buf[504] = 13u8
    cert_buf[505] = 1u8
    cert_buf[506] = 1u8
    cert_buf[507] = 11u8
    cert_buf[508] = 5u8
    cert_buf[509] = 0u8
    cert_buf[510] = 3u8
    cert_buf[511] = 130u8
    cert_buf[512] = 1u8
    cert_buf[513] = 1u8
    cert_buf[514] = 0u8
    cert_buf[515] = 133u8
    cert_buf[516] = 85u8
    cert_buf[517] = 76u8
    cert_buf[518] = 177u8
    cert_buf[519] = 87u8
    cert_buf[520] = 236u8
    cert_buf[521] = 180u8
    cert_buf[522] = 84u8
    cert_buf[523] = 156u8
    cert_buf[524] = 92u8
    cert_buf[525] = 70u8
    cert_buf[526] = 250u8
    cert_buf[527] = 116u8
    cert_buf[528] = 174u8
    cert_buf[529] = 210u8
    cert_buf[530] = 203u8
    cert_buf[531] = 163u8
    cert_buf[532] = 209u8
    cert_buf[533] = 202u8
    cert_buf[534] = 177u8
    cert_buf[535] = 243u8
    cert_buf[536] = 79u8
    cert_buf[537] = 238u8
    cert_buf[538] = 135u8
    cert_buf[539] = 105u8
    cert_buf[540] = 183u8
    cert_buf[541] = 135u8
    cert_buf[542] = 120u8
    cert_buf[543] = 117u8
    cert_buf[544] = 193u8
    cert_buf[545] = 77u8
    cert_buf[546] = 169u8
    cert_buf[547] = 215u8
    cert_buf[548] = 49u8
    cert_buf[549] = 194u8
    cert_buf[550] = 42u8
    cert_buf[551] = 1u8
    cert_buf[552] = 101u8
    cert_buf[553] = 109u8
    cert_buf[554] = 243u8
    cert_buf[555] = 225u8
    cert_buf[556] = 132u8
    cert_buf[557] = 115u8
    cert_buf[558] = 84u8
    cert_buf[559] = 43u8
    cert_buf[560] = 37u8
    cert_buf[561] = 174u8
    cert_buf[562] = 102u8
    cert_buf[563] = 228u8
    cert_buf[564] = 92u8
    cert_buf[565] = 120u8
    cert_buf[566] = 173u8
    cert_buf[567] = 186u8
    cert_buf[568] = 25u8
    cert_buf[569] = 90u8
    cert_buf[570] = 47u8
    cert_buf[571] = 112u8
    cert_buf[572] = 168u8
    cert_buf[573] = 103u8
    cert_buf[574] = 54u8
    cert_buf[575] = 62u8
    cert_buf[576] = 239u8
    cert_buf[577] = 129u8
    cert_buf[578] = 142u8
    cert_buf[579] = 242u8
    cert_buf[580] = 81u8
    cert_buf[581] = 6u8
    cert_buf[582] = 205u8
    cert_buf[583] = 178u8
    cert_buf[584] = 95u8
    cert_buf[585] = 87u8
    cert_buf[586] = 127u8
    cert_buf[587] = 219u8
    cert_buf[588] = 191u8
    cert_buf[589] = 5u8
    cert_buf[590] = 5u8
    cert_buf[591] = 9u8
    cert_buf[592] = 106u8
    cert_buf[593] = 162u8
    cert_buf[594] = 19u8
    cert_buf[595] = 83u8
    cert_buf[596] = 217u8
    cert_buf[597] = 81u8
    cert_buf[598] = 207u8
    cert_buf[599] = 191u8
    cert_buf[600] = 10u8
    cert_buf[601] = 246u8
    cert_buf[602] = 121u8
    cert_buf[603] = 161u8
    cert_buf[604] = 38u8
    cert_buf[605] = 250u8
    cert_buf[606] = 99u8
    cert_buf[607] = 176u8
    cert_buf[608] = 77u8
    cert_buf[609] = 176u8
    cert_buf[610] = 120u8
    cert_buf[611] = 207u8
    cert_buf[612] = 244u8
    cert_buf[613] = 25u8
    cert_buf[614] = 35u8
    cert_buf[615] = 87u8
    cert_buf[616] = 170u8
    cert_buf[617] = 97u8
    cert_buf[618] = 56u8
    cert_buf[619] = 122u8
    cert_buf[620] = 155u8
    cert_buf[621] = 237u8
    cert_buf[622] = 31u8
    cert_buf[623] = 246u8
    cert_buf[624] = 155u8
    cert_buf[625] = 199u8
    cert_buf[626] = 20u8
    cert_buf[627] = 127u8
    cert_buf[628] = 255u8
    cert_buf[629] = 37u8
    cert_buf[630] = 7u8
    cert_buf[631] = 231u8
    cert_buf[632] = 121u8
    cert_buf[633] = 173u8
    cert_buf[634] = 200u8
    cert_buf[635] = 130u8
    cert_buf[636] = 76u8
    cert_buf[637] = 41u8
    cert_buf[638] = 100u8
    cert_buf[639] = 12u8
    cert_buf[640] = 133u8
    cert_buf[641] = 217u8
    cert_buf[642] = 199u8
    cert_buf[643] = 118u8
    cert_buf[644] = 176u8
    cert_buf[645] = 169u8
    cert_buf[646] = 72u8
    cert_buf[647] = 127u8
    cert_buf[648] = 96u8
    cert_buf[649] = 94u8
    cert_buf[650] = 85u8
    cert_buf[651] = 102u8
    cert_buf[652] = 182u8
    cert_buf[653] = 45u8
    cert_buf[654] = 71u8
    cert_buf[655] = 134u8
    cert_buf[656] = 181u8
    cert_buf[657] = 93u8
    cert_buf[658] = 39u8
    cert_buf[659] = 53u8
    cert_buf[660] = 5u8
    cert_buf[661] = 220u8
    cert_buf[662] = 187u8
    cert_buf[663] = 69u8
    cert_buf[664] = 50u8
    cert_buf[665] = 59u8
    cert_buf[666] = 63u8
    cert_buf[667] = 41u8
    cert_buf[668] = 21u8
    cert_buf[669] = 161u8
    cert_buf[670] = 6u8
    cert_buf[671] = 44u8
    cert_buf[672] = 119u8
    cert_buf[673] = 172u8
    cert_buf[674] = 76u8
    cert_buf[675] = 112u8
    cert_buf[676] = 149u8
    cert_buf[677] = 241u8
    cert_buf[678] = 107u8
    cert_buf[679] = 35u8
    cert_buf[680] = 28u8
    cert_buf[681] = 151u8
    cert_buf[682] = 142u8
    cert_buf[683] = 114u8
    cert_buf[684] = 255u8
    cert_buf[685] = 34u8
    cert_buf[686] = 178u8
    cert_buf[687] = 132u8
    cert_buf[688] = 240u8
    cert_buf[689] = 189u8
    cert_buf[690] = 64u8
    cert_buf[691] = 18u8
    cert_buf[692] = 5u8
    cert_buf[693] = 112u8
    cert_buf[694] = 28u8
    cert_buf[695] = 27u8
    cert_buf[696] = 232u8
    cert_buf[697] = 15u8
    cert_buf[698] = 37u8
    cert_buf[699] = 1u8
    cert_buf[700] = 94u8
    cert_buf[701] = 93u8
    cert_buf[702] = 243u8
    cert_buf[703] = 18u8
    cert_buf[704] = 22u8
    cert_buf[705] = 109u8
    cert_buf[706] = 90u8
    cert_buf[707] = 9u8
    cert_buf[708] = 168u8
    cert_buf[709] = 128u8
    cert_buf[710] = 56u8
    cert_buf[711] = 38u8
    cert_buf[712] = 63u8
    cert_buf[713] = 52u8
    cert_buf[714] = 180u8
    cert_buf[715] = 174u8
    cert_buf[716] = 77u8
    cert_buf[717] = 61u8
    cert_buf[718] = 83u8
    cert_buf[719] = 202u8
    cert_buf[720] = 184u8
    cert_buf[721] = 72u8
    cert_buf[722] = 204u8
    cert_buf[723] = 171u8
    cert_buf[724] = 15u8
    cert_buf[725] = 135u8
    cert_buf[726] = 99u8
    cert_buf[727] = 13u8
    cert_buf[728] = 148u8
    cert_buf[729] = 31u8
    cert_buf[730] = 191u8
    cert_buf[731] = 175u8
    cert_buf[732] = 118u8
    cert_buf[733] = 205u8
    cert_buf[734] = 36u8
    cert_buf[735] = 229u8
    cert_buf[736] = 178u8
    cert_buf[737] = 87u8
    cert_buf[738] = 46u8
    cert_buf[739] = 121u8
    cert_buf[740] = 190u8
    cert_buf[741] = 121u8
    cert_buf[742] = 50u8
    cert_buf[743] = 89u8
    cert_buf[744] = 220u8
    cert_buf[745] = 239u8
    cert_buf[746] = 202u8
    cert_buf[747] = 125u8
    cert_buf[748] = 11u8
    cert_buf[749] = 142u8
    cert_buf[750] = 128u8
    cert_buf[751] = 16u8
    cert_buf[752] = 244u8
    cert_buf[753] = 48u8
    cert_buf[754] = 51u8
    cert_buf[755] = 72u8
    cert_buf[756] = 232u8
    cert_buf[757] = 42u8
    cert_buf[758] = 251u8
    cert_buf[759] = 143u8
    cert_buf[760] = 51u8
    cert_buf[761] = 46u8
    cert_buf[762] = 23u8
    cert_buf[763] = 41u8
    cert_buf[764] = 174u8
    cert_buf[765] = 229u8
    cert_buf[766] = 208u8
    cert_buf[767] = 104u8
    cert_buf[768] = 220u8
    cert_buf[769] = 122u8
    cert_buf[770] = 129u8
    // cut 1: buf_len=520, inside signatureValue content (header fits)
    var c1 = X509Cert.new()
    var r1 = 0
    unsafe:
        r1 = x509_parse(&raw mut c1 as *mut X509Cert, &cert_buf[0] as *const u8, 520)
    print_i32(r1)
    print_i32(c1.sig_start)
    print_i32(c1.sig_len)
    // cut 2: buf_len=200, inside modulus content
    var c2 = X509Cert.new()
    var r2 = 0
    unsafe:
        r2 = x509_parse(&raw mut c2 as *mut X509Cert, &cert_buf[0] as *const u8, 200)
    print_i32(r2)
    0
