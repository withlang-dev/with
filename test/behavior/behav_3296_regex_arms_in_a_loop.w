//! expect-stdout: 1 0 0
//! expect-stdout: 1 1
//! expect-stdout: 1 1 1 1 1 1
// #3296: a later regex arm's compiled pattern is written only when the arms
// before it fail. It was dropped at the match's end on every path, so the
// path of an earlier arm dropped storage never written: a segfault in a
// loop, `unwrap on None` in pcre2_code_free, a freed constant.

fn first_arm_only:
    var a = 0
    var b = 0
    var c = 0
    for s in ["aaa"]:
        match s:
            /^a/ => a += 1
            /^b/ => b += 1
            /^c/ => c += 1
    print(f"{a} {b} {c}")

fn no_wildcard:
    var proven = 0
    var stated = 0
    for prov in ["proof@a.w:1", "claim: stated@a.w:2", "default:x"]:
        match prov:
            /^proof@/         => proven += 1
            /^claim: stated@/ => stated += 1
    print(f"{proven} {stated}")

fn six_arms:
    var n = [0, 0, 0, 0, 0, 0]
    for prov in ["claim: profile:p:r@v.w:1", "proof@a", "evidence@b", "claim: stated@c", "claim: registry@d", "claim: annotation@e", "default:x"]:
        match prov:
            /^proof@/             => n[0] += 1
            /^evidence@/          => n[1] += 1
            /^claim: stated@/     => n[2] += 1
            /^claim: registry@/   => n[3] += 1
            /^claim: annotation@/ => n[4] += 1
            /^claim: profile:/    => n[5] += 1
            _                     => {}
    print(f"{n[0]} {n[1]} {n[2]} {n[3]} {n[4]} {n[5]}")

fn main:
    first_arm_only()
    no_wildcard()
    six_arms()
