//! expect-stdout: ok

use BuildGraphModel
use BuildGraphSupport
use BuildGraphCache
use std.fs

fn graph_with_budget(budget: &str):
    let header = "WITH_BUILD_GRAPH\t2\npackage\tordinary-app\t0.1.0\ndefault_target\tapp\ntarget\t0\tapp\tsrc/main.w\t0\t0\tout/app\n"
    parse_build_graph(header ++ budget)

fn main:
    let app = graph_with_budget("")
    assert(app.ok)
    // Recorded WIPE-sized and >32-bit measurements do not impose a policy.
    assert(build_graph_rss_budget_error(app, "app", 1327497216) == "")
    assert(build_graph_rss_budget_error(app, "app", 8589934592) == "")
    let compiler = graph_with_budget("arg\t0\trss-limit-bytes=1073741824\narg\t0\tuser-argument\n")
    assert(compiler.ok)
    assert(compiler.targets[0].rss_limit_bytes == 1073741824)
    assert(compiler.targets[0].args.len() == 1)
    assert(compiler.targets[0].args[0] == "user-argument")
    assert(build_graph_rss_budget_error(compiler, "app", 1073741823) == "")
    assert(build_graph_rss_budget_error(compiler, "app", 1073741824) == "")
    assert(build_graph_rss_budget_error(compiler, "app", 1073741825).contains("limit 1073741824 bytes"))
    assert(build_graph_rss_budget_error(compiler, "app", 8589934592).contains("8589934592 bytes"))
    assert(build_graph_rss_budget_error(compiler, "nested-app", 8589934592) == "")
    let custom = graph_with_budget("arg\t0\trss-limit-bytes=8589934592\n")
    assert(custom.ok)
    assert(build_graph_rss_budget_error(custom, "app", 8589934592) == "")
    assert(build_graph_rss_budget_error(custom, "app", 8589934593).contains("limit 8589934592 bytes"))
    let maximum = graph_with_budget("arg\t0\trss-limit-bytes=9223372036854775807\n")
    assert(maximum.ok)
    assert(maximum.targets[0].rss_limit_bytes == 9223372036854775807)
    let roundtrip = parse_build_graph(build_graph_emit(compiler))
    assert(roundtrip.ok)
    assert(roundtrip.targets[0].rss_limit_bytes == 1073741824)
    let selected = build_graph_filter_single_target(roundtrip, "app")
    assert(selected.ok)
    assert(selected.targets[0].rss_limit_bytes == 1073741824)
    let dir = "out/tmp/rss-budget-cache"
    assert(mkdir_p(dir) == 0)
    build_cache_graph_write(dir, "rss-test", selected)
    let cached = build_cache_graph_try_read(dir, "rss-test")
    assert(cached.ok)
    assert(cached.targets[0].rss_limit_bytes == 1073741824)
    assert(build_graph_rss_budget_error(cached, "app", 1073741825).len() > 0)
    for invalid in ["", "0", "-1", "1x", "9223372036854775808", "999999999999999999999999999999"]:
        let rejected = graph_with_budget("arg\t0\trss-limit-bytes=" ++ invalid ++ "\n")
        assert(not rejected.ok)
        assert(rejected.error_msg.contains("positive i64 byte count"))
    let duplicate = graph_with_budget("arg\t0\trss-limit-bytes=1\narg\t0\trss-limit-bytes=2\n")
    assert(not duplicate.ok)
    print("ok")
