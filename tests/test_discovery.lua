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

  eq(helpers.labels(items), { 'deploy-preview', 'explain-code', 'local-only', 'review-pr' })

  local review = helpers.find_item(items, 'review-pr')
  eq(review.description, 'Project review skill')
  eq(review.root_scope, 'repo')

  local nested = helpers.find_item(items, 'local-only')
  eq(nested.root_scope, 'repo')
  eq(nested.agent, 'codex')

  local deploy = helpers.find_item(items, 'deploy-preview')
  eq(deploy.agent, 'codex')
  eq(deploy.trigger_family, 'dollar')
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

return T
