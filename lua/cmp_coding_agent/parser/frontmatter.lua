local cache = require('cmp_coding_agent.cache')
local simple_yaml = require('cmp_coding_agent.parser.simple_yaml')
local util = require('cmp_coding_agent.util')

local M = {}

local function extract_excerpt(body)
  if not body or body == '' then
    return ''
  end

  local lines = vim.split(body, '\n', { plain = true })
  local paragraph = {}
  local seen_content = false

  for _, line in ipairs(lines) do
    if line:match('%S') then
      seen_content = true
      table.insert(paragraph, vim.trim(line))
    elseif seen_content then
      break
    end
  end

  return table.concat(paragraph, ' ')
end

function M.parse_string(content)
  content = (content or ''):gsub('\r\n', '\n')
  local meta = {}
  local body = content

  if vim.startswith(content, '---\n') or content == '---' then
    local lines = vim.split(content, '\n', { plain = true })
    local closing_index

    for index = 2, #lines do
      if lines[index] == '---' then
        closing_index = index
        break
      end
    end

    if closing_index then
      meta = simple_yaml.parse_string(table.concat(vim.list_slice(lines, 2, closing_index - 1), '\n'))
      body = table.concat(vim.list_slice(lines, closing_index + 1), '\n')
    end
  end

  return {
    meta = meta,
    body = body,
    excerpt = extract_excerpt(body),
  }
end

function M.parse_file(path)
  return cache.read_file(path, function(file_path)
    local content = util.read_file(file_path) or ''
    return M.parse_string(content)
  end) or {
    meta = {},
    body = '',
    excerpt = '',
  }
end

return M
