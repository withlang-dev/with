#!/usr/bin/env python3
"""Decode compile_error_texts from lib/std/re/pcre2_error.w and check the
messages for the error codes exercised by the re_compile probe against the
pcre2test oracle (oracle_expected.txt). Usage: python3 check_messages.py.
Exit 0 iff every checked code's text matches the oracle byte-for-byte.
"""
import re, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ERR_W = "/home/shawn/workspace2/with/lib/std/re/pcre2_error.w"

src = open(ERR_W).read()
m = re.search(r"let compile_error_texts: \[\d+\]u8 = \[([0-9, ]+)\]", src)
assert m, "table not found"
nums = [int(x) for x in m.group(1).split(",")]
raw = bytes(nums)
entries = raw.split(b"\x00")
# entry[i] corresponds to compile error code 100+i (entry[0] = "no error")
table = {100 + i: e.decode() for i, e in enumerate(entries) if e}

# code -> oracle message (from oracle_expected.txt / pcre2grep runs)
EXPECTED = {
    101: "\\ at end of pattern",          # pcre2grep (pcre2test cannot express)
    117: "unrecognised compile-time option bit(s)",  # optbit_oracle (raw bit)
    104: "numbers out of order in {} quantifier",
    105: "number too big in {} quantifier",
    106: "missing terminating ] for character class",
    108: "range out of order in character class",
    109: "quantifier does not follow a repeatable item",
    114: "missing closing parenthesis",
    115: "reference to non-existent subpattern",
    122: "unmatched closing parenthesis",
    125: "length of lookbehind assertion is not limited",
    134: "character code point value in \\x{} or \\o{} is too large",
    143: "two named subpatterns have the same name (PCRE2_DUPNAMES not set)",
    174: "using UTF is disabled by the application",
}

fails = 0
for code, want in sorted(EXPECTED.items()):
    got = table.get(code)
    status = "OK " if got == want else "MISMATCH"
    if got != want:
        fails += 1
    print(f"{status} {code}: port={got!r} oracle={want!r}")
print(f"table entries: {len(table)}, array bytes: {len(nums)}")
sys.exit(1 if fails else 0)
