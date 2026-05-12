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

    var behavior_tests = target_new(.Command, "behavior-tests", "scripts/run_tests.sh")
    behavior_tests = behavior_tests.input("scripts/run_tests.sh")
    behavior_tests = behavior_tests.dep("selfcheck")
    out = out.add_target(behavior_tests)

    var cli_selfhost_tests = target_new(.Command, "cli-selfhost-tests", "/usr/bin/env")
    cli_selfhost_tests = cli_selfhost_tests.input("scripts/run_cli_selfhost_tests.sh")
    cli_selfhost_tests = cli_selfhost_tests.input("out/bin/with-stage2")
    cli_selfhost_tests = cli_selfhost_tests.arg("WITH=out/bin/with-stage2")
    cli_selfhost_tests = cli_selfhost_tests.arg("scripts/run_cli_selfhost_tests.sh")
    cli_selfhost_tests = cli_selfhost_tests.dep("selfcheck")
    out = out.add_target(cli_selfhost_tests)

    var issue61_regression = target_new(.Command, "issue61-regression", "scripts/run_issue61_noop_local_regression.sh")
    issue61_regression = issue61_regression.input("scripts/run_issue61_noop_local_regression.sh")
    issue61_regression = issue61_regression.dep("selfcheck")
    out = out.add_target(issue61_regression)

    var embedded_runtime_regression = target_new(.Command, "embedded-runtime-regression", "scripts/run_embedded_runtime_extract_regression.sh")
    embedded_runtime_regression = embedded_runtime_regression.input("scripts/run_embedded_runtime_extract_regression.sh")
    embedded_runtime_regression = embedded_runtime_regression.dep("selfcheck")
    out = out.add_target(embedded_runtime_regression)

    var tests = target_new(.Group, "test", "")
    tests = tests.dep("behavior-tests")
    tests = tests.dep("cli-selfhost-tests")
    tests = tests.dep("issue61-regression")
    tests = tests.dep("embedded-runtime-regression")
    out = out.add_target(tests)

    var install_user = target_new(.Install, "install-user", "out/bin/with").output("$HOME/.local/bin/with")
    install_user = install_user.input("out/bin/with")
    install_user = install_user.arg("0755")
    install_user = install_user.dep("verified-existing-stage")
    out = out.add_target(install_user)

    var update_seed = target_new(.Install, "update-seed", "out/bin/with-stage2").output("src/main")
    update_seed = update_seed.input("out/bin/with-stage2")
    update_seed = update_seed.arg("0755")
    update_seed = update_seed.dep("verified-existing-stage")
    out = out.add_target(update_seed)

    out.default("verified-existing-stage")
