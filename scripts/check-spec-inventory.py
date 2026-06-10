#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys


SPEC = Path("docs/with-specification.md")
TOKEN = Path("src/Token.w")
PARSER = Path("src/Parser.w")
MAIN = Path("src/main.w")
DRIVER_OPTIONS = Path("src/compiler/DriverOptions.w")
STD = Path("lib/std")


# Spec-ahead items with dedicated implementation issues. These are not a
# generic ignore bucket; each entry is a known open issue from the Phase plan.
KNOWN_MISSING_FLAGS = {
    "--target": "#425",
    "--open": "#537",
}

KNOWN_MISSING_MODULES = {
    "std.os": "#476",
}

KNOWN_MISSING_ATTRIBUTES = {
    "ffi_stack": "§14.19 roadmap",
    "align": "#449",
    "repr": "#449",
    "target": "#479",
}

IMPLEMENTATION_INTERNAL_COMMANDS = {
    "ast",
    "bench",
    "clean",
    "get",
    "install-user",
    "ir",
    "lsp",
    "remove",
    "tokens",
}

IMPLEMENTATION_INTERNAL_FLAGS = {
    "--alloc",
    "--check",
    "--c-export-functions",
    "--convert-goto-to-structured",
    "--deterministic",
    "--diff",
    "--dry-run",
    "--dump-ast",
    "--dump-async-mir",
    "--dump-mir",
    "--dump-project-info",
    "--dump-resolved",
    "--dump-tokens",
    "--dump-typed",
    "--exclude",
    "--explain",
    "--filter",
    "--force",
    "--force-reinstall",
    "--freestanding",
    "--graph",
    "--help",
    "--ir-roundtrip",
    "--lib",
    "--migrate-one",
    "--name",
    "--no-c-export",
    "--no-deps",
    "--no-prelude",
    "--no-runtime",
    "--output",
    "--prefer-brace",
    "--prefer-colon",
    "--prefer-curly",
    "--prelude",
    "--quiet",
    "--shared-defs",
    "--shared-fragment",
    "--stats",
    "--verbose",
    "--width-slice",
    "--version",
    "-f",
    "-D",
    "-g0",
    "-h",
    "-I",
    "-include",
    "-l",
    "-o",
    "-q",
    "-v",
    "-w",
}

IMPLEMENTATION_INTERNAL_MODULES = {
    "std.builtins",
    "std.channel",
    "std.cfg",
    "std.async",
    "std.compiler",
    "std.component",
    "std.iter",
    "std.libc",
    "std.option",
    "std.prelude",
    "std.prelude_alloc",
    "std.prelude_core",
    "std.re",
    "std.result",
    "std.str",
    "std.str_abi",
    "std.sys",
    "std.sysinfo",
    "std.task",
    "std.tls",
    "std.traits",
}


def section(text: str, heading: str) -> str:
    start = text.find(heading)
    if start < 0:
        raise ValueError(f"missing spec heading {heading}")
    next_heading = re.search(r"\n##\s+", text[start + 1 :])
    if not next_heading:
        return text[start:]
    return text[start : start + 1 + next_heading.start()]


def subsection(text: str, heading: str) -> str:
    start = text.find(heading)
    if start < 0:
        raise ValueError(f"missing spec heading {heading}")
    next_heading = re.search(r"\n###\s+|\n##\s+", text[start + 1 :])
    if not next_heading:
        return text[start:]
    return text[start : start + 1 + next_heading.start()]


def spec_keywords(spec: str) -> set[str]:
    sec = subsection(spec, "### 29.11 Reserved Keywords")
    match = re.search(r"```\n(.*?)\n```", sec, re.S)
    if not match:
        raise ValueError("missing keyword code block")
    return set(match.group(1).split())


def impl_keywords() -> set[str]:
    text = TOKEN.read_text(encoding="utf-8")
    return set(re.findall(r'if s == "([^"]+)": return', text))


def attr_names(cell: str) -> set[str]:
    return set(re.findall(r"@\[([A-Za-z_][A-Za-z0-9_]*)", cell))


def spec_attributes(spec: str) -> tuple[set[str], set[str]]:
    sec = subsection(spec, "### 29.14 Attribute Index")
    public: set[str] = set()
    internal: set[str] = set()
    lines = sec.splitlines()
    for idx, line in enumerate(lines):
        if line.startswith("| `@["):
            first_cell = line.strip("|").split("|", 1)[0]
            public |= attr_names(first_cell)
        if line.startswith("**Implementation-internal"):
            paragraph = [line]
            for extra in lines[idx + 1 :]:
                if not extra.strip():
                    break
                paragraph.append(extra)
            internal |= attr_names(" ".join(paragraph))
    return public, internal


def impl_attributes() -> set[str]:
    text = PARSER.read_text(encoding="utf-8")
    start = text.find("fn Parser.skip_attributes")
    end = text.find("// ── Module parsing", start)
    if start >= 0 and end > start:
        text = text[start:end]
    names = set(re.findall(r'is_ident_named\("([^"]+)"\)', text))
    names |= set(re.findall(r'attr_text == "([^"]+)"', text))
    return names


def spec_cli(spec: str) -> tuple[set[str], set[str]]:
    sec = subsection(spec, "### 18.5 Toolchain")
    commands = {"version", "help"}
    flags = {"--release", "--target", "--emit-c", "--emit-obj", "--overflow", "--no-std", "-O0", "-O1", "-O2", "-O3", "--open", "-e", "-n", "-p"}
    block = re.search(r"```\n(.*?)\n```", sec, re.S)
    if block:
        for line in block.group(1).splitlines():
            stripped = line.strip()
            if not stripped.startswith("with "):
                continue
            body = stripped[5:].split("#", 1)[0].strip()
            for part in body.split("|"):
                part = part.strip()
                if part.startswith("with "):
                    part = part[5:].strip()
                token = part.split()[0] if part else ""
                if token and not token.startswith("[") and not token.startswith("-"):
                    commands.add(token)
    return commands, flags


def impl_commands() -> set[str]:
    text = MAIN.read_text(encoding="utf-8")
    return {cmd for cmd in re.findall(r'cli_command\(argc\) == "([^"]+)"', text) if not cmd.startswith("-")}


def impl_flags() -> set[str]:
    text = MAIN.read_text(encoding="utf-8") + "\n" + DRIVER_OPTIONS.read_text(encoding="utf-8")
    flags = set(re.findall(r'"(-{1,2}[A-Za-z0-9][A-Za-z0-9-]*)(?:[=<][^"]*)?"', text))
    flags |= set(re.findall(r'arg == "(-O[0-3])"', text))
    return flags


def spec_modules(spec: str) -> set[str]:
    sec = subsection(spec, "#### Module Map")
    return set(re.findall(r"`(std\.[A-Za-z0-9_]+)`", sec))


def impl_modules() -> set[str]:
    modules: set[str] = set()
    for path in STD.iterdir():
        if path.name.startswith("."):
            continue
        if path.is_file() and path.suffix == ".w":
            modules.add("std." + path.stem)
        elif path.is_dir():
            modules.add("std." + path.name)
    if (STD / "internal" / "str_abi.w").exists():
        modules.add("std.str_abi")
    return modules


def add_set_errors(errors: list[str], label: str, missing: set[str], extra: set[str]) -> None:
    for item in sorted(missing):
        errors.append(f"{label}: missing {item}")
    for item in sorted(extra):
        errors.append(f"{label}: implementation has unspec'd {item}")


def main() -> int:
    spec = SPEC.read_text(encoding="utf-8")
    errors: list[str] = []

    add_set_errors(errors, "keywords", spec_keywords(spec) - impl_keywords(), impl_keywords() - spec_keywords(spec))

    spec_public_attrs, spec_internal_attrs = spec_attributes(spec)
    allowed_attrs = spec_public_attrs | spec_internal_attrs
    missing_attrs = {attr for attr in allowed_attrs - impl_attributes() if attr not in KNOWN_MISSING_ATTRIBUTES}
    add_set_errors(errors, "attributes", missing_attrs, impl_attributes() - allowed_attrs)

    spec_cmds, spec_stable_flags = spec_cli(spec)
    impl_cmds = impl_commands()
    missing_cmds = spec_cmds - impl_cmds
    extra_cmds = impl_cmds - spec_cmds - IMPLEMENTATION_INTERNAL_COMMANDS
    add_set_errors(errors, "cli commands", missing_cmds, extra_cmds)

    impl_flag_set = impl_flags()
    missing_flags = {flag for flag in spec_stable_flags - impl_flag_set if flag not in KNOWN_MISSING_FLAGS}
    extra_flags = impl_flag_set - spec_stable_flags - IMPLEMENTATION_INTERNAL_FLAGS
    add_set_errors(errors, "cli flags", missing_flags, extra_flags)

    spec_mods = spec_modules(spec)
    impl_mods = impl_modules()
    missing_mods = {mod for mod in spec_mods - impl_mods if mod not in KNOWN_MISSING_MODULES}
    extra_mods = impl_mods - spec_mods - IMPLEMENTATION_INTERNAL_MODULES
    add_set_errors(errors, "stdlib modules", missing_mods, extra_mods)

    if errors:
        for error in errors:
            print(f"spec inventory: {error}", file=sys.stderr)
        if KNOWN_MISSING_FLAGS or KNOWN_MISSING_MODULES or KNOWN_MISSING_ATTRIBUTES:
            known = {**KNOWN_MISSING_FLAGS, **KNOWN_MISSING_MODULES, **KNOWN_MISSING_ATTRIBUTES}
            for item, issue in sorted(known.items()):
                print(f"spec inventory: known spec-ahead {item} tracked by {issue}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
