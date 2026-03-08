local helpers = require('tests.helpers')

local new_set = MiniTest.new_set
local eq = helpers.eq

local T = new_set()

T['parse_string()'] = new_set()

T['parse_string()']['parses scalar fields, booleans, lists, and excerpt'] = function()
  local parser = require('cmp_coding_agent.parser.frontmatter')
  local result = parser.parse_string(table.concat({
    '---',
    'name: review-pr',
    'description: Review a PR',
    'argument-hint: [pr-number]',
    'user-invocable: false',
    'allowed-tools:',
    '  - Read',
    '  - Bash',
    '---',
    '',
    'Review the current pull request.',
    '',
    'Use ripgrep before opening files.',
  }, '\n'))

  eq(result.meta.name, 'review-pr')
  eq(result.meta.description, 'Review a PR')
  eq(result.meta['argument-hint'], '[pr-number]')
  eq(result.meta['user-invocable'], false)
  eq(result.meta['allowed-tools'], { 'Read', 'Bash' })
  eq(result.excerpt, 'Review the current pull request.')
end

T['parse_string()']['falls back to first paragraph without frontmatter'] = function()
  local parser = require('cmp_coding_agent.parser.frontmatter')
  local result = parser.parse_string(table.concat({
    'Use this command to inspect the repo.',
    '',
    'Additional details follow here.',
  }, '\n'))

  eq(result.meta, {})
  eq(result.excerpt, 'Use this command to inspect the repo.')
end

return T
