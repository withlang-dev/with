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

    var behavior_tests = target_new(.Test, "behavior-tests", "test/behavior/*.w")
    behavior_tests = behavior_tests.arg("compiler=out/bin/with-stage2")
    behavior_tests = behavior_tests.dep("selfcheck")
    out = out.add_target(behavior_tests)

    var native_compile_error_tests = target_new(.Test, "native-compile-error-tests", "test/compile_errors/*.w")
    native_compile_error_tests = native_compile_error_tests.dep("selfcheck")
    out = out.add_target(native_compile_error_tests)

    var native_codegen_tests = target_new(.Test, "native-codegen-tests", "test/codegen/*.w")
    native_codegen_tests = native_codegen_tests.dep("selfcheck")
    out = out.add_target(native_codegen_tests)

    var native_spec_tests = target_new(.Test, "native-spec-tests", "test/spec/*.w")
    native_spec_tests = native_spec_tests.dep("selfcheck")
    out = out.add_target(native_spec_tests)

    var native_phase_tests = target_new(.Test, "native-phase-tests", "test/phase/*.w")
    native_phase_tests = native_phase_tests.dep("selfcheck")
    out = out.add_target(native_phase_tests)

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
    tests = tests.dep("native-compile-error-tests")
    tests = tests.dep("native-codegen-tests")
    tests = tests.dep("native-spec-tests")
    tests = tests.dep("native-phase-tests")
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

    var regex_test = target_new(.Command, "regex-test", "scripts/verify_pcre2_works.sh")
    regex_test = regex_test.input("scripts/verify_pcre2_works.sh")
    regex_test = regex_test.input("out/bin/with")
    regex_test = regex_test.input("out/pcre2_build/bin/pcre2test")
    regex_test = regex_test.input("out/pcre2_reference/pcre2-10.47/RunTest")
    regex_test = regex_test.dep("verified-existing-stage")
    out = out.add_target(regex_test)

    var regex_check_generated = target_new(.Command, "regex-check-generated", "scripts/pcre2_generated_workflow.sh")
    regex_check_generated = regex_check_generated.input("scripts/pcre2_generated_workflow.sh")
    regex_check_generated = regex_check_generated.input("out/bin/with")
    regex_check_generated = regex_check_generated.input("out/pcre2_build/lib/std/re/defs.w")
    regex_check_generated = regex_check_generated.arg("check")
    regex_check_generated = regex_check_generated.arg("out/bin/with")
    regex_check_generated = regex_check_generated.arg("out/pcre2_build/lib/std/re")
    regex_check_generated = regex_check_generated.dep("verified-existing-stage")
    out = out.add_target(regex_check_generated)

    var regex_promote = target_new(.Command, "regex-promote", "scripts/pcre2_generated_workflow.sh")
    regex_promote = regex_promote.input("scripts/pcre2_generated_workflow.sh")
    regex_promote = regex_promote.input("out/bin/with")
    regex_promote = regex_promote.input("out/pcre2_build/lib/std/re/defs.w")
    regex_promote = regex_promote.arg("promote")
    regex_promote = regex_promote.arg("out/bin/with")
    regex_promote = regex_promote.arg("out/pcre2_build/lib/std/re")
    regex_promote = regex_promote.arg("lib/std/re")
    regex_promote = regex_promote.dep("regex-test")
    regex_promote = regex_promote.dep("regex-check-generated")
    out = out.add_target(regex_promote)

    out.default("verified-existing-stage")
