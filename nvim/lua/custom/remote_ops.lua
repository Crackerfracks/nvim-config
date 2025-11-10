local M = {}

local function termcodes(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

local function feed(keys)
  vim.api.nvim_feedkeys(termcodes(keys), 'n', false)
end

local function in_insert()
  local mode = vim.fn.mode()
  return mode:sub(1, 1) == 'i'
end

local function start_sequence(seq, opts)
  opts = opts or {}
  local prefix = ''
  if in_insert() then
    prefix = '<C-o>'
  end
  feed(prefix .. seq)
  if opts.remote ~= false then
    vim.schedule(function()
      local ok, flash = pcall(require, 'flash')
      if ok then
        flash.remote(opts.remote_opts)
      end
    end)
  end
  if type(opts.post) == 'function' then
    vim.schedule(opts.post)
  end
end

local function range_positions(type_)
  local start_pos = vim.fn.getpos("'[")
  local end_pos = vim.fn.getpos("']")
  local start_row = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_row = end_pos[2] - 1
  local end_col = end_pos[3]
  local linewise = type_:sub(1, 1) == 'V' or type_ == 'line'
  local block = type_:sub(1, 1) == '\22'

  if linewise then
    return {
      mode = 'line',
      start_row = start_row,
      end_row = end_pos[2],
    }
  end

  if block then
    -- Treat block-wise selections as characterwise replacements.
    type_ = 'char'
  end

  return {
    mode = 'char',
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
  }
end

local function replace_range(lines, type_)
  local bufnr = vim.api.nvim_get_current_buf()
  local range = range_positions(type_)

  if range.mode == 'line' then
    vim.api.nvim_buf_set_lines(bufnr, range.start_row, range.end_row, false, lines)
    return
  end

  vim.api.nvim_buf_set_text(bufnr, range.start_row, range.start_col, range.end_row, range.end_col, lines)
end

local function get_register()
  local reg = vim.v.register
  if reg == '' then
    reg = '"'
  end
  local regtype = vim.fn.getregtype(reg)
  local lines = vim.fn.getreg(reg, 1, true)
  return reg, regtype, lines
end

local function normalize_lines(lines, regtype)
  if regtype:sub(1, 1) == 'V' and lines[#lines] ~= '' then
    table.insert(lines, '')
  end
  return lines
end

local function start_custom_operator(func)
  vim.go.operatorfunc = "v:lua.require'custom.remote_ops'." .. func
  local prefix = ''
  if in_insert() then
    prefix = '<C-o>'
  end
  feed(prefix .. 'g@')
  vim.schedule(function()
    local ok, flash = pcall(require, 'flash')
    if ok then
      flash.remote()
    end
  end)
end

function M.start_operator(seq, opts)
  start_sequence(seq, vim.tbl_extend('force', { remote = true }, opts or {}))
end

function M.start_put_after()
  start_custom_operator('operator_put_after')
end

function M.start_put_before()
  start_custom_operator('operator_put_before')
end

function M.start_yank()
  M.start_operator('y')
end

function M.start_delete()
  M.start_operator('d')
end

function M.start_change()
  M.start_operator('c')
end

function M.start_replace()
  M.start_operator('gr')
end

function M.start_replace_mode()
  start_sequence('R', { remote = false })
end

local surround_targets = { 'a', 'd', 'f', 'F', 'h', 'r' }

for _, key in ipairs(surround_targets) do
  M['start_surround_' .. key] = function()
    start_sequence('<leader>s' .. key, { remote = true })
  end
end

function M.operator_put_after(type_)
  local _, regtype, lines = get_register()
  lines = normalize_lines(vim.deepcopy(lines), regtype)
  replace_range(lines, type_)
end

function M.operator_put_before(type_)
  local _, regtype, lines = get_register()
  lines = normalize_lines(vim.deepcopy(lines), regtype)
  replace_range(lines, type_)
end

return M
