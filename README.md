# (Neo)Vim (+Tmux)

Tags: Comp Sci, Workflow
URL: https://www.youtube.com/watch?v=m8C0Cq9Uv9o&ab_channel=TJDeVries

This page outlines my learning lessons and recommendations for using Neovim. I assume that you already know how to use Vim. If not, run `vimtutor` in the terminal and complete the tutorial

# Setup

Install [Neovim](https://neovim.io/). Run it with `nvim`. Navigate files as you would with Vim. Create a config file with `sudo mkdir ~/.config/nvim` and `sudo touch `~/config/nvim/init.lua`. **Lua** is a lightweight programming language used for Neovim plugins.

The first Lua program we will require is **Lazy**. Lazy is a plug-in manager for Neovim. Follow the “Structured Setup” of the [installation page](https://lazy.folke.io/installation). Now we can add basic packages that we require. Note, your directory structure should be as so:

```bash
- ~/.config/nvim/
├── init.lua
└── lua/
    ├── config/
    │   ├── lazy.lua
    ├── plugins/
    └── util/
```

Under `config/`, we add config files for Neovim native configurations. `lazy.lua` contains the configuration for Lazy, following the aforementioned setup. We will structure `config/` as so:

```bash
- ~/.config/nvim/
├── init.lua
└── lua/
    ├── config/
    │   ├── init.lua
    │   ├── options.lua
    │   ├── keymaps.lua
    │   └── autocmds.lua
    ├── plugins/
    └── util/
```

## `config/`

See the configurations I use below.

**options**

| Line | Effect |
| --- | --- |
| vim.opt.number = true | Line numbers |
| vim.opt.relativenumber = true | Relative line numbers |
| vim.opt.expandtab = true | Use spaces instead of tabs |
| vim.opt.tabstop = 4 | How wide a tab looks |
| vim.opt.shiftwidth = 4 | Indent size |

**keymaps**

| Line | Effect |
| --- | --- |
| `vim.keymap.set("n", "<leader>r", ":e!<CR>", { desc = "Reload file from disk" })` | Use for **agentic workflows**. This command refreshes the open editor to view external changes (e.g., from an agent). |
| `vim.keymap.set("n", "<leader>e", ...)` | Toggle `nvim-tree`. |
| `vim.keymap.set("n", "<leader>ff", ...)` | Find files with Telescope, including hidden and ignored files. |
| `vim.keymap.set("n", "<leader>fg", ...)` | Search text with Telescope live grep. |
| `vim.keymap.set("n", "j" / "k", ...)` | Move by screen lines with `gj` / `gk` when no count is given; counted motions keep normal line movement. |
| `vim.keymap.set("n", "<Down>" / "<Up>", ...)` | Match the same screen-line behavior for the arrow keys. |
| `<leader>ma` | Add cursors for every match of the word under the cursor or the visual selection. |
| `<leader>mn` / `<leader>mN` | Add the next / previous matching cursor. |
| `<leader>ms` / `<leader>mS` | Skip the next / previous matching cursor. |

**autocmds**

`autocmds` are automatic commands that trigger on events, such as opening a file, writing a buffer, entering Insert mode, or an LSP attaching to a buffer.

| Line | Effect |
| --- | --- |

**lsp**

LSP configurations sit in the `lsp` config file.

| Line | Effect |
| --- | --- |

## `plugins/`

`plugins/` structure the plugins we require. I structure my plug-ins as so.

```bash
- ~/.config/nvim/
├── init.lua
└── lua/
    ├── config/
    │   ├── init.lua
    │   ├── options.lua
    │   ├── keymaps.lua
    │   └── autocmds.lua
    ├── plugins/
    │   ├── editor.lua
    │   ├── lsp.lua
    │   ├── latex.lua
    │   ├── markdown.lua
    │   ├── tmux.lua
    │   └── git.lua
    └── util/
```

### `core`

| Package | Purpose (+ notes) | Configurations |
| --- | --- | --- |
| [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) | Better explorer than the default (**netrw**). | Remap `<C+k>` (Info) to avoid conflict with Tmux. |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Formatting. Built around external formatters. |  |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Remember your keybinds. |  |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Extendable fuzzy finder to find, filter, preview, and pick items like files, strings, and LSP references |  |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Provides server configurations for the LSP. |  |
| [mason.nvim](https://github.com/mason-org/mason.nvim) | Portable package manager for LSP servers, DAP servers, linters, and formatters. |  |
| [multicursor.nvim](https://github.com/jake-stewart/multicursor.nvim) | Multiple cursors for editing repeated words or selections. | Use `<leader>ma` to add cursors for all matches, then edit normally. |

### `tmux`

| Package | Purpose | Configurations |
| --- | --- | --- |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Navigate between tmux panes and vim splits. | Maps `Ctrl+h/j/k/l` and `Ctrl+←/↓/↑/→` to directional pane movement, plus `Ctrl+\` for the previous pane. |

### `latex`

| Package | Purpose |
| --- | --- |
| [vimtex](https://github.com/lervag/vimtex) | Filetype and syntax plugin for LaTeX files. |

### `markdown`

| Package | Purpose | Configurations |
| --- | --- | --- |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | Render markdown inside Neovim. |  |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Snippet engine. Powers the math-typing snippets below. | Loader at `lua/snippets/markdown_math.lua` populates the `markdown` filetype on startup. Expansion is triggered by `<Space>`; `<S-Space>` inserts a literal space without expanding. |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | Autoclose `(`, `[`, `{`, `"`, etc. | `ts_config` includes a `markdown = {}` entry so the treesitter gate doesn't suppress pairing inside Markdown buffers. `$...$` and `$$...$$` are handled by a buffer-local `$` keymap in `markdown_math.lua`, not by autopairs. |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (`main` branch) | Parsers for `markdown`, `markdown_inline`, `lua`, `latex`. Used both by `render-markdown.nvim` and by the math-zone detector. | Requires the `tree-sitter` CLI on `$PATH` — `brew install tree-sitter-cli`. Highlighting enabled via a `FileType` autocmd. |
| [blink.cmp](https://github.com/Saghen/blink.cmp) (extension) | Wired into LuaSnip via `snippets = { preset = "luasnip" }`, with `snippets` added to the default source list. | `<Tab>` chain: `snippet_forward` → math-zone exit → `fallback`. Inside a snippet, advances tab stops; outside a snippet but inside math, jumps the cursor past the closing `$` / `$$`; otherwise normal Tab. `<S-Tab>` jumps back through snippet stops. |

#### Math typing

Inside a `$...$` or `$$...$$` zone in a Markdown buffer, the following snippets and keymaps apply. Math-zone activation is gated by Treesitter (`latex_block`, `inline_formula`, `displayed_equation`, etc.), so typing `alpha` in prose stays literal.

Expansion model: type the trigger, then `<Space>` to expand. Use `<S-Space>` to insert a literal space without expanding.

| Trigger | Expands to | Notes |
| --- | --- | --- |
| `^` | `^{\|}` | Direct insert-mode keymap (not a snippet). Type the exponent, then `<Right>` to exit. |
| `_` | `_{\|}` | Subscript counterpart. |
| `{a}/{b}<Space>` | `\frac{a}{b}` | Regex snippet — fires on `<Space>` once both braces are typed. |
| ~105 user-defined triggers (see `snippets.txt`) | e.g. `al<Space>` $\to$ `\alpha`, `bi<Space>` $\to$ `\binom{\|}{}`, `gather<Space>` $\to$ `\begin{gather}\|\end{gather}` | Word-trigger semantics; the `<Space>` is consumed by the expansion. |

Exiting a math zone:

| Keystroke | Effect |
| --- | --- |
| `$` at `$\|$` | Jump past closing `$`. |
| `$` at `$$\|$$` | Jump past closing `$$`. |
| `<Tab>` (no active snippet stop) | Jump past the closing `$` / `$$` of whichever math zone encloses the cursor. Inside an active snippet, `<Tab>` advances tab stops first. |

#### `snippets.txt` format

One snippet per line:

```
trigger:::expansion;
```

- `#cursor` marks the first tab stop (cursor lands here on expansion).
- `#tab` marks each subsequent tab stop in document order.

Examples:

```
al:::\alpha;
bi:::\binom{#cursor}{#tab};
gather:::\begin{gather}#cursor\end{gather};
```

The loader (`lua/snippets/markdown_math.lua`) reads the file at startup, converts each entry into a LuaSnip autosnippet, and surfaces warnings in `:messages` for duplicate triggers or malformed lines (e.g. expansion ends in a bare `\`). Skipped entries are noted with their line number so they're easy to fix.

### `python`

| Package | Purpose | Configurations |
| --- | --- | --- |
| [basedpyright](https://github.com/DetachHead/basedpyright) | Python type checker / LSP. Provides hover, go-to-def, completions, diagnostics. | `typeCheckingMode = "standard"`. Auto-installed via mason. Detects `.venv/`, `venv/`, conda envs, and `$VIRTUAL_ENV` automatically. |
| [ruff](https://github.com/astral-sh/ruff) | Linter + formatter. Runs as both an LSP (diagnostics, code actions like organize-imports / fix-all) and as a `conform.nvim` formatter (`ruff_organize_imports` $\to$ `ruff_format`). | Hover disabled on the ruff LSP so basedpyright owns hover output. The same mason-installed `ruff` binary serves both roles. |

The `python` treesitter parser is enabled for syntax highlighting. Format-on-save is not configured — run `:lua require("conform").format()` to format the current buffer.

### `git`

| Package | Purpose |
| --- | --- |
| [gitsigns](https://github.com/lewis6991/gitsigns.nvim) | Real-time Git integration for the editor. |
| [diffview.nvim](https://github.com/sindrets/diffview.nvim) | Side-by-side diff viewer and file history browser. |

**Commands**

| Command | Effect |
| --- | --- |
| `:DiffviewOpen` | Diff working tree against HEAD |
| `:DiffviewOpen HEAD~2` | Diff against a specific revision |
| `:DiffviewFileHistory %` | Commit history for the current file |
| `:DiffviewFileHistory` | Commit history for the whole repo |
| `:DiffviewClose` | Close the diffview |

Inside the diff view, `<tab>` / `<s-tab>` navigate between files, and `s` stages or unstages the highlighted file.

## Nerd Fonts

Many plugins will use icons only supported by nerd fonts. A popular nerd font is provided by JetBrains. Install with HomeBrew:

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

Then, configure your terminal to use the nerd font.

## Keybinds

Check for conflicts using:

```bash
verbose map <keybind>
```

E.g., `verbose map <C-k>`. 

Use `g?` to see what the current plug-in can do.

# Tmux

Use to manage panes. Install with `brew install tmux`. Create a config page, `~/.tmux.conf`. Use `Ctrl+b` to start a Tmux command.

| Keybind | Effect |
| --- | --- |
| `%` | Split vertically |
| `"` | Split horizontally |
| `← ↑ ↓ →` | Navigate panes |

Add the following to the config page:

```bash
set -g mouse on
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5
```

Now you can use `Ctrl+b → H/J/K/L` to resize the panes (instead of the arrow keys, which don’t work on MacOS, as `Ctrl+← ↑ ↓ →` has its own effects).

Install https://github.com/christoomey/vim-tmux-navigator with Lazy and follow the setup instructions. These changes enable shifting between tmux panes in and outside of nvim with `ctrl+h/j/k/l` or `ctrl+←/↓/↑/→`.

## Applications

To *really* do everything using Neovim+Tmux, we need the right applications executing workflows in the CLI. I have detailed some useful examples below.

### Agents

Use the standard Claude Code CLI or Codex CLI.

### Markdown

[**Glow**](https://github.com/charmbracelet/glow) for rendering Markdown in the CLI. Watches files and updates as they change.

[**mo**](https://github.com/k1LoW/mo) renders Markdown in the browser with live-reload, and handles GitHub-flavored Markdown, KaTeX math, and Mermaid diagrams. Install with `brew install k1low/tap/mo`. It runs as a background server on `localhost:6275` that serves every opened file from a single page — re-running `mo <file>` adds to the running session rather than starting a new one. Inspect or tear down the session with `mo --status` / `mo --shutdown`.

`ftplugin/markdown.lua` wires `mo` into Neovim with a buffer-local `:MoRender` command plus automatic cleanup:

| Command / event | Effect |
| --- | --- |
| `:MoRender` | Save the buffer if modified, then open it in the browser via `mo`. |
| Buffer deleted (`:bd`) | Remove the file from mo's session (`mo --close`) so it stops lingering in the sidebar. |
| Quit Neovim (`:q` / `:qa`) | Remove every rendered file from mo's session on exit. |

`mo` is a background server with no signal for the browser being closed, so cleanup is tied to the Neovim buffer lifecycle instead. Closing only the browser tab leaves the file in mo until you delete the buffer or quit Neovim. `BufDelete` (not `BufUnload`) is used so reloading the file with `:e` doesn't drop it from the session.

### LaTeX

[**Skim**](https://skim-app.sourceforge.io/index.html) for rendering PDFs. Works with SyncTeX.

Configure VimTeX to use Skim with SyncTeX in `lua/plugins/latex.lua`:

```lua
vim.g.vimtex_view_method = "skim"
vim.g.vimtex_view_skim_sync = 1      -- enable forward search
vim.g.vimtex_view_skim_activate = 1  -- bring Skim to foreground on forward search
```

Skim auto-reloads changed PDFs, so live preview works automatically once VimTeX compiles.

**Backward search (Skim → Neovim)**

Install [neovim-remote](https://github.com/mhinz/neovim-remote), which lets Skim send commands back to the running Neovim instance:

```bash
pip3 install neovim-remote
```

Then in **Skim → Settings → Sync**, set:

| Field | Value |
| --- | --- |
| Preset | Custom |
| Command | `nvr` |
| Arguments | `--remote-silent +"%line" "%file"` |

**Keybinds**

| Keybind | Effect |
| --- | --- |
| `\ll` | Compile |
| `\lv` | Forward search (jump to cursor position in Skim) |
| `Cmd+Shift+Click` | Backward search (jump to source line in Neovim) |
