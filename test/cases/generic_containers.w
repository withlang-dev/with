// Test: generic functions over container types (Vec[T], HashMap[K, V])

fn push_item[T](v: Vec[T], x: T) -> Vec[T] =
    var out = v
    out.push(x)
    out

fn vec_len[T](v: Vec[T]) -> i64 =
    v.len()

fn map_len[K, V](m: HashMap[K, V]) -> i64 =
    m.len()

fn main() -> i32 =
    var nums: Vec[i32] = Vec.new()
    nums = push_item(nums, 10)
    nums = push_item(nums, 20)
    assert(vec_len(nums) == 2)
    assert(nums.get(0) == 10)
    assert(nums.get(1) == 20)

    var m: HashMap[str, i32] = HashMap.new()
    m.insert("a", 1)
    m.insert("b", 2)
    assert(map_len(m) == 2)

    0
