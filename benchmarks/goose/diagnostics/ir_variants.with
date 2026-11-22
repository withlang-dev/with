use std.fs
const ROOT = "out/benchmarks/goose/root-causes/"
let blur = read_file(ROOT ++ "blur.stage1.ll").unwrap()
let signature = "@Image.blur(ptr nonnull readonly captures(none) %0, ptr nonnull readonly captures(none) %1) unnamed_addr"
let frame = blur.replace(signature, signature ++ " \"frame-pointer\"=\"all\"")
if frame == blur: panic("signature missing")
if write_file(ROOT ++ "blur.frame.ll", frame) != 0: panic("write failed")
