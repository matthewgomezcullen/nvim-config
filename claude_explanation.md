# Claude Code, wired into Neovim over tmux

A study page for the integration built in `lua/plugins/claude.lua`, `lua/config/claude.lua`, `scripts/claude-code.sh`, and `scripts/claude-nvim-helper.sh`.

## The one-sentence version

Neovim runs a WebSocket server speaking MCP; Claude Code, running in an ordinary tmux pane, discovers it through a lock file on disk and connects to it as a client.

The thing to lead with, because it inverts the expectation: **the editor is the server and the CLI is the client.** Almost every other property of the system follows from that. Because the connection carries structured data rather than terminal text, Claude can ask Neovim to open a real diff, and Neovim can push file references into Claude's prompt. You keep the stock Claude Code TUI, and you gain the editor integration.

The choice that makes this possible is `terminal = { provider = "none" }`. We use `claudecode.nvim` purely as a protocol server. It opens no window, no buffer, and no panel. That is what dissolves the usual objection to editor plugins wrapping a CLI: there is no plugin UI standing between you and Claude Code, because we asked it not to draw one.

## Component 1: the server, started at `setup()`

`claudecode.nvim` is loaded with `lazy = false`. Its `setup()` does three things.

1. Starts a pure-Lua WebSocket server on a random loopback port. The plugin implements RFC 6455 framing itself, in `server/frame.lua` and `server/handshake.lua`, roughly 2,100 lines, because Neovim has no WebSocket in its standard library.
2. Generates an auth token from the OS cryptographically secure RNG. The source is emphatic: *"Never falls back to math.random: a weak token is worse than a startup error."*
3. Writes `~/.claude/ide/<port>.lock`, mode `0600`, containing the pid, `workspaceFolders`, `ideName`, `transport: "ws"`, and the auth token. The port is the filename.

A live example on this machine, token redacted:

```json
{"ideName":"Neovim","pid":87091,"transport":"ws",
 "workspaceFolders":["/Users/mattgc/.config/nvim"],"authToken":"..."}
```

`lazy = false` is load-bearing. `auto_start` runs *inside* `setup()`, so deferring the plugin until a keymap is pressed would mean the lock file does not exist when `claude --ide` goes looking for it. Lazy-loading the plugin would race its own consumer.

The server exposes a set of MCP tools, one file each under `lua/claudecode/tools/`: `open_diff`, `open_file`, `get_diagnostics`, `close_tab`, `save_document`, `check_document_dirty`, and several others. These are the verbs Claude is permitted to invoke against your editor.

## Component 2: discovery and connection

`scripts/claude-code.sh` is nine lines of real code. It takes an optional port, exports it as `CLAUDE_CODE_SSE_PORT`, and runs `exec claude --ide`.

The CLI scans `~/.claude/ide/*.lock` **at runtime**, not at install time. The `--ide` flag means "auto-connect if exactly one valid IDE is available." That qualifier is the reason we pin the port. With two Neovim instances open, two lock files exist, the CLI finds an ambiguity, and it declines to connect at all rather than guessing. Setting `CLAUDE_CODE_SSE_PORT` narrows discovery to a single candidate, so `<leader>clc` always attaches to the Neovim that launched it, rather than to whichever instance happened to be alone.

The port comes out of the plugin's own state, in `lua/config/claude.lua`:

```lua
local ok, claudecode = pcall(require, "claudecode")
local port = ok and claudecode.state and claudecode.state.port
```

The CLI then dials `ws://127.0.0.1:<port>` with subprotocol `mcp` and the header `X-Claude-Code-Ide-Authorization: <token>`. Loopback binding plus a CSPRNG token behind `0600` file permissions is the entire security model: possession of the lock file *is* the credential.

Two details worth knowing, both of which show you read the binary rather than the docs. `ENABLE_IDE_INTEGRATION`, which the plugin still injects into the environment, has **zero occurrences** in CLI version 2.1.205. It is harmless protocol drift. Similarly, the `getCurrentSelection` and `getOpenEditors` tools still exist on the server, but the current CLI never calls them.

## Component 3: the two directions of traffic

These are asymmetric, and the asymmetry is the most interesting thing in the system.

### Neovim to Claude: a fire-and-forget notification

`<leader>cls` runs `ClaudeCodeSend`, which calls `M.broadcast("at_mentioned", params)`. Look at the message it constructs: a `jsonrpc` field, a `method`, `params`, and **no `id`**. In JSON-RPC, omitting the `id` makes the message a notification: no reply, no correlation, no blocking. Claude simply finds `@path#L10-20` appended to its prompt.

The CLI parses that mention syntax natively, with the regex `^([^#]+)(?:#L(\d+)(?:-(\d+))?)?`. This is why the send direction was essentially free to build: nothing had to be invented on either end.

One mapping covers normal and visual mode, because `ClaudeCodeSend` is declared with `range = true`, so Vim hands it the visual selection when there is one.

### Claude to Neovim: a blocking request

When Claude wants to edit a file, it calls the `openDiff` tool and *waits*.

On the Neovim side, `open_diff.lua` asserts that it is running inside a coroutine (`requires_coroutine = true`), sets up the diff UI, and then reaches `local user_action_result = coroutine.yield()` at `diff.lua:1669`. The coroutine parks there. **The human is the scheduler.** When you press `<leader>cla` or `<leader>cld`, the plugin resumes that coroutine with one of three payloads, and only then does the tool call return over the wire:

| Payload | Meaning |
| --- | --- |
| `FILE_SAVED` | accepted; carries the final buffer contents |
| `DIFF_REJECTED` | rejected |
| `TAB_CLOSED` | the diff tab was closed without a decision |

This is the part to lead with in an interview. It is a blocking RPC across a WebSocket, implemented with a Lua coroutine, whose resume condition is a keystroke.

## Component 4: the glue we wrote

`lua/config/claude.lua` is ours rather than the plugin's. It has three jobs.

### Pane management

`open_pane()` records the tmux pane id in a tmux *window option*, `@claude_code_pane`, rather than in a pane title, because Claude's TUI overwrites the title. Pressing `<leader>clc` a second time therefore refocuses the existing pane instead of stacking a new one. Both `<leader>clc` and `<leader>cln` share this machinery.

### Focus on send

With `provider = "none"`, the plugin's own `focus_after_send` option is inert: there is no in-editor terminal to focus. The plugin knows this and says so. Its warning at `init.lua:385` reads, in part, *"Use a `User ClaudeCodeSendComplete` autocmd to focus it yourself."*

So we do exactly that, calling `tmux select-pane` on the recorded pane and falling back to `{last}` when nothing was recorded. `select-pane` is idempotent, so a multi-file send that fires the event several times is harmless.

### Reload on accept, and the race

This is the subtlest bug in the system, and the best story in it.

`_resolve_diff_as_saved` never writes to disk. It hands the new contents back to the CLI inside the `FILE_SAVED` response, and the **CLI** writes the file, *after* it has already called `close_tab`. The plugin attempts a buffer reload behind a fixed `vim.defer_fn(..., 100)`, with the comment *"Add a small delay to ensure Claude CLI has finished writing the file."* When the write lands later than 100 ms, `:edit` re-reads the old bytes and the buffer is silently stale.

The obvious fix is a bigger number. That is still a guess. Instead, `reload_when_written` polls disk against the buffer every 100 ms, up to a 2 s ceiling, and reloads the instant the two diverge. Three properties fall out for free.

- A **rejected** diff never diverges, so the poller expires quietly. There is no need to branch on the event's `reason` field, which the plugin documents as diagnostic text rather than a stable enum.
- A **modified** buffer is skipped outright, so unsaved work is never clobbered.
- We re-read with `:edit` rather than `:checktime`, because Neovim detects external changes by mtime and size, and `getftime` has one-second resolution. A same-second write of identical length would be missed. Once divergence has been *proven*, an unconditional re-read is the correct move.

The cursor is restored via `nvim_win_call`, wrapped in `pcall`, since the file may have shrunk beneath it.

We use recursive `vim.defer_fn` rather than a `vim.uv` timer so there is no handle to leak or double-close.

### The constraint that nearly sank it

tmux `focus-events` is **off** on this machine. Any design built on `FocusGained`, of the shape "refresh the buffer when you switch back to Neovim," would have compiled, run, and silently never fired. The plugin's own `User` autocmds were the only trustworthy trigger. This is a good answer to "what surprised you."

## Design decisions worth defending

**Adopt the plugin; do not rebuild it.** The @-mention direction is nearly free, because the CLI parses the mention syntax itself. Native diffs are not: roughly 5,000 lines against an unpublished, drifting protocol, of which about 2,100 is WebSocket, 345 is lockfile and auth, and 2,480 is the blocking-diff state machine. That cost asymmetry decided the question. Adopting the plugin while refusing its UI captures the expensive half and pays nothing for the cheap half.

**The Q&A helper is deliberately not IDE-connected.** `<leader>cln` opens a separate, Opus-pinned, fzf-picked session, always cwd'd in `~/.config/nvim`. If it also held an IDE connection, it could capture `openDiff` calls intended for the project you are actually editing. Two Claudes, one wire: you want exactly one of them holding it.

**Do not touch plugin internals.** `reload_file_buffers_manual` exists and would have been a one-liner. It is not public API, and the plugin is beta. We used the documented `User` events instead.

## The keymaps

| Key | What it does |
| --- | --- |
| `<leader>clc` | open or refocus the project session, IDE-connected |
| `<leader>cln` | open or refocus the Neovim-config Q&A session, not IDE-connected |
| `<leader>cls` | send the file or selection as an `@`-mention, then focus the Claude pane |
| `<leader>cla` | accept the open diff; the buffer reloads on its own |
| `<leader>cld` | reject the open diff |
| `<leader>r` | manual buffer refresh, still there as an override |


## Source map

| File | Role |
| --- | --- |
| `lua/plugins/claude.lua` | plugin spec; `provider = "none"`, `lazy = false`, the three keymaps |
| `lua/config/claude.lua` | tmux pane management, focus-on-send, reload-on-accept |
| `scripts/claude-code.sh` | pins `CLAUDE_CODE_SSE_PORT`, execs `claude --ide` |
| `scripts/claude-nvim-helper.sh` | the separate, non-IDE Q&A session with its fzf picker |
| `~/.claude/ide/<port>.lock` | the rendezvous point between the two |
