use std.build

pub fn build(ctx: BuildCtx) -> Build:
    var out = ctx.new_build()
    out = out.copy_file("left-producer", "seed.bin", "out/left.bin")
    out = out.copy_file("right-producer", "seed.bin", "out/right.bin")
    out = out.binary_compare("compare", "out/left.bin", "out/right.bin")

    var extra_producer = target_new(.GenerateResponseFile, "extra-producer", "")
    extra_producer = extra_producer.output("out/primary.rsp")
    extra_producer = extra_producer.extra_output("out/extra.bin")
    extra_producer = extra_producer.arg("same")
    out = out.add_target(extra_producer)
    out = out.copy_file("extra-consumer", "out/extra.bin", "out/extra-copy.bin")

    out = out.executable("default-producer", "main.w")
    out = out.copy_file("default-consumer", "out/bin/default-producer", "out/default-copy.bin")

    out = out.copy_file("alias-producer", "seed.bin", "out/alias.bin")
    out = out.copy_file("alias-consumer", "./out/alias.bin", "out/alias-copy.bin")
    out.default("compare")
