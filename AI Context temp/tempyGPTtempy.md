### Including full current plugin code (ALL CURRENT MODULES) to minimize hallucination and ensure you have ROCK SOLID CONTEXT

```~/.config/nvim/lua/numhi/core.lua
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

-- lua/numhi/core.lua  (ADD at top of file)
local function has_visual_marks()
  return vim.fn.line("'<") ~= 0 and vim.fn.line("'>") ~= 0
end

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
-- lua/numhi/core.lua  (REPLACE the first 25 lines of C.highlight)
function C.highlight(slot)
  slot = tonumber(slot)
  if not slot or slot < 1 or slot > 99 then return end

  local pal   = State.active_palette
  local ns    = ns_ids[pal]
  local group = ensure_hl(pal, slot)
  local marks = {}

  -- NEW: prefer visual marks if they exist, even in Normal mode
  local v_ok = has_visual_marks()
  local mode = vim.fn.mode()

  if v_ok or mode:match("^[vV]") then
    local p1 = { unpack(vim.fn.getpos("'<"), 2, 3) }
    local p2 = { unpack(vim.fn.getpos("'>"), 2, 3) }
    p1[1], p1[2] = p1[1]-1, p1[2]-1
    p2[1], p2[2] = p2[1]-1, p2[2]-1
    -- … (rest of original Visual branch unchanged) …
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
      -- lua/numhi/collect_digits()  REPLACE the <CR> branch
    elseif ch == "\r" then
      local num = digits
      -- leave Visual and wait one tick so '< and '>' are updated
      vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
        "x", false)
      vim.schedule(function()
        C.highlight(num)
      end)
      echo("")
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

-- In lua/numhi/core.lua, add:
function C.edit_note()
  local pal_list = State.opts.palettes
  local l, c = unpack(api.nvim_win_get_cursor(0))
  -- Search each palette for an extmark at the cursor position
  for _, pal in ipairs(pal_list) do
    local ns = ns_ids[pal]
    local marks = api.nvim_buf_get_extmarks(0, ns, {l-1, c}, {l-1, c}, {details=true})
    if marks and #marks > 0 then
      local m = marks[1]
      local slot = tonumber(m[4].hl_group:match("_(%d+)$"))
      local id = m[1]
      -- Existing note and tags, if any
      local note = (m[4].user_data and m[4].user_data.note) or ""
      local tags = (m[4].user_data and m[4].user_data.tags) or {}

      -- Create a new scratch buffer
      local buf = api.nvim_create_buf(false, true)
      api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
      api.nvim_buf_set_name(buf, ('NumHiNote %s-%d'):format(pal, slot))
      -- Pre-fill with existing note text
      if note ~= "" then
        api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(note, "\\n"))
      end
      api.nvim_buf_set_option(buf, 'filetype', 'markdown')

      -- Open floating window at cursor
      local width = math.floor(vim.o.columns * 0.5)
      local height = math.floor(vim.o.lines * 0.3)
      local win = api.nvim_open_win(buf, true, {
        relative = 'cursor',
        row = 1, col = 0,
        width = width,
        height = height,
        style = 'minimal',
        border = 'rounded',
      })

      -- When writing the buffer, capture content and update extmark
      api.nvim_create_autocmd('BufWriteCmd', {
        buffer = buf,
        callback = function()
          local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
          local content = table.concat(lines, "\\n")
          -- Extract tags (words preceded by #)
          local new_tags = {}
          for _, line in ipairs(lines) do
            for tag in line:gmatch('#(%w+)') do
              table.insert(new_tags, tag)
            end
          end
          -- Update extmark with note and tags
          api.nvim_buf_set_extmark(0, ns, l-1, c, {
            id = id,
            user_data = { note = content, tags = new_tags },
          })
          -- Close the floating window
          if api.nvim_win_is_valid(win) then
            api.nvim_win_close(win, true)
          end
        end,
      })
      return
    end
  end
  print("No NumHi highlight under cursor")
end

return C

```

```~/.config/nvim/lua/numhi/ui.lua
--DO NOT DELETE LINE - THIS FILE LIVES @ filepath="~/.config/nvim/lua/numhi/ui.lua"

local api = vim.api
local M   = {}

-- floating tooltip ------------------------------------------------------
function M.tooltip(pal, slot, label, note)
  if vim.fn.exists("w:numhi_tooltip") == 1 then
    api.nvim_win_close(vim.g.numhi_tooltip, true)
  end
  local buf = api.nvim_create_buf(false, true)
  local lines = { ("%s-%d  %s"):format(pal, slot, label or ""),
                  note or "" }
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local win = api.nvim_open_win(buf, false, {
    relative = "cursor",
    row      = 1,
    col      = 0,
    width    = math.max(12, #lines[1]),
    height   = #lines,
    style    = "minimal",
    border   = "single",
  })
  vim.g.numhi_tooltip = win
  vim.defer_fn(function()
    if api.nvim_win_is_valid(win) then api.nvim_win_close(win, true) end
  end, 4000)                                       -- auto-hide after 4 s
end

return M
```

```~/.config/nvim/lua/numhi/palettes.lua
--DO NOT DELETE LINE - THIS FILE LIVES @ filepath="~/.config/nvim/lua/numhi/palettes.lua"
-- 10 base colours per palette (hex without '#')
local P = {}

P.base = {
  VID = { "ff5555","f1fa8c","50fa7b","8be9fd","bd93f9",
          "ff79c6","ffb86c","8affff","caffbf","ffaec9"},
  PAS = { "f8b5c0","f9d7a1","f9f1a7","b8e8d0","a8d9f0",
          "d0c4f7","f5bde6","c9e4de","fcd5ce","e8c8ff"},
  EAR = { "80664d","a67c52","73624b","4d6658","6d8a6d",
          "8c7156","665746","997950","595e4a","726256"},
  MET = { "d4af37","b87333","c0c0c0","8c7853","b08d57",
          "aaa9ad","e6be8a","9fa2a6","cd7f32","a97142"},
  CYB = { "ff2079","00e5ff","9dff00","ff6f00","ff36ff",
          "00f6ff","b4ff00","ff8c00","ff40ff","00ffff"},
}

return P

```

```~/.config/nvim/lua/numhi/init.lua
--DO NOT DELETE LINE - THIS FILE LIVES @ filepath="~/.config/nvim/lua/numhi/init.lua"
--[[-------------------------------------------------------------------
Numeric-Palette Highlighter — public façade
---------------------------------------------------------------------]]
local M = {}

-- ---------- defaults -----------------------------------------------
local default_opts = {
  palettes     = { "VID", "PAS", "EAR", "MET", "CYB" },
  key_leader   = "<leader><leader>",
  statusline   = true,
  history_max  = 500,
  hover_delay  = 400,            -- ms before label popup
}

M.state = {
  active_palette = "VID",
  history        = {},
  redo_stack     = {},
  labels         = {},           -- pal → slot → string
  opts           = {},
}

local core

-- ---------- setup ---------------------------------------------------
function M.setup(opts)
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})
  M.state.opts = opts
  core = require("numhi.core")
  core.setup(M)

  if opts.statusline then M.attach_statusline() end
  M.create_keymaps()
  M.create_hover_autocmd()
end
-----------------------------------------------------------------------
--  Thin wrappers -----------------------------------------------------
-----------------------------------------------------------------------
for _, f in ipairs {
  "highlight",
  "erase_under_cursor",
  "undo",
  "redo",
  "cycle_palette",
} do
  M[f] = function(...) return core[f](...) end
end
-----------------------------------------------------------------------
--  keymaps -----------------------------------------------------------
-----------------------------------------------------------------------
function M.create_keymaps()
  local leader = M.state.opts.key_leader       -- defaults to "<leader><leader>"
  local function map(lhs, rhs, desc, mode)
    vim.keymap.set(mode or { "n", "v" }, lhs, rhs,
      { silent = true, desc = desc })
  end

  -- 1. bring up digit-collector on  <leader><leader><CR>
  map(leader .. "<CR>", function() require("numhi.core").collect_digits() end,
      "NumHi: highlight with slot")

  -- 2. erase mark under cursor
  map(leader .. "0<CR>", M.erase_under_cursor, "NumHi: erase mark under cursor")

  -- 3. undo / redo
  map(leader .. "u", M.undo,               "NumHi: undo")
  map(leader .. "<C-r>", M.redo,           "NumHi: redo")

  -- (New) Edit note for highlight under cursor
  map(leader .. "n", function() require("numhi.core").edit_note() end,
      "NumHi: edit note for highlight")

  -- 4. palette cycle  (keep on p – only in Normal mode)
  vim.keymap.set("n", leader .. "p",
    function() M.cycle_palette(1) end,
    { silent = true, desc = "NumHi: next palette" })
end

-----------------------------------------------------------------------
--  Status-line component --------------------------------------------
-----------------------------------------------------------------------
function M.status_component()
  local pal = M.state.active_palette
  -- Create a colored block for palette: use slot 1's color as swatch
  local base_hl = core.ensure_hl(pal, 1)
  local swatch = string.format("%%#%s#▉%%*", base_hl)
  -- Build digit indicators as before
  local parts = {}
  for n = 1, 10 do
    local hl = core.ensure_hl(pal, n)
    table.insert(parts, string.format("%%#%s#%s%%*", hl, (n % 10 == 0) and "0" or tostring(n)))
  end
  -- Return something like "[█ PAL 1234567890]"
  return string.format("[%s %s %s] ", swatch, pal, table.concat(parts, ""))
end

-----------------------------------------------------------------------
--  Attach to user’s status-line impls (Mini / lualine / vanilla) -----
-----------------------------------------------------------------------
function M.attach_statusline()
  vim.schedule(function()   -- <-- wrap everything that follows
    -- 1. Mini.statusline
    local ok_mini, mini = pcall(require, "mini.statusline")
    if ok_mini then
      local orig = mini.section_window
      mini.section_window = function() return M.status_component() .. (orig and orig() or "") end
      return
    end

    -- 2. lualine (Kickstart default)
    local ok_lualine, lualine = pcall(require, "lualine")
    if ok_lualine then
      local comp = function() return M.status_component() end
      -- schedule so we run *after* user’s lualine.setup
      vim.schedule(function()
        local cfg = lualine.get_config and lualine.get_config() or {}
        cfg.sections             = cfg.sections             or {}
        cfg.sections.lualine_c   = cfg.sections.lualine_c   or {}
        table.insert(cfg.sections.lualine_c, 1, comp)
        lualine.setup(cfg)
      end)
      return
    end

    -- 3. plain string statusline
    vim.o.statusline = "%{%v:lua.require'numhi'.status_component()%}" .. vim.o.statusline
  end)
end

-- vim.api.nvim_create_autocmd("CursorHold", {
--   callback = function()
--     local pal  = require("numhi").state.active_palette
--     local ns   = require("numhi.core").ns_for(pal)     -- helper you expose
--     local l,c  = unpack(vim.api.nvim_win_get_cursor(0))
--     local m    = vim.api.nvim_buf_get_extmarks(0, ns,
--                  {l-1,c}, {l-1,c+1}, { details = true })[1]
--     if not m   then return end
--     local ud   = m[4].user_data
--     require("numhi.ui").tooltip(pal, ud.slot, ud.label, ud.note)
--   end,
-- })

vim.keymap.set("n", "<leader><CR>",
  function()
    local pal = require("numhi").state.active_palette
    local ns  = require("numhi.core").ns_for(pal)
    local l,c = unpack(vim.api.nvim_win_get_cursor(0))
    local id  = vim.api.nvim_buf_get_extmarks(0, ns,
               {l-1,c}, {l-1,c+1}, {})[1]
    if not id then return end
    vim.ui.input({ prompt = "NumHi note: " }, function(txt)
      if not txt then return end
      vim.api.nvim_buf_set_extmark(0, ns, l-1, c,
        { id = id, user_data = { note = txt }, })
    end)
  end,
  { desc = "NumHi: attach note to highlight" })
-----------------------------------------------------------------------
--  Hover label autocmd ----------------------------------------------
-----------------------------------------------------------------------
function M.create_hover_autocmd()
  vim.api.nvim_create_autocmd("CursorHold", {
    desc     = "NumHi: show label under cursor",
    callback = core.show_label_under_cursor,
  })
  vim.opt.updatetime = math.min(vim.opt.updatetime:get(), M.state.opts.hover_delay)
end

return M

```

### When creating a note for the first time

**_Steps_**:

- `<leader><leader><CR>` to activate `NumHi: highlight with slot`
- Naming the colorcode for that session using the cmdline looking popup at the top (snacks.nvim I think)
- Hovering my cursor over first cell in highlight, which currently is the only way to see the popup indicator displaying the color, the colorcode and custom name I assigned to the highlights (this of course must be fixed, and the hoverable window for triggering the on-hover and unlocking any keybindings applied only when hovering on a highlight must be extended to cover the entire highlighted range).
- <leader><CR> to activate `NumHi: Attach note to highlight`, which brings up a window similar to what was used to name the colorcode)
- Writing some arbitrary stuff there, exiting Insert Mode and hitting Enter or simply hitting Enter while in Insert mode (don't see a keybinding to save and close the note, so I just went for the intuitive assumption).

**_THE ERROR_**

````messages-(neovim)
Error executing vim.schedule lua callback: /home/svaughn/.config/nvim/lua/numhi/init.lua:154: invalid key: user_data
stack traceback:
        [C]: in function 'nvim_buf_set_extmark'
        /home/svaughn/.config/nvim/lua/numhi/init.lua:154: in function 'on_confirm'
        .../.local/share/nvim/lazy/snacks.nvim/lua/snacks/input.lua:130: in function <.../.local/share/nvim/lazy/snacks.nvim/lua/snacks/input.lua:123>```
````

### After following the above steps and then trying to open the note again

**_Steps_**:

- <`leader><leader>n` to do the only visible option I see, `Numhi: edit note for highlight`
- UNLIKE `NumHi: highlight with slot` which brings up something small, thin and resembling a cmdline, **`Numhi: edit note for highlight` ACTUALLY brings up the floating buffer for writing the notes for that highlight as described in the desired features (right below the bottom edge of the highlight to which the note is being applied**.
- Type some stuff there, try to write the buffer, get this: \nError detected while processing BufWriteCmd Autocommands for "<buffer=538>":\nError executing lua callback: /home/svaughn/.config/nvim/lua/numhi/core.lua:370: invalid key: user_dataistack traceback:\n[C]: in function 'nvim_buf_set_extmark'\n/home/svaughn/.config/nvim/lua/numhi/core.lua:370: in function </home/svaughn/.config/nvim/lua/numhi/core.lua:359>
- Quit the buffer without writing, try to open it again by placing my curson over the first cell in the highlight (again, needs fix as well)

**_THE ERROR (2)_**

```messages-(neovim)
E5108: Error executing lua: /home/svaughn/.config/nvim/lua/numhi/core.lua:337: Vim:E95: Buffer with this name already exists
stack traceback:
        [C]: in function 'nvim_buf_set_name'
        /home/svaughn/.config/nvim/lua/numhi/core.lua:337: in function 'edit_note'
        /home/svaughn/.config/nvim/lua/numhi/init.lua:71: in function </home/svaughn/.config/nvim/lua/numhi/init.lua:71>
```

### Facts of note

- `Numhi: edit note for highlight` brings up the (**correct style of**) buffer (in the **correct position directly underneath the bottommost edge of the highlight to which it is being attached**) REGARDLESS of whether `NumHi: highlight with slot` has been activated on that highlight - which SEEMS to make `NumHi: highlight with slot` redundant... perhaps it was meant for placing tags and some wires got crossed? Either way, obviously it doesn't work at all other than to open up a far-too-small 'note' window that can't have its content saved, can't be edited, and gives no indicator as to its existence (Something about the highlight is displayed should change when a note is attached... similar to how the chain link symbol is shown next to markdown links in certain markdown rendering plugins (like markview.nvim) to avoid users like me trying to add a note to a highlight when it already has one... [but you should be fixing `Numhi: edit note for highlight` so that it can create the note if it doesn't exist for a highlight, and if it does, just open the existing note.])

### New Feature Ideas I had while writing this

- A **VERY** quick way to temorarily hide the note buffer to see content underneath it temprorarily, OR something to switch from displaying the full note to just the current line and maybe the lines directly adjacent, as well as a way to display the note for a highlight wherever we want, after it has been created. (\*picker/browser for the notes attached to the highlights in a buffer, ability to have the note window follow the cursor and be able to toggle which side of the cursor it appears on; above, to the left or right, or below.) Finally a way to toggle from the floating window to a vertical or horizontal split, and/or back to the floating display or any other display modes... to make sure the note window isn't obstructing the content being referenced to write the note (of course, transparency on these floating note buffers would go a long way, but I don't think any plugin has that currently... though I could be wrong).
  - I'm thinking something like **one** of the following (**or ALL of them** if the bindings are **distinct** and the logic is **airtight**, ensuring the SAME highlight-specific-note is being accessed):
    1. Having <C-S-Space> in the note buffer bound to something that shrinks the note buffer to only 1-3 lines tall, centered on the current line, and half the width of the current buffer atop which it was being displayed.
    2. A way to toggle on a mode that automatically and temorarily hide the note if the cursor moves out of the buffer (mine "flashes" all over the place as I use flash.nvim)(more on this in the flash.nvim integration section).
    3. A way to toggle on a mode, similar to option 3, that automatically moves the floating note buffer as the cursor moves around the screen (similar to how the completion options window location follows the cursor, and switches its position if it would otherwise pop up off the window).
- Integration with flash.nvim: When using the remote operator, auto-hiding the window to reveal the entire buffer, then reopening the window when remote mode ends and the cursor tries to return to where it started before the remote operator had been initiated.

### Helpful Links

(**Browse with targeted intent as you ponder the best possible solutions for everything covered here.**)

### API (EXTENSIBILITY/SCRIPTING/PLUGINS)

[api](https://neovim.io/doc/user/api.html#api) Nvim API via RPC, Lua and Vimscript

[ui](https://neovim.io/doc/user/ui.html#ui) Nvim UI protocol (<- I have snacks.nvim, so keep that in mind)

[lua-guide](https://neovim.io/doc/user/lua-guide.html#lua-guide) Nvim Lua guide

[lua](https://neovim.io/doc/user/lua.html#lua) Lua API

[luaref](https://neovim.io/doc/user/luaref.html#luaref) Lua reference manual

[luvref](https://neovim.io/doc/user/luvref.html#luvref) Luv ([vim.uv](https://neovim.io/doc/user/lua.html#vim.uv)) reference manual

[autocmd](https://neovim.io/doc/user/autocmd.html#autocmd) Event handlers

[job-control](https://neovim.io/doc/user/job_control.html#job-control) Spawn and control multiple processes

[channel](https://neovim.io/doc/user/channel.html#channel) Nvim asynchronous IO

[vimscript](https://neovim.io/doc/user/eval.html#vimscript) Vimscript reference

[vimscript-functions](https://neovim.io/doc/user/builtin.html#vimscript-functions) Vimscript functions

I slapped the code for all four plugin files right up there at the top to hopefully prevent you from hallucinating files (you can propose new files if needed/helpful).
I have enabled the web search feature for you to use. Remember, ~~I'm not looking for a report on the search results~~, but rather for you to use as gospel when developing the plugin code, and even to examine what we have currently (which DOES "work" as a color highlighting plugin... albiet certainly not a stress-tested, robust plugin) for additional improvements or poor practices.
Your main goal is to address the current issues with your first wave of updates. You providing **complete code files** **is ideal**, unless changes are ~1-4 lines clustered in a tight space, **in which case the full block** housing them should be provided **to copy paste over the current one**.)

---

Second attempt (more explicit about expectations):
My friend... ensure that you follow the response content guidelines as -I- have indicated them, and adhere to the instructions (produce complete, untruncated copy-replace the whole file) and avoid introducing any placeholders of any kind, **ESPECIALLY THOSE UPON WHICH CORE/FOUNDATIONAL PLUGIN FUNCTIONALITY DEPENDS**.
**Your responses should NEVER force me to hunt and peck through the old file** (_which I already deleted and would have to re-create_) **to assemble the updated file**, and **you should also prohibit yourself from using commented instructions directing me to complete things** (e.g. Don't tell me that I'm supposed to fill in the blanks for you using existing code, code with which you've been provided pursuant to explicitly stated intent that you NOT adopt this type of "work avoidance tactic"(or any other such tactic, similar or distinct)).
Provide the full updated core file from start to finish, so that I can truly paste it into an empty file without any additional steps.
For example, the current file `core.lua` is nearly 400 LoC, so a response containing a new `core.lua` only of length 200 LoC, without any reasonable, verifiable explanation of why the disparity existed, would be undesirable... and set off major trust flags for me.
Of course a perfect refactor might drop that somewhat, and the removal of the redundant `NumHi: Attach note to highlight` would probably drop it as well, but not to that extent.

> > > **_Think meticulously and ensure you're being thorough_**<<<
> > > I've taken this prompt out of the Neovim Config Playground (ChatGPT 'Project' on the chatgpt.com interface), so you won't be able to scan project files as before, but my inclusion of the full set of plugin file's code and the web search should mitigate this (hopefully).

REALLY LOOKING FORWARD TO GETTING THIS WORKING!!! IT'S A PLEASURE WORKING WITH YOU **_󱚥_**!!
