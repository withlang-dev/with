//! expect-stdout: 1.5
//! expect-stdout: true true false
//! expect-stdout: 7 1
//! expect-stdout: -1 2 NaN
//! expect-stdout: true false
// D97 (#2182, §11.7): TotalF64 is a float key. `==` is numeric except that
// every NaN equals every NaN and -0.0 equals 0.0; the order is the float
// order with NaN above every number.
use std.collections
use std.traits.TotalF64

let nan = 0.0 / 0.0
print(TotalF64(1.5).value)
print(f"{TotalF64(nan) == TotalF64(nan)} {TotalF64(0.0) == TotalF64(-0.0)} {TotalF64(1.0) == TotalF64(2.0)}")

var counts: HashMap[TotalF64, i32] = HashMap.new()
counts.insert(TotalF64(-0.0), 7)
counts.insert(TotalF64(nan), 1)
print(f"{counts.get(TotalF64(0.0)) ?? 0} {counts.get(TotalF64(nan)) ?? 0}")

var ordered: BTreeSet[TotalF64] = BTreeSet.new()
ordered.insert(TotalF64(nan))
ordered.insert(TotalF64(2.0))
ordered.insert(TotalF64(-1.0))
var shown = ""
for v in ordered: shown = shown ++ (if shown.len() > 0: " " else: "") ++ (if v.value != v.value: "NaN" else: f"{v.value}")
print(shown)

print(f"{TotalF64(1.0) < TotalF64(nan)} {TotalF64(nan) < TotalF64(1.0)}")
