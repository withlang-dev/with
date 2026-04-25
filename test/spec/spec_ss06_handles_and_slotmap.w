//! skip
// Spec test: Section 6 — Handles and SlotMap (formerly 25.8)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: handle type mismatch
fn test:
    var textures = SlotMap[Texture].new()
    var meshes = SlotMap[Mesh].new()
    let h = textures.insert(Texture.default())
    meshes.get(h)                 // ERROR: Handle[Texture] vs Handle[Mesh]

// PASS: get2_mut
fn test:
    var map = SlotMap[i32].new()
    let a = map.insert(10)
    let b = map.insert(20)
    match map.get2_mut(a, b):
        Some((va, vb)) => { *va += 1; *vb += 1 }
        None => ()

// PASS: handles in containers
fn test:
    var map = SlotMap[String].new()
    let h1 = map.insert("hello")
    let h2 = map.insert("world")
    let handles = vec![h1, h2]    // OK: Copy, storable
