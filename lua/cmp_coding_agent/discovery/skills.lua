local frontmatter = require('cmp_coding_agent.parser.frontmatter')
local simple_yaml = require('cmp_coding_agent.parser.simple_yaml')
local util = require('cmp_coding_agent.util')

local M = {}

local function add_root(result, seen, path, agent, trigger_family, root_scope)
  path = util.normalize(path)
  if not path or not util.is_dir(path) or seen[path] then
    return
  end

  seen[path] = true
  table.insert(result, {
    path = path,
    agent = agent,
    trigger_family = trigger_family,
    root_scope = root_scope,
  })
end

local function collect_roots(opts)
  local roots = {}
  local seen = {}
  local include = opts.include or {}
  local project_root = util.normalize(opts.project_root)
  local buffer_dir = util.normalize(opts.buffer_dir) or project_root
  local home_dir = util.normalize(opts.home_dir)

  if project_root and include.repo_agents ~= false then
    for _, ancestor in ipairs(util.ancestors(buffer_dir or project_root, project_root)) do
      add_root(roots, seen, util.join(ancestor, '.agents/skills'), 'codex', 'dollar', 'repo')
    end
  end

  if project_root and include.repo_claude ~= false then
    add_root(roots, seen, util.join(project_root, '.claude/skills'), 'claude', 'slash', 'repo')
  end
  if project_root and include.repo_codex ~= false then
    add_root(roots, seen, util.join(project_root, '.codex/skills'), 'codex', 'dollar', 'repo')
  end

  if home_dir and include.user_agents ~= false then
    add_root(roots, seen, util.join(home_dir, '.agents/skills'), 'codex', 'dollar', 'user')
  end
  if home_dir and include.user_claude ~= false then
    add_root(roots, seen, util.join(home_dir, '.claude/skills'), 'claude', 'slash', 'user')
  end
  if home_dir and include.user_codex ~= false then
    add_root(roots, seen, util.join(home_dir, '.codex/skills'), 'codex', 'dollar', 'user')
  end

  return roots
end

local function read_openai_metadata(skill_dir)
  local path = util.join(skill_dir, 'agents/openai.yaml')
  if not util.is_file(path) then
    return {}
  end

  return simple_yaml.parse_string(util.read_file(path) or '')
end

local function build_record(root, skill_dir, opts)
  local skill_file = util.join(skill_dir, 'SKILL.md')
  if not util.is_file(skill_file) then
    return nil
  end

  local parsed = frontmatter.parse_file(skill_file)
  if root.agent == 'claude' and parsed.meta['user-invocable'] == false and not opts.include_non_user_invocable then
    return nil
  end

  local openai = read_openai_metadata(skill_dir)
  local name = parsed.meta.name or vim.fs.basename(skill_dir)
  local description = parsed.meta.description
    or openai.interface and openai.interface.short_description
    or parsed.excerpt
    or ''

  return {
    label = name,
    name = name,
    description = description,
    ['argument-hint'] = parsed.meta['argument-hint'],
    excerpt = parsed.excerpt,
    path = skill_file,
    agent = root.agent,
    source_kind = 'skill',
    trigger_family = root.trigger_family,
    root_scope = root.root_scope,
    display_name = openai.interface and openai.interface.display_name or nil,
    allow_implicit_invocation = openai.policy and openai.policy.allow_implicit_invocation or nil,
    match_inputs = { name },
  }
end

function M.collect(opts)
  opts = opts or {}
  local roots = collect_roots(opts)
  local result = {}
  local seen = {}

  for _, root in ipairs(roots) do
    for _, entry in ipairs(util.fs_entries(root.path)) do
      if entry.type == 'directory' then
        local record = build_record(root, entry.path, opts)
        if record then
          local dedupe_key = string.format('%s|%s|%s', record.agent, record.label:lower(), record.trigger_family)
          if not seen[dedupe_key] then
            seen[dedupe_key] = true
            table.insert(result, record)
          end
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
