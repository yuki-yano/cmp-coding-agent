local builtins = require('cmp_coding_agent.discovery.builtins')
local commands = require('cmp_coding_agent.discovery.commands')
local config = require('cmp_coding_agent.config')
local context = require('cmp_coding_agent.context')
local item = require('cmp_coding_agent.item')
local paths = require('cmp_coding_agent.discovery.paths')
local skills = require('cmp_coding_agent.discovery.skills')

local M = {}

local function matches_query(record, query)
  if query == '' then
    return true
  end

  for _, candidate in ipairs(record.match_inputs or { record.label }) do
    if (candidate or ''):lower():find('^' .. vim.pesc(query:lower())) then
      return true
    end
  end

  return false
end

local function sort_records(records)
  table.sort(records, function(left, right)
    if (left.sort_group or 50) ~= (right.sort_group or 50) then
      return (left.sort_group or 50) < (right.sort_group or 50)
    end
    if (left.sort_subgroup or 50) ~= (right.sort_subgroup or 50) then
      return (left.sort_subgroup or 50) < (right.sort_subgroup or 50)
    end
    if (left.agent or '') ~= (right.agent or '') then
      return (left.agent or '') < (right.agent or '')
    end
    return (left.label or '') < (right.label or '')
  end)
end

local function discovery_opts(bufnr)
  local ctx = context.build_discovery_context(bufnr)
  local current = config.get()
  return {
    ctx = ctx,
    config = current,
  }
end

local function collect_skill_records(ctx, current_config, trigger_family)
  local records = {}
  for _, record in
    ipairs(skills.collect({
      project_root = ctx.project_root,
      buffer_dir = ctx.buffer_dir,
      home_dir = ctx.home_dir,
      include = current_config.skills.include,
      include_non_user_invocable = current_config.skills.include_non_user_invocable,
    }))
  do
    if record.trigger_family == trigger_family then
      table.insert(records, record)
    end
  end
  return records
end

local function collect_command_records(ctx)
  return commands.collect({
    project_root = ctx.project_root,
    home_dir = ctx.home_dir,
    env = ctx.env,
  })
end

local function to_completion_items(records, prefix, max_items)
  sort_records(records)
  local items = {}

  for index, record in ipairs(records) do
    record.insert_text = prefix .. record.label
    if record.source_kind == 'prompt' then
      record.insert_text = '/' .. record.label
    end
    record.sort_subgroup = record.sort_subgroup or index
    table.insert(items, item.from_record(record))
    if max_items and #items >= max_items then
      break
    end
  end

  return items
end

function M.collect_slash_items(opts)
  local state = discovery_opts(opts.bufnr)
  local ctx = state.ctx
  local current = state.config
  local query = (opts.token or ''):sub(2)
  local records = {}

  if context.agent_enabled(ctx.agent, 'claude') and current.commands.include_builtins.claude then
    vim.list_extend(
      records,
      builtins.collect({
        agent = 'claude',
        query = query,
        commands_config = current.commands,
      })
    )
  end

  if context.agent_enabled(ctx.agent, 'codex') and current.commands.include_builtins.codex then
    vim.list_extend(
      records,
      builtins.collect({
        agent = 'codex',
        query = query,
        commands_config = current.commands,
      })
    )
  end

  if context.agent_enabled(ctx.agent, 'claude') then
    for _, record in ipairs(collect_skill_records(ctx, current, 'slash')) do
      record.sort_group = 20
      if matches_query(record, query) then
        table.insert(records, record)
      end
    end
  end

  for _, record in ipairs(collect_command_records(ctx)) do
    if record.agent == 'claude' and context.agent_enabled(ctx.agent, 'claude') then
      record.sort_group = 30
      if matches_query(record, query) then
        table.insert(records, record)
      end
    elseif record.agent == 'codex' and context.agent_enabled(ctx.agent, 'codex') and current.prompts.codex.enabled then
      record.sort_group = 40
      if matches_query(record, query) then
        table.insert(records, record)
      end
    end
  end

  local filtered = {}
  for _, record in ipairs(records) do
    if record.source_kind == 'builtin' then
      if matches_query(record, query) then
        table.insert(filtered, record)
      end
    elseif record.source_kind ~= 'builtin' then
      table.insert(filtered, record)
    end
  end

  return to_completion_items(filtered, '/', current.max_items)
end

function M.collect_dollar_items(opts)
  local state = discovery_opts(opts.bufnr)
  local ctx = state.ctx
  local current = state.config
  local query = (opts.token or ''):sub(2)
  local records = {}

  if context.agent_enabled(ctx.agent, 'codex') then
    for _, record in ipairs(collect_skill_records(ctx, current, 'dollar')) do
      record.sort_group = 20
      if matches_query(record, query) then
        table.insert(records, record)
      end
    end
  end

  return to_completion_items(records, '$', current.max_items)
end

function M.collect_at_items(opts)
  local state = discovery_opts(opts.bufnr)
  local ctx = state.ctx
  local current = state.config

  return paths.complete({
    token = opts.token,
    buffer_dir = ctx.buffer_dir,
    project_root = ctx.project_root,
    preserve_at_prefix = current.paths.preserve_at_prefix,
    show_hidden = current.paths.show_hidden,
    max_items = current.max_items,
    preview_lines = current.paths.preview_lines,
    deep_search = current.paths.deep_search,
    root = current.paths.root,
  })
end

return M
