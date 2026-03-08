local M = {}

local CLAUDE_BUILTINS = {
  { name = 'add-dir', description = 'Add a new working directory to the current session', argument_hint = '<path>' },
  { name = 'agents', description = 'Manage agent configurations' },
  { name = 'chrome', description = 'Configure Claude in Chrome settings' },
  { name = 'clear', description = 'Clear conversation history and free up context', aliases = { 'reset', 'new' } },
  {
    name = 'compact',
    description = 'Compact conversation with optional focus instructions',
    argument_hint = '[instructions]',
  },
  { name = 'config', description = 'Open the Settings interface (Config tab)', aliases = { 'settings' } },
  { name = 'context', description = 'Visualize current context usage as a colored grid' },
  { name = 'copy', description = 'Copy the last assistant response to clipboard' },
  { name = 'cost', description = 'Show token usage statistics' },
  {
    name = 'desktop',
    description = 'Continue the current session in the Claude Code Desktop app',
    aliases = { 'app' },
  },
  { name = 'diff', description = 'Open an interactive diff viewer showing uncommitted changes' },
  { name = 'doctor', description = 'Diagnose and verify your Claude Code installation and settings' },
  { name = 'exit', description = 'Exit the CLI', aliases = { 'quit' } },
  { name = 'export', description = 'Export the current conversation as plain text', argument_hint = '[filename]' },
  { name = 'extra-usage', description = 'Configure extra usage to keep working when rate limits are hit' },
  { name = 'fast', description = 'Toggle fast mode on or off', argument_hint = '[on|off]' },
  {
    name = 'feedback',
    description = 'Submit feedback about Claude Code',
    argument_hint = '[report]',
    aliases = { 'bug' },
  },
  { name = 'fork', description = 'Create a fork of the current conversation at this point', argument_hint = '[name]' },
  { name = 'help', description = 'Show help and available commands' },
  { name = 'hooks', description = 'Manage hook configurations for tool events' },
  { name = 'ide', description = 'Manage IDE integrations and show status' },
  { name = 'init', description = 'Initialize project with CLAUDE.md guide' },
  { name = 'insights', description = 'Generate a report analyzing your Claude Code sessions' },
  { name = 'install-github-app', description = 'Set up the Claude GitHub Actions app for a repository' },
  { name = 'install-slack-app', description = 'Install the Claude Slack app' },
  { name = 'keybindings', description = 'Open or create your keybindings configuration file' },
  { name = 'login', description = 'Sign in to your Anthropic account' },
  { name = 'logout', description = 'Sign out from your Anthropic account' },
  { name = 'mcp', description = 'Manage MCP server connections and OAuth authentication' },
  { name = 'memory', description = 'Edit CLAUDE.md memory files and auto-memory settings' },
  { name = 'mobile', description = 'Show QR code to download the Claude mobile app', aliases = { 'ios', 'android' } },
  { name = 'model', description = 'Select or change the AI model', argument_hint = '[model]' },
  { name = 'output-style', description = 'Switch between output styles', argument_hint = '[style]' },
  { name = 'passes', description = 'Share a free week of Claude Code with friends' },
  { name = 'permissions', description = 'View or update permissions', aliases = { 'allowed-tools' } },
  { name = 'plan', description = 'Enter plan mode directly from the prompt' },
  { name = 'plugin', description = 'Manage Claude Code plugins' },
  {
    name = 'pr-comments',
    description = 'Fetch and display comments from a GitHub pull request',
    argument_hint = '[PR]',
  },
  { name = 'privacy-settings', description = 'View and update your privacy settings' },
  { name = 'release-notes', description = 'View the full changelog' },
  { name = 'reload-plugins', description = 'Reload all active plugins to apply pending changes without restarting' },
  {
    name = 'remote-control',
    description = 'Make this session available for remote control from claude.ai',
    aliases = { 'rc' },
  },
  { name = 'remote-env', description = 'Configure the default remote environment for teleport sessions' },
  { name = 'rename', description = 'Rename the current session', argument_hint = '[name]' },
  {
    name = 'resume',
    description = 'Resume a conversation by ID or name',
    argument_hint = '[session]',
    aliases = { 'continue' },
  },
  { name = 'review', description = 'Review a pull request for code quality, correctness, security, and test coverage' },
  {
    name = 'rewind',
    description = 'Rewind the conversation and/or code to a previous point',
    aliases = { 'checkpoint' },
  },
  { name = 'sandbox', description = 'Toggle sandbox mode' },
  {
    name = 'security-review',
    description = 'Analyze pending changes on the current branch for security vulnerabilities',
  },
  { name = 'skills', description = 'List available skills' },
  { name = 'stats', description = 'Visualize daily usage, session history, streaks, and model preferences' },
  { name = 'status', description = 'Open the Settings interface (Status tab)' },
  { name = 'statusline', description = 'Configure Claude Code’s status line' },
  { name = 'stickers', description = 'Order Claude Code stickers' },
  { name = 'tasks', description = 'List and manage background tasks' },
  { name = 'terminal-setup', description = 'Configure terminal keybindings for Shift+Enter and other shortcuts' },
  { name = 'theme', description = 'Change the color theme' },
  { name = 'upgrade', description = 'Open the upgrade page to switch to a higher plan tier' },
  { name = 'usage', description = 'Show plan usage limits and rate limit status' },
  { name = 'vim', description = 'Toggle between Vim and Normal editing modes' },
}

local CODEX_BUILTINS = {
  { name = 'model', description = 'Choose what model and reasoning effort to use' },
  { name = 'fast', description = 'Toggle Fast mode to enable fastest inference at 2X plan usage' },
  { name = 'permissions', description = 'Choose what Codex is allowed to do', aliases = { 'approvals' } },
  { name = 'setup-default-sandbox', description = 'Set up elevated agent sandbox' },
  { name = 'sandbox-add-read-dir', description = 'Let sandbox read a directory', argument_hint = '<absolute_path>' },
  { name = 'experimental', description = 'Toggle experimental features' },
  { name = 'skills', description = 'Use skills to improve how Codex performs specific tasks' },
  { name = 'review', description = 'Review my current changes and find issues' },
  { name = 'rename', description = 'Rename the current thread' },
  { name = 'new', description = 'Start a new chat during a conversation' },
  { name = 'resume', description = 'Resume a saved chat' },
  { name = 'fork', description = 'Fork the current chat' },
  { name = 'init', description = 'Create an AGENTS.md file with instructions for Codex' },
  { name = 'compact', description = 'Summarize conversation to prevent hitting the context limit' },
  { name = 'plan', description = 'Switch to Plan mode' },
  { name = 'collab', description = 'Change collaboration mode' },
  { name = 'agent', description = 'Switch the active agent thread' },
  { name = 'multi-agents', description = 'Switch the active agent thread' },
  { name = 'diff', description = 'Show git diff (including untracked files)' },
  { name = 'copy', description = 'Copy the latest Codex output to your clipboard' },
  { name = 'mention', description = 'Mention a file' },
  { name = 'status', description = 'Show current session configuration and token usage' },
  { name = 'statusline', description = 'Configure which items appear in the status line' },
  { name = 'theme', description = 'Choose a syntax highlighting theme' },
  { name = 'mcp', description = 'List configured MCP tools' },
  { name = 'apps', description = 'Manage apps' },
  { name = 'logout', description = 'Log out of Codex' },
  { name = 'exit', description = 'Exit Codex', aliases = { 'quit' } },
  { name = 'feedback', description = 'Send logs to maintainers' },
  { name = 'ps', description = 'List background terminals' },
  { name = 'clean', description = 'Stop all background terminals' },
  { name = 'clear', description = 'Clear the terminal and start a new chat' },
  { name = 'personality', description = 'Choose a communication style for Codex' },
  { name = 'realtime', description = 'Toggle realtime voice mode' },
  { name = 'settings', description = 'Configure realtime microphone or speaker' },
}

local function disabled_set(names)
  local result = {}
  for _, name in ipairs(names or {}) do
    result[name] = true
  end
  return result
end

local function normalize_extra_entries(entries)
  local result = {}
  for _, entry in ipairs(entries or {}) do
    if type(entry) == 'string' then
      table.insert(result, {
        name = entry,
        description = 'User-defined built-in command',
      })
    elseif type(entry) == 'table' and entry.name then
      table.insert(result, entry)
    end
  end
  return result
end

local function add_entry(records, entry, opts, order, is_alias)
  if opts.disabled[entry.name] then
    return
  end
  if is_alias and opts.query == '' then
    return
  end

  table.insert(records, {
    label = entry.name,
    name = entry.name,
    description = entry.description,
    ['argument-hint'] = entry.argument_hint,
    agent = opts.agent,
    source_kind = 'builtin',
    trigger_family = 'slash',
    alias_of = entry.alias_of,
    match_inputs = { entry.name },
    sort_group = 10,
    sort_subgroup = order,
  })
end

function M.collect(opts)
  opts = opts or {}
  local agent = opts.agent or 'claude'
  local base = agent == 'claude' and CLAUDE_BUILTINS or CODEX_BUILTINS
  local user_config = opts.commands_config or {}
  local records = {}
  local disabled = disabled_set(user_config.disabled and user_config.disabled[agent] or {})
  local extra = normalize_extra_entries(user_config.extra and user_config.extra[agent] or {})
  local order = 0

  for _, entry in ipairs(base) do
    order = order + 1
    add_entry(records, entry, {
      agent = agent,
      query = opts.query or '',
      disabled = disabled,
    }, order, false)

    for _, alias in ipairs(entry.aliases or {}) do
      add_entry(records, {
        name = alias,
        description = entry.description,
        argument_hint = entry.argument_hint,
        alias_of = entry.name,
      }, {
        agent = agent,
        query = opts.query or '',
        disabled = disabled,
      }, order + 100, true)
    end
  end

  for _, entry in ipairs(extra) do
    order = order + 1
    add_entry(records, entry, {
      agent = agent,
      query = opts.query or '',
      disabled = disabled,
    }, order + 500, false)
  end

  return records
end

return M
