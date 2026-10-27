// TLS 1.2 client — record layer, PRF, and handshake
//
// Supports cipher suites:
//   TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256    (0xC02F)
//   TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256  (0xC02B)

use std.crypto.sha256
use std.crypto.sha512
use std.crypto.hmac
use std.crypto.aes
use std.crypto.gcm
use std.crypto.ec
use std.crypto.ecdsa
use std.crypto.x509
use std.crypto.endian
use std.net
use std.fs
use std.process
use std.internal.str_abi
use rt.rt_core

// ── TLS constants ──────────────────────────────────────────────────

let TLS_HANDSHAKE: u8 = 22u8
let TLS_CHANGE_CIPHER_SPEC: u8 = 20u8
let TLS_APPLICATION_DATA: u8 = 23u8
let TLS_ALERT: u8 = 21u8

let HS_CLIENT_HELLO: u8 = 1u8
let HS_SERVER_HELLO: u8 = 2u8
let HS_CERTIFICATE: u8 = 11u8
let HS_SERVER_KEY_EXCHANGE: u8 = 12u8
let HS_SERVER_HELLO_DONE: u8 = 14u8
let HS_CLIENT_KEY_EXCHANGE: u8 = 16u8
let HS_FINISHED: u8 = 20u8
let HS_NEW_SESSION_TICKET: u8 = 4u8

let SUITE_ECDHE_RSA_AES128_GCM: u16 = 0xC02Fu16
let SUITE_ECDHE_ECDSA_AES128_GCM: u16 = 0xC02Bu16

// ── TLS record I/O ─────────────────────────────────────────────────

// Send a TLS record. Returns bytes sent or -1 on error.
unsafe fn tls_send_record(fd: i32, content_type: u8, data: *const u8, data_len: i32) -> i32:
    // Build header: type(1) + version(2) + length(2)
    var hdr: [u8; 5] = [0u8; 5]
    hdr[0] = content_type
    hdr[1] = 0x03u8  // TLS 1.2
    hdr[2] = 0x03u8
    hdr[3] = (data_len >> 8) as u8
    hdr[4] = (data_len & 0xFF) as u8

    // Send header
    // Construct a temporary str view for the record header.
    let hp = &hdr[0] as *const u8
    var hdr_s: str = ""
    // Hack: set str ptr and len directly
    let sp = &raw mut hdr_s as *mut u8
    *(sp as *mut u64) = hp as u64
    *((sp + 8u64) as *mut i64) = 5i64
    let sent1 = with_net_send(fd, hdr_s)
    if sent1 < 0i64:
        return -1

    // Send data
    var data_s: str = ""
    let dp = &raw mut data_s as *mut u8
    *(dp as *mut u64) = data as u64
    *((dp + 8u64) as *mut i64) = data_len as i64
    let sent2 = with_net_send(fd, data_s)
    if sent2 < 0i64:
        return -1

    data_len

// Receive a TLS record into buf. Returns content length or -1 on error.
// Sets *content_type to the record's content type.
unsafe fn tls_recv_record(fd: i32, content_type: *mut u8, buf: *mut u8, buf_cap: i32) -> i32:

    // Read 5-byte header
    var hdr: [u8; 5] = [0u8; 5]
    var total_read = 0
    while total_read < 5:
        let chunk = recv(fd, (5 - total_read) as i64)
        if chunk.len() == 0:
            return -1
        var ci = 0
        while ci < chunk.len():
            let v = chunk[ci] as u8
            hdr[total_read + ci] = v
            ci = ci + 1
        total_read = total_read + chunk.len()

    *(content_type + 0u64) = hdr[0]
    let h3 = hdr[3] as u32
    let h4 = hdr[4] as u32
    let rec_len = ((h3 << 8u32) | h4) as i32
    if rec_len > buf_cap or rec_len < 0:
        return -1

    // Read record body
    total_read = 0
    while total_read < rec_len:
        let chunk = recv(fd, (rec_len - total_read) as i64)
        if chunk.len() == 0:
            return -1
        var ci = 0
        while ci < chunk.len():
            let v = chunk[ci] as u8
            *(buf + (total_read + ci) as u64) = v
            ci = ci + 1
        total_read = total_read + chunk.len()

    rec_len

// ── TLS PRF (SHA-256 based) ────────────────────────────────────────

// P_SHA256: generate output_len bytes of PRF output
unsafe fn tls_prf_sha256(
    secret: *const u8, secret_len: i32,
    label: *const u8, label_len: i32,
    seed: *const u8, seed_len: i32,
    output: *mut u8, output_len: i32,
):
    // seed_full = label + seed
    let seed_full_len = label_len + seed_len
    var seed_full: [u8; 256] = [0u8; 256]
    var i = 0
    while i < label_len:
        let v = *(label + i as u64)
        seed_full[i] = v
        i = i + 1
    i = 0
    while i < seed_len:
        let v = *(seed + i as u64)
        seed_full[label_len + i] = v
        i = i + 1

    // A(0) = seed_full
    var a: [u8; 32] = [0u8; 32]
    // A(1) = HMAC(secret, A(0))
    hmac_sha256(secret, secret_len, &seed_full[0] as *const u8, seed_full_len, &raw mut a[0] as *mut u8)

    var produced = 0
    while produced < output_len:
        // P_i = HMAC(secret, A(i) + seed_full)
        var concat: [u8; 288] = [0u8; 288]
        // Copy A(i)
        var j = 0
        while j < 32:
            concat[j] = a[j]
            j = j + 1
        // Copy seed_full
        j = 0
        while j < seed_full_len:
            concat[32 + j] = seed_full[j]
            j = j + 1

        var p_block: [u8; 32] = [0u8; 32]
        hmac_sha256(secret, secret_len, &concat[0] as *const u8, 32 + seed_full_len, &raw mut p_block[0] as *mut u8)

        // Copy to output
        j = 0
        while j < 32 and produced + j < output_len:
            *(output + (produced + j) as u64) = p_block[j]
            j = j + 1
        produced = produced + j

        // A(i+1) = HMAC(secret, A(i))
        var a_next: [u8; 32] = [0u8; 32]
        hmac_sha256(secret, secret_len, &a[0] as *const u8, 32, &raw mut a_next[0] as *mut u8)
        j = 0
        while j < 32:
            a[j] = a_next[j]
            j = j + 1

// ── TLS connection state ───────────────────────────────────────────

type TlsConn  {
    fd: i32,
    // Handshake state
    client_random: [u8; 32],
    server_random: [u8; 32],
    // Encryption state
    client_write_key: [u8; 16],
    server_write_key: [u8; 16],
    client_write_iv: [u8; 4],
    server_write_iv: [u8; 4],
    client_seq: u64,
    server_seq: u64,
    cipher_active: i32,
    // Handshake hash (SHA-256 of all handshake messages)
    hs_hash_ctx: Sha256,
    // Master secret, kept for the Finished verify_data checks (#1061)
    master_secret: [u8; 48],
    // Chosen cipher suite
    cipher_suite: u16,
    // Error flag
    err_flag: i32,
}

fn TlsConn.new(fd: i32) -> TlsConn:
    TlsConn {
        fd: fd,
        client_random: [0u8; 32],
        server_random: [0u8; 32],
        client_write_key: [0u8; 16],
        server_write_key: [0u8; 16],
        client_write_iv: [0u8; 4],
        server_write_iv: [0u8; 4],
        client_seq: 0u64,
        server_seq: 0u64,
        cipher_active: 0,
        hs_hash_ctx: Sha256.new(),
        master_secret: [0u8; 48],
        cipher_suite: 0u16,
        err_flag: 0,
    }

// Update handshake hash with a handshake message
unsafe fn tls_hs_hash_update(conn: *mut TlsConn, data: *const u8, len: i32):
    var ctx = conn.hs_hash_ctx
    let cp = &raw mut ctx as *mut Sha256
    sha256_update(cp, data, len)
    conn.hs_hash_ctx = ctx

// Get current handshake hash (without finalizing the running context)
unsafe fn tls_hs_hash_current(conn: *mut TlsConn, out: *mut u8):
    // Copy the context to avoid modifying the running one
    var ctx = conn.hs_hash_ctx
    let cp = &raw mut ctx as *mut Sha256
    sha256_finish(cp, out)

// ── Encrypted record send/recv ─────────────────────────────────────

// Send an encrypted TLS record using AES-128-GCM
unsafe fn tls_send_encrypted(conn: *mut TlsConn, content_type: u8, data: *const u8, data_len: i32) -> i32:
    // Build nonce: client_write_iv (4) + explicit nonce (8)
    var nonce: [u8; 12] = [0u8; 12]
    var ni = 0
    while ni < 4:
        nonce[ni] = conn.client_write_iv[ni]
        ni = ni + 1
    // Explicit nonce = sequence number (big-endian)
    u64_to_be(&raw mut nonce[4] as *mut u8, 0, conn.client_seq)

    // Encrypt
    var ct: [u8; 16640] = [0u8; 16640]  // max TLS record + overhead
    var tag: [u8; 16] = [0u8; 16]
    var aes_ctx = AesGcm.new(&conn.client_write_key[0] as *const u8, &nonce[0] as *const u8, 12)

    // AAD: seq(8) + type(1) + version(2) + length(2)
    var aad: [u8; 13] = [0u8; 13]
    u64_to_be(&raw mut aad[0] as *mut u8, 0, conn.client_seq)
    aad[8] = content_type
    aad[9] = 0x03u8
    aad[10] = 0x03u8
    aad[11] = (data_len >> 8) as u8
    aad[12] = (data_len & 0xFF) as u8
    AesGcm.aad(&raw mut aes_ctx as *mut AesGcm, &aad[0] as *const u8, 13)

    AesGcm.encrypt(&raw mut aes_ctx as *mut AesGcm, data, &raw mut ct[8] as *mut u8, data_len)
    AesGcm.tag(&raw mut aes_ctx as *mut AesGcm, &raw mut tag[0] as *mut u8)

    // Record payload: explicit_nonce(8) + ciphertext(data_len) + tag(16)
    // Copy explicit nonce to start of ct
    ni = 0
    while ni < 8:
        ct[ni] = nonce[4 + ni]
        ni = ni + 1
    // Copy tag after ciphertext
    ni = 0
    while ni < 16:
        ct[8 + data_len + ni] = tag[ni]
        ni = ni + 1

    let total = 8 + data_len + 16
    conn.client_seq = conn.client_seq + 1u64

    tls_send_record(conn.fd, content_type, &ct[0] as *const u8, total)

// Decrypt a received encrypted record (AES-128-GCM)
// Returns plaintext length or -1 on error/auth failure.
unsafe fn tls_decrypt_record(conn: *mut TlsConn, content_type: u8, enc_data: *const u8, enc_len: i32, plain: *mut u8) -> i32:
    if enc_len < 24:  // 8 nonce + 0 data + 16 tag minimum
        return -1

    // Build nonce: server_write_iv(4) + explicit_nonce(8)
    var nonce: [u8; 12] = [0u8; 12]
    var ni = 0
    while ni < 4:
        nonce[ni] = conn.server_write_iv[ni]
        ni = ni + 1
    ni = 0
    while ni < 8:
        let v = *(enc_data + ni as u64)
        nonce[4 + ni] = v
        ni = ni + 1

    let ct_len = enc_len - 8 - 16
    let ct_start = enc_data + 8u64

    // AAD
    var aad: [u8; 13] = [0u8; 13]
    u64_to_be(&raw mut aad[0] as *mut u8, 0, conn.server_seq)
    aad[8] = content_type
    aad[9] = 0x03u8
    aad[10] = 0x03u8
    aad[11] = (ct_len >> 8) as u8
    aad[12] = (ct_len & 0xFF) as u8

    // Decrypt: GHASH the ciphertext,: XOR with keystream
    var aes_ctx = AesGcm.new(&conn.server_write_key[0] as *const u8, &nonce[0] as *const u8, 12)
    AesGcm.aad(&raw mut aes_ctx as *mut AesGcm, &aad[0] as *const u8, 13)
    AesGcm.decrypt(&raw mut aes_ctx as *mut AesGcm, ct_start, plain, ct_len)

    // Verify tag
    var computed_tag: [u8; 16] = [0u8; 16]
    AesGcm.tag(&raw mut aes_ctx as *mut AesGcm, &raw mut computed_tag[0] as *mut u8)
    let expected_tag = enc_data + (8 + ct_len) as u64
    var tag_ok = 1
    ni = 0
    while ni < 16:
        if computed_tag[ni] != *(expected_tag + ni as u64):
            tag_ok = 0
        ni = ni + 1

    conn.server_seq = conn.server_seq + 1u64

    if tag_ok == 0:
        return -1
    ct_len

// ── High-level TLS send/recv ───────────────────────────────────────

// Send application data (encrypted after handshake)
unsafe fn tls_send(conn: *mut TlsConn, data: *const u8, data_len: i32) -> i32:
    if conn.cipher_active != 0:
        return tls_send_encrypted(conn, TLS_APPLICATION_DATA, data, data_len)
    tls_send_record(conn.fd, TLS_APPLICATION_DATA, data, data_len)

// Receive application data. Returns plaintext length or -1.
unsafe fn tls_recv(conn: *mut TlsConn, buf: *mut u8, buf_cap: i32) -> i32:
    var ct: u8 = 0u8
    var rec_buf: [u8; 16640] = [0u8; 16640]
    let rec_len = tls_recv_record(conn.fd, &raw mut ct as *mut u8, &raw mut rec_buf[0] as *mut u8, 16640)
    if rec_len < 0:
        return -1
    if ct != TLS_APPLICATION_DATA:
        return -1
    if conn.cipher_active != 0:
        if rec_len - 24 > buf_cap:
            return -1
        return tls_decrypt_record(conn, ct, &rec_buf[0] as *const u8, rec_len, buf)
    // Unencrypted: copy directly
    var i = 0
    while i < rec_len and i < buf_cap:
        *(buf + i as u64) = rec_buf[i]
        i = i + 1
    rec_len

// ── Random bytes ───────────────────────────────────────────────────


unsafe fn fill_random(buf: *mut u8, len: i32):
    with_fill_random(buf, len as i64)

// ── TLS 1.2 Handshake ─────────────────────────────────────────────

// Build and send ClientHello. Returns 0 on success, -1 on error.
unsafe fn tls_send_client_hello(conn: *mut TlsConn, hostname: *const u8, hostname_len: i32) -> i32:
    // Generate client random
    fill_random(&raw mut conn.client_random[0] as *mut u8, 32)

    var buf: [u8; 512] = [0u8; 512]
    var pos: i32 = 0

    // Handshake header (filled later with length)
    buf[pos] = HS_CLIENT_HELLO
    pos = pos + 1
    let len_pos = pos
    pos = pos + 3  // 3-byte length placeholder

    // Protocol version: TLS 1.2
    buf[pos] = 0x03u8
    buf[pos + 1] = 0x03u8
    pos = pos + 2

    // Client random (32 bytes)
    var ri = 0
    while ri < 32:
        buf[pos + ri] = conn.client_random[ri]
        ri = ri + 1
    pos = pos + 32

    // Session ID length: 0
    buf[pos] = 0u8
    pos = pos + 1

    // Cipher suites (2 suites = 4 bytes + 2 length)
    buf[pos] = 0u8
    buf[pos + 1] = 4u8  // 4 bytes of cipher suites
    pos = pos + 2
    // TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (0xC02F)
    buf[pos] = 0xC0u8
    buf[pos + 1] = 0x2Fu8
    pos = pos + 2
    // TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 (0xC02B)
    buf[pos] = 0xC0u8
    buf[pos + 1] = 0x2Bu8
    pos = pos + 2

    // Compression methods: null only
    buf[pos] = 1u8  // 1 method
    buf[pos + 1] = 0u8  // null compression
    pos = pos + 2

    // Extensions
    let ext_len_pos = pos
    pos = pos + 2  // extensions length placeholder

    // Extension: supported_groups (0x000A). In TLS 1.2 this list also
    // bounds the curves a server certificate may use (RFC 4492): both
    // curves we verify and do ECDHE on are offered, P-256 first.
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x0Au8
    pos = pos + 2
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x06u8  // ext data length
    pos = pos + 2
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x04u8  // named curve list length
    pos = pos + 2
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x17u8  // secp256r1
    buf[pos + 2] = 0x00u8
    buf[pos + 3] = 0x18u8  // secp384r1
    pos = pos + 4

    // Extension: ec_point_formats (0x000B)
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x0Bu8
    pos = pos + 2
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x02u8  // ext data length
    pos = pos + 2
    buf[pos] = 0x01u8  // format list length
    buf[pos + 1] = 0x00u8  // uncompressed
    pos = pos + 2

    // Extension: signature_algorithms (0x000D)
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x0Du8
    pos = pos + 2
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x0Eu8  // ext data length
    pos = pos + 2
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x0Cu8  // sig alg list length
    pos = pos + 2
    // RSA PKCS1 SHA256 (0x0401), ECDSA SHA256 (0x0403),
    // RSA PKCS1 SHA384 (0x0501), ECDSA SHA384 (0x0503),
    // RSA PKCS1 SHA512 (0x0601), ECDSA SHA512 (0x0603)
    buf[pos] = 0x04u8
    buf[pos + 1] = 0x01u8
    buf[pos + 2] = 0x04u8
    buf[pos + 3] = 0x03u8
    buf[pos + 4] = 0x05u8
    buf[pos + 5] = 0x01u8
    buf[pos + 6] = 0x05u8
    buf[pos + 7] = 0x03u8
    buf[pos + 8] = 0x06u8
    buf[pos + 9] = 0x01u8
    buf[pos + 10] = 0x06u8
    buf[pos + 11] = 0x03u8
    pos = pos + 12

    // Extension: server_name (SNI) (0x0000)
    if hostname_len > 0:
        buf[pos] = 0x00u8
        buf[pos + 1] = 0x00u8
        pos = pos + 2
        let sni_len = hostname_len + 5
        buf[pos] = (sni_len >> 8) as u8
        buf[pos + 1] = (sni_len & 0xFF) as u8
        pos = pos + 2
        let sni_list_len = hostname_len + 3
        buf[pos] = (sni_list_len >> 8) as u8
        buf[pos + 1] = (sni_list_len & 0xFF) as u8
        pos = pos + 2
        buf[pos] = 0x00u8  // host_name type
        pos = pos + 1
        buf[pos] = (hostname_len >> 8) as u8
        buf[pos + 1] = (hostname_len & 0xFF) as u8
        pos = pos + 2
        var hi = 0
        while hi < hostname_len:
            let v = *(hostname + hi as u64)
            buf[pos + hi] = v
            hi = hi + 1
        pos = pos + hostname_len

    // Fill extensions length
    let ext_total = pos - ext_len_pos - 2
    buf[ext_len_pos] = (ext_total >> 8) as u8
    buf[ext_len_pos + 1] = (ext_total & 0xFF) as u8

    // Fill handshake length (3 bytes, big-endian)
    let hs_len = pos - len_pos - 3
    buf[len_pos] = 0u8
    buf[len_pos + 1] = (hs_len >> 8) as u8
    buf[len_pos + 2] = (hs_len & 0xFF) as u8

    // Update handshake hash
    tls_hs_hash_update(conn, &buf[0] as *const u8, pos)

    // Send as TLS handshake record
    tls_send_record(conn.fd, TLS_HANDSHAKE, &buf[0] as *const u8, pos)

// Parse ServerHello from handshake message body.
unsafe fn tls_parse_server_hello(conn: *mut TlsConn, data: *const u8, len: i32) -> i32:
    if len < 38:
        return -1
    // Skip version (2), copy server_random (32)
    var i = 2
    var ri = 0
    while ri < 32:
        let v = *(data + (i + ri) as u64)
        conn.server_random[ri] = v
        ri = ri + 1
    i = i + 32

    // Session ID
    let sid_len_v = *(data + i as u64)
    let sid_len = sid_len_v as i32
    i = i + 1 + sid_len

    // Cipher suite (2 bytes)
    if i + 2 > len:
        return -1
    let cs_hi = *(data + i as u64)
    let cs_lo = *(data + (i + 1) as u64)
    conn.cipher_suite = ((cs_hi as u16) << 8u16) | (cs_lo as u16)
    i = i + 2

    // Compression (1 byte, must be 0)
    i = i + 1

    0

// What tls_recv_server_handshake extracts for peer verification (#1061):
// the presented chain as slices of cert_buf, the parsed leaf, and the
// ServerKeyExchange parameters and signature as received.
type TlsPeerEvidence {
    chain_starts: [i32; 8],
    chain_lens: [i32; 8],
    chain_count: i32,
    leaf_start: i32,
    leaf: X509Cert,
    ske_params: [u8; 101],
    ske_params_len: i32,
    // The ECDHE named group the server chose: 23 (P-256) or 24 (P-384).
    ske_curve: i32,
    ske_hash_alg: i32,
    ske_sig_alg: i32,
    ske_sig: [u8; 528],
    ske_sig_len: i32,
}

fn TlsPeerEvidence.new() -> TlsPeerEvidence:
    TlsPeerEvidence {
        chain_starts: [0; 8], chain_lens: [0; 8], chain_count: 0,
        leaf_start: 0, leaf: X509Cert.new(),
        ske_params: [0u8; 101], ske_params_len: 0, ske_curve: 0,
        ske_hash_alg: 0, ske_sig_alg: 0,
        ske_sig: [0u8; 528], ske_sig_len: 0,
    }

// Receive and process all server handshake messages until ServerHelloDone.
// Extracts certificate chain and ECDHE parameters.
// Returns 0 on success, -1 on error.
unsafe fn tls_recv_server_handshake(
    conn: *mut TlsConn,
    server_pub_x: *mut u8, server_pub_y: *mut u8,
    server_ecdh_pub: *mut u8,
    cert_buf: *mut u8, cert_len: *mut i32,
    evidence: *mut TlsPeerEvidence,
) -> i32:
    var done = 0
    while done == 0:
        var ct: u8 = 0u8
        var rec_buf: [u8; 16640] = [0u8; 16640]
        let rec_len = tls_recv_record(conn.fd, &raw mut ct as *mut u8, &raw mut rec_buf[0] as *mut u8, 16640)
        if rec_len < 0:
            return -1
        if ct != TLS_HANDSHAKE:
            return -1

        // Parse handshake messages (may be multiple per record)
        var rp = 0
        while rp < rec_len:
            if rp + 4 > rec_len:
                return -1
            let hs_type = rec_buf[rp]
            let hs_len_b1 = rec_buf[rp + 1] as u32
            let hs_len_b2 = rec_buf[rp + 2] as u32
            let hs_len_b3 = rec_buf[rp + 3] as u32
            let hs_len = ((hs_len_b1 << 16u32) | (hs_len_b2 << 8u32) | hs_len_b3) as i32
            // #1062: the length is the server's word; the message must lie
            // inside the record received, or the hash and every parse below
            // read past the buffer. A message that does not fits nothing.
            if hs_len > rec_len - rp - 4:
                return -1

            // Update handshake hash (type + length + body)
            tls_hs_hash_update(conn, &rec_buf[rp] as *const u8, 4 + hs_len)

            let body = &rec_buf[rp + 4] as *const u8

            if hs_type == HS_SERVER_HELLO:
                let r = tls_parse_server_hello(conn, body, hs_len)
                if r < 0:
                    return -1

            if hs_type == HS_CERTIFICATE:
                // Copy the whole Certificate message; a chain that does
                // not fit is refused, never truncated into a partial one.
                if hs_len > 16384 or hs_len < 3:
                    return -1
                var ci = 0
                while ci < hs_len:
                    let bv = *(body + ci as u64)
                    *(cert_buf + ci as u64) = bv
                    ci = ci + 1
                *(cert_len + 0u64) = ci

                // Walk the certificate list: total length (3), then per
                // certificate a 3-byte length and the DER.
                let list_len = (((*(body + 0u64) as u32) << 16u32) | ((*(body + 1u64) as u32) << 8u32) | (*(body + 2u64) as u32)) as i32
                if list_len != hs_len - 3:
                    return -1
                var cp = 3
                var count = 0
                while cp < hs_len:
                    if cp + 3 > hs_len or count >= 8:
                        return -1
                    let one_len = (((*(body + cp as u64) as u32) << 16u32) | ((*(body + (cp + 1) as u64) as u32) << 8u32) | (*(body + (cp + 2) as u64) as u32)) as i32
                    if one_len <= 0 or one_len > hs_len - cp - 3:
                        return -1
                    evidence.chain_starts[count] = cp + 3
                    evidence.chain_lens[count] = one_len
                    count = count + 1
                    cp = cp + 3 + one_len
                if count == 0:
                    return -1
                evidence.chain_count = count
                evidence.leaf_start = evidence.chain_starts[0]

                // Parse the leaf for its public key and for verification.
                let first_cert_data = cert_buf + evidence.leaf_start as u64
                if x509_parse(&raw mut evidence.leaf as *mut X509Cert, first_cert_data, evidence.chain_lens[0]) == 0:
                    return -1
                if evidence.leaf.key_type == 2:
                    let pt_start = evidence.leaf.key_point_start
                    if evidence.leaf.key_point_len == 65:
                        var pi = 0
                        while pi < 32:
                            let vx = *(first_cert_data + (pt_start + 1 + pi) as u64)
                            *(server_pub_x + pi as u64) = vx
                            let vy = *(first_cert_data + (pt_start + 33 + pi) as u64)
                            *(server_pub_y + pi as u64) = vy
                            pi = pi + 1

            if hs_type == HS_SERVER_KEY_EXCHANGE:
                // ECDHE parameters, then the signature over them. Only
                // the named-curve forms ClientHello offered are accepted
                // (P-256, P-384); the parameters and signature are kept
                // verbatim for verification against the leaf key.
                if hs_len < 4 + 2 + 2:
                    return -1
                if *(body + 0u64) != 3u8 or *(body + 1u64) != 0u8:
                    return -1
                let curve_id = *(body + 2u64) as i32
                let pt_len = *(body + 3u64) as i32
                if curve_id == 23:
                    if pt_len != 65:
                        return -1
                else if curve_id == 24:
                    if pt_len != 97:
                        return -1
                else:
                    return -1
                evidence.ske_curve = curve_id
                let params_len = 4 + pt_len
                if hs_len < params_len + 4:
                    return -1
                var pi = 0
                while pi < pt_len:
                    let ev = *(body + (4 + pi) as u64)
                    *(server_ecdh_pub + pi as u64) = ev
                    pi = pi + 1
                pi = 0
                while pi < params_len:
                    evidence.ske_params[pi] = *(body + pi as u64)
                    pi = pi + 1
                evidence.ske_params_len = params_len
                evidence.ske_hash_alg = *(body + params_len as u64) as i32
                evidence.ske_sig_alg = *(body + (params_len + 1) as u64) as i32
                let sig_len = (((*(body + (params_len + 2) as u64) as u32) << 8u32) | (*(body + (params_len + 3) as u64) as u32)) as i32
                if sig_len <= 0 or sig_len > 528 or params_len + 4 + sig_len > hs_len:
                    return -1
                evidence.ske_sig_len = sig_len
                pi = 0
                while pi < sig_len:
                    evidence.ske_sig[pi] = *(body + (params_len + 4 + pi) as u64)
                    pi = pi + 1

            if hs_type == HS_SERVER_HELLO_DONE:
                done = 1

            rp = rp + 4 + hs_len
    0

// Derive keys from pre-master secret.
unsafe fn tls_derive_keys(conn: *mut TlsConn, premaster: *const u8, premaster_len: i32):
    // master_secret = PRF(premaster, "master secret", client_random + server_random)
    var seed: [u8; 64] = [0u8; 64]
    var si = 0
    while si < 32:
        seed[si] = conn.client_random[si]
        seed[32 + si] = conn.server_random[si]
        si = si + 1

    var master_secret: [u8; 48] = [0u8; 48]
    var label_ms: [u8; 13] = [0x6Du8, 0x61u8, 0x73u8, 0x74u8, 0x65u8, 0x72u8, 0x20u8, 0x73u8, 0x65u8, 0x63u8, 0x72u8, 0x65u8, 0x74u8]
    tls_prf_sha256(premaster, premaster_len, &label_ms[0] as *const u8, 13, &seed[0] as *const u8, 64, &raw mut master_secret[0] as *mut u8, 48)

    // key_block = PRF(master_secret, "key expansion", server_random + client_random)
    // Note: seed order is reversed for key expansion
    si = 0
    while si < 32:
        seed[si] = conn.server_random[si]
        seed[32 + si] = conn.client_random[si]
        si = si + 1

    // For AES-128-GCM: client_write_key(16) + server_write_key(16) + client_write_iv(4) + server_write_iv(4) = 40 bytes
    var key_block: [u8; 40] = [0u8; 40]
    var label_ke: [u8; 13] = [0x6Bu8, 0x65u8, 0x79u8, 0x20u8, 0x65u8, 0x78u8, 0x70u8, 0x61u8, 0x6Eu8, 0x73u8, 0x69u8, 0x6Fu8, 0x6Eu8]
    tls_prf_sha256(&master_secret[0] as *const u8, 48, &label_ke[0] as *const u8, 13, &seed[0] as *const u8, 64, &raw mut key_block[0] as *mut u8, 40)

    // Distribute keys
    si = 0
    while si < 16:
        conn.client_write_key[si] = key_block[si]
        conn.server_write_key[si] = key_block[16 + si]
        si = si + 1
    si = 0
    while si < 4:
        conn.client_write_iv[si] = key_block[32 + si]
        conn.server_write_iv[si] = key_block[36 + si]
        si = si + 1

    // Keep the master secret for both Finished verify_data computations.
    si = 0
    while si < 48:
        conn.master_secret[si] = master_secret[si]
        si = si + 1

// Send ClientKeyExchange + ChangeCipherSpec + Finished.
// `curve_id` is the ECDHE group the server chose (23 or 24).
unsafe fn tls_send_client_finish(conn: *mut TlsConn, server_ecdh_pub: *const u8, curve_id: i32) -> i32:
    var width = 32
    if curve_id == 24:
        width = 48
    else if curve_id != 23:
        return -1
    let point_len = 1 + 2 * width

    // Generate ECDHE key pair on the negotiated curve
    var ecdh_priv: [u8; 48] = [0u8; 48]
    fill_random(&raw mut ecdh_priv[0] as *mut u8, width)

    var ecdh_pub: [u8; 97] = [0u8; 97]
    var shared_secret: [u8; 48] = [0u8; 48]
    if width == 48:
        p384_compute_public(&ecdh_priv[0] as *const u8, &raw mut ecdh_pub[0] as *mut u8)
        p384_ecdh(&ecdh_priv[0] as *const u8, server_ecdh_pub, &raw mut shared_secret[0] as *mut u8)
    else:
        p256_compute_public(&ecdh_priv[0] as *const u8, &raw mut ecdh_pub[0] as *mut u8)
        p256_ecdh(&ecdh_priv[0] as *const u8, server_ecdh_pub, &raw mut shared_secret[0] as *mut u8)

    // Send ClientKeyExchange
    var cke: [u8; 102] = [0u8; 102]
    cke[0] = HS_CLIENT_KEY_EXCHANGE
    cke[1] = 0u8
    cke[2] = 0u8
    cke[3] = (1 + point_len) as u8  // length = 1 + point
    cke[4] = point_len as u8  // point length
    var ci = 0
    while ci < point_len:
        cke[5 + ci] = ecdh_pub[ci]
        ci = ci + 1
    let cke_len = 5 + point_len
    tls_hs_hash_update(conn, &cke[0] as *const u8, cke_len)
    let r1 = tls_send_record(conn.fd, TLS_HANDSHAKE, &cke[0] as *const u8, cke_len)
    if r1 < 0:
        return -1

    // Derive keys
    tls_derive_keys(conn, &shared_secret[0] as *const u8, width)

    // Send ChangeCipherSpec
    var ccs: [u8; 1] = [1u8]
    let r2 = tls_send_record(conn.fd, TLS_CHANGE_CIPHER_SPEC, &ccs[0] as *const u8, 1)
    if r2 < 0:
        return -1

    // Activate cipher for sending
    conn.cipher_active = 1

    // Compute Finished verify_data
    // verify_data = PRF(master_secret, "client finished", Hash(handshake_messages))[0..12]
    var hs_hash: [u8; 32] = [0u8; 32]
    tls_hs_hash_current(conn, &raw mut hs_hash[0] as *mut u8)

    var verify_data: [u8; 12] = [0u8; 12]
    var label_cf: [u8; 15] = [0x63u8, 0x6Cu8, 0x69u8, 0x65u8, 0x6Eu8, 0x74u8, 0x20u8, 0x66u8, 0x69u8, 0x6Eu8, 0x69u8, 0x73u8, 0x68u8, 0x65u8, 0x64u8]
    tls_prf_sha256(&conn.master_secret[0] as *const u8, 48, &label_cf[0] as *const u8, 15, &hs_hash[0] as *const u8, 32, &raw mut verify_data[0] as *mut u8, 12)

    // Build Finished message: type(1) + length(3) + verify_data(12) = 16
    var fin: [u8; 16] = [0u8; 16]
    fin[0] = HS_FINISHED
    fin[1] = 0u8
    fin[2] = 0u8
    fin[3] = 12u8
    ci = 0
    while ci < 12:
        fin[4 + ci] = verify_data[ci]
        ci = ci + 1

    // Update hash BEFORE encrypting (Finished is hashed as plaintext)
    tls_hs_hash_update(conn, &fin[0] as *const u8, 16)

    // Send encrypted Finished
    tls_send_encrypted(conn, TLS_HANDSHAKE, &fin[0] as *const u8, 16)

// Receive server's ChangeCipherSpec and Finished, verifying the
// Finished verify_data against the handshake transcript (#1061): a
// peer that cannot produce it does not hold the master secret for the
// handshake as exchanged. A NewSessionTicket may precede Finished.
unsafe fn tls_recv_server_finish(conn: *mut TlsConn) -> i32:
    // Receive ChangeCipherSpec
    var ct: u8 = 0u8
    var rec_buf: [u8; 16640] = [0u8; 16640]
    var rec_len = tls_recv_record(conn.fd, &raw mut ct as *mut u8, &raw mut rec_buf[0] as *mut u8, 16640)
    if rec_len < 0 or ct != TLS_CHANGE_CIPHER_SPEC:
        return -1

    var plain: [u8; 16640] = [0u8; 16640]
    while true:
        rec_len = tls_recv_record(conn.fd, &raw mut ct as *mut u8, &raw mut rec_buf[0] as *mut u8, 16640)
        if rec_len < 0 or ct != TLS_HANDSHAKE:
            return -1
        let plain_len = tls_decrypt_record(conn, ct, &rec_buf[0] as *const u8, rec_len, &raw mut plain[0] as *mut u8)
        if plain_len < 4:
            return -1
        if plain[0] == HS_NEW_SESSION_TICKET:
            tls_hs_hash_update(conn, &plain[0] as *const u8, plain_len)
            continue
        if plain[0] != HS_FINISHED or plain_len != 16:
            return -1
        if plain[1] != 0u8 or plain[2] != 0u8 or plain[3] != 12u8:
            return -1
        var hs_hash: [u8; 32] = [0u8; 32]
        tls_hs_hash_current(conn, &raw mut hs_hash[0] as *mut u8)
        var expected: [u8; 12] = [0u8; 12]
        var label_sf: [u8; 15] = [0x73u8, 0x65u8, 0x72u8, 0x76u8, 0x65u8, 0x72u8, 0x20u8, 0x66u8, 0x69u8, 0x6Eu8, 0x69u8, 0x73u8, 0x68u8, 0x65u8, 0x64u8]
        tls_prf_sha256(&conn.master_secret[0] as *const u8, 48, &label_sf[0] as *const u8, 15, &hs_hash[0] as *const u8, 32, &raw mut expected[0] as *mut u8, 12)
        var diff: u32 = 0
        var vi = 0
        while vi < 12:
            diff = diff | ((expected[vi] ^ plain[4 + vi]) as u32)
            vi = vi + 1
        if diff != 0:
            return -1
        return 0
    0

// ── Peer verification (#1061) ──────────────────────────────────────

// The OS trust store as PEM text, read in With from the platform's
// bundle file; on Windows the runtime enumerates the ROOT store to
// DER directly (tls_load_windows_roots). Empty means no store found.
// SSL_CERT_FILE, when set, names the bundle instead — the convention
// curl, OpenSSL and Go share. A set-but-unreadable override yields no
// roots and the peer is refused; it never falls back silently.
fn tls_roots_override_path() -> str:
    env("SSL_CERT_FILE")

fn tls_system_roots_pem() -> str:
    let os = with_sysinfo_os()
    if os == "Macos":
        return read_file("/etc/ssl/cert.pem") ?? ""
    if os == "Linux":
        let debian = read_file("/etc/ssl/certs/ca-certificates.crt") ?? ""
        if debian.len() > 0:
            return debian
        let rhel = read_file("/etc/pki/tls/certs/ca-bundle.crt") ?? ""
        if rhel.len() > 0:
            return rhel
        return read_file("/etc/ssl/cert.pem") ?? ""
    ""

// Verify the peer: chain to the OS trust store, hostname, and the
// ServerKeyExchange signature under the leaf key. 0 on success.
unsafe fn tls_verify_peer(
    conn: *mut TlsConn,
    hostname: *const u8, hostname_len: i32,
    cert_buf: *const u8,
    evidence: *mut TlsPeerEvidence,
) -> i32:
    if evidence.chain_count <= 0 or evidence.ske_params_len <= 0 or evidence.ske_sig_len <= 0:
        return -1
    let roots_buf = with_alloc(1048576)
    var roots_starts: [i32; 512] = [0; 512]
    var roots_lens: [i32; 512] = [0; 512]
    var roots_count = -1
    let override_path = tls_roots_override_path()
    if override_path.len() == 0 and with_sysinfo_os() == "Windows":
        roots_count = with_tls_load_windows_roots(roots_buf, 1048576, &raw mut roots_starts[0] as *mut i32, &raw mut roots_lens[0] as *mut i32, 512)
    else:
        let pem = if override_path.len() > 0: (read_file(override_path) ?? "") else: tls_system_roots_pem()
        if pem.len() > 0 and pem.len() <= 4194304:
            let pem_bytes = str_copy_bytes(pem)
            roots_count = x509_pem_parse_certs(pem_bytes, pem.len(), roots_buf, 1048576, &raw mut roots_starts[0] as *mut i32, &raw mut roots_lens[0] as *mut i32, 512)
            str_free_bytes(pem_bytes)
    var ok = 0
    if roots_count > 0:
        if x509_verify_chain_at(cert_buf, &evidence.chain_starts[0] as *const i32, &evidence.chain_lens[0] as *const i32, evidence.chain_count, roots_buf, &roots_starts[0] as *const i32, &roots_lens[0] as *const i32, roots_count, with_time_now()) != 0:
            let leaf_buf = cert_buf + evidence.leaf_start as u64
            if x509_verify_hostname(leaf_buf, &evidence.leaf as *const X509Cert, hostname, hostname_len) != 0:
                ok = 1
    with_free(roots_buf)
    if ok == 0:
        return -1

    // ServerKeyExchange signature over client_random | server_random | params.
    // Only the hashes ClientHello offered verify (4=SHA-256, 5=SHA-384,
    // 6=SHA-512); anything else is a refusal.
    let hash_alg = evidence.ske_hash_alg
    if hash_alg != 4 and hash_alg != 5 and hash_alg != 6:
        return -1
    var signed: [u8; 165] = [0u8; 165]
    var si = 0
    while si < 32:
        signed[si] = conn.client_random[si]
        signed[32 + si] = conn.server_random[si]
        si = si + 1
    si = 0
    while si < evidence.ske_params_len:
        signed[64 + si] = evidence.ske_params[si]
        si = si + 1
    var digest: [u8; 64] = [0u8; 64]
    let signed_len = 64 + evidence.ske_params_len
    var digest_len = 32
    if hash_alg == 4:
        sha256_hash(&signed[0] as *const u8, signed_len, &raw mut digest[0] as *mut u8)
    else if hash_alg == 5:
        sha384_hash(&signed[0] as *const u8, signed_len, &raw mut digest[0] as *mut u8)
        digest_len = 48
    else:
        sha512_hash(&signed[0] as *const u8, signed_len, &raw mut digest[0] as *mut u8)
        digest_len = 64
    let leaf = &evidence.leaf as *const X509Cert
    let leaf_buf2 = cert_buf + evidence.leaf_start as u64
    if conn.cipher_suite == SUITE_ECDHE_RSA_AES128_GCM:
        if evidence.ske_sig_alg != 1 or leaf.key_type != 1:
            return -1
        return if rsa_pkcs1_verify(leaf_buf2 + leaf.key_n_start as u64, leaf.key_n_len, leaf_buf2 + leaf.key_e_start as u64, leaf.key_e_len, &evidence.ske_sig[0] as *const u8, evidence.ske_sig_len, &digest[0] as *const u8, digest_len) != 0: 0 else: -1
    if conn.cipher_suite == SUITE_ECDHE_ECDSA_AES128_GCM:
        if evidence.ske_sig_alg != 3 or leaf.key_type != 2:
            return -1
        return if x509_ecdsa_verify_der_bytes(leaf_buf2 + leaf.key_point_start as u64, leaf.key_point_len, leaf.key_curve, &evidence.ske_sig[0] as *const u8, evidence.ske_sig_len, &digest[0] as *const u8, digest_len) != 0: 0 else: -1
    -1

// ── Public API: TLS connect ────────────────────────────────────────

// Perform TLS 1.2 handshake on an established TCP connection.
// Returns 0 on success, -1 on error.
unsafe fn tls_handshake(conn: *mut TlsConn, hostname: &str) -> i32:
    let hl = hostname.len() as i32

    // Send ClientHello
    let r1 = unsafe:
        let host_bytes = str_copy_bytes(hostname)
        let n = tls_send_client_hello(conn, host_bytes as *const u8, hl)
        str_free_bytes(host_bytes)
        n
    if r1 < 0:
        return -1

    // Receive server handshake messages
    var server_pub_x: [u8; 32] = [0u8; 32]
    var server_pub_y: [u8; 32] = [0u8; 32]
    var server_ecdh_pub: [u8; 97] = [0u8; 97]
    var cert_buf: [u8; 16384] = [0u8; 16384]
    var cert_len: i32 = 0
    var evidence = TlsPeerEvidence.new()
    let r2 = tls_recv_server_handshake(
        conn,
        &raw mut server_pub_x[0] as *mut u8,
        &raw mut server_pub_y[0] as *mut u8,
        &raw mut server_ecdh_pub[0] as *mut u8,
        &raw mut cert_buf[0] as *mut u8,
        &raw mut cert_len as *mut i32,
        &raw mut evidence as *mut TlsPeerEvidence,
    )
    if r2 < 0:
        return -1

    // Authenticate the peer before sending anything under the new keys:
    // chain to the OS trust store, hostname, SKE signature (#1061).
    let host_bytes2 = str_copy_bytes(hostname)
    let rv = tls_verify_peer(conn, host_bytes2 as *const u8, hl, &cert_buf[0] as *const u8, &raw mut evidence as *mut TlsPeerEvidence)
    str_free_bytes(host_bytes2)
    if rv < 0:
        return -1

    // Send ClientKeyExchange + ChangeCipherSpec + Finished
    let r3 = tls_send_client_finish(conn, &server_ecdh_pub[0] as *const u8, evidence.ske_curve)
    if r3 < 0:
        return -1

    // Receive server's ChangeCipherSpec + Finished
    let r4 = tls_recv_server_finish(conn)
    if r4 < 0:
        return -1

    0

// Connect to a host via TLS, returning a TlsConn ready for data transfer.
// Returns a TlsConn with fd >= 0 on success, fd = -1 on error.
fn tls_connect(hostname: &str, port: i32) -> TlsConn: tls_connect_timeout(hostname, port, 0, 0)

// tls_connect with a bound on the TCP connect (`connect_ms`) and on every
// later wait for the peer, the handshake included (`idle_ms`); 0 is no bound.
fn tls_connect_timeout(hostname: &str, port: i32, connect_ms: i32, idle_ms: i32) -> TlsConn:
    let fd = if connect_ms > 0: tcp_connect_timeout(hostname, port, connect_ms) else: tcp_connect(hostname, port)
    if fd < 0:
        return TlsConn.new(-1)
    if connect_ms > 0 or idle_ms > 0:
        let _ = set_timeout(fd, idle_ms)
    var conn = TlsConn.new(fd)
    let r = unsafe { tls_handshake(&raw mut conn as *mut TlsConn, hostname) }
    if r < 0:
        socket_close(fd)
        return TlsConn.new(-1)
    conn
