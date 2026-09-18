#!/usr/bin/env python3
"""Oracle driver for re_compile audit (rev 450733e5).
Runs each (pattern, modifiers, subject) through system pcre2test 10.47
(one invocation per case: pcre2test modifiers are sticky within a file).
Emits oracle_expected.txt: one line per case with accept/reject, error
code/offset/message, or match outcome. Compare against the With probe
(.audit/probes/re_compile/compile_opts.w) output.
"""
import subprocess, os

HERE = os.path.dirname(os.path.abspath(__file__))
E_ACUTE = "é".encode("utf-8")  # b'\xc3\xa9'

# (tag, pattern_bytes, pcre2test_modifiers, subject_bytes)
CASES = [
    ("plain", b"hello", "", b"hello world"),
    ("ci", b"abc", "i", b"ABC"),
    ("ci-off", b"abc", "", b"ABC"),
    ("ci-class", b"[a-z]+", "i", b"HELLO"),
    ("ml", b"^b", "multiline", b"a\\nb"),
    ("noml", b"^b", "", b"a\\nb"),
    ("ds", b"a.*b", "s", b"a\\nb"),
    ("nods", b"a.*b", "", b"a\\nb"),
    ("ext", b"a b c", "extended", b"abc"),
    ("noext", b"a b c", "", b"abc"),
    ("ungreedy", b"(a+)(b)", "ungreedy", b"aaab"),
    ("greedy", b"(a+)(b)", "", b"aaab"),
    ("utf", "é".encode(), "utf", E_ACUTE),
    ("utf-ascii", b"a", "utf", b"a"),
    ("dupnames-ok", b"(?P<n>a)(?P<n>b)", "dupnames", b"ab"),
    ("anchored", b"b", "anchored", b"ab"),
    ("noanch", b"b", "", b"ab"),
    ("endonly", b"a$", "dollar_endonly", b"a\\n"),
    ("noendonly", b"a$", "", b"a\\n"),
    ("literal", b"a+b", "literal", b"a+b"),
    ("noliteral", b"a+b", "", b"a+b"),
    ("ucp", b"\\w+", "ucp", E_ACUTE),
    ("noucp", b"\\w+", "", E_ACUTE),
    ("no-auto-possess", b"a+b", "no_auto_possess", b"aaab"),
    ("possessive", b"a++b", "", b"aaab"),
    ("allow-empty-class", b"[]b", "allow_empty_class", b"b"),
    ("noallow-empty-class", b"[]b", "", b"b"),
    ("bad-unclosed", b"(abc", "", b"abc"),
    ("bad-class", b"[abc", "", b"abc"),
    ("bad-quant", b"*abc", "", b"abc"),
    ("bad-backref", b"(a)\\2", "", b"aa"),
    ("bad-range", b"a{3,2}", "", b"aaa"),
    ("bad-trailbs", b"abc\\", "", b"abc"),
    ("bad-lonebs", b"\\", "", b""),
    ("bad-lookbehind", b"(?<=a*)b", "", b"ab"),
    ("bad-dupname", b"(?P<n>a)(?P<n>b)", "", b"ab"),
    ("bad-conflict", b"a", "utf,never_utf", b"a"),
    ("bad-bigrange", b"[z-a]", "", b"a"),
    ("bad-varlook", b"(?<=a|bb)c", "", b"abc"),
    ("bad-bigcount", b"a{1,100000}", "", b"a"),
    ("bad-toolarge-utf", b"\\x{110000}", "utf", b"a"),
    ("toolarge-noutf", b"\\x{110000}", "", b"a"),
    ("bad-optset", b"(?i", "", b"a"),
    ("bad-rparen", b"(a))", "", b"aa"),
]

def run_case(tag, pat, mods, subj):
    pat_line = b"/" + pat + b"/" + mods.encode()
    data = pat_line + b"\n" + subj + b"\n"
    inp = os.path.join(HERE, "_o_in.txt")
    outp = os.path.join(HERE, "_o_out.txt")
    with open(inp, "wb") as f:
        f.write(data)
    p = subprocess.run(["pcre2test", inp, outp], capture_output=True, text=True)
    if p.returncode != 0:
        return f"{tag} ORACLE_ERROR rc={p.returncode} stderr={p.stderr.strip()[:120]}"
    with open(outp, "rb") as f:
        out = f.read().decode("utf-8", "replace")
    lines = out.split("\n")
    # line 0: version, line 1: pattern echo
    for ln in lines[2:]:
        if ln.startswith("Failed:"):
            return f"{tag} {ln.strip()}"
        if ln.startswith("**"):
            return f"{tag} ORACLE_MODIFIER_REJECT {ln.strip()}"
        if ln.startswith(" 0:") or ln == "No match":
            return f"{tag} COMPILE_OK {ln.strip()}"
    return f"{tag} ORACLE_UNPARSED {out.strip()[:200]!r}"

def main():
    results = [run_case(t, p, m, s) for (t, p, m, s) in CASES]
    with open(os.path.join(HERE, "oracle_expected.txt"), "w") as f:
        f.write("\n".join(results) + "\n")
    print("\n".join(results))

if __name__ == "__main__":
    main()
