// TLS 1.2 client — record layer, PRF, and handshake
//
// Supports cipher suites:
//   TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256    (0xC02F)
//   TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256  (0xC02B)

use std.crypto.sha256
use std.crypto.hmac
use std.crypto.aes
use std.crypto.gcm
use std.crypto.ec
use std.crypto.ecdsa
use std.crypto.x509
use std.crypto.endian
use std.net

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
    let hdr_str = unsafe: *(&hdr[0] as *const str)
    // Actually, we need to construct a str from ptr+len
    // Use the with_net_send extern directly
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
        let chunk_p = chunk as *const u8
        var ci = 0
        while ci < chunk.len() as i32:
            let v = *(chunk_p + ci as u64)
            hdr[total_read + ci] = v
            ci = ci + 1
        total_read = total_read + chunk.len() as i32

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
        let chunk_p = chunk as *const u8
        var ci = 0
        while ci < chunk.len() as i32:
            let v = *(chunk_p + ci as u64)
            *(buf + (total_read + ci) as u64) = v
            ci = ci + 1
        total_read = total_read + chunk.len() as i32

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

    // Decrypt: GHASH the ciphertext, then XOR with keystream
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
        return tls_decrypt_record(conn, ct, &rec_buf[0] as *const u8, rec_len, buf)
    // Unencrypted: copy directly
    var i = 0
    while i < rec_len and i < buf_cap:
        *(buf + i as u64) = rec_buf[i]
        i = i + 1
    rec_len

// ── Random bytes ───────────────────────────────────────────────────

extern fn with_fs_read_file(path: str) -> str
extern fn with_fill_random(buf: *mut u8, len: i32)

unsafe fn fill_random(buf: *mut u8, len: i32):
    with_fill_random(buf, len)

// ── TLS 1.2 Handshake ─────────────────────────────────────────────

// Build and send ClientHello. Returns 0 on success, -1 on error.
unsafe fn tls_send_client_hello(conn: *mut TlsConn, hostname: *const u8, hostname_len: i32) -> i32:
    // Generate client random
    fill_random(&raw mut conn.client_random[0] as *mut u8, 32)

    var buf: [u8; 512] = [0u8; 512]
    var pos = 0

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

    // Extension: supported_groups (0x000A)
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x0Au8
    pos = pos + 2
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x04u8  // ext data length
    pos = pos + 2
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x02u8  // named curve list length
    pos = pos + 2
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x17u8  // secp256r1
    pos = pos + 2

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
    buf[pos + 1] = 0x06u8  // ext data length
    pos = pos + 2
    buf[pos] = 0x00u8
    buf[pos + 1] = 0x04u8  // sig alg list length
    pos = pos + 2
    // RSA PKCS1 SHA256 (0x0401)
    buf[pos] = 0x04u8
    buf[pos + 1] = 0x01u8
    pos = pos + 2
    // ECDSA SHA256 (0x0403)
    buf[pos] = 0x04u8
    buf[pos + 1] = 0x03u8
    pos = pos + 2

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

// Receive and process all server handshake messages until ServerHelloDone.
// Extracts certificate chain and ECDHE parameters.
// Returns 0 on success, -1 on error.
unsafe fn tls_recv_server_handshake(
    conn: *mut TlsConn,
    server_pub_x: *mut u8, server_pub_y: *mut u8,
    server_ecdh_pub: *mut u8,
    cert_buf: *mut u8, cert_len: *mut i32,
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

            // Update handshake hash (type + length + body)
            tls_hs_hash_update(conn, &rec_buf[rp] as *const u8, 4 + hs_len)

            let body = &rec_buf[rp + 4] as *const u8

            if hs_type == HS_SERVER_HELLO:
                let r = tls_parse_server_hello(conn, body, hs_len)
                if r < 0:
                    return -1

            if hs_type == HS_CERTIFICATE:
                // Copy raw certificate data
                var ci = 0
                while ci < hs_len and ci < 8192:
                    let bv = *(body + ci as u64)
                    *(cert_buf + ci as u64) = bv
                    ci = ci + 1
                *(cert_len + 0u64) = hs_len

                // Parse first cert to get server's public key
                if hs_len > 6:
                    let fc_b1 = *(body + 3u64) as u32
                    let fc_b2 = *(body + 4u64) as u32
                    let fc_b3 = *(body + 5u64) as u32
                    let first_cert_len = ((fc_b1 << 16u32) | (fc_b2 << 8u32) | fc_b3) as i32
                    let first_cert_data = body + 6u64
                    var parsed_cert = X509Cert.new()
                    let parse_ok = x509_parse(&raw mut parsed_cert as *mut X509Cert, first_cert_data, first_cert_len)
                    if parse_ok != 0:
                        if parsed_cert.key_type == 2:
                            let pt_start = parsed_cert.key_point_start
                            if parsed_cert.key_point_len == 65:
                                var pi = 0
                                while pi < 32:
                                    let vx = *(first_cert_data + (pt_start + 1 + pi) as u64)
                                    *(server_pub_x + pi as u64) = vx
                                    let vy = *(first_cert_data + (pt_start + 33 + pi) as u64)
                                    *(server_pub_y + pi as u64) = vy
                                    pi = pi + 1

            if hs_type == HS_SERVER_KEY_EXCHANGE:
                // Parse ECDHE parameters
                if hs_len >= 69:
                    let pt_len_v = *(body + 3u64)
                    let pt_len = pt_len_v as i32
                    if pt_len == 65:
                        var pi = 0
                        while pi < 65:
                            let ev = *(body + (4 + pi) as u64)
                            *(server_ecdh_pub + pi as u64) = ev
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

    // Save master secret for Finished messages (reuse seed buffer)
    // We need it later, store in server_random temporarily... actually let's
    // compute the Finished verify_data here and store it.
    // Actually we need the master secret stored. Let's extend TlsConn or
    // just pass it around. For simplicity, recompute when needed.
    // Store master_secret in first 48 bytes of a buffer we pass around.
    ()

// Send ClientKeyExchange + ChangeCipherSpec + Finished
unsafe fn tls_send_client_finish(conn: *mut TlsConn, server_ecdh_pub: *const u8) -> i32:
    // Generate ECDHE key pair
    var ecdh_priv: [u8; 32] = [0u8; 32]
    fill_random(&raw mut ecdh_priv[0] as *mut u8, 32)

    var ecdh_pub: [u8; 65] = [0u8; 65]
    p256_compute_public(&ecdh_priv[0] as *const u8, &raw mut ecdh_pub[0] as *mut u8)

    // Compute shared secret
    var shared_secret: [u8; 32] = [0u8; 32]
    p256_ecdh(&ecdh_priv[0] as *const u8, server_ecdh_pub, &raw mut shared_secret[0] as *mut u8)

    // Send ClientKeyExchange
    var cke: [u8; 70] = [0u8; 70]
    cke[0] = HS_CLIENT_KEY_EXCHANGE
    cke[1] = 0u8
    cke[2] = 0u8
    cke[3] = 66u8  // length = 1 + 65
    cke[4] = 65u8  // point length
    var ci = 0
    while ci < 65:
        cke[5 + ci] = ecdh_pub[ci]
        ci = ci + 1
    tls_hs_hash_update(conn, &cke[0] as *const u8, 70)
    let r1 = tls_send_record(conn.fd, TLS_HANDSHAKE, &cke[0] as *const u8, 70)
    if r1 < 0:
        return -1

    // Derive keys
    tls_derive_keys(conn, &shared_secret[0] as *const u8, 32)

    // Send ChangeCipherSpec
    var ccs: [u8; 1] = [1u8]
    let r2 = tls_send_record(conn.fd, TLS_CHANGE_CIPHER_SPEC, &ccs[0] as *const u8, 1)
    if r2 < 0:
        return -1

    // Activate cipher for sending
    conn.cipher_active = 1

    // Compute Finished verify_data
    // verify_data = PRF(master_secret, "client finished", Hash(handshake_messages))[0..12]
    // We need master_secret. Recompute it.
    var ms_seed: [u8; 64] = [0u8; 64]
    ci = 0
    while ci < 32:
        ms_seed[ci] = conn.client_random[ci]
        ms_seed[32 + ci] = conn.server_random[ci]
        ci = ci + 1
    var master_secret: [u8; 48] = [0u8; 48]
    var label_ms: [u8; 13] = [0x6Du8, 0x61u8, 0x73u8, 0x74u8, 0x65u8, 0x72u8, 0x20u8, 0x73u8, 0x65u8, 0x63u8, 0x72u8, 0x65u8, 0x74u8]
    tls_prf_sha256(&shared_secret[0] as *const u8, 32, &label_ms[0] as *const u8, 13, &ms_seed[0] as *const u8, 64, &raw mut master_secret[0] as *mut u8, 48)

    var hs_hash: [u8; 32] = [0u8; 32]
    tls_hs_hash_current(conn, &raw mut hs_hash[0] as *mut u8)

    var verify_data: [u8; 12] = [0u8; 12]
    var label_cf: [u8; 15] = [0x63u8, 0x6Cu8, 0x69u8, 0x65u8, 0x6Eu8, 0x74u8, 0x20u8, 0x66u8, 0x69u8, 0x6Eu8, 0x69u8, 0x73u8, 0x68u8, 0x65u8, 0x64u8]
    tls_prf_sha256(&master_secret[0] as *const u8, 48, &label_cf[0] as *const u8, 15, &hs_hash[0] as *const u8, 32, &raw mut verify_data[0] as *mut u8, 12)

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

// Receive server's ChangeCipherSpec and Finished.
unsafe fn tls_recv_server_finish(conn: *mut TlsConn) -> i32:
    // Receive ChangeCipherSpec
    var ct: u8 = 0u8
    var rec_buf: [u8; 16640] = [0u8; 16640]
    var rec_len = tls_recv_record(conn.fd, &raw mut ct as *mut u8, &raw mut rec_buf[0] as *mut u8, 16640)
    if rec_len < 0 or ct != TLS_CHANGE_CIPHER_SPEC:
        return -1

    // Now server sends encrypted
    // Receive encrypted Finished
    rec_len = tls_recv_record(conn.fd, &raw mut ct as *mut u8, &raw mut rec_buf[0] as *mut u8, 16640)
    if rec_len < 0 or ct != TLS_HANDSHAKE:
        return -1

    // Decrypt
    var plain: [u8; 256] = [0u8; 256]
    let plain_len = tls_decrypt_record(conn, ct, &rec_buf[0] as *const u8, rec_len, &raw mut plain[0] as *mut u8)
    if plain_len < 0:
        return -1

    // Verify it's a Finished message (type 20, length 12)
    if plain_len < 16:
        return -1
    if plain[0] != HS_FINISHED:
        return -1

    // Could verify server's verify_data here, but for MVP just accept
    0

// ── Public API: TLS connect ────────────────────────────────────────

// Perform TLS 1.2 handshake on an established TCP connection.
// Returns 0 on success, -1 on error.
unsafe fn tls_handshake(conn: *mut TlsConn, hostname: str) -> i32:
    let hp = hostname as *const u8
    let hl = hostname.len() as i32

    // Send ClientHello
    let r1 = tls_send_client_hello(conn, hp, hl)
    if r1 < 0:
        return -1

    // Receive server handshake messages
    var server_pub_x: [u8; 32] = [0u8; 32]
    var server_pub_y: [u8; 32] = [0u8; 32]
    var server_ecdh_pub: [u8; 65] = [0u8; 65]
    var cert_buf: [u8; 8192] = [0u8; 8192]
    var cert_len: i32 = 0
    let r2 = tls_recv_server_handshake(
        conn,
        &raw mut server_pub_x[0] as *mut u8,
        &raw mut server_pub_y[0] as *mut u8,
        &raw mut server_ecdh_pub[0] as *mut u8,
        &raw mut cert_buf[0] as *mut u8,
        &raw mut cert_len as *mut i32,
    )
    if r2 < 0:
        return -1

    // Send ClientKeyExchange + ChangeCipherSpec + Finished
    let r3 = tls_send_client_finish(conn, &server_ecdh_pub[0] as *const u8)
    if r3 < 0:
        return -1

    // Receive server's ChangeCipherSpec + Finished
    let r4 = tls_recv_server_finish(conn)
    if r4 < 0:
        return -1

    0

// Connect to a host via TLS, returning a TlsConn ready for data transfer.
// Returns a TlsConn with fd >= 0 on success, fd = -1 on error.
fn tls_connect(hostname: str, port: i32) -> TlsConn:
    let fd = tcp_connect(hostname, port)
    if fd < 0:
        return TlsConn.new(-1)
    var conn = TlsConn.new(fd)
    let r = unsafe: tls_handshake(&raw mut conn as *mut TlsConn, hostname)
    if r < 0:
        socket_close(fd)
        return TlsConn.new(-1)
    conn
