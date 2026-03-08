local M = {}

local defaults = {
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
      user_agents = true,
      user_claude = true,
      user_codex = true,
    },
    include_non_user_invocable = false,
  },
  commands = {
    include_builtins = {
      claude = true,
      codex = true,
    },
    extra = {
      claude = {},
      codex = {},
    },
    disabled = {
      claude = {},
      codex = {},
    },
  },
  prompts = {
    codex = {
      enabled = true,
    },
  },
}

local config = vim.deepcopy(defaults)

function M.get()
  return config
end

function M.setup(user_config)
  config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), user_config or {})
end

function M.defaults()
  return vim.deepcopy(defaults)
end

return M
