local M = {
  file = {},
}

local uv = vim.uv or vim.loop

local function make_key(stat)
  return string.format(
    '%s:%s:%s',
    stat.size or 0,
    stat.mtime and stat.mtime.sec or 0,
    stat.mtime and stat.mtime.nsec or 0
  )
end

function M.clear()
  M.file = {}
end

function M.read_file(path, loader)
  local stat = uv.fs_stat(path)
  if not stat then
    M.file[path] = nil
    return nil
  end

  local key = make_key(stat)
  local cached = M.file[path]
  if cached and cached.key == key then
    return cached.value
  end

  local value = loader(path)
  M.file[path] = {
    key = key,
    value = value,
  }

  return value
end

return M
