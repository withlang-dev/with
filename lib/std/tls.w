// TLS 1.2 client — record layer, PRF, and handshake
//
// Supports cipher suites:
//   TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256    (0xC02F)
//   TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256  (0xC02B)
//   TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256    (0xCCA8, RFC 7905)
//   TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256  (0xCCA9, RFC 7905)

use std.crypto.sha256
use std.crypto.sha512
use std.crypto.hmac
use std.crypto.aes
use std.crypto.gcm
use std.crypto.chacha20poly1305
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
let SUITE_ECDHE_RSA_CHACHA20: u16 = 0xCCA8u16
let SUITE_ECDHE_ECDSA_CHACHA20: u16 = 0xCCA9u16

fn tls_suite_is_chacha(suite: u16): suite == SUITE_ECDHE_RSA_CHACHA20 or suite == SUITE_ECDHE_ECDSA_CHACHA20
fn tls_suite_is_rsa(suite: u16): suite == SUITE_ECDHE_RSA_AES128_GCM or suite == SUITE_ECDHE_RSA_CHACHA20
fn tls_suite_is_ecdsa(suite: u16): suite == SUITE_ECDHE_ECDSA_AES128_GCM or suite == SUITE_ECDHE_ECDSA_CHACHA20

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
// WITH_TLS_TRACE=1 narrates the handshake and every record on stderr: which
// stage a connection reaches before it stalls (#2922: the windows-aarch64
// release runner connected and read no response; no other platform did).
var tls_trace_state: i32 = 0

fn tls_trace_on() -> bool:
    if tls_trace_state == 0: tls_trace_state = if env("WITH_TLS_TRACE").len() > 0: 1 else: 2
    tls_trace_state == 1

fn tls_trace(message: &str):
    if tls_trace_on(): eprint("tls: " ++ message)

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
    tls_trace(f"record type {hdr[0]} version {hdr[1]}.{hdr[2]} length {rec_len}")
    if rec_len > buf_cap or rec_len < 0:
        tls_trace(f"record length {rec_len} exceeds the buffer ({buf_cap})")
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
    // AES-128-GCM uses 16 bytes of a key and 4 of an IV; ChaCha20-Poly1305
    // all 32 and 12.
    client_write_key: [u8; 32],
    server_write_key: [u8; 32],
    client_write_iv: [u8; 12],
    server_write_iv: [u8; 12],
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
        client_write_key: [0u8; 32],
        server_write_key: [0u8; 32],
        client_write_iv: [0u8; 12],
        server_write_iv: [0u8; 12],
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

unsafe fn tls_bytes(p: *const u8, len: i32) -> List[u8]:
    let out = []
    for i in 0..len: out.push(*(p + i as u64))
    out

// The additional data of a record (RFC 5246 §6.2.3.3): seq(8) + type(1) +
// version(2) + plaintext length(2).
fn tls_record_aad(seq: u64, content_type: u8, len: i32) -> List[u8]:
    var aad: [u8; 13] = [0u8; 13]
    u64_to_be(&raw mut aad[0] as *mut u8, 0, seq)
    aad[8] = content_type
    aad[9] = 0x03u8
    aad[10] = 0x03u8
    aad[11] = (len >> 8) as u8
    aad[12] = (len & 0xFF) as u8
    unsafe { tls_bytes(&aad[0] as *const u8, 13) }

// RFC 7905 §2: the nonce is the 12-byte write IV with the record's sequence
// number, big-endian, XORed into its last 8 bytes. Nothing of it is sent.
unsafe fn tls_chacha_nonce(iv: *const u8, seq: u64) -> List[u8]:
    var seq_be: [u8; 8] = [0u8; 8]
    u64_to_be(&raw mut seq_be[0] as *mut u8, 0, seq)
    let nonce = []
    for i in 0..12: nonce.push(if i < 4: *(iv + i as u64) else: *(iv + i as u64) ^ seq_be[i - 4])
    nonce

// A ChaCha20-Poly1305 record: the ciphertext, then its tag.
unsafe fn tls_send_chacha(conn: *mut TlsConn, content_type: u8, data: *const u8, data_len: i32) -> i32:
    let key = tls_bytes(&conn.client_write_key[0] as *const u8, 32)
    let nonce = tls_chacha_nonce(&conn.client_write_iv[0] as *const u8, conn.client_seq)
    let sealed = chacha20_poly1305_seal(&key, &nonce, &tls_record_aad(conn.client_seq, content_type, data_len), tls_bytes(data, data_len))
    conn.client_seq = conn.client_seq + 1u64
    if sealed.is_err(): return -1
    let record = sealed.unwrap()
    tls_send_record(conn.fd, content_type, record.ptr as *const u8, data_len + 16)

// The plaintext length of a received ChaCha20-Poly1305 record, or -1 when
// its tag does not match.
unsafe fn tls_decrypt_chacha(conn: *mut TlsConn, content_type: u8, enc_data: *const u8, enc_len: i32, plain: *mut u8) -> i32:
    if enc_len < 16: return -1
    let key = tls_bytes(&conn.server_write_key[0] as *const u8, 32)
    let nonce = tls_chacha_nonce(&conn.server_write_iv[0] as *const u8, conn.server_seq)
    let opened = chacha20_poly1305_open(&key, &nonce, &tls_record_aad(conn.server_seq, content_type, enc_len - 16), tls_bytes(enc_data, enc_len))
    conn.server_seq = conn.server_seq + 1u64
    if opened.is_err(): return -1
    let text = opened.unwrap()
    for i in 0..enc_len - 16: *(plain + i as u64) = text[i]
    enc_len - 16

// What a protected record carries beyond its plaintext: the tag, and for
// AES-GCM the explicit nonce.
unsafe fn tls_record_overhead(conn: *mut TlsConn): if tls_suite_is_chacha(conn.cipher_suite): 16 else: 24

// Send an encrypted TLS record under the negotiated suite
unsafe fn tls_send_encrypted(conn: *mut TlsConn, content_type: u8, data: *const u8, data_len: i32) -> i32:
    if tls_suite_is_chacha(conn.cipher_suite): return tls_send_chacha(conn, content_type, data, data_len)
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

// Decrypt a received encrypted record under the negotiated suite
// Returns plaintext length or -1 on error/auth failure.
unsafe fn tls_decrypt_record(conn: *mut TlsConn, content_type: u8, enc_data: *const u8, enc_len: i32, plain: *mut u8) -> i32:
    if tls_suite_is_chacha(conn.cipher_suite): return tls_decrypt_chacha(conn, content_type, enc_data, enc_len, plain)
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
        if rec_len - tls_record_overhead(conn) > buf_cap:
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

    // Cipher suites (4 suites = 8 bytes + 2 length), AES-GCM preferred
    buf[pos] = 0u8
    buf[pos + 1] = 8u8  // 8 bytes of cipher suites
    pos = pos + 2
    // TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (0xC02F)
    buf[pos] = 0xC0u8
    buf[pos + 1] = 0x2Fu8
    pos = pos + 2
    // TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 (0xC02B)
    buf[pos] = 0xC0u8
    buf[pos + 1] = 0x2Bu8
    pos = pos + 2
    // TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 (0xCCA8)
    buf[pos] = 0xCCu8
    buf[pos + 1] = 0xA8u8
    pos = pos + 2
    // TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256 (0xCCA9)
    buf[pos] = 0xCCu8
    buf[pos + 1] = 0xA9u8
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
    // A suite this client did not offer is not one it can speak.
    if not tls_suite_is_rsa(conn.cipher_suite) and not tls_suite_is_ecdsa(conn.cipher_suite):
        tls_trace(f"the server chose suite {conn.cipher_suite as i32}, which was not offered")
        return -1
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
                if x509_parse(&raw mut evidence.leaf as *mut X509Cert, first_cert_data, evidence.chain_lens[0]) == false:
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

    // client_write_key + server_write_key + client_write_iv + server_write_iv:
    // 16, 16, 4, 4 for AES-128-GCM (40 bytes); 32, 32, 12, 12 for
    // ChaCha20-Poly1305 (88). The PRF's output is a stream, so the shorter
    // block is the longer one's first bytes.
    var key_block: [u8; 88] = [0u8; 88]
    var label_ke: [u8; 13] = [0x6Bu8, 0x65u8, 0x79u8, 0x20u8, 0x65u8, 0x78u8, 0x70u8, 0x61u8, 0x6Eu8, 0x73u8, 0x69u8, 0x6Fu8, 0x6Eu8]
    tls_prf_sha256(&master_secret[0] as *const u8, 48, &label_ke[0] as *const u8, 13, &seed[0] as *const u8, 64, &raw mut key_block[0] as *mut u8, 88)

    // Distribute keys
    let key_len = if tls_suite_is_chacha(conn.cipher_suite): 32 else: 16
    let iv_len = if tls_suite_is_chacha(conn.cipher_suite): 12 else: 4
    for k in 0..key_len:
        conn.client_write_key[k] = key_block[k]
        conn.server_write_key[k] = key_block[key_len + k]
    for k in 0..iv_len:
        conn.client_write_iv[k] = key_block[2 * key_len + k]
        conn.server_write_iv[k] = key_block[2 * key_len + iv_len + k]

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

// The trust store this verifier can hold: 4096 roots in 8 MiB of DER (a
// root is ~1.5 KB; a Windows release runner's store passed 512), from a
// PEM bundle of up to 16 MiB.
const TLS_ROOTS_MAX = 4096
const TLS_ROOTS_BYTES = 8388608
const TLS_ROOTS_PEM_BYTES = 16777216

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
    // Room for the whole store. Windows's ROOT view (its own roots, the
    // machine's and the auto-updated AuthRoot) exceeded 512 certificates on
    // a release runner; the loader stopped there and the root of every
    // chain past the cut was "untrusted" (#2922: zlib.net and GitHub's
    // asset host refused, github.com verified). A DER root is ~1.5 KB.
    let roots_buf = with_alloc(TLS_ROOTS_BYTES)
    var roots_starts: [i32; TLS_ROOTS_MAX] = [0; TLS_ROOTS_MAX]
    var roots_lens: [i32; TLS_ROOTS_MAX] = [0; TLS_ROOTS_MAX]
    let override_path = tls_roots_override_path()
    let windows_store = override_path.len() == 0 and with_sysinfo_os() == "Windows"
    var ok = 0
    // Windows fills its trust store lazily: a root it has not met is fetched
    // the first time CryptoAPI builds a chain through it. A chain the store
    // cannot complete is built once by CryptoAPI, the roots reloaded, and
    // the verdict is this verifier's again (#2922: a fresh release runner
    // refused zlib.net and GitHub's asset host while github.com verified).
    var attempt = 0
    while ok == 0 and attempt < 2:
        var roots_count = -1
        if windows_store:
            roots_count = with_tls_load_windows_roots(roots_buf, TLS_ROOTS_BYTES, &raw mut roots_starts[0] as *mut i32, &raw mut roots_lens[0] as *mut i32, TLS_ROOTS_MAX)
        else:
            let pem = if override_path.len() > 0: (read_file(override_path) ?? "") else: tls_system_roots_pem()
            if pem.len() > 0 and pem.len() <= TLS_ROOTS_PEM_BYTES:
                let pem_bytes = str_copy_bytes(pem)
                roots_count = x509_pem_parse_certs(pem_bytes, pem.len(), roots_buf, TLS_ROOTS_BYTES, &raw mut roots_starts[0] as *mut i32, &raw mut roots_lens[0] as *mut i32, TLS_ROOTS_MAX)
                str_free_bytes(pem_bytes)
        tls_trace(f"{roots_count} trust roots loaded; the server sent a chain of {evidence.chain_count}")
        if roots_count >= TLS_ROOTS_MAX:
            // Loud, not silent: a store this loader cannot hold whole is the
            // defect behind every "untrusted" verdict that follows.
            eprint(f"tls: the trust store holds more than {TLS_ROOTS_MAX} roots; only the first were loaded (raise TLS_ROOTS_MAX in std.tls)")
        if roots_count > 0:
            if x509_verify_chain_at(cert_buf, &evidence.chain_starts[0] as *const i32, &evidence.chain_lens[0] as *const i32, evidence.chain_count, roots_buf, &roots_starts[0] as *const i32, &roots_lens[0] as *const i32, roots_count, with_time_now()):
                let leaf_buf = cert_buf + evidence.leaf_start as u64
                if x509_verify_hostname(leaf_buf, &evidence.leaf as *const X509Cert, hostname, hostname_len):
                    ok = 1
                else:
                    tls_trace("the leaf certificate does not name the host")
                    attempt = 2
            else:
                tls_trace("the chain does not end in a trusted root")
        if ok == 0 and attempt == 0 and windows_store:
            tls_trace("asking Windows to complete the chain, so a root it has not met enters its store")
            let _built = with_tls_windows_complete_chain(cert_buf, &evidence.chain_starts[0] as *const i32, &evidence.chain_lens[0] as *const i32, evidence.chain_count)
            attempt = 1
        else:
            attempt = 2
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
    if tls_suite_is_rsa(conn.cipher_suite):
        if evidence.ske_sig_alg != 1 or leaf.key_type != 1:
            return -1
        return if rsa_pkcs1_verify(leaf_buf2 + leaf.key_n_start as u64, leaf.key_n_len, leaf_buf2 + leaf.key_e_start as u64, leaf.key_e_len, &evidence.ske_sig[0] as *const u8, evidence.ske_sig_len, &digest[0] as *const u8, digest_len): 0 else: -1
    if tls_suite_is_ecdsa(conn.cipher_suite):
        if evidence.ske_sig_alg != 3 or leaf.key_type != 2:
            return -1
        return if x509_ecdsa_verify_der_bytes(leaf_buf2 + leaf.key_point_start as u64, leaf.key_point_len, leaf.key_curve, &evidence.ske_sig[0] as *const u8, evidence.ske_sig_len, &digest[0] as *const u8, digest_len): 0 else: -1
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
        tls_trace("ClientHello could not be sent")
        return -1
    tls_trace("ClientHello sent; awaiting the server's handshake")

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
        tls_trace("the server's handshake did not complete")
        return -1
    tls_trace(f"server handshake received: certificate {cert_len} bytes, curve {evidence.ske_curve}")

    // Authenticate the peer before sending anything under the new keys:
    // chain to the OS trust store, hostname, SKE signature (#1061).
    let host_bytes2 = str_copy_bytes(hostname)
    let rv = tls_verify_peer(conn, host_bytes2 as *const u8, hl, &cert_buf[0] as *const u8, &raw mut evidence as *mut TlsPeerEvidence)
    str_free_bytes(host_bytes2)
    if rv < 0:
        tls_trace("peer verification failed")
        return -1
    tls_trace("peer verified")

    // Send ClientKeyExchange + ChangeCipherSpec + Finished
    let r3 = tls_send_client_finish(conn, &server_ecdh_pub[0] as *const u8, evidence.ske_curve)
    if r3 < 0:
        tls_trace("ClientKeyExchange, ChangeCipherSpec and Finished could not be sent")
        return -1
    tls_trace("ClientKeyExchange, ChangeCipherSpec and Finished sent; awaiting the server's Finished")

    // Receive server's ChangeCipherSpec + Finished
    let r4 = tls_recv_server_finish(conn)
    if r4 < 0:
        tls_trace("the server's Finished did not verify")
        return -1
    tls_trace("handshake complete")

    0

// Connect to a host via TLS, returning a TlsConn ready for data transfer.
// Returns a TlsConn with fd >= 0 on success, fd = -1 on error.
fn tls_connect(hostname: &str, port: i32) -> TlsConn: tls_connect_timeout(hostname, port, 0, 0)

// tls_connect with a bound on the TCP connect (`connect_ms`) and on every
// later wait for the peer, the handshake included (`idle_ms`); 0 is no bound.
fn tls_connect_timeout(hostname: &str, port: i32, connect_ms: i32, idle_ms: i32) -> TlsConn:
    let fd = if connect_ms > 0: tcp_connect_timeout(hostname, port, connect_ms) else: tcp_connect(hostname, port)
    if fd < 0:
        tls_trace(f"no TCP connection to {hostname}:{port} (fd {fd})")
        return TlsConn.new(-1)
    tls_trace(f"TCP connected to {hostname}:{port}; idle bound {idle_ms} ms")
    if connect_ms > 0 or idle_ms > 0:
        set_timeout(fd, idle_ms)
    var conn = TlsConn.new(fd)
    let r = unsafe { tls_handshake(&raw mut conn as *mut TlsConn, hostname) }
    if r < 0:
        socket_close(fd)
        return TlsConn.new(-1)
    conn

// Known answer (#1063): the TLS working group's P_SHA256 vector (secret
// 9bbe436b…db35, label "test label", seed a0ba9f93…198c, 100 bytes of
// output), compared on its first 32 bytes. 0 on pass.
pub fn tls_prf_sha256_kat() -> i32:
    let secret: [u8; 16] = [0x9bu8, 0xbeu8, 0x43u8, 0x6bu8, 0xa9u8, 0x40u8, 0xf0u8, 0x17u8, 0xb1u8, 0x76u8, 0x52u8, 0x84u8, 0x9au8, 0x71u8, 0xdbu8, 0x35u8]
    let seed: [u8; 16] = [0xa0u8, 0xbau8, 0x9fu8, 0x93u8, 0x6cu8, 0xdau8, 0x31u8, 0x18u8, 0x27u8, 0xa6u8, 0xf7u8, 0x96u8, 0xffu8, 0xd5u8, 0x19u8, 0x8cu8]
    // "test label"
    let label: [u8; 10] = [0x74u8, 0x65u8, 0x73u8, 0x74u8, 0x20u8, 0x6cu8, 0x61u8, 0x62u8, 0x65u8, 0x6cu8]
    var out: [u8; 100] = [0u8; 100]
    unsafe { tls_prf_sha256(&raw const secret[0] as *const u8, 16, &raw const label[0] as *const u8, 10, &raw const seed[0] as *const u8, 16, &raw mut out[0] as *mut u8, 100) }
    if sha256_hex(&raw const out[0] as *const u8) != "e3f229ba727be17b8d122620557cd453c2aab21d07c3d495329b52d4e61edb5a": return 1
    0

// Known answer for the ChaCha20-Poly1305 record path (RFC 7905 §2). The
// nonce of IV 40..4b and sequence number 0x0102030405060708 is the IV with
// the number XORed into its last eight bytes; a record sealed under one
// direction's key opens under the same key, IV and number, advances the
// number, and is refused once a byte of it changes. 0 on pass.
pub fn tls_chacha_record_kat() -> i32:
    var conn = TlsConn.new(-1)
    conn.cipher_suite = SUITE_ECDHE_RSA_CHACHA20
    for i in 0..32: conn.server_write_key[i] = (0x80 + i) as u8
    for i in 0..12: conn.server_write_iv[i] = (0x40 + i) as u8
    conn.server_seq = 0x0102030405060708u64
    let text_len = 22
    unsafe:
        let cp = &raw mut conn as *mut TlsConn
        let key = tls_bytes(&conn.server_write_key[0] as *const u8, 32)
        let nonce = tls_chacha_nonce(&conn.server_write_iv[0] as *const u8, conn.server_seq)
        let expected: [u8; 12] = [0x40u8, 0x41u8, 0x42u8, 0x43u8, 0x45u8, 0x47u8, 0x45u8, 0x43u8, 0x4du8, 0x4fu8, 0x4du8, 0x43u8]
        for i in 0..12:
            if nonce[i] != expected[i]: return 1
        let aad = tls_record_aad(conn.server_seq, TLS_APPLICATION_DATA, text_len)
        let body = []
        for i in 0..text_len: body.push((0x61 + i) as u8)
        let record = chacha20_poly1305_seal(&key, &nonce, &aad, body).unwrap()
        if record.len() != 38: return 2
        var plain: [u8; 64] = [0u8; 64]
        let n = tls_decrypt_record(cp, TLS_APPLICATION_DATA, record.ptr as *const u8, text_len + 16, &raw mut plain[0] as *mut u8)
        if n != text_len or conn.server_seq != 0x0102030405060709u64: return 3
        for i in 0..n:
            if plain[i] != (0x61 + i) as u8: return 4
        // The same bytes under the next sequence number are another record.
        if tls_decrypt_record(cp, TLS_APPLICATION_DATA, record.ptr as *const u8, text_len + 16, &raw mut plain[0] as *mut u8) != -1: return 5
    0
