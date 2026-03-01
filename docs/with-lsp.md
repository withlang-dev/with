# `with lsp` — Language Server & Editor Support

## 1. Architecture

```
VSCode extension (TypeScript, ~200 lines)
    │
    │  stdio
    │
with lsp (With binary, ships with the compiler)
    │
    ├── Parser (shared with compiler)
    ├── Type checker (shared with compiler)
    ├── Borrow checker (shared with compiler)
    └── LSP protocol handler
```

The language server is a subcommand of the `with` binary. Not a
separate binary. Not a separate install. `with lsp` starts the
server. The VSCode extension launches it and talks to it over
stdio.

The server reuses the compiler's frontend — same parser, same
type checker, same borrow checker. This is non-negotiable. If
the LSP has a different parser than the compiler, diagnostics
will disagree. One parser, two consumers.

---

## 2. What to Ship at Launch

Not everything. Just enough that people don't reach for another
editor. Prioritized by "what makes someone close the browser
tab and keep coding":

### 2.1 Must-Have (Launch)

**Syntax highlighting.** TextMate grammar in the VSCode extension.
This doesn't need the LSP at all — it's a regex-based `.tmLanguage`
file. Keywords, strings, comments, numbers, types, functions.
Covers 90% of the visual experience.

**Diagnostics (errors and warnings).** The LSP runs the compiler
frontend on every save (or on every keystroke with debouncing)
and pushes diagnostics. Red squiggles under type errors, borrow
violations, unknown names. This is the #1 reason people use an
LSP. Without it, the edit-save-compile cycle is painful.

**Go to definition.** Click a function name, jump to where it's
defined. Click a type name, jump to the type. Click an import,
jump to the file. This requires the LSP to maintain a symbol
table with source locations.

**Hover for type info.** Hover over a variable, see its type.
Hover over a function call, see its signature. This is the type
checker outputting what it already knows. Low implementation cost,
high usability impact.

**Basic autocomplete.** When you type `foo.`, suggest the fields
and methods of `foo`'s type. When you type a partial name, suggest
matching names in scope. This requires the type checker to answer
"what's in scope at this cursor position" — which is the hardest
part of an LSP, but a basic version (complete from current file +
imports) is manageable.

### 2.2 Nice-to-Have (Soon After)

**Find all references.** Where is this function called? Where is
this type used? Inverse of go-to-definition. Requires a full
project index.

**Rename symbol.** Rename a variable/function/type across all
files. Requires find-all-references plus edit generation.

**Signature help.** While typing function arguments, show the
parameter names and types. Triggered by `(` and `,`.

**Document symbols.** The outline panel in VSCode — list of
functions, types, and constants in the current file.

**Format on save.** Run `with fmt` on the file automatically.
Since the formatter is non-configurable, this is simple: call
the formatter, replace the buffer.

### 2.3 Later

**Inlay hints.** Show inferred types inline:
`let x /* : i32 */ = foo()`. Useful but divisive — some people
hate visual noise.

**Code actions.** "Import this symbol," "add missing match arm,"
"convert to `with` block." These are the IDE magic moments but
each one is a custom implementation.

**Semantic highlighting.** Replace the TextMate grammar with
LSP-driven token coloring. Mutable variables in a different
color. Comptime code in a different color. Higher quality than
regex highlighting but the TextMate grammar is good enough for
launch.

**Workspace-wide diagnostics.** Check the entire project, not
just open files. Requires background compilation.

---

## 3. Implementation

### 3.1 The LSP Binary

`with lsp` is a long-running process that speaks JSON-RPC over
stdio. It handles:

```
initialize          → report capabilities
textDocument/didOpen    → parse file, send diagnostics
textDocument/didChange  → re-parse, re-check, send diagnostics
textDocument/didSave    → full check, send diagnostics
textDocument/completion → autocomplete at cursor
textDocument/definition → go to definition
textDocument/hover      → type info at cursor
textDocument/formatting → run with fmt
shutdown / exit         → clean up
```

The protocol is standardized. The With-specific work is:

1. **Incremental re-parsing.** When a file changes, don't re-parse
   the entire project. Re-parse the changed file, re-check it
   against the existing symbol table, push diagnostics. Full
   project re-check on save.

2. **Error-tolerant parsing.** The compiler parser can bail on the
   first error. The LSP parser must not — it needs to produce a
   partial AST from broken code so that autocomplete and hover
   still work in the rest of the file. This is the main difference
   between the compiler frontend and the LSP frontend. Either make
   the parser error-tolerant from the start (recommended) or
   maintain a separate recovery layer for the LSP.

3. **Symbol index.** A map from name → (location, type, kind) for
   every symbol in the project. Built on first open, updated
   incrementally. This powers go-to-definition, find-references,
   autocomplete, and hover.

### 3.2 Error-Tolerant Parsing

This is the hardest engineering problem in the LSP. When the user
is mid-keystroke, the code is broken. The parser must:

- Parse what it can
- Skip what it can't
- Produce an AST with holes
- Still resolve types and scopes around the holes

Strategy: when the parser hits an unexpected token, it enters
recovery mode. It skips tokens until it finds a synchronization
point (a newline at the same or lower indentation level, a
keyword like `fn` or `type` or `let`), inserts an error node in
the AST, and continues parsing.

Since With uses indentation, synchronization is natural — a line
at the same indentation as the previous statement is probably a
new statement. This is actually easier than brace-based languages
where recovery requires matching brace depth.

### 3.3 Performance Targets

| Operation | Target | Notes |
|-----------|--------|-------|
| Diagnostics after keystroke | <100ms | Debounce 150ms, then check |
| Go to definition | <50ms | Symbol table lookup |
| Autocomplete | <100ms | Scope query + type lookup |
| Hover | <30ms | Direct type table lookup |
| Full project re-check | <2s | On save, background thread |
| Format file | <50ms | Already fast, it's `with fmt` |

For a project under 50 files (which covers 99% of With projects
at launch), these targets are easy to hit. The compiler already
parses and type-checks fast because it emits C. The LSP reuses
the same frontend.

---

## 4. VSCode Extension

### 4.1 Structure

```
with-vscode/
├── package.json           # extension manifest
├── language-configuration.json
├── syntaxes/
│   └── with.tmLanguage.json   # TextMate grammar
├── src/
│   └── extension.ts       # ~100 lines: start LSP, done
├── README.md
└── icon.png
```

The extension is thin. It does three things:

1. Register the `.w` file extension
2. Provide a TextMate grammar for syntax highlighting
3. Launch `with lsp` and connect via stdio

That's it. All intelligence lives in the LSP binary.

### 4.2 `package.json` (Key Fields)

```json
{
  "name": "with-lang",
  "displayName": "With",
  "description": "With language support",
  "version": "0.1.0",
  "engines": { "vscode": "^1.80.0" },
  "categories": ["Programming Languages"],
  "activationEvents": ["onLanguage:with"],
  "main": "./out/extension.js",
  "contributes": {
    "languages": [{
      "id": "with",
      "aliases": ["With"],
      "extensions": [".w"],
      "configuration": "./language-configuration.json"
    }],
    "grammars": [{
      "language": "with",
      "scopeName": "source.with",
      "path": "./syntaxes/with.tmLanguage.json"
    }],
    "configuration": {
      "title": "With",
      "properties": {
        "with.lsp.path": {
          "type": "string",
          "default": "with",
          "description": "Path to the with binary"
        }
      }
    }
  }
}
```

### 4.3 `extension.ts`

```typescript
import { workspace, ExtensionContext } from 'vscode';
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: ExtensionContext) {
  const command = workspace
    .getConfiguration('with.lsp')
    .get<string>('path', 'with');

  const serverOptions: ServerOptions = {
    command: command,
    args: ['lsp'],
  };

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'with' }],
  };

  client = new LanguageClient(
    'with-lsp',
    'With Language Server',
    serverOptions,
    clientOptions,
  );

  client.start();
}

export function deactivate(): Thenable<void> | undefined {
  return client?.stop();
}
```

That's the entire extension logic. ~30 lines. Everything else
is the TextMate grammar.

### 4.4 TextMate Grammar (Key Scopes)

```json
{
  "scopeName": "source.with",
  "patterns": [
    { "include": "#comments" },
    { "include": "#strings" },
    { "include": "#keywords" },
    { "include": "#types" },
    { "include": "#functions" },
    { "include": "#numbers" },
    { "include": "#operators" }
  ],
  "repository": {
    "keywords": {
      "match": "\\b(fn|let|var|type|use|if|else|match|for|while|return|break|continue|and|or|not|in|as|mut|pub|impl|trait|extend|defer|with|comptime|const|true|false|async|await|extern|unsafe|gen|yield|spawn|error|select|scope|move|where)\\b",
      "name": "keyword.control.with"
    },
    "types": {
      "match": "\\b(i8|i16|i32|i64|u8|u16|u32|u64|f32|f64|bool|str|Unit|usize|isize|Self|Option|Result|Vec|HashMap|Box)\\b",
      "name": "entity.name.type.with"
    },
    "functions": {
      "match": "\\b(fn)\\s+([a-zA-Z_][a-zA-Z0-9_]*)\\b",
      "captures": {
        "1": { "name": "keyword.control.with" },
        "2": { "name": "entity.name.function.with" }
      }
    },
    "strings": {
      "begin": "\"",
      "end": "\"",
      "name": "string.quoted.double.with",
      "patterns": [
        {
          "match": "\\{[^}]+\\}",
          "name": "constant.other.placeholder.with"
        },
        {
          "match": "\\\\.",
          "name": "constant.character.escape.with"
        }
      ]
    },
    "comments": {
      "match": "//.*$",
      "name": "comment.line.double-slash.with"
    },
    "numbers": {
      "match": "\\b[0-9]+(\\.[0-9]+)?\\b",
      "name": "constant.numeric.with"
    }
  }
}
```

This is a starter grammar. It handles the basics: keywords light
up, strings are colored, interpolation `{expr}` inside strings
gets its own color, function definitions are highlighted. Enough
to make `.w` files look like code instead of plain text.

---

## 5. Shipping

### 5.1 VSCode Marketplace

Publish as `with-lang` on the VSCode Marketplace. Free. Requires
a Microsoft/Azure DevOps account.

```
$ cd with-vscode
$ npx vsce package        # creates with-lang-0.1.0.vsix
$ npx vsce publish        # pushes to marketplace
```

Users install via: search "With" in VSCode extensions, or:

```
code --install-extension quixiai.with-lang
```

### 5.2 `with lsp` Ships with the Compiler

No separate install. If you have `with`, you have `with lsp`.
The VSCode extension just needs `with` to be in PATH. The
settings page has one option: path to the `with` binary, default
is `"with"`.

### 5.3 JetBrains (Later)

When the LSP is solid, JetBrains support is a thin plugin that
launches `with lsp` and maps LSP responses to IntelliJ's API.
The LSP4IJ library makes this straightforward. Same story for
Neovim (native LSP support), Zed (native LSP support), Helix
(native LSP support). One LSP, every editor.

---

## 6. What to Build First

Order matters. Each step is usable on its own:

**Step 1: TextMate grammar only.** No LSP. Just syntax
highlighting. Ship the VSCode extension with just the grammar.
People can write With code with colors. This takes a day.

**Step 2: Diagnostics.** The LSP reports errors on save. Red
squiggles. This is the moment the extension becomes useful
instead of decorative. This takes the longest because it requires
the error-tolerant parser.

**Step 3: Go to definition + hover.** The LSP becomes productive.
You can navigate code. You can inspect types. This requires the
symbol index.

**Step 4: Autocomplete.** Type `foo.`, get suggestions. This is
the moment it feels like a real IDE experience.

**Step 5: Format on save, document symbols, signature help.** Polish. Each one is small and independent.

Everything after step 5 is luxury. Steps 1–4 are the "people
will actually use this language" threshold.

---

*`with lsp` — v0.1*