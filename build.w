use std.build

pub fn build(b: Build) -> Build:
    var out = b

    var selfcheck = target_new(.RunCorpusTest, "selfcheck", "out/bin/with-stage2")
    selfcheck = selfcheck.output("out/corpus/selfcheck")
    selfcheck = selfcheck.arg("check")
    selfcheck = selfcheck.arg("src/main.w")
    out = out.add_target(selfcheck)

    out = out.fixpoint_compare("fixpoint", "out/bin/with-stage2-fixpoint.o", "out/bin/with-stage3-fixpoint.o")

    var verified = target_new(.Group, "verified-existing-stage", "")
    verified = verified.dep("selfcheck")
    verified = verified.dep("fixpoint")
    out = out.add_target(verified)

    out.default("verified-existing-stage")
