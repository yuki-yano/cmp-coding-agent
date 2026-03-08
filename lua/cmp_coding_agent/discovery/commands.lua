local frontmatter = require('cmp_coding_agent.parser.frontmatter')
local util = require('cmp_coding_agent.util')

local M = {}

local function add_root(result, seen, path, kind, agent, root_scope)
  path = util.normalize(path)
  if not path or not util.is_dir(path) or seen[path] then
    return
  end

  seen[path] = true
  table.insert(result, {
    path = path,
    kind = kind,
    agent = agent,
    root_scope = root_scope,
  })
end

local function collect_claude_roots(opts)
  local roots = {}
  local seen = {}
  local env = opts.env or {}
  local project_root = util.normalize(opts.project_root)
  local home_dir = util.normalize(opts.home_dir)

  if env.CLAUDE_CONFIG_DIR then
    add_root(roots, seen, util.join(env.CLAUDE_CONFIG_DIR, 'commands'), 'command', 'claude', 'config')
  end
  if home_dir then
    add_root(roots, seen, util.join(home_dir, '.claude/commands'), 'command', 'claude', 'user')
  end
  if project_root then
    add_root(roots, seen, util.join(project_root, '.claude/commands'), 'command', 'claude', 'repo')
  end

  return roots
end

local function collect_codex_roots(opts)
  local roots = {}
  local seen = {}
  local env = opts.env or {}
  local home_dir = util.normalize(opts.home_dir)

  if env.CODEX_HOME then
    add_root(roots, seen, util.join(env.CODEX_HOME, 'prompts'), 'prompt', 'codex', 'config')
  else
    add_root(roots, seen, util.join(home_dir, '.codex/prompts'), 'prompt', 'codex', 'user')
  end

  return roots
end

local function build_command_record(root, path)
  local parsed = frontmatter.parse_file(path)
  local relative = util.relpath(path, root.path)
  local stem = relative:gsub('%.md$', ''):gsub('[\\/]', ':')

  return {
    label = stem,
    name = stem,
    description = parsed.meta.description or parsed.excerpt or '',
    ['argument-hint'] = parsed.meta['argument-hint'],
    excerpt = parsed.excerpt,
    path = path,
    agent = 'claude',
    source_kind = 'command',
    trigger_family = 'slash',
    root_scope = root.root_scope,
    match_inputs = { stem },
  }
end

local function build_prompt_record(root, path)
  local parsed = frontmatter.parse_file(path)
  local stem = vim.fs.basename(path):gsub('%.md$', '')

  return {
    label = 'prompts:' .. stem,
    name = stem,
    description = parsed.meta.description or parsed.excerpt or '',
    ['argument-hint'] = parsed.meta['argument-hint'],
    excerpt = parsed.excerpt,
    path = path,
    agent = 'codex',
    source_kind = 'prompt',
    trigger_family = 'slash',
    root_scope = root.root_scope,
    match_inputs = {
      'prompts:' .. stem,
      stem,
    },
  }
end

function M.collect(opts)
  opts = opts or {}
  local result = {}
  local seen = {}

  for _, root in ipairs(collect_claude_roots(opts)) do
    for _, path in ipairs(util.walk_files(root.path, { recursive = true, extension = '.md' })) do
      local record = build_command_record(root, path)
      local dedupe_key = string.format('%s|%s', record.agent, record.label:lower())
      if not seen[dedupe_key] then
        seen[dedupe_key] = true
        table.insert(result, record)
      end
    end
  end

  for _, root in ipairs(collect_codex_roots(opts)) do
    for _, entry in ipairs(util.fs_entries(root.path)) do
      if entry.type == 'file' and vim.endswith(entry.name, '.md') then
        local record = build_prompt_record(root, entry.path)
        local dedupe_key = string.format('%s|%s', record.agent, record.label:lower())
        if not seen[dedupe_key] then
          seen[dedupe_key] = true
          table.insert(result, record)
        end
      end
    end
  end

  table.sort(result, function(left, right)
    if left.label ~= right.label then
      return left.label < right.label
    end
    return left.agent < right.agent
  end)

  return result
end

return M
