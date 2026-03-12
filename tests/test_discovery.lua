local helpers = require('tests.helpers')

local new_set = MiniTest.new_set
local eq = helpers.eq

local temp_dirs = {}

local T = new_set({
  hooks = {
    post_once = function()
      for _, path in ipairs(temp_dirs) do
        helpers.rm_rf(path)
      end
    end,
  },
})

T['skills.collect()'] = new_set()

T['skills.collect()']['collects repo and user skills with precedence'] = function()
  local project = helpers.new_temp_dir('project')
  local home = helpers.new_temp_dir('home')
  table.insert(temp_dirs, project)
  table.insert(temp_dirs, home)

  helpers.write_file(
    helpers.join(project, '.agents/skills/review-pr/SKILL.md'),
    table.concat({
      '---',
      'description: Project review skill',
      '---',
      '',
      'Review the project diff.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(project, '.claude/skills/explain-code/SKILL.md'),
    table.concat({
      '---',
      'name: explain-code',
      'description: Explain selected code',
      '---',
      '',
      'Explain code in Claude.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(project, 'apps/web/.agents/skills/local-only/SKILL.md'),
    table.concat({
      '---',
      'description: Nested repo skill',
      '---',
      '',
      'Only visible from nested app buffers.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.agents/skills/review-pr/SKILL.md'),
    table.concat({
      '---',
      'description: Global review skill',
      '---',
      '',
      'Global version should lose to repo version.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.codex/skills/deploy-preview/SKILL.md'),
    table.concat({
      '---',
      'description: Deploy preview',
      '---',
      '',
      'Deploy preview environments.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.config/claude/skills/agent-browser/SKILL.md'),
    table.concat({
      '---',
      'description: Browser automation skill',
      '---',
      '',
      'Automate browser actions.',
    }, '\n')
  )

  local items = require('cmp_coding_agent.discovery.skills').collect({
    project_root = project,
    buffer_dir = helpers.join(project, 'apps/web'),
    home_dir = home,
    include_non_user_invocable = false,
    include = {
      repo_agents = true,
      repo_claude = true,
      repo_codex = true,
      user_agents = true,
      user_claude = true,
      user_codex = true,
    },
  })

  eq(helpers.labels(items), { 'agent-browser', 'deploy-preview', 'explain-code', 'local-only', 'review-pr' })

  local review = helpers.find_item(items, 'review-pr')
  eq(review.description, 'Project review skill')
  eq(review.root_scope, 'repo')

  local nested = helpers.find_item(items, 'local-only')
  eq(nested.root_scope, 'repo')
  eq(nested.agent, 'codex')

  local deploy = helpers.find_item(items, 'deploy-preview')
  eq(deploy.agent, 'codex')
  eq(deploy.trigger_family, 'dollar')

  local browser = helpers.find_item(items, 'agent-browser')
  eq(browser.agent, 'claude')
  eq(browser.trigger_family, 'slash')
  eq(browser.root_scope, 'user')
end

T['skills.collect()']['uses project_root when buffer_dir is outside the repo'] = function()
  local project = helpers.new_temp_dir('project-outside-buffer')
  local home = helpers.new_temp_dir('home-outside-buffer')
  local scratch = helpers.new_temp_dir('scratch-outside-buffer')
  table.insert(temp_dirs, project)
  table.insert(temp_dirs, home)
  table.insert(temp_dirs, scratch)

  helpers.write_file(
    helpers.join(project, '.agents/skills/review-pr/SKILL.md'),
    table.concat({
      '---',
      'description: Project review skill',
      '---',
      '',
      'Review the project diff.',
    }, '\n')
  )

  local items = require('cmp_coding_agent.discovery.skills').collect({
    project_root = project,
    buffer_dir = scratch,
    home_dir = home,
    include_non_user_invocable = false,
    include = {
      repo_agents = true,
      repo_claude = true,
      repo_codex = true,
      user_agents = true,
      user_claude = true,
      user_codex = true,
    },
  })

  local review = helpers.find_item(items, 'review-pr')
  eq(review.root_scope, 'repo')
end

T['skills.collect()']['collects copilot skills from repo, shared, user, and env roots'] = function()
  local project = helpers.new_temp_dir('copilot-project')
  local home = helpers.new_temp_dir('copilot-home')
  local extra = helpers.new_temp_dir('copilot-extra')
  table.insert(temp_dirs, project)
  table.insert(temp_dirs, home)
  table.insert(temp_dirs, extra)

  helpers.write_file(
    helpers.join(project, '.github/skills/root-skill/SKILL.md'),
    table.concat({
      '---',
      'description: Project GitHub skill',
      '---',
      '',
      'Available for Copilot slash completion.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(project, '.agents/skills/shared-skill/SKILL.md'),
    table.concat({
      '---',
      'description: Shared repo skill',
      '---',
      '',
      'Available for Codex and Copilot.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(project, '.claude/skills/claude-compatible/SKILL.md'),
    table.concat({
      '---',
      'description: Claude compatible skill',
      '---',
      '',
      'Shared with Copilot.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(project, 'apps/.github/skills/nested-skill/SKILL.md'),
    table.concat({
      '---',
      'description: Nested GitHub skill',
      '---',
      '',
      'Takes precedence from nested buffer directories.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(project, 'apps/.github/skills/shared-priority/SKILL.md'),
    table.concat({
      '---',
      'description: Repo priority wins',
      '---',
      '',
      'Repo version should win.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.copilot/skills/user-copilot/SKILL.md'),
    table.concat({
      '---',
      'description: User Copilot skill',
      '---',
      '',
      'Available from COPILOT_HOME.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.claude/skills/user-claude-compatible/SKILL.md'),
    table.concat({
      '---',
      'description: User Claude compatible skill',
      '---',
      '',
      'Shared with Copilot.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.copilot/skills/shared-priority/SKILL.md'),
    table.concat({
      '---',
      'description: User priority loses',
      '---',
      '',
      'User version should lose.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(extra, 'extra-skill/SKILL.md'),
    table.concat({
      '---',
      'description: Extra env skill',
      '---',
      '',
      'Loaded from COPILOT_SKILLS_DIRS.',
    }, '\n')
  )

  local items = require('cmp_coding_agent.discovery.skills').collect({
    project_root = project,
    buffer_dir = helpers.join(project, 'apps/web'),
    home_dir = home,
    agent_mode = 'copilot',
    env = {
      COPILOT_HOME = helpers.join(home, '.copilot'),
      COPILOT_SKILLS_DIRS = extra,
    },
    include_non_user_invocable = false,
    include = {
      repo_agents = true,
      repo_claude = false,
      repo_codex = false,
      repo_copilot = true,
      user_agents = false,
      user_claude = false,
      user_codex = false,
      user_copilot = true,
    },
  })

  eq(
    helpers.labels(items),
    {
      'claude-compatible',
      'extra-skill',
      'nested-skill',
      'root-skill',
      'shared-priority',
      'shared-skill',
      'user-claude-compatible',
      'user-copilot',
    }
  )

  local nested = helpers.find_item(items, 'nested-skill')
  eq(nested.agent, 'copilot')
  eq(nested.trigger_family, 'slash')

  local shared = helpers.find_item(items, 'shared-skill')
  eq(shared.agent, 'copilot')
  eq(shared.trigger_family, 'slash')

  local priority = helpers.find_item(items, 'shared-priority')
  eq(priority.description, 'Repo priority wins')

  local extra_skill = helpers.find_item(items, 'extra-skill')
  eq(extra_skill.root_scope, 'config')
end

T['commands.collect()'] = new_set()

T['commands.collect()']['collects claude commands and top-level codex prompts'] = function()
  local project = helpers.new_temp_dir('commands-project')
  local home = helpers.new_temp_dir('commands-home')
  table.insert(temp_dirs, project)
  table.insert(temp_dirs, home)

  helpers.write_file(
    helpers.join(project, '.claude/commands/review/security.md'),
    table.concat({
      '---',
      'description: Security review command',
      'argument-hint: [scope]',
      '---',
      '',
      'Review security implications.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.claude/commands/explain.md'),
    table.concat({
      '---',
      'description: Explain command',
      '---',
      '',
      'Explain the current diff.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.codex/prompts/ship-it.md'),
    table.concat({
      '---',
      'description: Ship current changes',
      'argument-hint: [notes]',
      '---',
      '',
      'Prepare a release summary.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.codex/prompts/nested/skip-me.md'),
    table.concat({
      '---',
      'description: Should be ignored',
      '---',
      '',
      'Nested prompts are unsupported.',
    }, '\n')
  )

  local items = require('cmp_coding_agent.discovery.commands').collect({
    project_root = project,
    home_dir = home,
    env = {},
  })

  eq(helpers.labels(items), { 'explain', 'prompts:ship-it', 'review:security' })

  local review = helpers.find_item(items, 'review:security')
  eq(review.agent, 'claude')
  eq(review['argument-hint'], '[scope]')

  local prompt = helpers.find_item(items, 'prompts:ship-it')
  eq(prompt.agent, 'codex')
  eq(prompt.source_kind, 'prompt')
end

T['commands.collect()']['collects copilot command records from claude command roots'] = function()
  local project = helpers.new_temp_dir('copilot-commands-project')
  local home = helpers.new_temp_dir('copilot-commands-home')
  local config_dir = helpers.new_temp_dir('copilot-commands-config')
  table.insert(temp_dirs, project)
  table.insert(temp_dirs, home)
  table.insert(temp_dirs, config_dir)

  helpers.write_file(
    helpers.join(project, '.claude/commands/research.md'),
    table.concat({
      '---',
      'description: Research the current change',
      'allowed-tools:',
      '  - web_search',
      'disable-model-invocation: true',
      '---',
      '',
      'Gather external references.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.claude/commands/explain.md'),
    table.concat({
      '---',
      'description: Explain current changes',
      '---',
      '',
      'Explain the diff.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(config_dir, 'commands/admin.md'),
    table.concat({
      '---',
      'description: Claude only config command',
      '---',
      '',
      'Only for Claude.',
    }, '\n')
  )

  local items = require('cmp_coding_agent.discovery.commands').collect({
    project_root = project,
    home_dir = home,
    agent_mode = 'copilot',
    env = {
      CLAUDE_CONFIG_DIR = config_dir,
    },
  })

  local explain_copilot
  local research_copilot
  local admin_copilot

  for _, item in ipairs(items) do
    if item.label == 'explain' and item.agent == 'copilot' then
      explain_copilot = item
    elseif item.label == 'research' and item.agent == 'copilot' then
      research_copilot = item
    elseif item.label == 'admin' and item.agent == 'copilot' then
      admin_copilot = item
    end
  end

  eq(explain_copilot.description, 'Explain current changes')
  eq(research_copilot['disable-model-invocation'], true)
  eq(research_copilot['allowed-tools'][1], 'web_search')
  eq(admin_copilot, nil)
end

return T
