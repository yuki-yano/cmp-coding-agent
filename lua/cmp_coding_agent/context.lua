local config = require('cmp_coding_agent.config')
local util = require('cmp_coding_agent.util')

local M = {}

local valid_agents = {
  claude = true,
  codex = true,
  copilot = true,
  both = true,
  all = true,
}

function M.resolve_agent(opts)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local ok, buffer_value = pcall(vim.api.nvim_buf_get_var, bufnr, 'cmp_coding_agent_agent')
  if ok and valid_agents[buffer_value] then
    return buffer_value
  end

  local value = config.get().agent
  if type(value) == 'function' then
    value = value({
      bufnr = bufnr,
      buffer_path = util.resolve_buffer_path(bufnr),
      project_root = util.resolve_project_root(bufnr),
    })
  end

  if not valid_agents[value] then
    return 'both'
  end

  return value
end

function M.agent_enabled(mode, agent)
  if mode == 'all' then
    return valid_agents[agent] == true
  end

  if mode == 'both' then
    return agent == 'claude' or agent == 'codex'
  end

  return mode == agent
end

function M.build_discovery_context(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return {
    bufnr = bufnr,
    buffer_path = util.resolve_buffer_path(bufnr),
    buffer_dir = util.resolve_buffer_dir(bufnr),
    project_root = util.resolve_project_root(bufnr),
    home_dir = util.normalize(vim.env.HOME),
    env = {
      CLAUDE_CONFIG_DIR = util.normalize(vim.env.CLAUDE_CONFIG_DIR),
      CODEX_HOME = util.normalize(vim.env.CODEX_HOME),
      COPILOT_CUSTOM_INSTRUCTIONS_DIRS = vim.env.COPILOT_CUSTOM_INSTRUCTIONS_DIRS,
      COPILOT_HOME = util.normalize(vim.env.COPILOT_HOME),
      COPILOT_SKILLS_DIRS = vim.env.COPILOT_SKILLS_DIRS,
    },
    agent = M.resolve_agent({ bufnr = bufnr }),
  }
end

return M
