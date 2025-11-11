local M = {}

local state = {
  pending = nil,
}

local function feed(keys, opts)
  opts = opts or {}
  local seq = keys
  if opts.from_insert then
    seq = '<C-o>' .. seq
  end
  local termcodes = vim.api.nvim_replace_termcodes(seq, true, false, true)
  vim.api.nvim_feedkeys(termcodes, 'n', false)
end

local function restore_register(name, value, regtype)
  if name then
    vim.fn.setreg(name, value, regtype)
  end
end

local function get_register_content(preferred)
  local reg = preferred
  if not reg or reg == '' then
    reg = vim.v.register ~= '' and vim.v.register or '"'
  end
  local content = vim.fn.getreg(reg)
  local regtype = vim.fn.getregtype(reg)
  return reg, content, regtype
end

local function split_register_lines(content, regtype)
  local lines = vim.split(content, '\n', true)
  if regtype == 'V' or regtype == 'v' then
    if lines[#lines] == '' then
      table.remove(lines)
    end
  end
  if #lines == 0 then
    lines = { '' }
  end
  return lines
end

local function delete_range(range_type)
  local start_pos = vim.api.nvim_buf_get_mark(0, '[')
  local end_pos = vim.api.nvim_buf_get_mark(0, ']')
  if not start_pos or not end_pos then
    return false, 'missing range marks'
  end

  local sr, sc = start_pos[1] - 1, start_pos[2]
  local er, ec = end_pos[1] - 1, end_pos[2]

  if range_type == 'line' then
    ec = 0
    er = er + 1
    vim.api.nvim_buf_set_lines(0, sr, er, false, {})
    return true
  elseif range_type == 'block' then
    return false, 'blockwise put is not supported yet'
  else
    ec = ec + 1
    vim.api.nvim_buf_set_text(0, sr, sc, er, ec, {})
    return true
  end
end

local function do_put(pending, range_type)
  local register, content, regtype = get_register_content(pending.register)
  local default_content = vim.fn.getreg('"')
  local default_type = vim.fn.getregtype('"')
  local ok, err = delete_range(range_type)
  if not ok then
    vim.notify(string.format('flash put: %s', err), vim.log.levels.WARN)
    return
  end
  local lines = split_register_lines(content, regtype)
  vim.fn.setreg('"', content, regtype)
  local status, put_err = pcall(vim.api.nvim_put, lines, regtype == 'V', pending.which == 'p', true)
  vim.fn.setreg('"', default_content, default_type)
  if not status then
    vim.notify(string.format('flash put failed: %s', put_err), vim.log.levels.ERROR)
  end
  restore_register(register, content, regtype)
end

function M.start_put(which, opts)
  opts = opts or {}
  state.pending = {
    which = which or 'p',
    register = opts.register,
  }
  vim.go.operatorfunc = 'v:lua.__flash_put_handler'
  local prefix = ''
  if opts.register and opts.register ~= '' then
    prefix = '"' .. opts.register
  end
  feed(prefix .. 'g@r', { from_insert = opts.from_insert })
end

function M.put_handler(range_type)
  local pending = state.pending
  state.pending = nil
  if not pending then
    return
  end
  do_put(pending, range_type)
end

function M.operator(op, opts)
  opts = opts or {}
  local prefix = ''
  if opts.register and opts.register ~= '' then
    prefix = '"' .. opts.register
  end
  return function()
    feed(prefix .. op .. 'r', { from_insert = opts.from_insert })
  end
end

function M.execute_normal(cmd, opts)
  opts = opts or {}
  return function()
    feed(cmd, { from_insert = opts.from_insert })
  end
end

function M.finish_at_cursor()
  if not state.pending then
    return false
  end
  local pending = state.pending
  state.pending = nil
  do_put(pending, 'char')
  return true
end

function M.cancel()
  state.pending = nil
end

return M

---@diagnostic disable-next-line: lowercase-global
function _G.__flash_put_handler(range_type)
  require('custom.remote_ops').put_handler(range_type)
end

