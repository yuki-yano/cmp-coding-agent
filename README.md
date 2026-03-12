# cmp-coding-agent

`nvim-cmp` source collection for coding-agent prompt authoring.

It targets Claude Code, Codex, and Copilot CLI, and provides three sources:

- `coding_agent_slash`
- `coding_agent_dollar`
- `coding_agent_at`

## Features

- Claude Code, Codex, and Copilot CLI built-in slash command completion
- Skill discovery from repo and user scopes
  - `.github/skills`
  - `.agents/skills`
  - `.claude/skills`
  - `.codex/skills`
  - `~/.copilot/skills`
  - `~/.config/claude/skills`
- Claude and Copilot custom command completion from `.claude/commands`
- Codex prompt completion from `~/.codex/prompts` or `$CODEX_HOME/prompts`
- `@` file path completion with configurable `@` preservation
- Root-aware discovery for Git repos and non-Git directories
- No runtime dependency besides `nvim-cmp`

## Installation

### lazy.nvim

```lua
{
  'yuki-yano/cmp-coding-agent',
  dependencies = {
    'hrsh7th/nvim-cmp',
  },
}
```

## Setup

```lua
require('cmp_coding_agent').setup({
  agent = 'both',
  max_items = 200,
  paths = {
    preserve_at_prefix = true,
    show_hidden = true,
    preview_lines = 20,
    deep_search = false,
    root = 'git',
  },
  skills = {
    include = {
      repo_agents = true,
      repo_claude = true,
      repo_codex = true,
      repo_copilot = true,
      user_agents = true,
      user_claude = true,
      user_codex = true,
      user_copilot = true,
    },
    include_non_user_invocable = false,
  },
  commands = {
    include_builtins = {
      claude = true,
      codex = true,
      copilot = true,
    },
    extra = {
      claude = {},
      codex = {},
      copilot = {},
    },
    disabled = {
      claude = {},
      codex = {},
      copilot = {},
    },
  },
  prompts = {
    codex = {
      enabled = true,
    },
  },
})
```

Add the sources to your `cmp.setup()` configuration:

```lua
local cmp = require('cmp')

cmp.setup({
  sources = cmp.config.sources({
    { name = 'coding_agent_slash' },
    { name = 'coding_agent_dollar' },
    { name = 'coding_agent_at' },
  }),
})
```

## Source Behavior

### `coding_agent_slash`

- Claude built-ins
- Codex built-ins
- Copilot built-ins
- Copilot skills from `.github/skills`, `.agents/skills`, and `.claude/skills`
- Claude skills from `.claude/skills`
- Claude and Copilot commands from `.claude/commands`
- Codex prompts as `/prompts:name`

### `coding_agent_dollar`

- Codex skills from `.agents/skills` and `.codex/skills`

### `coding_agent_at`

- Relative file and directory completion
- `insertText` can keep `@path` or strip to `path`
- `paths.deep_search = true` enables recursive path discovery from the selected root

## Discovery Rules

### Skills

- Repo-local Copilot roots
  - each ancestor `.github/skills` from current buffer directory to project root
  - each ancestor `.agents/skills` from current buffer directory to project root
  - project root `.claude/skills`
- Repo-local Codex roots
  - each ancestor `.agents/skills` from current buffer directory to project root
  - project root `.codex/skills`
- Repo-local Claude roots
  - project root `.claude/skills`
- User roots
  - `~/.agents/skills`
  - `$COPILOT_HOME/skills`
  - otherwise `~/.copilot/skills`
  - `~/.config/claude/skills`
  - `~/.claude/skills`
  - `~/.codex/skills`
  - `COPILOT_SKILLS_DIRS` entries

### Commands and prompts

- Claude commands
  - `$CLAUDE_CONFIG_DIR/commands`
  - `~/.claude/commands`
  - project `.claude/commands`
- Copilot commands
  - `~/.claude/commands`
  - project `.claude/commands`
- Codex prompts
  - `$CODEX_HOME/prompts`
  - otherwise `~/.codex/prompts`

## Configuration Notes

- `agent` accepts `'claude'`, `'codex'`, `'copilot'`, `'both'`, `'all'`, or a function.
- Buffer-local override is available via `vim.b.cmp_coding_agent_agent`.
- `commands.extra.<agent>` accepts either command strings or `{ name = ..., description = ... }`.
- `commands.disabled.<agent>` removes built-ins by name.

## Development

Bootstrap test dependencies:

```sh
./scripts/bootstrap_deps.sh
```

Run tests:

```sh
make test
```

Format Lua files:

```sh
make format
```

## License

MIT. See [LICENSE](./LICENSE).
