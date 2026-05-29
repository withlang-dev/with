//! expect-check-fail: argument 1 expects Handle[Mesh]
type Texture:
    id: i32

fn Texture.default() -> Texture:
    Texture { id: 0 }

type Mesh:
    id: i32

fn Mesh.default() -> Mesh:
    Mesh { id: 0 }

fn main:
    var textures = SlotMap[Texture].new()
    var meshes = SlotMap[Mesh].new()
    let h = textures.insert(Texture.default())
    meshes.get(h)
