//! expect-stdout: ok
// M8 (Slice F): a Drop value held across a suspend (await) drops exactly once.

type Resource { id: i32, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id

fn consume(r: Resource): ()

async fn ping() -> i32:
    1

async fn struct_across(slot: *mut i32) -> i32:
    let r = Resource { id: 1, slot }   // live across the suspend
    let x = ping().await
    consume(r)
    x

async fn list_across(slot: *mut i32) -> i32:
    var v: List[Resource] = List.new()
    v.push(Resource { id: 1, slot })
    v.push(Resource { id: 1, slot })
    let x = ping().await
    v.len() as i32

async fn main:
    var drops = 0
    let a = struct_across(&raw mut drops).await
    let b = list_across(&raw mut drops).await
    assert(a == 1)
    assert(b == 2)
    assert(drops == 3)
    print("ok")
