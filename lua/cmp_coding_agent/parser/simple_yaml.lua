local M = {}

local function parse_scalar(raw)
  raw = vim.trim(raw or '')
  if raw == '' then
    return ''
  end

  if raw == 'true' then
    return true
  end
  if raw == 'false' then
    return false
  end

  if (raw:sub(1, 1) == '"' and raw:sub(-1) == '"') or (raw:sub(1, 1) == "'" and raw:sub(-1) == "'") then
    return raw:sub(2, -2)
  end

  if raw:sub(1, 1) == '[' and raw:sub(-1) == ']' and raw:find(',') then
    local inner = raw:sub(2, -2)
    if inner == '' then
      return {}
    end

    local items = {}
    for item in inner:gmatch('[^,]+') do
      table.insert(items, parse_scalar(item))
    end
    return items
  end

  local number = tonumber(raw)
  if number ~= nil then
    return number
  end

  return raw
end

local function next_meaningful_line(lines, start_index)
  for index = start_index, #lines do
    local line = lines[index]
    if line and line:match('%S') and not line:match('^%s*#') then
      return vim.trim(line), #(line:match('^%s*') or '')
    end
  end

  return nil, nil
end

function M.parse_string(content)
  local lines = vim.split(content or '', '\n', { plain = true })
  local root = {}
  local stack = {
    {
      indent = -1,
      container = root,
      type = 'map',
    },
  }

  for index, line in ipairs(lines) do
    if line:match('%S') and not line:match('^%s*#') then
      local indent = #(line:match('^%s*') or '')
      local trimmed = vim.trim(line)

      while #stack > 1 and indent <= stack[#stack].indent do
        table.remove(stack)
      end

      local current = stack[#stack]

      if vim.startswith(trimmed, '- ') then
        if current.type == 'list' then
          table.insert(current.container, parse_scalar(trimmed:sub(3)))
        end
      else
        local key, raw = trimmed:match('^([^:]+):%s*(.*)$')
        if key then
          key = vim.trim(key)
          if raw == '' then
            local next_trimmed, next_indent = next_meaningful_line(lines, index + 1)
            local container
            local container_type
            if next_trimmed and next_indent and next_indent > indent and vim.startswith(next_trimmed, '- ') then
              container = {}
              container_type = 'list'
            else
              container = {}
              container_type = 'map'
            end
            current.container[key] = container
            table.insert(stack, {
              indent = indent,
              container = container,
              type = container_type,
            })
          else
            current.container[key] = parse_scalar(raw)
          end
        end
      end
    end
  end

  return root
end

return M
