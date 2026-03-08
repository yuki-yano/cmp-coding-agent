local helpers = require('tests.helpers')

local new_set = MiniTest.new_set
local eq = helpers.eq

local child = helpers.new_child_neovim()
local temp_dirs = {}

local function count_items(items, label)
  local count = 0
  for _, item in ipairs(items) do
    if item.label == label then
      count = count + 1
    end
  end
  return count
end

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
    end,
    post_once = function()
      child.stop()
      for _, path in ipairs(temp_dirs) do
        helpers.rm_rf(path)
      end
    end,
  },
})

T['source modules'] = new_set()

T['source modules']['slash source returns built-ins, skills, commands, and prompts'] = function()
  local project = helpers.new_temp_dir('slash-project')
  local home = helpers.new_temp_dir('slash-home')
  table.insert(temp_dirs, project)
  table.insert(temp_dirs, home)

  helpers.write_file(
    helpers.join(project, '.claude/skills/review-pr/SKILL.md'),
    table.concat({
      '---',
      'description: Review the current changes',
      '---',
      '',
      'Review the current changes.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(project, '.claude/commands/fix/tests.md'),
    table.concat({
      '---',
      'description: Fix broken tests',
      '---',
      '',
      'Repair the failing test suite.',
    }, '\n')
  )
  helpers.write_file(
    helpers.join(home, '.codex/prompts/release-notes.md'),
    table.concat({
      '---',
      'description: Draft release notes',
      '---',
      '',
      'Prepare release notes.',
    }, '\n')
  )

  child.lua(
    [[
    local project, home = ...
    vim.env.HOME = home
    vim.cmd('cd ' .. vim.fn.fnameescape(project))
    vim.cmd('edit ' .. vim.fn.fnameescape(project .. '/README.md'))
    require('cmp_coding_agent').setup({
      agent = 'both',
      commands = {
        include_builtins = { claude = true, codex = true },
        extra = { claude = {}, codex = {} },
        disabled = { claude = {}, codex = {} },
      },
    })

    require('cmp_coding_agent.source.slash').new():complete({
      context = {
        bufnr = 0,
        cursor_before_line = '/',
      },
    }, function(response)
      _G.cmp_coding_agent_test_items = response.items
    end)
  ]],
    { project, home }
  )
  local items = child.lua_get('_G.cmp_coding_agent_test_items')

  local labels = {}
  for _, item in ipairs(items) do
    labels[item.label] = true
  end

  eq(labels.review, true)
  eq(labels['review-pr'], true)
  eq(labels['fix:tests'], true)
  eq(labels['prompts:release-notes'], true)

  local review = helpers.find_item(items, 'review')
  eq(review.menu, '[Agent]')
  eq(count_items(items, 'compact'), 1)

  local review_pr = helpers.find_item(items, 'review-pr')
  eq(review_pr.menu, '[Claude]')

  local prompt = helpers.find_item(items, 'prompts:release-notes')
  eq(prompt.menu, '[Codex]')
end

T['source modules']['dollar and at sources respect agent and insert settings'] = function()
  local project = helpers.new_temp_dir('dollar-project')
  local home = helpers.new_temp_dir('dollar-home')
  table.insert(temp_dirs, project)
  table.insert(temp_dirs, home)

  helpers.write_file(
    helpers.join(project, '.agents/skills/deploy-preview/SKILL.md'),
    table.concat({
      '---',
      'description: Deploy preview environments',
      '---',
      '',
      'Deploy the preview app.',
    }, '\n')
  )
  helpers.write_file(helpers.join(project, 'src/app.lua'), 'return true\n')

  child.lua(
    [[
    local project, home = ...
    vim.env.HOME = home
    vim.cmd('cd ' .. vim.fn.fnameescape(project))
    vim.cmd('edit ' .. vim.fn.fnameescape(project .. '/src/app.lua'))
    require('cmp_coding_agent').setup({
      agent = 'codex',
      paths = {
        preserve_at_prefix = false,
        show_hidden = false,
        preview_lines = 5,
        root = 'git',
      },
    })

    local dollar_items
    require('cmp_coding_agent.source.dollar').new():complete({
      context = {
        bufnr = 0,
        cursor_before_line = '$de',
      },
    }, function(response)
      dollar_items = response.items
    end)

    local at_items
    require('cmp_coding_agent.source.at').new():complete({
      context = {
        bufnr = 0,
        cursor_before_line = '@src/a',
      },
    }, function(response)
      at_items = response.items
    end)

    _G.cmp_coding_agent_test_result = {
      dollar_items = dollar_items,
      at_items = at_items,
    }
  ]],
    { project, home }
  )
  local result = child.lua_get('_G.cmp_coding_agent_test_result')

  local skill = helpers.find_item(result.dollar_items, 'deploy-preview')
  eq(skill.insertText, '$deploy-preview')
  eq(skill.filterText, '$deploy-preview')
  eq(skill.menu, '[Codex]')

  local file = helpers.find_item(result.at_items, 'src/app.lua')
  eq(file.insertText, 'src/app.lua')
  eq(file.filterText, '@src/app.lua')
end

T['source modules']['at source can enable deep search from setup config'] = function()
  local project = helpers.new_temp_dir('at-deep-project')
  local home = helpers.new_temp_dir('at-deep-home')
  table.insert(temp_dirs, project)
  table.insert(temp_dirs, home)

  helpers.write_file(helpers.join(project, 'src/nested/api.lua'), 'return true\n')

  child.lua(
    [[
    local project, home = ...
    vim.env.HOME = home
    vim.cmd('cd ' .. vim.fn.fnameescape(project))
    vim.cmd('edit ' .. vim.fn.fnameescape(project .. '/README.md'))
    require('cmp_coding_agent').setup({
      agent = 'codex',
      paths = {
        preserve_at_prefix = false,
        deep_search = true,
      },
    })

    require('cmp_coding_agent.source.at').new():complete({
      context = {
        bufnr = 0,
        cursor_before_line = '@api',
      },
    }, function(response)
      _G.cmp_coding_agent_test_at_deep_items = response.items
    end)
  ]],
    { project, home }
  )

  local items = child.lua_get('_G.cmp_coding_agent_test_at_deep_items')
  local file = helpers.find_item(items, 'src/nested/api.lua')
  eq(file.insertText, 'src/nested/api.lua')
  eq(file.filterText, '@src/nested/api.lua')
end

T['source modules']['uses cwd project roots for temp editprompt buffers'] = function()
  local project = helpers.new_temp_dir('cwd-project')
  local home = helpers.new_temp_dir('cwd-home')
  local scratch = helpers.new_temp_dir('cwd-scratch')
  table.insert(temp_dirs, project)
  table.insert(temp_dirs, home)
  table.insert(temp_dirs, scratch)

  vim.fn.mkdir(helpers.join(project, '.git'), 'p')
  helpers.write_file(
    helpers.join(project, '.claude/skills/review-pr/SKILL.md'),
    table.concat({
      '---',
      'description: Review the current changes',
      '---',
      '',
      'Review the current changes.',
    }, '\n')
  )
  helpers.write_file(helpers.join(project, 'src/app.lua'), 'return true\n')
  helpers.write_file(helpers.join(scratch, 'prompt.md'), 'temporary prompt\n')

  child.lua(
    [[
    local project, home, scratch = ...
    vim.env.HOME = home
    vim.cmd('cd ' .. vim.fn.fnameescape(project))
    vim.cmd('edit ' .. vim.fn.fnameescape(scratch .. '/prompt.md'))
    require('cmp_coding_agent').setup({
      agent = 'both',
      paths = {
        preserve_at_prefix = false,
      },
    })

    require('cmp_coding_agent.source.slash').new():complete({
      context = {
        bufnr = 0,
        cursor_before_line = '/re',
      },
    }, function(response)
      _G.cmp_coding_agent_test_cwd_slash_items = response.items
    end)

    require('cmp_coding_agent.source.at').new():complete({
      context = {
        bufnr = 0,
        cursor_before_line = '@src/a',
      },
    }, function(response)
      _G.cmp_coding_agent_test_cwd_at_items = response.items
    end)
  ]],
    { project, home, scratch }
  )

  local slash_items = child.lua_get('_G.cmp_coding_agent_test_cwd_slash_items')
  local at_items = child.lua_get('_G.cmp_coding_agent_test_cwd_at_items')

  local review_pr = helpers.find_item(slash_items, 'review-pr')
  eq(review_pr.menu, '[Claude]')

  local file = helpers.find_item(at_items, 'src/app.lua')
  eq(file.insertText, 'src/app.lua')
end

return T
