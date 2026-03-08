local M = {}

local uv = vim.uv or vim.loop

function M.join(...)
  return vim.fs.normalize(table.concat({ ... }, '/'))
end

function M.expand(path)
  if not path or path == '' then
    return path
  end

  if vim.startswith(path, '~') then
    return vim.fn.expand(path)
  end

  return path
end

function M.normalize(path)
  if not path or path == '' then
    return nil
  end

  return vim.fs.normalize(M.expand(path))
end

function M.path_exists(path)
  path = M.normalize(path)
  return path ~= nil and uv.fs_stat(path) ~= nil
end

function M.is_dir(path)
  local stat = uv.fs_stat(M.normalize(path) or '')
  return stat ~= nil and stat.type == 'directory'
end

function M.is_file(path)
  local stat = uv.fs_stat(M.normalize(path) or '')
  return stat ~= nil and stat.type == 'file'
end

function M.read_file(path)
  path = M.normalize(path)
  if not path then
    return nil
  end

  local fd = uv.fs_open(path, 'r', 438)
  if not fd then
    return nil
  end

  local stat = uv.fs_fstat(fd)
  local data = stat and stat.size > 0 and uv.fs_read(fd, stat.size, 0) or ''
  uv.fs_close(fd)
  return data
end

function M.read_lines(path, max_lines)
  local content = M.read_file(path)
  if content == nil then
    return {}
  end

  local lines = vim.split(content, '\n', { plain = true })
  if max_lines and #lines > max_lines then
    return vim.list_slice(lines, 1, max_lines)
  end
  return lines
end

function M.fs_entries(path)
  local result = {}
  path = M.normalize(path)
  if not path or not M.is_dir(path) then
    return result
  end

  for name, type_ in vim.fs.dir(path) do
    table.insert(result, {
      name = name,
      type = type_,
      path = M.join(path, name),
    })
  end

  table.sort(result, function(left, right)
    if left.type ~= right.type then
      return left.type == 'directory'
    end
    return left.name < right.name
  end)

  return result
end

function M.walk_files(root, opts)
  opts = opts or {}
  root = M.normalize(root)
  if not root or not M.is_dir(root) then
    return {}
  end

  local results = {}
  local stack = { root }

  while #stack > 0 do
    local current = table.remove(stack)
    for _, entry in ipairs(M.fs_entries(current)) do
      if entry.type == 'directory' and opts.recursive then
        table.insert(stack, entry.path)
      elseif entry.type == 'file' then
        local include = true
        if opts.extension then
          include = vim.endswith(entry.name, opts.extension)
        end
        if include then
          table.insert(results, entry.path)
        end
      end
    end
  end

  table.sort(results)
  return results
end

function M.resolve_buffer_path(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' then
    return nil
  end
  return M.normalize(name)
end

function M.resolve_buffer_dir(bufnr)
  local path = M.resolve_buffer_path(bufnr)
  if path then
    return vim.fs.dirname(path)
  end
  return M.normalize(uv.cwd())
end

function M.resolve_project_root(bufnr)
  local start = M.resolve_buffer_dir(bufnr) or M.normalize(uv.cwd())
  if not start then
    return nil
  end

  local git_marker = vim.fs.find('.git', {
    path = start,
    upward = true,
    limit = 1,
  })[1]

  if git_marker then
    return vim.fs.dirname(git_marker)
  end

  local cwd = M.normalize(uv.cwd())
  if cwd and (start == cwd or vim.startswith(start, cwd .. '/')) then
    return cwd
  end

  return start
end

function M.ancestors(start, stop)
  local result = {}
  start = M.normalize(start)
  stop = M.normalize(stop)

  if not start then
    return result
  end

  local current = start
  while current do
    table.insert(result, current)
    if stop and current == stop then
      break
    end

    local parent = vim.fs.dirname(current)
    if not parent or parent == current then
      break
    end
    current = parent
  end

  return result
end

function M.relpath(path, root)
  path = M.normalize(path)
  root = M.normalize(root)
  if not path or not root then
    return path
  end

  if path == root then
    return '.'
  end

  local prefix = root .. '/'
  if vim.startswith(path, prefix) then
    return path:sub(#prefix + 1)
  end

  return path
end

function M.extract_trigger_token(line, trigger)
  if not line or line == '' then
    return nil
  end

  local token = line:match('(%S+)$')
  if token and vim.startswith(token, trigger) then
    return token
  end

  return nil
end

function M.trim(value)
  return vim.trim(value or '')
end

function M.starts_with_casefold(value, prefix)
  value = (value or ''):lower()
  prefix = (prefix or ''):lower()
  return prefix == '' or vim.startswith(value, prefix)
end

return M
