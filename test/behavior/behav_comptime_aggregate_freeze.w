//! expect-stdout: ok

type Package {
    values: Vec[i32],
    table: HashMap[str, i32],
    total: i64,
}

comptime fn build_package() -> Package:
    var values = Vec[i32].new()
    values.push(4)
    values.push(8)

    var table = HashMap[str, i32].new()
    table.insert("left", 11)
    table.insert("right", 22)

    Package {
        values: values,
        table: table,
        total: values.len(),
    }

const PACKAGE: Package = comptime build_package()
const PACKAGE_TOTAL: i64 = comptime PACKAGE.total
const PACKAGE_FIRST: i32 = comptime PACKAGE.values.get(0)
const PACKAGE_SECOND: i32 = comptime PACKAGE.values.get(1)
const PACKAGE_LEFT: i32 = comptime PACKAGE.table.get("left")
const PACKAGE_RIGHT: i32 = comptime PACKAGE.table.get("right")

fn main:
    assert(PACKAGE.total == 2)
    assert(PACKAGE.values.get(0) == 4)
    assert(PACKAGE.values.get(1) == 8)
    assert(PACKAGE.table.get("left").unwrap() == 11)
    assert(PACKAGE.table.get("right").unwrap() == 22)
    assert(PACKAGE_TOTAL == 2)
    assert(PACKAGE_FIRST == 4)
    assert(PACKAGE_SECOND == 8)
    assert(PACKAGE_LEFT == 11)
    assert(PACKAGE_RIGHT == 22)
    print("ok")
