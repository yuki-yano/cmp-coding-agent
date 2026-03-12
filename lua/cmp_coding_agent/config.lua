---@alias cmp_coding_agent.AgentName
---| 'claude'
---| 'codex'
---| 'copilot'
---| 'both'
---| 'all'

---@class cmp_coding_agent.AgentContext
---@field bufnr integer
---@field buffer_path string|nil
---@field project_root string|nil

---@alias cmp_coding_agent.AgentSelector cmp_coding_agent.AgentName|fun(ctx: cmp_coding_agent.AgentContext): cmp_coding_agent.AgentName

---@class cmp_coding_agent.PathConfig
---@field preserve_at_prefix? boolean
---@field show_hidden? boolean
---@field preview_lines? integer
---@field deep_search? boolean
---@field root? '"'"'git'"'"'|'"'"'cwd'"'"'

---@class cmp_coding_agent.SkillIncludeConfig
---@field repo_agents? boolean
---@field repo_claude? boolean
---@field repo_codex? boolean
---@field repo_copilot? boolean
---@field user_agents? boolean
---@field user_claude? boolean
---@field user_codex? boolean
---@field user_copilot? boolean

---@class cmp_coding_agent.SkillConfig
---@field include? cmp_coding_agent.SkillIncludeConfig
---@field include_non_user_invocable? boolean

---@class cmp_coding_agent.CommandExtraEntry
---@field name string
---@field description? string
---@field argument_hint? string
---@field aliases? string[]

---@class cmp_coding_agent.CommandBuiltinsConfig
---@field claude? boolean
---@field codex? boolean
---@field copilot? boolean

---@class cmp_coding_agent.CommandAgentEntries
---@field claude? (string|cmp_coding_agent.CommandExtraEntry)[]
---@field codex? (string|cmp_coding_agent.CommandExtraEntry)[]
---@field copilot? (string|cmp_coding_agent.CommandExtraEntry)[]

---@class cmp_coding_agent.CommandDisabledConfig
---@field claude? string[]
---@field codex? string[]
---@field copilot? string[]

---@class cmp_coding_agent.CommandConfig
---@field include_builtins? cmp_coding_agent.CommandBuiltinsConfig
---@field extra? cmp_coding_agent.CommandAgentEntries
---@field disabled? cmp_coding_agent.CommandDisabledConfig

---@class cmp_coding_agent.CodexPromptConfig
---@field enabled? boolean

---@class cmp_coding_agent.PromptConfig
---@field codex? cmp_coding_agent.CodexPromptConfig

---@class cmp_coding_agent.Config
---@field agent? cmp_coding_agent.AgentSelector
---@field max_items? integer
---@field paths? cmp_coding_agent.PathConfig
---@field skills? cmp_coding_agent.SkillConfig
---@field commands? cmp_coding_agent.CommandConfig
---@field prompts? cmp_coding_agent.PromptConfig

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
}

local config = vim.deepcopy(defaults)

function M.get()
  return config
end

---@param user_config? cmp_coding_agent.Config
function M.setup(user_config)
  config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), user_config or {})
end

---@return cmp_coding_agent.Config
function M.defaults()
  return vim.deepcopy(defaults)
end

return M
