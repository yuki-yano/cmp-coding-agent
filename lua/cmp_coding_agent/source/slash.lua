local registry = require('cmp_coding_agent.registry')
local util = require('cmp_coding_agent.util')

local Source = {}
Source.__index = Source

function Source.new()
  return setmetatable({}, Source)
end

function Source:get_debug_name()
  return 'cmp-coding-agent-slash'
end

function Source:get_trigger_characters()
  return { '/' }
end

function Source:get_keyword_pattern()
  return [[/\S*]]
end

function Source:complete(params, callback)
  local token = util.extract_trigger_token(params.context.cursor_before_line, '/')
  if not token then
    callback({ items = {} })
    return
  end

  callback({
    items = registry.collect_slash_items({
      bufnr = params.context.bufnr,
      token = token,
    }),
    isIncomplete = false,
  })
end

return Source
