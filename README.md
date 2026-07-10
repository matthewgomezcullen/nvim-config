# (Neo)Vim (+Tmux)

Tags: Comp Sci, Workflow
URL: https://www.youtube.com/watch?v=m8C0Cq9Uv9o&ab_channel=TJDeVries

This page outlines my learning lessons and recommendations for using Neovim. I assume that you already know how to use Vim. If not, run `vimtutor` in the terminal and complete the tutorial

# Setup

Install [Neovim](https://neovim.io/). Run it with `nvim`. Navigate files as you would with Vim. Create a config file with `sudo mkdir ~/.config/nvim` and `sudo touch `~/config/nvim/init.lua`. **Lua** is a lightweight programming language used for Neovim plugins.

## Dependencies

A few features shell out to command-line tools. The rest of this page introduces each one where it is used, but these two are needed up front:

```bash
brew install tmux fzf
```

[**tmux**](#tmux) hosts the Claude panes. [**fzf**](https://github.com/junegunn/fzf) is a command-line fuzzy finder: you pipe it a list, it draws an interactive filterable menu, and it prints back what you chose. `<leader>cln` uses it to pick between past questions about this config — see [Agents](#agents).

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
    │   ├── lazy.lua
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
| `<leader>cln` | Open a picker over past questions about this Neovim setup, in a small tmux pane below Neovim. Resume one, or ask a new one in its own session. Also available as `:Claude`. See [Agents](#agents). |
| `<leader>clc` | Open the project Claude Code session in a tmux pane to the left, connected to this Neovim. Also available as `:ClaudeProject`. See [Agents](#agents). |
| `<leader>cls` | Send the visual selection (or the current file) to that session as an `@file#L10-20` mention, then focus the Claude pane so you can type straight away. |
| `<leader>cla` / `<leader>cld` | Accept / reject the diff Claude is proposing. Equivalent to `:w` / `:q` in the diff buffer. An accepted diff reloads the buffer automatically. |

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
    │   ├── lazy.lua
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
| ~90 user-defined triggers (see `snippets.txt`) | e.g. `al<Space>` $\to$ `\alpha`, `bi<Space>` $\to$ `\binom{\|}{}`, `gather<Space>` $\to$ `\begin{gather}\|\end{gather}` | Word-trigger semantics; the `<Space>` is consumed by the expansion. |

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

The loader (`lua/snippets/markdown_math.lua`) reads the file at startup, converts each entry into a LuaSnip snippet (expanded on `<Space>`, gated to math zones), and surfaces warnings in `:messages` for duplicate triggers or malformed lines (e.g. expansion ends in a bare `\`). Skipped entries are noted with their line number so they're easy to fix.

#### Tests

The math-typing module has a headless test suite covering math-zone detection, the `$` / `^` / `_` autopairs, space-triggered expansion, and math-zone exit. Run it with:

```bash
nvim --headless -u test/init.lua -c "luafile test/markdown_math_spec.lua"
```

The runner exits non-zero if any test fails, so it slots into CI or a pre-commit hook.

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

### `claude`

| Package | Purpose | Configurations |
| --- | --- | --- |
| [claudecode.nvim](https://github.com/coder/claudecode.nvim) | Connects the Claude Code CLI to Neovim over the same IDE protocol the official VS Code extension speaks, so selections become `@file#L10-20` mentions and Claude's edits open as native diffs. | `terminal = { provider = "none" }`, so it manages no terminal and Claude keeps running in its own tmux pane. Loaded eagerly (`lazy = false`) because its WebSocket server starts inside `setup()`. |

The plugin only supplies the integration server; the panes, the launchers, and the `<leader>cl` keymaps live in `lua/config/claude.lua`. See [Agents](#agents).

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

For questions *about this Neovim setup* while editing any project, `<leader>cln` (or `:Claude`) opens a Claude session in a small tmux pane below Neovim. It always runs cwd'd in `~/.config/nvim`, so Claude can read the config and answer setup questions — e.g. "how do I go to the implementation of the word under my cursor in Python?" — independent of whatever project your main session is focused on. `<leader>cl` is a prefix reserved for Claude helpers, so this one takes `n`, for Neovim.

The pane opens on an [fzf](https://github.com/junegunn/fzf) picker listing the questions asked before, one row per session:

| Key | Effect |
| --- | --- |
| `enter`, on a row | Resume that session. |
| `enter`, when the query matched nothing | Start a new session, taking the query as the first question. |
| `alt-enter` | Start a new session from the query even if rows matched. |
| `ctrl-x` | Forget the highlighted row. The registry entry goes; the transcript on disk stays. |
| `esc` | Close the pane. |

`ctrl-x` rather than `ctrl-d` for forget, because `Ctrl-D` already means "exit Claude" and a destructive second meaning one keystroke away invites muscle-memory mistakes.

| Behavior | Detail |
| --- | --- |
| One session per question | Every question opens its own session id, so no question spends input tokens re-sending an unrelated question's history. Past sessions stay on disk and remain resumable from the picker. |
| Tuned for short answers | The launcher passes `--append-system-prompt` on every run, asking Claude to lead with the exact keystroke or command, stay within about five lines, and answer from this config rather than from generic Neovim advice. The prompt lives in the launcher rather than in `CLAUDE.md` so that it shapes only this helper. |
| Pinned to Sonnet | The launcher passes `--model sonnet`. These are short lookups against a small config, so the faster model is the better trade, and it leaves the model you pick for your main session untouched. |
| Persistent pane | Focus it with `<C-j>` (vim-tmux-navigator). Exiting Claude (`Ctrl-D`) returns to the picker rather than closing the pane; `esc` from the picker closes it and Neovim reclaims the space. Re-invoking refocuses the existing pane instead of stacking a new one. Requires Neovim running inside tmux. |

The registry is a CSV at `${XDG_STATE_HOME:-~/.local/state}/claude-nvim-helper/sessions.csv`, most-recently-used first, one `<uuid>,<question>` row per session. It sits outside this repo on purpose: the questions are personal state, not configuration, and must never be committed. Rows are split on the *first* comma — a uuid contains none — so a question may hold commas, quotes and apostrophes without escaping. Before each render the picker drops rows whose transcript has gone, since Claude deletes transcripts once they pass `cleanupPeriodDays` and `--resume` on a missing id errors out.

Implementation: `scripts/claude-nvim-helper.sh` (the picker, the registry, the model and system prompt) and `lua/config/claude.lua` (the `:Claude` command, `<leader>cln` map, and pane management).

#### Editor integration for the project session

`<leader>clc` (or `:ClaudeProject`) opens the project Claude Code session in a tmux pane to the left, connected to this Neovim over the same IDE protocol the official VS Code extension speaks. Once connected, `<leader>cls` sends the visual selection as an `@file#L10-20` mention, and every edit Claude proposes opens as a native Neovim diff — accept it with `<leader>cla` (or `:w`), reject it with `<leader>cld` (or `:q`).

`coder/claudecode.nvim` provides this, configured with `terminal = { provider = "none" }`. That setting is the point: the plugin does not wrap Claude Code in a panel of its own. It spawns the real `claude` binary, and with the `none` provider it spawns nothing at all — `setup()` merely starts a local WebSocket server and advertises it in `~/.claude/ide/<port>.lock`. The interface stays exactly the Claude Code TUI you already run in tmux, so it cannot drift behind the real thing.

| Behavior | Detail |
| --- | --- |
| Connects on launch | `scripts/claude-code.sh` runs `claude --ide`, which finds the lock file and attaches. It also pins `CLAUDE_CODE_SSE_PORT` to this Neovim's port, because `--ide` auto-connects only when *exactly one* IDE is available and would otherwise decline with a second Neovim open. |
| Loaded eagerly | The plugin spec sets `lazy = false`, because the server starts inside `setup()`. Lazy-loading it on a keymap would race: `claude --ide` would find no lock file. |
| Local only | The server binds `127.0.0.1`. The lock file (mode `0600`, in a `0700` directory) carries a 128-bit CSPRNG token, checked with a constant-time compare during the WebSocket handshake. The plugin reports no telemetry. |
| The setup helper stays out of it | `<leader>cln` passes neither `--ide` nor a port, and `autoConnectIde` is off, so the read-only setup helper never attaches and never captures a diff meant for the project you are editing. |
| Focus follows a send | The plugin's `focus_after_send` is inert with `provider = "none"`, since Claude runs outside Neovim. A `User ClaudeCodeSendComplete` autocmd focuses the pane recorded by `<leader>clc` instead, falling back to tmux `{last}` if you launched Claude by hand. |
| Accepted diffs reload the buffer | Neovim hands the accepted contents back to the CLI, which writes the file *after* it asks Neovim to close the diff; the plugin's own reload waits a fixed 100 ms for that write and loses the race on anything slow. So on `User ClaudeCodeDiffClosed` we poll until the file on disk diverges from the buffer, then re-read it with the cursor preserved. Modified buffers are skipped, so unsaved work is never clobbered, and a rejected diff never diverges, so it costs nothing. `<leader>r` remains the manual override. |

Implementation: `lua/plugins/claude.lua` (the plugin spec and the `cls` / `cla` / `cld` maps), `scripts/claude-code.sh` (the `--ide` launcher), and `lua/config/claude.lua` (tmux pane management for both panes).

Two caveats. The wire protocol is not published by Anthropic and `claudecode.nvim` is beta, so a CLI update can break the integration; the TUI and `<leader>cln` keep working regardless. And with `provider = "none"` the plugin's own terminal commands (`:ClaudeCode`, `:ClaudeCodeOpen`, `:ClaudeCodeSendText`) are inert, so they are deliberately left unmapped. If you ever enable `format_on_save` in `conform.nvim`, exclude diff buffers (`buftype == "acwrite"`, or names containing `(proposed)`) or saving will silently accept Claude's diff.

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
