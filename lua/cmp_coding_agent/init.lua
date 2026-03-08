local config = require('cmp_coding_agent.config')

local M = {}

local registered = false

function M.ensure_registered()
  if registered then
    return true
  end

  local ok, cmp = pcall(require, 'cmp')
  if not ok then
    return false
  end

  cmp.register_source('coding_agent_slash', require('cmp_coding_agent.source.slash').new())
  cmp.register_source('coding_agent_dollar', require('cmp_coding_agent.source.dollar').new())
  cmp.register_source('coding_agent_at', require('cmp_coding_agent.source.at').new())
  registered = true
  return true
end

function M.setup(user_config)
  config.setup(user_config)
  M.ensure_registered()
end

function M.get_config()
  return config.get()
end

return M
