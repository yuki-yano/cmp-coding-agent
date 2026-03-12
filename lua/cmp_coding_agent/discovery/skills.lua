local frontmatter = require('cmp_coding_agent.parser.frontmatter')
local simple_yaml = require('cmp_coding_agent.parser.simple_yaml')
local util = require('cmp_coding_agent.util')

local M = {}

local function agent_enabled(mode, agent)
  mode = mode or 'both'

  if mode == 'all' then
    return true
  end

  if mode == 'both' then
    return agent == 'claude' or agent == 'codex'
  end

  return mode == agent
end

local function add_root(result, seen, path, agent, trigger_family, root_scope)
  path = util.normalize(path)
  local key = string.format('%s|%s|%s', agent, trigger_family, path or '')
  if not path or not util.is_dir(path) or seen[key] then
    return
  end

  seen[key] = true
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
  local env = opts.env or {}
  local agent_mode = opts.agent_mode or 'both'
  local repo_buffer_dir = buffer_dir

  if
    project_root
    and repo_buffer_dir
    and repo_buffer_dir ~= project_root
    and not vim.startswith(repo_buffer_dir, project_root .. '/')
  then
    repo_buffer_dir = project_root
  end

  if project_root and include.repo_copilot == true and agent_enabled(agent_mode, 'copilot') then
    for _, ancestor in ipairs(util.ancestors(repo_buffer_dir or project_root, project_root)) do
      add_root(roots, seen, util.join(ancestor, '.github/skills'), 'copilot', 'slash', 'repo')
    end
  end

  if project_root and include.repo_agents ~= false then
    for _, ancestor in ipairs(util.ancestors(repo_buffer_dir or project_root, project_root)) do
      if agent_enabled(agent_mode, 'codex') then
        add_root(roots, seen, util.join(ancestor, '.agents/skills'), 'codex', 'dollar', 'repo')
      end
      if agent_enabled(agent_mode, 'copilot') then
        add_root(roots, seen, util.join(ancestor, '.agents/skills'), 'copilot', 'slash', 'repo')
      end
    end
  end

  if project_root and include.repo_copilot == true and agent_enabled(agent_mode, 'copilot') then
    add_root(roots, seen, util.join(project_root, '.claude/skills'), 'copilot', 'slash', 'repo')
  end

  if project_root and include.repo_claude ~= false and agent_enabled(agent_mode, 'claude') then
    add_root(roots, seen, util.join(project_root, '.claude/skills'), 'claude', 'slash', 'repo')
  end
  if project_root and include.repo_codex ~= false and agent_enabled(agent_mode, 'codex') then
    add_root(roots, seen, util.join(project_root, '.codex/skills'), 'codex', 'dollar', 'repo')
  end

  if home_dir and include.user_agents ~= false and agent_enabled(agent_mode, 'codex') then
    add_root(roots, seen, util.join(home_dir, '.agents/skills'), 'codex', 'dollar', 'user')
  end
  if home_dir and include.user_claude ~= false and agent_enabled(agent_mode, 'claude') then
    add_root(roots, seen, util.join(home_dir, '.config/claude/skills'), 'claude', 'slash', 'user')
    add_root(roots, seen, util.join(home_dir, '.claude/skills'), 'claude', 'slash', 'user')
  end
  if include.user_copilot == true and agent_enabled(agent_mode, 'copilot') then
    local copilot_home = util.normalize(env.COPILOT_HOME) or (home_dir and util.join(home_dir, '.copilot')) or nil
    local copilot_scope = env.COPILOT_HOME and 'config' or 'user'

    if copilot_home then
      add_root(roots, seen, util.join(copilot_home, 'skills'), 'copilot', 'slash', copilot_scope)
    end
    if home_dir then
      add_root(roots, seen, util.join(home_dir, '.claude/skills'), 'copilot', 'slash', 'user')
    end
    for _, path in ipairs(util.split_csv_paths(env.COPILOT_SKILLS_DIRS)) do
      add_root(roots, seen, path, 'copilot', 'slash', 'config')
    end
  end
  if home_dir and include.user_codex ~= false and agent_enabled(agent_mode, 'codex') then
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
  if root.trigger_family == 'slash' and parsed.meta['user-invocable'] == false and not opts.include_non_user_invocable then
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
