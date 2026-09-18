#!/usr/bin/env python3
"""Oracle comparator for re_engines/match_matrix.
Compares With port output (match_matrix.out) vs python3 re (bytes mode)
and system pcre2test 10.47 (same upstream version as the port).
"""
import json, re, subprocess, sys

CASES = [
    # (pattern_bytes, subject_bytes, copts)
    (b"abc", b"xabcdef", 0),
    (b"hello, (\\w+)!", b"hello, world!", 0),
    (b"[a-z]+", b"abcXYZ", 0),
    (b"[^0-9]+", b"ab12", 0),
    (b"\\d+", b"ab12cd", 0),
    (b"a{2,3}", b"aaaa", 0),
    (b"a+?", b"aaaa", 0),
    (b"a++", b"aaaa", 0),          # possessive: python re cannot do this
    (b"a++b", b"aaab", 0),         # possessive: python re cannot do this
    (b"a+?b", b"aaab", 0),
    (b"colou?r", b"colour", 0),
    (b"a*", b"bbb", 0),
    (b"a+", b"bbb", 0),
    (b"^abc$", b"abc", 0),
    (b"^abc$", b"xabc", 0),
    (b"abc$", b"xabc", 0),
    (b"\\bfoo\\b", b"foo bar", 0),
    (b"\\bfoo\\b", b"foobar", 0),
    (b"(a|b)\\1", b"aa", 0),
    (b"(a|b)\\1", b"ab", 0),
    (b"(a)(b)(c)", b"abc", 0),
    (b"(?:ab)+", b"ababab", 0),
    (b"(?P<w>\\w+)", b"hi there", 0),
    (b"cat|dog", b"dog", 0),
    (b"a|ab", b"ab", 0),
    (b"foo(?=bar)", b"foobar", 0),
    (b"foo(?=bar)", b"foobaz", 0),
    (b"(?<=foo)bar", b"foobar", 0),
    (b"foo(?!bar)", b"foobaz", 0),
    (b"foo(?!bar)", b"foobar", 0),
    (b"()", b"abc", 0),
    (b"x?", b"abc", 0),
    (b"", b"abc", 0),
    (b"a*", b"", 0),
    (b"(a)?b\\1", b"b", 0),
    (b"(", b"abc", 0),             # compile error expected
    (b"a{2,1}", b"a", 0),          # compile error expected
    (b"\xc3\xa9", "caf\xc3\xa9 x".encode("latin1"), 0x00080000),  # UTF
]
PY_SKIP = {7, 8}  # possessive quantifiers: unsupported by python re

def parse_with(path):
    text = open(path).read().split()
    # tokens: CASE i RC <n|NOMATCH n|COMPILEFAIL ec eo> [OV s e ...]
    cases = {}
    i = 0
    while i < len(text):
        assert text[i] == "CASE", text[i]
        idx = int(text[i + 1]); i += 2
        assert text[i] == "RC", text[i]
        if text[i + 1] == "NOMATCH":
            cases[idx] = ("nomatch", int(text[i + 2])); i += 3
        elif text[i + 1] == "COMPILEFAIL":
            cases[idx] = ("fail", int(text[i + 2]), int(text[i + 3])); i += 4
        else:
            rc = int(text[i + 1]); i += 2
            assert text[i] == "OV", text[i]; i += 1
            spans = []
            for _ in range(rc):
                s, e = int(text[i]), int(text[i + 1]); i += 2
                spans.append((s, e))
            cases[idx] = ("match", spans)
    return cases

def py_oracle(pat, subj):
    try:
        m = re.compile(pat).search(subj)
    except re.error:
        return ("fail",)
    if m is None:
        return ("nomatch",)
    return ("match", [m.span(k) for k in range(0, len(m.groups()) + 1)
                      if k <= m.re.groups])

def pcre2test_oracle():
    # one invocation per case (batch mode echoes input and merges groups
    # across patterns, so per-case runs with strict line filtering instead).
    # Returns list idx -> ("match", [texts]) | ("nomatch",) | ("fail",) | ("na",).
    results = []
    for idx, (pat, subj, copts) in enumerate(CASES):
        if subj == b"":
            results.append(("na",))  # pcre2test skips blank subject lines
            continue
        opt = b"utf" if copts else b""
        blob = b"/" + pat + b"/" + opt + b"\n    " + subj + b"\n"
        p = subprocess.run(["/home/linuxbrew/.linuxbrew/bin/pcre2test"],
                           input=blob, capture_output=True)
        out = p.stdout.decode("utf-8", "replace").splitlines()
        groups = [l for l in out if re.match(r"^ *[0-9]+: ", l)]
        if any(l.startswith("Failed:") for l in out):
            results.append(("fail",))
        elif "No match" in out:
            assert not groups, (idx, out)
            results.append(("nomatch",))
        else:
            assert groups, (idx, out)
            # pcre2test escapes non-ASCII as \x{<codepoint hex>}; unescape to
            # the character so UTF-mode matches compare by character.
            texts = [re.sub(r"\\x\{([0-9a-fA-F]+)\}",
                            lambda m: chr(int(m.group(1), 16)),
                            l.split(": ", 1)[1] if ": " in l else "")
                     for l in groups]
            results.append(("match", texts))
    return results

def main():
    withres = parse_with(".audit/probes/re_engines/match_matrix.out")
    p2res = pcre2test_oracle()
    fails = 0
    for idx, (pat, subj, copts) in enumerate(CASES):
        w = withres[idx]
        tag = f"case {idx} pat={pat!r} subj={subj!r}"
        # 1. vs pcre2test (same version: strongest oracle)
        p2 = p2res[idx] if idx < len(p2res) else ("?",)
        if p2[0] == "na":
            pass  # empty subject: pcre2test cannot express it; python covers it
        elif w[0] == "match" and p2[0] == "match":
            wtexts = [subj[s:e].decode("utf-8", "replace") if s >= 0 else "<unset>"
                      for (s, e) in w[1]]
            if wtexts != p2[1]:
                print(f"MISMATCH(pcre2test-text) {tag}: with={wtexts} pcre2test={p2[1]}")
                fails += 1
        elif p2[0] != "na" and w[0] != p2[0] and not (w[0] == "fail" and p2[0] == "fail"):
            # status class must agree (match vs nomatch vs fail)
            print(f"MISMATCH(pcre2test-status) {tag}: with={w[0]} pcre2test={p2[0]}")
            fails += 1
        # 2. vs python re (offsets, where supported; bytes mode also covers UTF)
        if idx not in PY_SKIP:
            py = py_oracle(pat, subj)
            if w[0] == "match" and py[0] == "match":
                if list(w[1]) != list(py[1]):
                    print(f"MISMATCH(py-spans) {tag}: with={w[1]} py={py[1]}")
                    fails += 1
            elif (w[0] == "match") != (py[0] == "match"):
                if not (w[0] == "fail" or py[0] == "fail"):
                    print(f"MISMATCH(py-status) {tag}: with={w[0]} py={py[0]}")
                    fails += 1
            elif w[0] == "fail" and py[0] != "fail":
                print(f"MISMATCH(py-compile) {tag}: with fails, py compiles")
                fails += 1
            elif py[0] == "fail" and w[0] != "fail":
                print(f"MISMATCH(py-compile) {tag}: py fails, with={w[0]}")
                fails += 1
    print(f"pcre2test cases parsed: {len(p2res)}/{len(CASES)}")
    print("FAILURES:", fails)
    return 1 if fails else 0

sys.exit(main())
