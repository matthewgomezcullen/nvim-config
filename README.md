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
| vim.keymap.set("n", "<leader>r", ":e<CR>", { desc = "Reload file from disk" }) | Use for **agentic workflows**. This command refreshes the open editor to view external changes (e.g., from an agent) |

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

### `tmux`

| Package | Purpose |
| --- | --- |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Navigate between tmux panes and vim splits. |

### `latex`

| Package | Purpose |
| --- | --- |
| [vimtex](https://github.com/lervag/vimtex) | Filetype and syntax plugin for LaTeX files. |

### `markdown`

| Package | Purpose |
| --- | --- |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | Render markdown inside Neovim. |

### `git`

| Package | Purpose |
| --- | --- |
| [gitsigns](https://github.com/lewis6991/gitsigns.nvim) | Real-time Git integration for the editor. |

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

Install https://github.com/christoomey/vim-tmux-navigator with Lazy and follow the setup instructions. These changes enable shifting between tmux panels in and outside of nvim with `ctrl+h/j/k/l`.

## Applications

To *really* do everything using Neovim+Tmux, we need the right applications executing workflows in the CLI. I have detailed some useful examples below.

### Agents

Use the standard Claude Code CLI or Codex CLI.

### Markdown

[**Glow**](https://github.com/charmbracelet/glow) for rendering Markdown in the CLI. Watches files and updates as they change.

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