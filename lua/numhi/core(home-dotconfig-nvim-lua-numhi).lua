--DO NOT DELETE LINE - THIS FILE LIVES @ filepath="~/.config/nvim/lua/numhi/core.lua"
--[[-------------------------------------------------------------------
Heavy-lifting logic: extmarks, colour maths, history, labels, prompt
---------------------------------------------------------------------]]
local C        = {}
local palettes = require("numhi.palettes").base
local hsluv    = require("hsluv")
local api      = vim.api

local unpack_ = table.unpack or unpack      -- Lua 5.1 fallback

local ns_ids   = {}        -- palette → namespace id
local State                     -- back-pointer filled by setup()
---------------------------------------------------------------------
--  Helpers ----------------------------------------------------------
---------------------------------------------------------------------
local function slot_to_color(pal, slot)
  local base_hex = palettes[pal][((slot - 1) % 10) + 1]
  if slot <= 10 then return base_hex end
  local k       = math.floor((slot - 1) / 10)          -- 1-9
  local h, s, l = unpack_(hsluv.hex_to_hsluv("#" .. base_hex))
  l             = math.max(15, math.min(95, l + (k * 6 - 3)))
  return hsluv.hsluv_to_hex { h, s, l }:sub(2)         -- strip '#'
end

local function contrast_fg(hex)
  local r = tonumber(hex:sub(1, 2), 16) / 255
  local g = tonumber(hex:sub(3, 4), 16) / 255
  local b = tonumber(hex:sub(5, 6), 16) / 255
  local yiq = r * 0.299 + g * 0.587 + b * 0.114
  return (yiq > 0.55) and "#000000" or "#ffffff"
end

local function ensure_hl(pal, slot)
  local group = ("NumHi_%s_%d"):format(pal, slot)
  if vim.fn.hlexists(group) == 0 then
    local bg = slot_to_color(pal, slot)
    api.nvim_set_hl(0, group, { bg = "#" .. bg, fg = contrast_fg(bg) })
  end
  return group
end

local function line_len(buf, l)
  local txt = api.nvim_buf_get_lines(buf, l, l + 1, true)[1]
  return txt and #txt or 0
end

local function index_of(t, val)
  for i, v in ipairs(t) do if v == val then return i end end
end

-- pretty-print helper -------------------------------------------------
local function echo(chunks, hl)
  -- Accept plain string *or* pre-built {{msg, hl}} list
  if type(chunks) == "string" then
    if hl then
      chunks = { { chunks, hl } }          -- msg + colour
    else
      chunks = { { chunks } }              -- msg only (no nil!)
    end
  end
  if #chunks == 0 or chunks[1][1] == "" then
    vim.api.nvim_echo({}, false, {})       -- clear cmdline quietly
  else
    vim.api.nvim_echo(chunks, false, {})
  end
end

---------------------------------------------------------------------
--  Setup ------------------------------------------------------------
---------------------------------------------------------------------
function C.setup(top)
  State = top.state
  for _, pal in ipairs(State.opts.palettes) do
    ns_ids[pal] = api.nvim_create_namespace("numhi_" .. pal)
  end
end
---------------------------------------------------------------------
--  (optional) word range when no visual selection -------------------
---------------------------------------------------------------------
local function word_range()
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  local line      = api.nvim_get_current_line()
  if col >= #line or not line:sub(col + 1, col + 1):match("[%w_]") then
    return col, col + 1                               -- single char fallback
  end
  local s, e = col, col
  while s > 0         and line:sub(s,     s    ):match("[%w_]") do s = s - 1 end
  while e < #line - 1 and line:sub(e + 2, e + 2):match("[%w_]") do e = e + 1 end
  return s, e + 1                                     -- exclusive end
end
---------------------------------------------------------------------
--  Labels -----------------------------------------------------------
---------------------------------------------------------------------
local function get_label(pal, slot)
  State.labels[pal] = State.labels[pal] or {}
  local label       = State.labels[pal][slot]
  if not label then
    vim.ui.input(
      { prompt = ("NumHi %s-%d label (empty = none): "):format(pal, slot) },
      function(input)
        if input and input ~= "" then State.labels[pal][slot] = input end
      end
    )
  end
  return State.labels[pal][slot]
end
---------------------------------------------------------------------
--  Highlight action -------------------------------------------------
---------------------------------------------------------------------
function C.highlight(slot)
  slot = tonumber(slot)
  if not slot or slot < 1 or slot > 99 then return end

  local pal   = State.active_palette
  local ns    = ns_ids[pal]
  local group = ensure_hl(pal, slot)
  local marks = {}

  local mode = vim.fn.mode()
  if mode:match("^[vV]") then
    local p1 = { unpack(vim.fn.getpos("'<"), 2, 3) }   -- {lnum,col}
    local p2 = { unpack(vim.fn.getpos("'>"), 2, 3) }
    p1[1], p1[2] = p1[1] - 1, p1[2] - 1               -- 0-index
    p2[1], p2[2] = p2[1] - 1, p2[2] - 1
    local last = api.nvim_buf_line_count(0) - 1         -- 0-based last line
    if p1[1] < 0 or p2[1] < 0 then return end           -- marks not set yet
    p1[1] = math.min(p1[1], last)                       -- never past EOF
    p2[1] = math.min(p2[1], last)
    if (p2[1] < p1[1]) or (p2[1] == p1[1] and p2[2] < p1[2]) then
      p1, p2 = p2, p1
    end
    for l = p1[1], p2[1] do
      local s_col = (l == p1[1]) and p1[2] or 0
      local e_col
      if l == p2[1] then                                        -- last line in the range
        e_col = math.min(p2[2] + 1, line_len(0, l))            -- +1, but never past EOL
      else                                                     -- any full intermediate line
        e_col = line_len(0, l)                                 -- highlight right up to EOL
      end
      local id    = api.nvim_buf_set_extmark(
        0,
        ns,
        l,
        s_col,
        {
          id       = nil,
          end_row  = l,
          end_col  = e_col,
          hl_group = group,
          hl_eol   = (e_col == line_len(0, l)),
        }
      )
      table.insert(marks, { 0, id, slot })
    end
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  else
    local lnum, _ = unpack(api.nvim_win_get_cursor(0))
    local s_col, e_col = word_range()
    local id = api.nvim_buf_set_extmark(
      0,
      ns,
      lnum - 1,
      s_col,
      { id = nil, end_row = lnum - 1, end_col = e_col, hl_group = group }
    )
    table.insert(marks, { 0, id, slot })
  end

  -- 2. label (prompt once) ------------------------------------------
  get_label(pal, slot)

  -- 3. history push --------------------------------------------------
  table.insert(State.history, { pal = pal, slot = slot, marks = marks })
  State.redo_stack = {}
  if #State.history > State.opts.history_max then table.remove(State.history, 1) end
end
---------------------------------------------------------------------
--  Collect digits prompt -------------------------------------------
---------------------------------------------------------------------
function C.collect_digits()
  local digits = ""
  local function prompt()
    local pal = State.active_palette
    local txt = (#digits > 0) and digits or "_"
    local hl  = (#digits > 0) and ensure_hl(pal, tonumber(digits)) or "Comment"
    -- one tidy call: the echo() helper will wrap it correctly
    echo(string.format("NumHi %s ◈  slot: %s (1-99)", pal, txt), hl)
  end
  prompt()
  while true do
    local ok, ch = pcall(vim.fn.getchar)
    if not ok then return end
    if type(ch) == "number" then ch = vim.fn.nr2char(ch) end
    if ch:match("%d") and #digits < 2 then
      digits = digits .. ch
      prompt()
    elseif ch == "\r" then
      C.highlight(digits)
      echo("")                                                 -- clear
      return
    else
      echo("")                                                 -- cancel
      return
    end
  end
end
---------------------------------------------------------------------
--  Erase one --------------------------------------------------------
---------------------------------------------------------------------
function C.erase_under_cursor()
  local pal  = State.active_palette
  local ns   = ns_ids[pal]
  local l, c = unpack(api.nvim_win_get_cursor(0))
  local ids  = api.nvim_buf_get_extmarks(0, ns, { l - 1, c }, { l - 1, c + 1 }, {})
  for _, m in ipairs(ids) do api.nvim_buf_del_extmark(0, ns, m[1]) end
end
---------------------------------------------------------------------
--  Undo / redo ------------------------------------------------------
---------------------------------------------------------------------
local function restore_mark(mark, pal)
  local buf, id, slot = mark[1], mark[2], mark[3]
  local pos = api.nvim_buf_get_extmark_by_id(buf, ns_ids[pal], id, {})
  if not pos or not pos[1] then return end
  api.nvim_buf_set_extmark(
    buf,
    ns_ids[pal],
    pos[1],
    pos[2],
    {
      id       = id,
      end_row  = pos[1],
      end_col  = pos[2] + 1,
      hl_group = ensure_hl(pal, slot),
      user_data = { pal = pal, slot = slot, label = get_label(pal, slot) },
    }
  )
end

function C.undo()
  local entry = table.remove(State.history)
  if not entry then return end
  for _, m in ipairs(entry.marks) do api.nvim_buf_del_extmark(m[1], ns_ids[entry.pal], m[2]) end
  table.insert(State.redo_stack, entry)
end

function C.redo()
  local entry = table.remove(State.redo_stack)
  if not entry then return end
  for _, m in ipairs(entry.marks) do restore_mark(m, entry.pal) end
  table.insert(State.history, entry)
end
---------------------------------------------------------------------
--  Palette cycle ----------------------------------------------------
---------------------------------------------------------------------
function C.cycle_palette(step)
  local list = State.opts.palettes
  local idx  = index_of(list, State.active_palette) or 1
  State.active_palette = list[((idx - 1 + step) % #list) + 1]

  -- coloured swatch message
  local chunks = { { "NumHi → palette " .. State.active_palette .. "  ", "ModeMsg" } }
  for n = 1, 10 do
    local hl = ensure_hl(State.active_palette, n)
    table.insert(chunks, { tostring((n % 10 == 0) and 10 or n), hl })
    if n < 10 then table.insert(chunks, { " ", "" }) end
  end
  echo(chunks)
end
---------------------------------------------------------------------
--  Hover label ------------------------------------------------------
---------------------------------------------------------------------
function C.show_label_under_cursor()
  local l, c = unpack(api.nvim_win_get_cursor(0))
  for _, pal in ipairs(State.opts.palettes) do
    local marks = api.nvim_buf_get_extmarks(
      0,
      ns_ids[pal],
      { l - 1, c },
      { l - 1, c + 1 },
      { details = true }
    )
    if #marks > 0 then
      local slot  = tonumber(marks[1][4].hl_group:match("_(%d+)$"))
      local label = State.labels[pal] and State.labels[pal][slot] or ""
      local hl    = ensure_hl(pal, slot)
      local msg   = ("NumHi  %s-%d"):format(pal, slot)
      if label and label ~= "" then msg = msg .. ("  →  %s"):format(label) end
      echo(msg, hl)
      return
    end
  end
end
---------------------------------------------------------------------
--  Expose utils to init.lua -----------------------------------------
---------------------------------------------------------------------
C.ensure_hl = ensure_hl
function C.ns_for(pal) 
  return ns_ids[pal] 
end

return C

