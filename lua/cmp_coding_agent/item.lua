local M = {}

local CompletionItemKind = {
  Text = 1,
  Function = 3,
  Module = 9,
  File = 17,
  Folder = 19,
}

local function detail_for(record)
  if record.detail then
    return record.detail
  end

  if record.source_kind == 'skill' then
    return string.format('(%s skill)', record.agent)
  end
  if record.source_kind == 'command' then
    return '(claude command)'
  end
  if record.source_kind == 'prompt' then
    return '(codex prompt)'
  end
  if record.source_kind == 'builtin' then
    return '(built-in)'
  end
  if record.source_kind == 'directory' then
    return '(directory)'
  end
  if record.source_kind == 'file' then
    return '(file)'
  end

  return ''
end

local function documentation_for(record)
  if record.documentation then
    return record.documentation
  end

  local sections = {}

  if record.description and record.description ~= '' then
    table.insert(sections, record.description)
  end
  if record['argument-hint'] and record['argument-hint'] ~= '' then
    table.insert(sections, '`' .. record['argument-hint'] .. '`')
  end
  if record.excerpt and record.excerpt ~= '' and record.excerpt ~= record.description then
    table.insert(sections, record.excerpt)
  end
  if record.alias_of then
    table.insert(sections, string.format('Alias of `/%s`', record.alias_of))
  end
  if record.path and record.path ~= '' then
    table.insert(sections, '`' .. record.path .. '`')
  end

  if #sections == 0 then
    return nil
  end

  return {
    kind = 'markdown',
    value = table.concat(sections, '\n\n'),
  }
end

local function kind_for(record)
  if record.source_kind == 'file' then
    return CompletionItemKind.File
  end
  if record.source_kind == 'directory' then
    return CompletionItemKind.Folder
  end
  if record.source_kind == 'builtin' then
    return CompletionItemKind.Function
  end
  if record.source_kind == 'prompt' then
    return CompletionItemKind.Text
  end
  return CompletionItemKind.Module
end

function M.from_record(record)
  return {
    label = record.label,
    insertText = record.insert_text,
    filterText = record.filter_text or record.label,
    detail = detail_for(record),
    documentation = documentation_for(record),
    kind = kind_for(record),
    menu = record.menu and ('[' .. record.menu .. ']') or (record.agent and ('[' .. record.agent .. ']') or nil),
    sortText = string.format(
      '%03d:%03d:%s',
      record.sort_group or 50,
      record.sort_subgroup or 50,
      (record.label or ''):lower()
    ),
  }
end

return M
