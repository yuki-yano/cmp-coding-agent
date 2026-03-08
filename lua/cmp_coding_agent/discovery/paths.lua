local item = require('cmp_coding_agent.item')
local util = require('cmp_coding_agent.util')

local M = {}

local function choose_root(opts)
  if opts.root == 'buffer' then
    return util.normalize(opts.buffer_dir)
  end
  if opts.root == 'cwd' then
    return util.normalize((vim.uv or vim.loop).cwd())
  end
  return util.normalize(opts.project_root) or util.normalize(opts.buffer_dir)
end

local function preview_for(path, max_lines)
  if not max_lines or max_lines <= 0 or not util.is_file(path) then
    return nil
  end

  local lines = util.read_lines(path, max_lines)
  if #lines == 0 then
    return nil
  end

  return {
    kind = 'markdown',
    value = table.concat({
      '```text',
      table.concat(lines, '\n'),
      '```',
      '',
      '`' .. path .. '`',
    }, '\n'),
  }
end

local function resolve_search_state(opts)
  local raw = (opts.token or ''):sub(2)
  local root = choose_root(opts)
  local base_root = root

  if vim.startswith(raw, './') or vim.startswith(raw, '../') then
    base_root = util.normalize(opts.buffer_dir) or root
  end

  local dir_prefix = raw:match('^(.*)/') or ''
  local fragment = raw:match('([^/]*)$') or raw
  local search_dir = dir_prefix ~= '' and util.join(base_root, dir_prefix) or base_root
  local display_prefix = dir_prefix
  if display_prefix ~= '' and not vim.endswith(display_prefix, '/') then
    display_prefix = display_prefix .. '/'
  end

  return {
    root = root,
    base_root = base_root,
    search_dir = search_dir,
    display_prefix = display_prefix,
    fragment = fragment,
    raw = raw,
  }
end

local function build_item(entry_path, is_dir, opts, label)
  local insert = opts.preserve_at_prefix == false and label or '@' .. label

  return item.from_record({
    label = label,
    insert_text = insert,
    filter_text = '@' .. label,
    agent = nil,
    source_kind = is_dir and 'directory' or 'file',
    documentation = preview_for(entry_path, opts.preview_lines),
    path = entry_path,
    sort_group = 5,
    sort_subgroup = is_dir and 0 or 1,
  })
end

local function include_hidden(name, show_hidden)
  return show_hidden or not vim.startswith(name, '.')
end

local function collect_shallow(state, opts)
  local results = {}

  for _, entry in ipairs(util.fs_entries(state.search_dir)) do
    if include_hidden(entry.name, opts.show_hidden) and util.starts_with_casefold(entry.name, state.fragment) then
      local is_dir = entry.type == 'directory'
      local label = state.display_prefix .. entry.name .. (is_dir and '/' or '')
      table.insert(results, build_item(entry.path, is_dir, opts, label))
    end
  end

  return results
end

local function deep_match(state, label, name)
  return util.starts_with_casefold(label, state.raw) or util.starts_with_casefold(name, state.fragment)
end

local function collect_deep(state, opts)
  local results = {}
  local stack = { state.search_dir }

  while #stack > 0 do
    local current = table.remove(stack)
    for _, entry in ipairs(util.fs_entries(current)) do
      if include_hidden(entry.name, opts.show_hidden) then
        local is_dir = entry.type == 'directory'
        local label = util.relpath(entry.path, state.base_root)
        if is_dir then
          label = label .. '/'
          table.insert(stack, entry.path)
        end

        if deep_match(state, label, entry.name) then
          table.insert(results, build_item(entry.path, is_dir, opts, label))
          if opts.max_items and #results >= opts.max_items then
            return results
          end
        end
      end
    end
  end

  return results
end

function M.complete(opts)
  opts = opts or {}
  local state = resolve_search_state(opts)
  if not state.search_dir or not util.is_dir(state.search_dir) then
    return {}
  end

  local results = opts.deep_search and collect_deep(state, opts) or collect_shallow(state, opts)

  if opts.max_items and #results > opts.max_items then
    return vim.list_slice(results, 1, opts.max_items)
  end

  return results
end

return M
