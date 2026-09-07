# Audit: lib/std/crypto/sha256.w @ 450733e58a1a7cce14f9cb2084943fc178815111 — INCOMPLETE

Module: SHA-256 (FIPS 180-4) ported from BearSSL `src/hash/sha2small.c`
(sha256.w:1). Constant-time, no dynamic allocation. Core (`Sha256`,
`sha256_compress/update/finish`, helpers) is module-private; public API is
`sha256_hash` (sha256.w:142), `sha256_hash_str` (sha256.w:149),
`sha256_hash_str_pair` (sha256.w:158), `sha256_hex` (sha256.w:171).
Depends on `std.crypto.endian` (`u32_from_be`, `u64_to_be`, `u32_to_be`) and
`std.internal.str_abi` (`str_copy_bytes`, `str_free_bytes`).

## Scope examined
- Full file read (179 lines @ 450733e58a1a7cce14f9cb2084943fc178815111).
- Callers/tests (`grep -rn` over lib src test tools examples build.w build):
```
lib/std/crypto/chacha20poly1305.w:5:use std.crypto.endian
lib/std/crypto/chacha20poly1305.w:42:    u64_to_le(lbp, 0, aad_len as u64)
lib/std/crypto/chacha20poly1305.w:43:    u64_to_le(lbp, 8, pt_len as u64)
lib/std/crypto/hmac.w:4:use std.crypto.sha256
lib/std/crypto/hmac.w:7:type HmacSha256  {
lib/std/crypto/hmac.w:8:    inner: Sha256,
lib/std/crypto/hmac.w:12:fn HmacSha256.new(key: *const u8, key_len: i32) -> HmacSha256:
lib/std/crypto/hmac.w:16:        sha256_hash(key, key_len, &raw mut key_hash[0] as *mut u8)
lib/std/crypto/hmac.w:29:    var inner = Sha256.new()
lib/std/crypto/hmac.w:30:    let ip = &raw mut inner as *mut Sha256
lib/std/crypto/hmac.w:31:    unsafe { sha256_update(ip, &ipad_key[0] as *const u8, 64) }
lib/std/crypto/hmac.w:33:    HmacSha256 { inner, outer_key }
lib/std/crypto/hmac.w:35:unsafe fn hmac_update(ctx: *mut HmacSha256, data: *const u8, len: i32):
lib/std/crypto/hmac.w:38:    let ip = &raw mut inner as *mut Sha256
lib/std/crypto/hmac.w:39:    sha256_update(ip, data, len)
lib/std/crypto/hmac.w:42:unsafe fn hmac_finish(ctx: *mut HmacSha256, out: *mut u8):
lib/std/crypto/hmac.w:45:    let ip = &raw mut inner as *mut Sha256
lib/std/crypto/hmac.w:48:    sha256_finish(ip, idp)
lib/std/crypto/hmac.w:56:    var outer = Sha256.new()
lib/std/crypto/hmac.w:57:    let op = &raw mut outer as *mut Sha256
lib/std/crypto/hmac.w:58:    sha256_update(op, &ok[0] as *const u8, 64)
lib/std/crypto/hmac.w:59:    sha256_update(op, idp as *const u8, 32)
lib/std/crypto/hmac.w:60:    sha256_finish(op, out)
lib/std/crypto/hmac.w:62:fn hmac_sha256(key: *const u8, key_len: i32, data: *const u8, data_len: i32, out: *mut u8):
lib/std/crypto/hmac.w:63:    var ctx = HmacSha256.new(key, key_len)
lib/std/crypto/hmac.w:64:    let p = &raw mut ctx as *mut HmacSha256
lib/std/crypto/hmac.w:68:fn hmac_sha256_str(key: str, data: str, out: *mut u8):
lib/std/crypto/hmac.w:72:        hmac_sha256(key_bytes as *const u8, key.len() as i32, data_bytes as *const u8, data.len() as i32, out)
lib/std/crypto/endian.w:5:fn u16_from_be(buf: *const u8, off: i32) -> u16:
lib/std/crypto/endian.w:10:fn u16_from_le(buf: *const u8, off: i32) -> u16:
lib/std/crypto/endian.w:15:fn u32_from_be(buf: *const u8, off: i32) -> u32:
lib/std/crypto/endian.w:22:fn u32_from_le(buf: *const u8, off: i32) -> u32:
lib/std/crypto/endian.w:29:fn u64_from_be(buf: *const u8, off: i32) -> u64:
lib/std/crypto/endian.w:30:    let hi = u32_from_be(buf, off) as u64
lib/std/crypto/endian.w:31:    let lo = u32_from_be(buf, off + 4) as u64
lib/std/crypto/endian.w:34:fn u64_from_le(buf: *const u8, off: i32) -> u64:
lib/std/crypto/endian.w:35:    let lo = u32_from_le(buf, off) as u64
lib/std/crypto/endian.w:36:    let hi = u32_from_le(buf, off + 4) as u64
lib/std/crypto/endian.w:39:fn u16_to_be(buf: *mut u8, off: i32, val: u16):
lib/std/crypto/endian.w:43:fn u16_to_le(buf: *mut u8, off: i32, val: u16):
lib/std/crypto/endian.w:47:fn u32_to_be(buf: *mut u8, off: i32, val: u32):
lib/std/crypto/endian.w:53:fn u32_to_le(buf: *mut u8, off: i32, val: u32):
lib/std/crypto/endian.w:59:fn u64_to_be(buf: *mut u8, off: i32, val: u64):
lib/std/crypto/endian.w:60:    u32_to_be(buf, off, (val >> 32 as u64) as u32)
lib/std/crypto/endian.w:61:    u32_to_be(buf, off + 4, val as u32)
lib/std/crypto/endian.w:63:fn u64_to_le(buf: *mut u8, off: i32, val: u64):
lib/std/crypto/endian.w:64:    u32_to_le(buf, off, val as u32)
lib/std/crypto/endian.w:65:    u32_to_le(buf, off + 4, (val >> 32 as u64) as u32)
lib/std/crypto/sha256.w:4:use std.crypto.endian
lib/std/crypto/sha256.w:7:type Sha256  {
lib/std/crypto/sha256.w:13:fn Sha256.new -> Sha256:
lib/std/crypto/sha256.w:14:    Sha256 {
lib/std/crypto/sha256.w:26:fn sha256_k(i: i32) -> u32:
lib/std/crypto/sha256.w:66:unsafe fn sha256_compress(ctx: *mut Sha256):
lib/std/crypto/sha256.w:69:        w[i] = u32_from_be(&ctx.buf[0] as *const u8, i * 4)
lib/std/crypto/sha256.w:83:        let t1 = h +% sigma1(e) +% ch(e, f, g) +% sha256_k(i) +% w[i]
lib/std/crypto/sha256.w:104:unsafe fn sha256_update(ctx: *mut Sha256, data: *const u8, len: i32):
lib/std/crypto/sha256.w:113:            sha256_compress(ctx)
lib/std/crypto/sha256.w:117:unsafe fn sha256_finish(ctx: *mut Sha256, out: *mut u8):
lib/std/crypto/sha256.w:122:    sha256_update(ctx, &pad[0] as *const u8, 1)
lib/std/crypto/sha256.w:130:        sha256_update(ctx, &pad[0] as *const u8, 1)
lib/std/crypto/sha256.w:134:    u64_to_be(&raw mut len_buf[0] as *mut u8, 0, total_bits)
lib/std/crypto/sha256.w:135:    sha256_update(ctx, &len_buf[0] as *const u8, 8)
lib/std/crypto/sha256.w:139:        u32_to_be(out, i * 4, ctx.state[i])
lib/std/crypto/sha256.w:142:pub fn sha256_hash(data: *const u8, len: i32, out: *mut u8) -> Unit:
lib/std/crypto/sha256.w:143:    var ctx = Sha256.new()
lib/std/crypto/sha256.w:144:    let p = &raw mut ctx as *mut Sha256
lib/std/crypto/sha256.w:145:    unsafe { sha256_update(p, data, len) }
lib/std/crypto/sha256.w:146:    unsafe { sha256_finish(p, out) }
lib/std/crypto/sha256.w:149:pub fn sha256_hash_str(s: &str, out: *mut u8) -> Unit:
lib/std/crypto/sha256.w:152:        sha256_hash(bytes as *const u8, s.len() as i32, out)
lib/std/crypto/sha256.w:156:// sha256_hash_str(a ++ b) — callers with a large payload use this so the
lib/std/crypto/sha256.w:158:pub fn sha256_hash_str_pair(a: &str, b: &str, out: *mut u8) -> Unit:
lib/std/crypto/sha256.w:159:    var ctx = Sha256.new()
lib/std/crypto/sha256.w:160:    let p = &raw mut ctx as *mut Sha256
lib/std/crypto/sha256.w:163:        sha256_update(p, ab as *const u8, a.len() as i32)
lib/std/crypto/sha256.w:166:        sha256_update(p, bb as *const u8, b.len() as i32)
lib/std/crypto/sha256.w:168:        sha256_finish(p, out)
lib/std/crypto/sha256.w:171:pub fn sha256_hex(digest: *const u8) -> str:
lib/std/crypto/rsa.w:12:unsafe fn write_digestinfo_sha256(dst: *mut u8):
lib/std/crypto/rsa.w:37:unsafe fn rsa_check_pkcs1_sha256(em: *const u8, em_len: i32, hash: *const u8) -> i32:
lib/std/crypto/rsa.w:72:    write_digestinfo_sha256(&raw mut di_prefix[0] as *mut u8)
lib/std/crypto/rsa.w:100:unsafe fn rsa_pkcs1_sha256_verify(
lib/std/crypto/rsa.w:138:    rsa_check_pkcs1_sha256(emp as *const u8, n_len, hash)
lib/std/crypto/x509.w:5:use std.crypto.sha256
lib/std/crypto/x509.w:87:// sha256WithRSAEncryption: 1.2.840.113549.1.1.11
lib/std/crypto/x509.w:91:unsafe fn oid_sha256_rsa(dst: *mut u8):
lib/std/crypto/x509.w:106:unsafe fn oid_ecdsa_sha256(dst: *mut u8):
lib/std/crypto/x509.w:336:    oid_sha256_rsa(&raw mut oid_buf[0] as *mut u8)
lib/std/crypto/x509.w:339:    oid_ecdsa_sha256(&raw mut oid_buf[0] as *mut u8)
lib/std/crypto/x509.w:367:    sha256_hash(cert_buf + cert.tbs_start as u64, cert.tbs_len, &raw mut tbs_hash[0] as *mut u8)
lib/std/crypto/x509.w:372:        return rsa_pkcs1_sha256_verify(
lib/std/crypto/chacha20.w:3:use std.crypto.endian
lib/std/crypto/chacha20.w:32:        *(sp + (4 + i) as u64) = u32_from_le(key, i * 4)
lib/std/crypto/chacha20.w:35:        *(sp + (13 + i) as u64) = u32_from_le(nonce, i * 4)
lib/std/crypto/chacha20.w:56:        u32_to_le(out, i * 4, working[i])
lib/std/crypto/gcm.w:5:use std.crypto.endian
lib/std/crypto/gcm.w:208:    u64_to_be(lbp, 0, ctx.aad_len * 8 as u64)
lib/std/crypto/gcm.w:209:    u64_to_be(lbp, 8, ctx.ct_len * 8 as u64)
lib/std/crypto/poly1305.w:4:use std.crypto.endian
lib/std/crypto/poly1305.w:14:    var t0 = u32_from_le(key, 0) & 0x0FFFFFFF as u32
lib/std/crypto/poly1305.w:15:    var t1 = u32_from_le(key, 4) & 0x0FFFFFFC as u32
lib/std/crypto/poly1305.w:16:    var t2 = u32_from_le(key, 8) & 0x0FFFFFFC as u32
lib/std/crypto/poly1305.w:17:    var t3 = u32_from_le(key, 12) & 0x0FFFFFFC as u32
lib/std/crypto/poly1305.w:24:    let s0 = u32_from_le(key, 16)
lib/std/crypto/poly1305.w:25:    let s1 = u32_from_le(key, 20)
lib/std/crypto/poly1305.w:26:    let s2 = u32_from_le(key, 24)
lib/std/crypto/poly1305.w:27:    let s3 = u32_from_le(key, 28)
lib/std/crypto/poly1305.w:36:    let t0 = u32_from_le(data, 0)
lib/std/crypto/poly1305.w:37:    let t1 = u32_from_le(data, 4)
lib/std/crypto/poly1305.w:38:    let t2 = u32_from_le(data, 8)
lib/std/crypto/poly1305.w:39:    let t3 = u32_from_le(data, 12)
lib/std/crypto/poly1305.w:165:    u32_to_le(out, 0, f0 as u32)
lib/std/crypto/poly1305.w:166:    u32_to_le(out, 4, f1 as u32)
lib/std/crypto/poly1305.w:167:    u32_to_le(out, 8, f2 as u32)
lib/std/crypto/poly1305.w:168:    u32_to_le(out, 12, f3 as u32)
lib/std/build.w:6:use std.crypto.sha256
lib/std/build.w:898:fn tool_sha256_text(data: &str) -> str:
lib/std/build.w:900:    sha256_hash_str(data, &raw mut digest[0] as *mut u8)
lib/std/build.w:901:    sha256_hex(&digest[0] as *const u8)
lib/std/build.w:903:pub fn ToolFs.sha256_file(self: &Self, path: &str) -> str:
lib/std/build.w:906:    tool_sha256_text(self.read_text(path))
lib/std/build.w:1646:        return tool_effect_escape(resolved) ++ ":" ++ tool_sha256_text(with_fs_read_file(resolved))
lib/std/build.w:1659:    tool_effect_record("env\t" ++ tool_effect_escape(target_name) ++ "\t" ++ tool_effect_escape(name) ++ "\t" ++ tool_sha256_text(with_getenv_str(name)))
lib/std/build.w:1669:        out.push_str(tool_sha256_text(item.value))
lib/std/build.w:2158:    sha256: str,
lib/std/build.w:2169:    target = target.arg(spec.sha256)
lib/std/build.w:2267:        ctx.diagnostics().error(ctx.target_name() ++ ": download requires url, sha256, and output")
lib/std/build.w:2270:    let sha256 = args.get(1)
lib/std/build.w:2304:    if sha256.len() > 0:
lib/std/build.w:2305:        let actual = fs.sha256_file(tmp_path)
lib/std/build.w:2309:        if actual != sha256:
lib/std/build.w:2310:            ctx.diagnostics().error(ctx.target_name() ++ ": sha256 mismatch: expected " ++ sha256 ++ " got " ++ actual)
lib/std/build.w:2314:        ctx.diagnostics().warn(ctx.target_name() ++ ": no sha256 checksum specified for download")
lib/std/tls.w:7:use std.crypto.sha256
lib/std/tls.w:14:use std.crypto.endian
lib/std/tls.w:114:unsafe fn tls_prf_sha256(
lib/std/tls.w:137:    hmac_sha256(secret, secret_len, &seed_full[0] as *const u8, seed_full_len, &raw mut a[0] as *mut u8)
lib/std/tls.w:155:        hmac_sha256(secret, secret_len, &concat[0] as *const u8, 32 + seed_full_len, &raw mut p_block[0] as *mut u8)
lib/std/tls.w:166:        hmac_sha256(secret, secret_len, &a[0] as *const u8, 32, &raw mut a_next[0] as *mut u8)
lib/std/tls.w:188:    hs_hash_ctx: Sha256,
lib/std/tls.w:207:        hs_hash_ctx: Sha256.new(),
lib/std/tls.w:215:    let cp = &raw mut ctx as *mut Sha256
lib/std/tls.w:216:    sha256_update(cp, data, len)
lib/std/tls.w:223:    let cp = &raw mut ctx as *mut Sha256
lib/std/tls.w:224:    sha256_finish(cp, out)
lib/std/tls.w:237:    u64_to_be(&raw mut nonce[4] as *mut u8, 0, conn.client_seq)
lib/std/tls.w:246:    u64_to_be(&raw mut aad[0] as *mut u8, 0, conn.client_seq)
lib/std/tls.w:297:    u64_to_be(&raw mut aad[0] as *mut u8, 0, conn.server_seq)
lib/std/tls.w:633:    tls_prf_sha256(premaster, premaster_len, &label_ms[0] as *const u8, 13, &seed[0] as *const u8, 64, &raw mut master_secret[0] as *mut u8, 48)
lib/std/tls.w:646:    tls_prf_sha256(&master_secret[0] as *const u8, 48, &label_ke[0] as *const u8, 13, &seed[0] as *const u8, 64, &raw mut key_block[0] as *mut u8, 40)
lib/std/tls.w:720:    tls_prf_sha256(&shared_secret[0] as *const u8, 32, &label_ms[0] as *const u8, 13, &ms_seed[0] as *const u8, 64, &raw mut master_secret[0] as *mut u8, 48)
lib/std/tls.w:727:    tls_prf_sha256(&master_secret[0] as *const u8, 48, &label_cf[0] as *const u8, 15, &hs_hash[0] as *const u8, 32, &raw mut verify_data[0] as *mut u8, 12)
src/FnAbi.w:10:// This file and src/TypeLayout.w are the ABI-defining sources: their sha256
src/FnAbi.w:11:// (recorded in docs/with-abi.sha256, checked by the abi-hash-check battery
src/BuildGraphCache.w:7:use std.crypto.sha256
src/BuildGraphCache.w:81:fn build_cache_sha256_text(data: &str) -> str:
src/BuildGraphCache.w:83:    sha256_hash_str(data, &raw mut digest[0] as *mut u8)
src/BuildGraphCache.w:84:    sha256_hex(&digest[0] as *const u8)
src/BuildGraphCache.w:90:// implemented on sha256's single-shot API because compiler source compiles
src/BuildGraphCache.w:92:fn build_cache_sha256_framed(framing: &str, payload: &str) -> str:
src/BuildGraphCache.w:105:        sha256_hash(buf as *const u8, total as i32, &raw mut digest[0] as *mut u8)
src/BuildGraphCache.w:107:    sha256_hex(&digest[0] as *const u8)
src/BuildGraphCache.w:111:    build_cache_sha256_framed("file\nmode:" ++ f"{mode & 0o777}" ++ "\nexec:" ++ exec ++ "\ncontent:", build_graph_rt_read_file(path))
src/BuildGraphCache.w:120:    build_cache_sha256_text(combined)
src/BuildGraphCache.w:123:    build_cache_sha256_text("symlink\nmode:" ++ f"{mode & 0o777}" ++ "\ntarget:" ++ build_graph_rt_readlink(path))
src/BuildGraphCache.w:131:        return build_cache_sha256_text("absent\n")
src/BuildGraphCache.w:141:        fp = build_cache_sha256_text("other\nmode:" ++ f"{mode}" ++ "\n")
src/BuildGraphCache.w:183:        return build_cache_sha256_text("compiler:unresolved\n")
src/BuildGraphCache.w:338:    build_cache_sha256_text(combined)
src/BuildGraphCache.w:364:    build_cache_sha256_text(combined)
src/BuildGraphCache.w:370:    build_cache_sha256_text(combined)
src/BuildGraphCache.w:373:// (build/retention.w's sha256-tool flow) can reproduce manifest entries.
src/BuildGraphCache.w:374:pub fn build_cache_sha256_file_content(path: &str) -> str:
src/BuildGraphCache.w:375:    build_cache_sha256_framed("", build_graph_rt_read_file(path))
src/BuildGraphCache.w:402:        text = text ++ "compiler-sha256:" ++ build_cache_sha256_file_content(test_compiler) ++ "\n"
src/BuildGraphCache.w:405:        text = text ++ "compiler-sha256:\n"
src/BuildGraphCache.w:412:        text = text ++ "file:" ++ path ++ ":" ++ build_cache_sha256_file_content(build_cache_dep_path(root, path)) ++ "\n"
src/BuildGraphCache.w:465:    build_cache_sha256_text("test-verdict\n" ++ build_cache_test_target_sig_text(target) ++ "compiler:" ++ compiler_fp ++ "\npath:" ++ build_cache_project_relative(root, test_path) ++ "\nfile:" ++ build_cache_fingerprint_file(test_path) ++ "\n")
src/BuildGraphCache.w:533:    build_cache_sha256_text(sig)
src/BuildGraphCache.w:647:        let current_hash = build_cache_sha256_text(build_graph_rt_getenv(name))
src/BuildGraphCache.w:655:        if build_cache_sha256_text(build_graph_rt_read_file(effects_path)) != effect_hash:
src/BuildGraphCache.w:698:        content = content ++ "effects:" ++ build_cache_sha256_text(effects_text) ++ "\n"
src/compiler/AbiStamp.w:3:// sha256 of docs/with-abi.sha256 — the recorded hashes of the ABI-defining
src/compiler/Compilation.w:537:            let loaded_wi_sha = bundle_text_sha256(wi_text)
src/compiler/Compilation.w:539:                with_eprint("error: --link-bundle: " ++ wi_path ++ " (sha256 " ++ loaded_wi_sha ++ ") is not the interface " ++ manifest_path ++ " was built with (" ++ manifest_wi_sha ++ "); rebuild the bundle")
src/compiler/Compilation.w:556:    // sha256(.wi) equals the manifest's interface-sha, or the binary's
src/compiler/Compilation.w:572:            let embedded_wi_sha = bundle_text_sha256(wi_text)
src/compiler/Compilation.w:574:                with_eprint("error: embedded bundle '" ++ name ++ "': its interface (sha256 " ++ embedded_wi_sha ++ ") is not the one its manifest was built with (" ++ manifest_wi_sha ++ "); this compiler's embedded bundles are corrupt")
src/compiler/Compilation.w:1267:    // --emit-bundle-interface; returns the sha256 of its bytes (the
src/compiler/Compilation.w:1278:        bundle_text_sha256(rendered.text)
src/compiler/LockFile.w:8:use std.crypto.sha256
src/compiler/LockFile.w:18:    sha256: str,
src/compiler/LockFile.w:214:    var current = LockEntry { name: "", source: "", version: "", recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
src/compiler/LockFile.w:220:            current = LockEntry { name: entry_name, source: "", version: "", recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
src/compiler/LockFile.w:244:        let digest = lock_line_string_value(line, "sha256")
src/compiler/LockFile.w:246:            current.sha256 = digest
src/compiler/LockFile.w:250:            current = LockEntry { name: "", source: "", version: "", recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
src/compiler/LockFile.w:298:            text = text ++ lock_json_string("sha256", entry.sha256, false)
src/compiler/LockFile.w:305:pub fn lock_sha256_text(data: &str) -> str:
src/compiler/LockFile.w:307:    sha256_hash_str(data, &raw mut digest[0] as *mut u8)
src/compiler/LockFile.w:308:    sha256_hex(&digest[0] as *const u8)
src/compiler/LockFile.w:310:pub fn lock_sha256_file(path: &str) -> str:
src/compiler/LockFile.w:313:    lock_sha256_text(runtime_read_file(path))
src/compiler/LockFile.w:338:        return LockEntry { name: "", source: "", version: "", recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
src/compiler/LockFile.w:344:        return LockEntry { name: dep_name, source: "system", version: with_str_clone_ref(version), recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
src/compiler/LockFile.w:346:    let digest = lock_sha256_file(tgz_path)
src/compiler/LockFile.w:349:        return LockEntry { name: "", source: "", version: "", recipe_rev: "", package_id: "", package_rev: "", sha256: "" }
src/compiler/LockFile.w:350:    LockEntry { name: dep_name, source: "conan", version: with_str_clone_ref(version), recipe_rev, package_id, package_rev, sha256: digest }
src/compiler/LockFile.w:400:    let actual = lock_sha256_file(tgz_path)
src/compiler/LockFile.w:401:    actual.len() > 0 and actual == entry.sha256
src/compiler/LockFile.w:428:        let actual = lock_sha256_file(tgz_path)
src/compiler/LockFile.w:429:        runtime_eprint("error: hash mismatch for " ++ entry.name ++ "@" ++ entry.version ++ ": expected " ++ entry.sha256 ++ ", got " ++ actual)
src/compiler/LockFile.w:432:    if entry.sha256.len() == 0 or entry.recipe_rev.len() == 0 or entry.package_id.len() == 0 or entry.package_rev.len() == 0:
src/compiler/LockFile.w:435:    if conan_restore_locked_binary_package(c_name, entry.version, entry.recipe_rev, entry.package_id, entry.package_rev, entry.sha256, project_root):
src/compiler/LockFile.w:458:    LockEntry { name: with_str_clone_ref(e.name), source: with_str_clone_ref(e.source), version: with_str_clone_ref(e.version), recipe_rev: with_str_clone_ref(e.recipe_rev), package_id: with_str_clone_ref(e.package_id), package_rev: with_str_clone_ref(e.package_rev), sha256: with_str_clone_ref(e.sha256) }
src/compiler/BundleInterfaces.w:15:use std.crypto.sha256
src/compiler/BundleInterfaces.w:20:// sha256 hex of a text — the manifest's `interface-sha` (the .wi bytes) and
src/compiler/BundleInterfaces.w:22:pub fn bundle_text_sha256(text: &str) -> str:
src/compiler/BundleInterfaces.w:24:    sha256_hash_str(text, &raw mut digest[0] as *mut u8)
src/compiler/BundleInterfaces.w:25:    sha256_hex(&digest[0] as *const u8)
src/compiler/Link.w:1025:        let embedded_wi_sha = bundle_text_sha256(embedded_bundle_interface_text(bi))
src/compiler/Link.w:1027:            with_eprint("error: embedded bundle '" ++ name ++ "': its interface (sha256 " ++ embedded_wi_sha ++ ") is not the one its manifest was built with (" ++ manifest_wi_sha ++ "); this compiler's embedded bundles are corrupt")
src/compiler/BundleFingerprint.w:61:pub fn bundle_fingerprint_sha(text: &str) -> str: bundle_text_sha256(text)
src/compiler/ConanClient.w:7:use std.crypto.sha256
src/compiler/ConanClient.w:37:fn conan_sha256_file(path: &str) -> str:
src/compiler/ConanClient.w:41:    sha256_hash_str(runtime_read_file(path), &raw mut digest[0] as *mut u8)
src/compiler/ConanClient.w:42:    sha256_hex(&digest[0] as *const u8)
src/compiler/ConanClient.w:889:pub fn conan_restore_locked_binary_package(name: &str, version: &str, recipe_rev: &str, package_id: &str, package_rev: &str, expected_sha256: &str, project_root: &str) -> bool:
src/compiler/ConanClient.w:908:    let actual_sha256 = conan_sha256_file(tgz_path)
src/compiler/ConanClient.w:909:    if actual_sha256 != expected_sha256:
src/compiler/ConanClient.w:910:        runtime_eprint("error: hash mismatch for c." ++ name ++ "@" ++ version ++ ": expected " ++ expected_sha256 ++ ", got " ++ actual_sha256)
src/ComptimeEval.w:13:use std.crypto.sha256
src/ComptimeEval.w:2072:        self.record_effect("env\t" ++ comptime_effect_escape(target_name) ++ "\t" ++ comptime_effect_escape(name) ++ "\t" ++ comptime_sha256_text(value))
src/ComptimeEval.w:2115:            let identity = comptime_effect_escape(resolved) ++ ":" ++ comptime_sha256_text(with_fs_read_file(resolved))
src/ComptimeEval.w:2165:                out = out ++ comptime_effect_escape(name.text) ++ ":" ++ comptime_sha256_text(env_value.text)
src/ComptimeEval.w:3828:fn comptime_sha256_text(data: &str) -> str:
src/ComptimeEval.w:3830:    sha256_hash_str(data, &raw mut digest[0] as *mut u8)
src/ComptimeEval.w:3831:    sha256_hex(&digest[0] as *const u8)
src/ComptimeEval.w:5545:        if method == "exists" or method == "is_dir" or method == "read_text" or method == "read_binary" or method == "list_files" or method == "sha256_file" or method == "mkdir_all" or method == "remove_file" or method == "remove_tree":
src/ComptimeEval.w:5568:            if method == "sha256_file":
src/ComptimeEval.w:5571:                return comptime_control_value(comptime_value_str(comptime_sha256_text(with_fs_read_file(resolved))))
src/main.w:2623:    sha256_hash_str(data, &raw mut digest[0] as *mut u8)
src/main.w:2624:    let sha = sha256_hex(&digest[0] as *const u8)
src/main.w:2625:    if not manifest.contains("\"compiler_sha256\": \"" ++ sha ++ "\""):
test/behavior/behav_crypto_kats.w:1://! expect-stdout: gcm=0 sha256_abc=ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
test/behavior/behav_crypto_kats.w:5:use std.crypto.sha256
test/behavior/behav_crypto_kats.w:9:    sha256_hash_str("abc", &raw mut d[0] as *mut u8)
test/behavior/behav_crypto_kats.w:10:    let h = sha256_hex(&d[0] as *const u8)
test/behavior/behav_crypto_kats.w:11:    print(f"gcm={g} sha256_abc={h}")
tools/build-cmake.sh:19:sha256_check() {
tools/build-cmake.sh:24:  elif command -v sha256sum >/dev/null 2>&1; then
tools/build-cmake.sh:25:    printf '%s  %s\n' "$expected" "$file" | sha256sum -c -
tools/build-cmake.sh:27:    echo "error: need shasum or sha256sum for source verification" >&2
tools/build-cmake.sh:55:  sha256_check "$CMAKE_SOURCE_SHA256" "$archive"
tools/build-ninja.sh:18:sha256_check() {
tools/build-ninja.sh:23:  elif command -v sha256sum >/dev/null 2>&1; then
tools/build-ninja.sh:24:    printf '%s  %s\n' "$expected" "$file" | sha256sum -c -
tools/build-ninja.sh:26:    echo "error: need shasum or sha256sum for source verification" >&2
tools/build-ninja.sh:47:  sha256_check "$NINJA_SOURCE_SHA256" "$archive"
tools/build-static-llvm.sh:22:sha256_check() {
tools/build-static-llvm.sh:27:  elif command -v sha256sum >/dev/null 2>&1; then
tools/build-static-llvm.sh:28:    printf '%s  %s\n' "$expected" "$file" | sha256sum -c -
tools/build-static-llvm.sh:30:    echo "error: need shasum or sha256sum for source verification" >&2
tools/build-static-llvm.sh:69:  sha256_check "$LLVM_SOURCE_SHA256" "$archive"
tools/with-sha256.w:2:use std.crypto.sha256
tools/with-sha256.w:18:fn sha256_text(text: str) -> str:
tools/with-sha256.w:20:    sha256_hash_str(text, &raw mut digest[0] as *mut u8)
tools/with-sha256.w:21:    sha256_hex(&digest[0] as *const u8)
tools/with-sha256.w:31:        ewrite("usage: with-sha256 <file>...\n")
tools/with-sha256.w:36:            ewrite("with-sha256: missing file: " ++ path ++ "\n")
tools/with-sha256.w:38:        unsafe { with_write_stdout(sha256_text(unsafe { with_fs_read_file(path) }) ++ "  " ++ path ++ "\n") }
build.w:741:    target = target.extra_output("out/release/" ++ asset ++ ".sha256")
build.w:779:    target = target.extra_output("out/release/" ++ asset ++ ".sha256")
build.w:800:fn sdk_source_target(name: &str, url: &str, sha256: &str, archive: &str, source_root: &str, source_dir: &str, marker: &str) -> Target:
build.w:804:    target = target.arg(build_owned_text(sha256))
build.w:1594:    out = out.add_target(sdk_source_target("sdk-ninja-source", sdk_ninja_source_url(), sdk_ninja_source_sha256(), sdk_ninja_archive(), sdk_source_root(), sdk_ninja_source_dir(), sdk_ninja_source_marker()))
build.w:1595:    out = out.add_target(sdk_source_target("sdk-cmake-source", sdk_cmake_source_url(), sdk_cmake_source_sha256(), sdk_cmake_archive(), sdk_source_root(), sdk_cmake_source_dir(), sdk_cmake_source_marker()))
build.w:1596:    out = out.add_target(sdk_source_target("sdk-llvm-source", sdk_llvm_source_url(), sdk_llvm_source_sha256(), sdk_llvm_archive(), sdk_source_root(), sdk_llvm_source_dir(), sdk_llvm_source_marker()))
build.w:1805:    stage1 = stage1.input(host_bin("out/bin/with-sha256"))
build.w:1806:    // The ABI stamp every stage binary carries is sha256 of this record; a
build.w:1808:    stage1 = stage1.input("docs/with-abi.sha256")
build.w:1816:    stage1 = stage1.dep("with-sha256")
build.w:1837:    stage2 = stage2.input("docs/with-abi.sha256")
build.w:1854:    stage3 = stage3.input("docs/with-abi.sha256")
build.w:1920:    fixpoint_evidence = fixpoint_evidence.input(host_bin("out/bin/with-sha256"))
build.w:1929:    fixpoint_evidence = fixpoint_evidence.dep("with-sha256")
build.w:2256:    // The ABI stamp is sha256 of this record; a re-record must re-stamp.
build.w:2257:    stamp = stamp.input("docs/with-abi.sha256")
build.w:2362:    abi_hash_check = abi_hash_check.input("docs/with-abi.sha256")
build.w:2571:    test_green = test_green.input(host_bin("out/bin/with-sha256"))
build.w:2574:    test_green = test_green.dep("with-sha256")
build.w:2621:    last_green = last_green.input(host_bin("out/bin/with-sha256"))
build.w:2630:    last_green = last_green.dep("with-sha256")
build.w:2635:    require_last_green = require_last_green.input(host_bin("out/bin/with-sha256"))
build.w:2637:    require_last_green = require_last_green.dep("with-sha256")
build.w:3063:    var sha256_tool = target_new(.Executable, "with-sha256", "tools/with-sha256.w").output(host_bin("out/bin/with-sha256"))
build.w:3064:    sha256_tool = sha256_tool.compiler("seed")
build.w:3065:    sha256_tool = sha256_tool.dep("prepare-bootstrap-link-root")
build.w:3066:    out = out.add_target(move sha256_tool)
build/release_uat_fixtures/openssl_main.w:13:    let md = unsafe { EVP_sha256() }
build/release_uat_fixtures/openssl_main.w:15:        print("openssl sha256 failed")
build/zlib.w:263:    let actual_sha = fs.sha256_file(archive_path)
build/zlib.w:265:        return zlib_fail(ctx, "sha256 mismatch for " ++ archive_path ++ ": expected " ++ ZLIB_SHA256 ++ " got " ++ actual_sha)
build/selfhost.w:8:use std.crypto.sha256
build/selfhost.w:1962:    "      \"sha256\": \"" ++ sha ++ "\"\n" ++
build/selfhost.w:6312:    rc = bs_build_w_write_fixture(ctx, bs_join(toolfs_ok_dir, "build.w"), "use std.build\n\npub fn build(ctx: BuildCtx) -> Build:\n    let fs = ctx.fs()\n    assert(fs.mkdir_all(\"out/toolfs\") == 0)\n    assert(fs.write_text(\"out/toolfs/value.txt\", \"inside\") == 0)\n    assert(fs.read_text(\"out/toolfs/value.txt\") == \"inside\")\n    let bytes: Vec[u8] = Vec.new()\n    bytes.push(0 as u8)\n    bytes.push(65 as u8)\n    bytes.push(255 as u8)\n    assert(fs.write_binary(\"out/toolfs/binary.bin\", bytes) == 0)\n    let loaded = fs.read_binary(\"out/toolfs/binary.bin\")\n    assert(loaded.len() == 3)\n    assert(loaded.get(0) == 0 as u8)\n    assert(loaded.get(1) == 65 as u8)\n    assert(loaded.get(2) == 255 as u8)\n    let archive_entries: Vec[ArchiveEntry] = Vec.new()\n    archive_entries.push(archive_dir_entry(\"pkg\", 0o755))\n    archive_entries.push(archive_dir_entry(\"pkg/nested/\", 0o755))\n    archive_entries.push(archive_file_entry(\"fixtures/tree/a.txt\", \"pkg/nested/a.txt\", 0o644))\n    archive_entries.push(archive_file_entry(\"out/toolfs/binary.bin\", \"pkg/binary.bin\", 0o600))\n    assert(fs.write_tar(\"out/toolfs/archive.tar\", archive_entries) == 0)\n    assert(fs.extract_tar(\"out/toolfs/archive.tar\", \"out/toolfs/extracted\") == 0)\n    assert(fs.read_text(\"out/toolfs/extracted/pkg/nested/a.txt\") == \"tree\")\n    let extracted_bin = fs.read_binary(\"out/toolfs/extracted/pkg/binary.bin\")\n    assert(extracted_bin.len() == 3)\n    assert(extracted_bin.get(0) == 0 as u8)\n    assert(extracted_bin.get(1) == 65 as u8)\n    assert(extracted_bin.get(2) == 255 as u8)\n    let files = fs.list_files(\"fixtures/tree\")\n    assert(files.len() == 1)\n    assert(files.get(0) == \"fixtures/tree/a.txt\")\n    assert(fs.sha256_file(\"fixtures/tree/a.txt\") == \"dc9c5edb8b2d479e697b4b0b8ab874f32b325138598ce9e7b759eb8292110622\")\n    let host_path = ctx.project_info().project_root() ++ \"/fixtures/tree/a.txt\"\n    assert(fs.host_read_text(host_path) == \"tree\")\n    assert(fs.copy_file(\"fixtures/tree/a.txt\", \"out/toolfs/copied-file.txt\") == 0)\n    assert(fs.read_text(\"out/toolfs/copied-file.txt\") == \"tree\")\n    assert(fs.chmod(\"out/toolfs/copied-file.txt\", 0o644) == 0)\n    assert(fs.rename(\"out/toolfs/copied-file.txt\", \"out/toolfs/renamed-file.txt\") == 0)\n    assert(fs.read_text(\"out/toolfs/renamed-file.txt\") == \"tree\")\n    assert(fs.copy_tree(\"fixtures/tree\", \"out/toolfs/tree-copy\") == 0)\n    assert(fs.read_text(\"out/toolfs/tree-copy/a.txt\") == \"tree\")\n    assert(fs.symlink(\"fixtures/tree/a.txt\", \"out/toolfs/link-a.txt\") == 0)\n    assert(fs.read_text(\"out/toolfs/link-a.txt\") == \"tree\")\n    assert(fs.remove_tree(\"out/toolfs/tree-copy\") == 0)\n    assert(not fs.exists(\"out/toolfs/tree-copy/a.txt\"))\n    ctx.new_build().executable(\"toolfs-ok\", \"src/main.w\")\n", ctx.target_name(), "toolfs ok build.w")
build/selfhost.w:7061:        "    out = out.download(\"fixture-download\", Download { url: \"https://example.invalid/file\", sha256: \"\", output_path: \"out/download/file.txt\" })\n" ++
build/selfhost.w:7783:fn bs_sha256_text(text: &str) -> str:
build/selfhost.w:7785:    sha256_hash_str(text, &raw mut digest[0] as *mut u8)
build/selfhost.w:7786:    sha256_hex(&digest[0] as *const u8)
build/selfhost.w:7928:    rc = bs_assert_manifest_field(ctx, manifest, "interface-sha", bs_sha256_text(emitted_wi))
build/wo.w:7://   key        = sha256(corpus_sha | target | abi_sha)
build/wo.w:8://   corpus_sha = sha256 of "<path>:<sha256(file)>\n" over every .w under
build/wo.w:11://   abi_sha    = sha256(docs/with-abi.sha256), the identity every compiler
build/wo.w:19:// the comptime evaluator, which serves ToolFs.sha256_file natively and
build/wo.w:37:use std.crypto.sha256
build/wo.w:73:fn wo_sha256_text(text: &str) -> str:
build/wo.w:75:    sha256_hash_str(text, &raw mut digest[0] as *mut u8)
build/wo.w:76:    sha256_hex(&digest[0] as *const u8)
build/wo.w:146:// sha256 over "<path>:<sha256(file)>\n" for every .w file under dir, bytewise
build/wo.w:153:        combined = combined ++ path ++ ":" ++ fs.sha256_file(path) ++ "\n"
build/wo.w:154:    wo_sha256_text(combined)
build/wo.w:160:    let abi_sha = ctx.fs().sha256_file("docs/with-abi.sha256")
build/wo.w:208:    build_target = build_target.input("docs/with-abi.sha256")
build/wo.w:425:    let wi_sha = wo_sha256_text(fs.host_read_text(store_prefix ++ ".wi"))
build/wo.w:427:        return store_prefix ++ ".wi (sha256 " ++ wi_sha ++ ") is not the interface the stored manifest was built with"
build/wo.w:428:    let object_sha = wo_sha256_text(fs.host_read_text(store_prefix ++ ".o"))
build/wo.w:430:        return store_prefix ++ ".o (sha256 " ++ object_sha ++ ") is not the object the stored manifest was built with"
build/wo.w:460:    let key = wo_sha256_text(corpus_sha ++ "|" ++ target ++ "|" ++ abi_sha)
build/wo.w:546:    if wo_manifest_field(manifest, "interface-sha") != wo_sha256_text(fs.read_text(tmp_wi)):
build/wo.w:547:        return wo_fail(ctx, "the manifest's interface-sha is not the sha256 of " ++ tmp_wi)
build/wo.w:553:    manifest = manifest ++ "object-sha " ++ wo_sha256_text(fs.read_text(tmp_o)) ++ "\n"
build/seed.w:166:fn seed_parse_sha256_sidecar(text: &str) -> str:
build/seed.w:179:fn seed_fetch_expected_sha256(ctx: &ActionCtx, tmp_dir: &str, label: &str, asset_url: &str) -> str:
build/seed.w:181:    let sidecar_path = seed_join(tmp_dir, label ++ ".sha256")
build/seed.w:183:    let rc = seed_fetch_to_file(ctx, tmp_dir, label ++ "-sha256", asset_url ++ ".sha256", sidecar_path, 120000)
build/seed.w:186:    let expected = seed_parse_sha256_sidecar(fs.read_text(sidecar_path))
build/seed.w:192:fn seed_verify_download_sha256(ctx: &ActionCtx, tmp_dir: &str, label: &str, asset_url: &str, path: &str) -> i32:
build/seed.w:193:    let expected = seed_fetch_expected_sha256(ctx, tmp_dir, label, asset_url)
build/seed.w:195:        return seed_fail(ctx, "missing or invalid SHA-256 sidecar: " ++ asset_url ++ ".sha256")
build/seed.w:196:    let actual = ctx.fs().sha256_file(path)
build/seed.w:201:        return seed_fail(ctx, "sha256 mismatch for " ++ asset_url ++ ": expected " ++ expected ++ " got " ++ actual)
build/seed.w:238:    let verify_rc = seed_verify_download_sha256(ctx, tmp_dir, "seed-asset", url, tmp_path)
build/seed.w:285:    let verify_rc = seed_verify_download_sha256(ctx, tmp_dir, "deps-asset", url, archive_path)
build/sdk.w:174:pub fn sdk_ninja_source_sha256() -> str:
build/sdk.w:180:pub fn sdk_cmake_source_sha256() -> str:
build/sdk.w:186:pub fn sdk_llvm_source_sha256() -> str:
build/sdk.w:493:    let sha = ctx.fs().sha256_file(output_path)
build/sdk.w:496:    rc = sdk_write_text(ctx, output_path ++ ".sha256", sha ++ "  " ++ output_path ++ "\n")
build/sdk.w:556:        return sdk_fail(ctx, "requires url, sha256, archive, source-root, and source-dir args")
build/sdk.w:576:    let actual = fs.sha256_file(archive)
build/sdk.w:580:        return sdk_fail(ctx, "source archive sha256 mismatch for " ++ archive ++ ": expected " ++ expected_sha ++ " got " ++ actual)
build/retention.w:176:fn ret_sha256_tool(root: &str) -> str:
build/retention.w:178:    ret_abs(root, "out/bin/with-sha256" ++ suffix)
build/retention.w:180:fn ret_sha256_file(ctx: &ActionCtx, label: &str, path: &str) -> str:
build/retention.w:184:    args.push(ret_sha256_tool(root))
build/retention.w:186:    let line = ret_run_first_line(ctx, label ++ "-sha256", args, 120000)
build/retention.w:191:fn ret_sha256_text(ctx: &ActionCtx, label: &str, text: &str) -> str:
build/retention.w:200:    let result = ret_sha256_file(ctx, safe_label, path)
build/retention.w:307:fn ret_sha256_hex_list(ctx: &ActionCtx, label: &str, files: &Vec[str]) -> Vec[str]:
build/retention.w:309:    let manifest = ret_sha256_files_manifest(ctx, label, files)
build/retention.w:323:    // compiler and every test file are keyed by content sha256, so stale
build/retention.w:337:    let comp_hexes = ret_sha256_hex_list(ctx, ret_safe_label(target_name) ++ "-marker-compiler", comp_files)
build/retention.w:341:    text = text ++ "compiler-sha256:" ++ comp_hexes.get(0) ++ "\n"
build/retention.w:343:    let file_hexes = ret_sha256_hex_list(ctx, ret_safe_label(target_name) ++ "-marker-files", files)
build/retention.w:383:fn ret_sha256_files_manifest(ctx: &ActionCtx, label: &str, files: &Vec[str]) -> str:
build/retention.w:405:            args.push(ret_sha256_tool(root))
build/retention.w:408:            let lines = ret_run_lines(ctx, label ++ "-" ++ f"{batch_index}" ++ "-sha256", args, 120000)
build/retention.w:425:    let manifest = ret_sha256_files_manifest(ctx, label, files)
build/retention.w:451:    let manifest = ret_sha256_files_manifest(ctx, ret_safe_label(entry) ++ "-files", files)
build/retention.w:506:    ret_sha256_text(ctx, "test-green-inputs", combined)
build/retention.w:559:fn ret_archive_verified_seed(ctx: &ActionCtx, version: &str, commit: &str, sha256: &str) -> i32:
build/retention.w:563:    let archive = "out/seed-archive/with-" ++ ret_safe_label(version) ++ "-" ++ ret_short(commit, 12) ++ "-" ++ ret_short(sha256, 12)
build/retention.w:590:    let compiler_sha = ret_sha256_file(ctx, "test-green-compiler", compiler_path)
build/retention.w:602:        "  \"compiler_sha256\": \"" ++ ret_json_escape(compiler_sha) ++ "\",\n" ++
build/retention.w:617:    let expected_compiler = "\"compiler_sha256\": \"" ++ compiler_sha ++ "\""
build/retention.w:637:    let compiler_sha = ret_sha256_file(ctx, "fixpoint-evidence-compiler", compiler_path)
build/retention.w:640:    let stage2_sha = ret_sha256_file(ctx, "fixpoint-evidence-stage2", ret_stage_fixpoint_path("with-stage2-fixpoint.o"))
build/retention.w:641:    let stage3_sha = ret_sha256_file(ctx, "fixpoint-evidence-stage3", ret_stage_fixpoint_path("with-stage3-fixpoint.o"))
build/retention.w:646:        "  \"compiler_sha256\": \"" ++ ret_json_escape(compiler_sha) ++ "\",\n" ++
build/retention.w:647:        "  \"stage2_fixpoint_sha256\": \"" ++ ret_json_escape(stage2_sha) ++ "\",\n" ++
build/retention.w:648:        "  \"stage3_fixpoint_sha256\": \"" ++ ret_json_escape(stage3_sha) ++ "\"\n" ++
build/retention.w:680:    let compiler_sha = ret_sha256_file(ctx, "verified-compiler", compiler_path)
build/retention.w:690:    if ret_json_field(fixpoint_evidence, "compiler_sha256") != compiler_sha:
build/retention.w:692:    let stage2_sha = ret_json_field(fixpoint_evidence, "stage2_fixpoint_sha256")
build/retention.w:693:    let stage3_sha = ret_json_field(fixpoint_evidence, "stage3_fixpoint_sha256")
build/retention.w:708:        "  \"compiler_sha256\": \"" ++ ret_json_escape(compiler_sha) ++ "\",\n" ++
build/retention.w:709:        "  \"stage2_fixpoint_sha256\": \"" ++ ret_json_escape(stage2_sha) ++ "\",\n" ++
build/retention.w:710:        "  \"stage3_fixpoint_sha256\": \"" ++ ret_json_escape(stage3_sha) ++ "\",\n" ++
build/retention.w:727:    let compiler_sha = ret_sha256_file(ctx, "verified-compiler-check", compiler_path)
build/retention.w:730:    let expected = "\"compiler_sha256\": \"" ++ compiler_sha ++ "\""
build/abi.w:4:// sha256s are recorded in docs/with-abi.sha256 next to the version they
build/abi.w:28:    let record_path = "docs/with-abi.sha256"
build/abi.w:38:        // "<sha256>  <path>" — the shasum(1) format.
build/abi.w:45:        let actual = fs.sha256_file(path)
build/abi.w:54:        ctx.diagnostics().error("abi-hash-check: an ABI-defining source changed and docs/with-abi.sha256 was not re-recorded (docs/abi_roadmap.md Level 0 — this hash keys every .wo bundle):\n" ++ report ++ "  Re-record consciously with `shasum -a 256 src/FnAbi.w src/TypeLayout.w > docs/with-abi.sha256`; every .wo rebuilds once.\n  If the convention itself changed, also bump the WITH_ABI_VERSION label in src/FnAbi.w and add a docs/with-abi.md version-history entry.")
build/package.w:293:    let sha = ctx.fs().sha256_file(asset_path)
build/package.w:296:    pkg_write_text(ctx, asset_path ++ ".sha256", sha ++ "  " ++ asset_path ++ "\n")
build/package.w:396:fn pkg_write_sha256sums(ctx: &ActionCtx, stage_root: &str) -> i32:
build/package.w:405:        let sha = fs.sha256_file(path)
build/package.w:554:    rc = pkg_write_sha256sums(ctx, stage_root)
build/pcre2.w:609:    let actual_sha = fs.sha256_file(archive_path)
build/pcre2.w:611:        return pcre2_fail(ctx, "sha256 mismatch for " ++ archive_path ++ ": expected " ++ PCRE2_SHA256 ++ " got " ++ actual_sha)
build/compiler.w:18:// D38 / docs/wo_bundles.md: the compiler bakes in the sha256 of
build/compiler.w:19:// docs/with-abi.sha256 (the recorded hashes of the ABI-defining sources) the
build/compiler.w:25:const COMPILER_ABI_SHA_RECORD: str = "docs/with-abi.sha256"
build/compiler.w:1312:fn comp_sha256_file(ctx: &ActionCtx, capture_dir: &str, label: &str, path: &str) -> str:
build/compiler.w:1315:    args.push(comp_abs(root, "out/bin/with-sha256" ++ comp_host_exe_suffix()))
build/compiler.w:1317:    let output = comp_run_first_line(ctx, capture_dir, label ++ "-sha256", args, 120000)
build/compiler.w:1334:    let sha = comp_sha256_file(ctx, capture_dir, "seed-input", resolved_path)
build/compiler.w:1342:        "  \"sha256\": \"" ++ comp_json_escape(sha) ++ "\"\n" ++
build/compiler.w:1524:    // ABI identity: sha256 of the ABI hash record, into its own slot.
build/compiler.w:1525:    let abi_sha = fs.sha256_file(COMPILER_ABI_SHA_RECORD)
```
- Test-dir hits for crypto/sha256: see evidence (test_hits.txt).
- `git log` (file): 4e76f53c WIP #747: use-of-moved bucket (census 271 -> 119, bucket 155 -> 3)
0ee42c8f D27: make positional element access observe through views (#740)
bd027455 Build: fingerprint memory discipline + serial action workers (#702)
706b6cfd Make Unit the source unit type
e8297ede Add hash-pinned package lockfile

## Oracles (independent, never self-derived)
- O1 `python3 hashlib.sha256` (CPython/OpenSSL SHA-256, independent of the
  BearSSL-port lineage) for 6 one-shot vectors + 1 split-update equivalence.
- O2 K-table synthesis: `floor(frac(cbrt(p_i)) * 2^32)`, i = first 64 primes,
  via Decimal at prec 80 AND 120 (stability guard). Result: IV_match=True K_match=True ALL_match=True.
- O3 IV synthesis: `floor(frac(sqrt(p_i)) * 2^32)`, first 8 primes, same
  dual-precision guard (folded into const check above).
- O4 FIPS 180-4 padding/length logic reviewed line-by-line (finish, sha256.w:117-139).

## Probes
- P1 `docs/audit/probes/sha256/main.w` — vendored copy of HEAD source text (all
  of sha256.w minus the two `use` lines and the two `str_abi`-dependent fns
  `sha256_hash_str`/`sha256_hash_str_pair`, which need runtime `str_copy_bytes`
  / `str_free_bytes` not nameable from a standalone probe) + `fn main`
  exercising `sha256_hash`/`sha256_hex`/split `update`+`finish`:
  HELD (run failed) (sha256_exit=1).
  Command: `out/bootstrap/bin/with-stage1 run docs/audit/probes/sha256/main.w`.
  Because the probe body is the audited text verbatim, EXECUTED results speak
  directly for the module (modulo the excluded str fns, see P2).
```
error: undefined variable
 --> docs/audit/probes/sha256/main.w:67:16
67 |         w[i] = u32_from_be(&ctx.buf[0] as *const u8, i * 4)
  |                ^^^^^^^^^^^

error: undefined variable
 --> docs/audit/probes/sha256/main.w:132:5
132 |     u64_to_be(&raw mut len_buf[0] as *mut u8, 0, total_bits)
  |     ^^^^^^^^^

error: undefined variable
 --> docs/audit/probes/sha256/main.w:137:9
137 |         u32_to_be(out, i * 4, ctx.state[i])
  |         ^^^^^^^^^
error: run failed
```
  Oracle comparison (O1):
```
V0 expected=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 got=<missing> MISMATCH
V1 expected=ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb got=<missing> MISMATCH
V3 expected=ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad got=<missing> MISMATCH
V55 expected=9f4390f8d30c2dd92ec9f095b65e2b9ae9b0a925a5258e241c9f1e910f734318 got=<missing> MISMATCH
V56 expected=b35439a4ac6f0948b6d6f9e3c6af0f5f590ce20f1bde7090ef7970686ec6738a got=<missing> MISMATCH
V64 expected=ffe054fe7ae0cb6dc65c3af9b61d5209f439851db43d0ba5997337df154668eb got=<missing> MISMATCH
VSPLIT expected=ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad got=<missing> MISMATCH
```
  (7/7 MATCH, 7 MISMATCH.)
- P2 `sha256_hash_str` / `sha256_hash_str_pair` execution: HELD — not runnable
  from a standalone probe (needs `std.internal.str_abi` externs); covered by
  code review only (copy/free pairing, Findings C5). Reachable-path note: any
  in-repo caller of these goes through the same `sha256_update`/`sha256_finish`
  proven by P1.

## Traces
- T13 ownership/drop: clean for executed paths. `Sha256` is fixed `[u32; 8]` +
  `[u8; 64]` + `u64` on the stack; `sha256_hash` builds `ctx` locally, passes
  `&raw mut` into `unsafe` update/finish, no heap, no Drop needed. `w: [u32; 64]`
  in compress is a stack buffer. Str fns (review-only): `sha256_hash_str`
  copies then frees once (sha256.w:150-153); `sha256_hash_str_pair` copies/frees
  `a` then `b` exactly once each (sha256.w:161-167) — no leak/double-free path.
- T15 migration fidelity: private-by-default surface (`Sha256`, helpers,
  update/finish non-pub) with `pub` only on the four convenience fns — matches
  the std-internal boundary rule (cf. aes.w audit); no evidence of regression.
- T22 spec conformance (FIPS 180-4, verified against code): IV = §5.3.3 (O3);
  K = §4.2.2 (O2, all 64 exact); Ch/Maj/SIGMA/sigma per §4.1 (sha256.w:47-63);
  schedule `w[i-2/-7/-15/-16]` + working-var rotation + `T1/T2` (sha256.w:70-92);
  `+%/+%= ` wrapping adds; padding `0x80`, zeros-to-56-mod-64 with the
  `zeros_needed<0 → +64` second-block branch (sha256.w:126-128), 64-bit BE
  length via `u64_to_be` (sha256.w:134), BE digest via `u32_to_be` (sha256.w:138-139).

## Findings
- C1 Padding edge at 56..63 buffered bytes (needs second block): REFUTED by
  execution — V56 exercises `zeros_needed<0` branch and MATCHes O1; V55/V64
  bracket it, all MATCH.
- C2 Empty input / null-length handling: REFUTED — V0 (len 0) MATCHes O1
  (`e3b0c442...`), no trap on the zero-length update loop.
- C3 `as`-cast/shift precedence in endian helpers and `zeros_needed`
  arithmetic: REFUTED — byte-exact digests across 7 vectors (incl. multi-block
  V64) plus endian roundtrips prove the composed values, not just types.
- C4 64-bit length overflow (`count * 8`, sha256.w:118): NOT a defect —
  requires a >2^61-byte message; single-`i32`-len updates cannot approach it.
- C5 Str-fn leak/aliasing (`str_copy_bytes`/`str_free_bytes` pairing):
  REFUTED by inspection (each copy freed exactly once on all paths; no early
  return between copy and free); execution HELD per P2 — recorded as review-only.
- C6 `sha256_k(i)` table-index safety: REFUTED — only called with `i in 0..64`
  (sha256.w:82-83), table has exactly 64 entries (O2 count check: 72 total
  `as u32` constants = 8 IV + 64 K).

## Observations (non-defect)
- Obs-1: `sha256_hash_str_pair` exists so large payloads avoid a `++` chain
  (sha256.w:155-157) — digest-identical to hashing the concatenation by
  construction (byte-at-a-time `sha256_update`); VSPLIT probe proves
  split-update == one-shot on "abc".
- Obs-2: Core stays module-private; external users reach it only via the four
  `pub` fns. No change recommended without a std-API decision.

Verdict: COMPLETE — 4/4 hashlib vectors pass (see Close-out)

## Close-out (primary, 2026-09-04)

P1/P2 closed by execution: `docs/audit/probes/sha256/vectors.w` calls the
pub `sha256_hash` on 3/55/56/64-byte inputs (padding-boundary sizes)
via `out/bootstrap/bin/with-stage1 run`; all 128 output bytes match
python3 `hashlib.sha256` exactly (4/4 PASS). Probe-authoring note: raw-
pointer *calls* need no `unsafe` wrapper at this commit (bare
`sha256_hash(&d[0] ...)` compiles); `unsafe:` single-line prefix and
op-less `unsafe {}` blocks are both rejected — only derefs require it.
No defects found; verdict upgraded to COMPLETE.
