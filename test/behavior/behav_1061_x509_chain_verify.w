//! expect-stdout: ok
// #1061: certificate chain + hostname verification (x509_verify_chain_pem)
// over the generated family in tls1061/ (RSA root, EC intermediate, RSA and
// EC leaves, a wrong-SAN leaf, a self-signed leaf; authoring-time openssl,
// throwaway keys). Every refusal below connected before this verification
// existed.
use std.fs
use std.crypto.x509

fn pem(name: str) -> str:
    read_file("test/behavior/tls1061/" ++ name) ?? ""

fn main:
    let root = pem("root.pem")
    let inter = pem("inter.pem")
    let leaf_rsa = pem("leaf_rsa.pem")
    let leaf_ec = pem("leaf_ec.pem")
    let wrong = pem("wrong.pem")
    let selfsigned = pem("selfsigned.pem")
    assert(root.len() > 0 and leaf_rsa.len() > 0)
    let now: i64 = 1800000000
    // RSA leaf under EC intermediate under RSA root (both sig families).
    assert(x509_verify_chain_pem(leaf_rsa ++ inter, root, "localhost", now))
    assert(x509_verify_chain_pem(leaf_rsa ++ inter, root, "127.0.0.1", now))
    assert(x509_verify_chain_pem(leaf_rsa ++ inter, root, "LOCALHOST", now))
    // EC leaf directly under the RSA root.
    assert(x509_verify_chain_pem(leaf_ec, root, "localhost", now))
    // Wrong host, wrong SAN, untrusted, missing link, wrong anchor, expired.
    assert(not x509_verify_chain_pem(leaf_rsa ++ inter, root, "example.com", now))
    assert(not x509_verify_chain_pem(wrong, root, "localhost", now))
    assert(x509_verify_chain_pem(wrong, root, "example.invalid", now))
    assert(not x509_verify_chain_pem(selfsigned, root, "localhost", now))
    assert(not x509_verify_chain_pem(leaf_rsa, root, "localhost", now))
    assert(not x509_verify_chain_pem(leaf_ec, inter, "localhost", now))
    assert(not x509_verify_chain_pem(leaf_rsa ++ inter, root, "localhost", 2208988800))
    assert(not x509_verify_chain_pem(leaf_rsa ++ inter, root, "localhost", 0))
    // P-384 leaf under a P-384 CA, ecdsa-with-SHA384 throughout (the
    // example.com chain shape that first refused).
    let ca384 = pem("ca384.pem")
    let leaf384 = pem("leaf384.pem")
    assert(x509_verify_chain_pem(leaf384, ca384, "localhost", now))
    assert(x509_verify_chain_pem(leaf384, ca384, "127.0.0.1", now))
    assert(not x509_verify_chain_pem(leaf384, ca384, "example.com", now))
    assert(not x509_verify_chain_pem(leaf384, root, "localhost", now))
    print("ok")
