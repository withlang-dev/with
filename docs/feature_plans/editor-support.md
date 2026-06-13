# Editor Support

The With compiler includes a built-in language server: `with lsp`. It provides
diagnostics, go-to-definition, hover, and format-on-save.

## VSCode

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

## Neovim

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

## Vim

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

## Emacs

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

## Zed

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

## Helix

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
