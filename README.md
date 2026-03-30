# With

With is a systems language with a self-hosted compiler.

The compiler is written in With and compiles itself. The repository includes a
frozen Zig bootstrap compiler (`bootstrap/`) as a historical artifact — it is
no longer used in the build pipeline.

## Requirements

- LLVM toolchain (default: `/usr/local/llvm`, override with `LLVM_PREFIX`)
- clang available on PATH (for linking user programs)
- Zig (optional, for cross-compilation)

## Build

The Makefile is the primary build interface. Normal development should go
through `make`, not through ad hoc shell scripts.

The self-host chain is:

```text
seed → stage1 → stage2 → stage3
```

Common targets:

```sh
make stage1        # build stage1 only
make stage2        # build stage2 only
make build         # alias for stage2, also refreshes out/bin/with
make stage3        # build stage3 only
make fixpoint      # verify stage2 == stage3
make test          # run selfhost suite and CLI regressions with stage2
make smoke         # quick compiler smoke check
```

The seed compiler is resolved from `WITH` env var, `with` on PATH, or
a downloaded seed binary:

```sh
make build                           # uses `with` on PATH
make seed && make build              # downloads seed from GitHub releases
WITH=~/other/with make build         # uses explicit binary
```

`src/main` is a local downloaded seed binary. It is gitignored and must never
be committed or pushed.

`out/bin/with-stage2` is the canonical built compiler in the workspace, and
`out/bin/with` is a copy of it for convenience. `make fixpoint` builds stage3
from stage2 and verifies they are byte-identical.

## Install

```sh
make install-user                    # installs to ~/.local/bin/with
make install PREFIX=$HOME/.local     # explicit local prefix install
sudo make install                    # installs to /usr/local/bin/with
```

`make build` does not install to your PATH. Installing is a separate step.

For fish shell:

```sh
fish_add_path -g ~/.local/bin
```

## Use

Basic commands:

```sh
with check examples/hello.w
with build examples/hello.w
./examples/hello
with run examples/hello.w
```

Debug/dump commands:

```sh
with check --dump-tokens examples/hello.w
with check --dump-ast examples/hello.w
with check --dump-resolved examples/hello.w
with check --dump-typed examples/hello.w
with check --dump-mir examples/hello.w
with check --dump-async-mir examples/hello.w
```

C emission path:

```sh
with build --emit-c examples/hello.w -o hello.c
cc -I runtime hello.c runtime/with_runtime.c runtime/helpers.c runtime/fiber.c runtime/fiber_asm_aarch64.s -o hello
```

## Test

Selfhost test suite and CLI regressions:

```sh
make test
```

Fixpoint verification (stage2 == stage3):

```sh
make fixpoint
```

## Editor Support

The compiler includes a built-in language server: `with lsp`. It provides
diagnostics, go-to-definition, hover, and format-on-save.

### VSCode

Install the extension from `with-vscode/`:

```sh
cd with-vscode
npm install
npx tsc -p ./
```

Then open VSCode, run **Extensions: Install from VSIX** (or press F1), or
symlink the extension directory:

```sh
ln -s "$(pwd)/with-vscode" ~/.vscode/extensions/with-lang
```

Restart VSCode. Files with `.w` extension get syntax highlighting and LSP
features automatically. Configure the compiler path in settings if `with`
is not on your PATH:

```json
{ "with.lsp.path": "/path/to/with" }
```

### Neovim

Using the built-in LSP client (requires Neovim 0.5+):

```lua
-- ~/.config/nvim/init.lua (or ftplugin/with.lua)
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'with',
  callback = function()
    vim.lsp.start({
      name = 'with-lsp',
      cmd = { 'with', 'lsp' },
      root_dir = vim.fs.dirname(vim.fs.find({ 'with.toml' }, { upward = true })[1]),
    })
  end,
})

vim.filetype.add({ extension = { w = 'with' } })
```

### Vim

Using [vim-lsp](https://github.com/prabirshrestha/vim-lsp):

```vim
" ~/.vimrc
au User lsp_setup call lsp#register_server({
    \ 'name': 'with-lsp',
    \ 'cmd': ['with', 'lsp'],
    \ 'allowlist': ['with'],
    \ })

au BufRead,BufNewFile *.w set filetype=with
```

Using [coc.nvim](https://github.com/neoclide/coc.nvim), add to
`coc-settings.json`:

```json
{
  "languageserver": {
    "with": {
      "command": "with",
      "args": ["lsp"],
      "filetypes": ["with"]
    }
  }
}
```

### Emacs

Using [lsp-mode](https://github.com/emacs-lsp/lsp-mode):

```elisp
;; ~/.emacs.d/init.el or ~/.emacs
(define-derived-mode with-mode prog-mode "With"
  "Major mode for the With language."
  (setq-local comment-start "// "))

(add-to-list 'auto-mode-alist '("\\.w\\'" . with-mode))

(with-eval-after-load 'lsp-mode
  (add-to-list 'lsp-language-id-configuration '(with-mode . "with"))
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection '("with" "lsp"))
    :activation-fn (lsp-activate-on "with")
    :server-id 'with-lsp)))

(add-hook 'with-mode-hook #'lsp)
```

Using [eglot](https://github.com/joaotavora/eglot) (built into Emacs 29+):

```elisp
(define-derived-mode with-mode prog-mode "With"
  (setq-local comment-start "// "))

(add-to-list 'auto-mode-alist '("\\.w\\'" . with-mode))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs '(with-mode . ("with" "lsp"))))

(add-hook 'with-mode-hook #'eglot-ensure)
```

### Zed

Add to your Zed settings (`~/.config/zed/settings.json`):

```json
{
  "lsp": {
    "with-lsp": {
      "binary": { "path": "with", "arguments": ["lsp"] }
    }
  },
  "languages": {
    "With": {
      "language_servers": ["with-lsp"]
    }
  },
  "file_types": {
    "With": ["w"]
  }
}
```

### Helix

Add to `~/.config/helix/languages.toml`:

```toml
[[language]]
name = "with"
scope = "source.with"
file-types = ["w"]
comment-token = "//"
indent = { tab-width = 4, unit = "    " }
language-servers = ["with-lsp"]

[language-server.with-lsp]
command = "with"
args = ["lsp"]
```

## Repo Layout

```text
src/                 self-hosted compiler (.w)
src/main             local seed binary (gitignored; download via `make seed`)
src/compiler/        Compilation-first architecture port layer
runtime/             C runtime source (.c, .h, .s)
lib/std/             standard library (.w)
test/cases/          behavior tests
out/                 all build output (gitignored)
  bin/               compiler binaries
  lib/               compiled runtime objects (.o), LLVM link config
  log/               build logs
bootstrap/           historical Zig bootstrap compiler (frozen, unused)
```

## Troubleshooting

- `install: ... Operation not permitted` under `/usr/local`:
  use `make install-user`, `PREFIX=$HOME/.local`, or run `sudo make install`.
- `no LLVM bridge available`: install LLVM at `/usr/local/llvm` or set `LLVM_PREFIX`.
  The compiler statically links LLVM — no dynamic library needed at runtime.
- Need only the staged compiler rebuild:
  use `make stage2` for stage2 only, or `make fixpoint` for stage2 plus stage3 verification.
- Legacy scripts that say `./scripts/rebuild_selfhost.sh ...`:
  that script is now only a compatibility wrapper around `make stage1|stage2|stage3`.
