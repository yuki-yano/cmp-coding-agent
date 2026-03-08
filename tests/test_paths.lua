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

T['paths.complete()'] = new_set()

T['paths.complete()']['builds relative path items and previews files'] = function()
  local project = helpers.new_temp_dir('paths')
  table.insert(temp_dirs, project)

  helpers.write_file(helpers.join(project, 'src/main.lua'), "print('hello')\nprint('world')\n")
  helpers.write_file(helpers.join(project, 'src/module/init.lua'), 'return { ok = true }\n')
  helpers.write_file(helpers.join(project, '.secret'), 'hidden\n')

  local paths = require('cmp_coding_agent.discovery.paths')
  local items = paths.complete({
    token = '@src/m',
    buffer_dir = project,
    project_root = project,
    preserve_at_prefix = false,
    show_hidden = false,
    max_items = 20,
    preview_lines = 2,
  })

  local main = helpers.find_item(items, 'src/main.lua')
  eq(main.insertText, 'src/main.lua')
  eq(main.filterText, '@src/main.lua')
  helpers.expect.match(main.documentation.value, "print%('hello'%)")

  local module_dir = helpers.find_item(items, 'src/module/')
  eq(module_dir.insertText, 'src/module/')
  eq(module_dir.filterText, '@src/module/')
end

T['paths.complete()']['respects preserve_at_prefix and hidden file setting'] = function()
  local project = helpers.new_temp_dir('paths-hidden')
  table.insert(temp_dirs, project)

  helpers.write_file(helpers.join(project, '.env'), 'TOKEN=value\n')

  local paths = require('cmp_coding_agent.discovery.paths')

  eq(
    paths.complete({
      token = '@.',
      buffer_dir = project,
      project_root = project,
      preserve_at_prefix = true,
      show_hidden = false,
      max_items = 20,
      preview_lines = 0,
    }),
    {}
  )

  local items = paths.complete({
    token = '@.',
    buffer_dir = project,
    project_root = project,
    preserve_at_prefix = true,
    show_hidden = true,
    max_items = 20,
    preview_lines = 0,
  })

  local env_file = helpers.find_item(items, '.env')
  eq(env_file.insertText, '@.env')
  eq(env_file.filterText, '@.env')
end

T['paths.complete()']['supports optional deep search for nested paths'] = function()
  local project = helpers.new_temp_dir('paths-deep')
  table.insert(temp_dirs, project)

  helpers.write_file(helpers.join(project, 'src/nested/api.lua'), 'return true\n')
  helpers.write_file(helpers.join(project, 'docs/api.md'), '# API\n')

  local paths = require('cmp_coding_agent.discovery.paths')

  eq(
    paths.complete({
      token = '@api',
      buffer_dir = project,
      project_root = project,
      preserve_at_prefix = false,
      show_hidden = true,
      max_items = 20,
      preview_lines = 0,
      deep_search = false,
    }),
    {}
  )

  local items = paths.complete({
    token = '@api',
    buffer_dir = project,
    project_root = project,
    preserve_at_prefix = false,
    show_hidden = true,
    max_items = 20,
    preview_lines = 0,
    deep_search = true,
  })

  eq(helpers.labels(items), { 'docs/api.md', 'src/nested/api.lua' })
end

return T
