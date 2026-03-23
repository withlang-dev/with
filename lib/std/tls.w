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
    let sp = &mut hdr_s as *mut u8
    *(sp as *mut u64) = hp as u64
    *((sp + 8u64) as *mut i64) = 5i64
    let sent1 = with_net_send(fd, hdr_s)
    if sent1 < 0i64:
        return -1

    // Send data
    var data_s: str = ""
    let dp = &mut data_s as *mut u8
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
    let rec_len = ((hdr[3] as i32) << 8) | (hdr[4] as i32)
    if rec_len > buf_cap:
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
    hmac_sha256(secret, secret_len, &seed_full[0] as *const u8, seed_full_len, &mut a[0] as *mut u8)

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
        hmac_sha256(secret, secret_len, &concat[0] as *const u8, 32 + seed_full_len, &mut p_block[0] as *mut u8)

        // Copy to output
        j = 0
        while j < 32 and produced + j < output_len:
            *(output + (produced + j) as u64) = p_block[j]
            j = j + 1
        produced = produced + j

        // A(i+1) = HMAC(secret, A(i))
        var a_next: [u8; 32] = [0u8; 32]
        hmac_sha256(secret, secret_len, &a[0] as *const u8, 32, &mut a_next[0] as *mut u8)
        j = 0
        while j < 32:
            a[j] = a_next[j]
            j = j + 1

// ── TLS connection state ───────────────────────────────────────────

type TlsConn = {
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
    let cp = &mut ctx as *mut Sha256
    sha256_update(cp, data, len)
    conn.hs_hash_ctx = ctx

// Get current handshake hash (without finalizing the running context)
unsafe fn tls_hs_hash_current(conn: *mut TlsConn, out: *mut u8):
    // Copy the context to avoid modifying the running one
    var ctx = conn.hs_hash_ctx
    let cp = &mut ctx as *mut Sha256
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
    u64_to_be(&mut nonce[4] as *mut u8, 0, conn.client_seq)

    // Encrypt
    var ct: [u8; 16640] = [0u8; 16640]  // max TLS record + overhead
    var tag: [u8; 16] = [0u8; 16]
    var aes_ctx = AesGcm.new(&conn.client_write_key[0] as *const u8, &nonce[0] as *const u8, 12)

    // AAD: seq(8) + type(1) + version(2) + length(2)
    var aad: [u8; 13] = [0u8; 13]
    u64_to_be(&mut aad[0] as *mut u8, 0, conn.client_seq)
    aad[8] = content_type
    aad[9] = 0x03u8
    aad[10] = 0x03u8
    aad[11] = (data_len >> 8) as u8
    aad[12] = (data_len & 0xFF) as u8
    AesGcm.aad(&mut aes_ctx as *mut AesGcm, &aad[0] as *const u8, 13)

    AesGcm.encrypt(&mut aes_ctx as *mut AesGcm, data, &mut ct[8] as *mut u8, data_len)
    AesGcm.tag(&mut aes_ctx as *mut AesGcm, &mut tag[0] as *mut u8)

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
    u64_to_be(&mut aad[0] as *mut u8, 0, conn.server_seq)
    aad[8] = content_type
    aad[9] = 0x03u8
    aad[10] = 0x03u8
    aad[11] = (ct_len >> 8) as u8
    aad[12] = (ct_len & 0xFF) as u8

    // Decrypt (GCM decrypt = encrypt with same keystream)
    var aes_ctx = AesGcm.new(&conn.server_write_key[0] as *const u8, &nonce[0] as *const u8, 12)
    AesGcm.aad(&mut aes_ctx as *mut AesGcm, &aad[0] as *const u8, 13)
    AesGcm.encrypt(&mut aes_ctx as *mut AesGcm, ct_start, plain, ct_len)

    // Verify tag
    var computed_tag: [u8; 16] = [0u8; 16]
    AesGcm.tag(&mut aes_ctx as *mut AesGcm, &mut computed_tag[0] as *mut u8)
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
    let rec_len = tls_recv_record(conn.fd, &mut ct as *mut u8, &mut rec_buf[0] as *mut u8, 16640)
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
