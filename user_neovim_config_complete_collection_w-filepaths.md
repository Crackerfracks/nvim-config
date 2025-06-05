```lua /home/svaughn/.config/nvim/lua/numhi/ui.lua
local api = vim.api
local M   = {}

function M.tooltip(pal, slot, label, note)
  if vim.fn.exists("w:numhi_tooltip") == 1 then
    api.nvim_win_close(vim.g.numhi_tooltip, true)
  end
  local buf   = api.nvim_create_buf(false, true)
  local lines = { ("%s-%d  %s"):format(pal, slot, label or ""),
                  (note and "✎ " .. note:gsub("\n.*", " …") or "") }
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local win = api.nvim_open_win(buf, false, {
    relative = "cursor",
    row      = 1,
    col      = 0,
    width    = math.max(14, #lines[1]),
    height   = #lines,
    style    = "minimal",
    border   = "single",
  })
  vim.g.numhi_tooltip = win
  vim.defer_fn(function()
    if api.nvim_win_is_valid(win) then api.nvim_win_close(win, true) end
  end, 4000)
end

return M

```

```lua /home/svaughn/.config/nvim/lua/numhi/core.lua
local C        = {}
local palettes = require("numhi.palettes").base
local hsluv    = require("hsluv")
local api      = vim.api
local fn       = vim.fn
local unpack_  = table.unpack or unpack

local ns_ids        = {}        -- palette → namespace id
local State                         -- back-pointer filled by setup()
local _loaded_bufs   = {}         -- avoid double-loading metadata

local function has_visual_marks()
  return fn.line("'<") ~= 0 and fn.line("'>") ~= 0
end

local function slot_to_color(pal, slot)
  local base_hex = palettes[pal][((slot - 1) % 10) + 1]
  if slot <= 10 then return base_hex end
  local k       = math.floor((slot - 1) / 10)
  local h, s, l = unpack_(hsluv.hex_to_hsluv("#" .. base_hex))
  l             = math.max(15, math.min(95, l + (k * 6 - 3)))
  return hsluv.hsluv_to_hex { h, s, l }:sub(2)
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
  if fn.hlexists(group) == 0 then
    local bg = slot_to_color(pal, slot)
    api.nvim_set_hl(0, group, { bg = "#" .. bg, fg = contrast_fg(bg) })
  end
  return group
end

local function ensure_note_hl()
  if fn.hlexists("NumHiNoteSign") == 0 then
    api.nvim_set_hl(0, "NumHiNoteSign", { fg = "#ffaa00", bg = "NONE" })
  end
  if fn.hlexists("NumHiNoteVirt") == 0 then
    api.nvim_set_hl(0, "NumHiNoteVirt", { fg = "#ffaa00", bg = "NONE" })
  end
end

local function line_len(buf, l)
  local txt = api.nvim_buf_get_lines(buf, l, l + 1, true)[1]
  return txt and #txt or 0
end

local function index_of(t, val)
  for i, v in ipairs(t) do if v == val then return i end end
end

local function echo(chunks, hl)
  if type(chunks) == "string" then chunks = { { chunks, hl } } end
  local msg = ""
  for _, c in ipairs(chunks) do msg = msg .. c[1] end
  if vim.notify then
    vim.notify(msg, vim.log.levels.INFO, { title = "NumHi" })
  else
    api.nvim_echo(chunks, false, {})
  end
end

local function note_store(buf)
  State.notes[buf] = State.notes[buf] or {}
  return State.notes[buf]
end

local function get_note(buf, id)  return note_store(buf)[id]      end
local function set_note(buf, id, note, tags)
  note_store(buf)[id] = { note = note, tags = tags or {} }
end

local function meta_path(buf)
  local name = api.nvim_buf_get_name(buf)
  if name == "" then return nil end
  local dir  = fn.stdpath("data") .. "/numhi"
  fn.mkdir(dir, "p")
  name = name:gsub("[\\/]", "%%")  -- sanitise
  return dir .. "/" .. name .. ".json"
end

local function save_metadata(buf)
  local path = meta_path(buf)
  if not path then return end
  local marks = {}
  for pal, ns in pairs(ns_ids) do
    local em = api.nvim_buf_get_extmarks(buf, ns, 0, -1,
      { details = true })
    for _, m in ipairs(em) do
      local id, sr, sc, details = m[1], m[2], m[3], m[4]
      marks[#marks + 1] = {
        pal      = pal,
        slot     = tonumber(details.hl_group:match("_(%d+)$")),
        sr       = sr, sc = sc,
        er       = details.end_row, ec = details.end_col,
        id       = id,
        label    = (State.labels[pal] or {})[tonumber(details.hl_group:match("_(%d+)$"))],
        note     = (note_store(buf)[id] or {}).note,
        tags     = (note_store(buf)[id] or {}).tags,
      }
    end
  end
  fn.writefile({ fn.json_encode(marks) }, path)
end

local function clamp_col(buf, row, col)
  return math.min(col, line_len(buf, row))
end

local function load_metadata(buf)
  if _loaded_bufs[buf] then return end
  _loaded_bufs[buf] = true
  local path = meta_path(buf)
  if not path or fn.filereadable(path) == 0 then return end
  local ok, data = pcall(fn.readfile, path)
  if not ok or not data or #data == 0 then return end
  local ok2, marks = pcall(fn.json_decode, table.concat(data, "\n"))
  if not ok2 or type(marks) ~= "table" then return end
  for _, m in ipairs(marks) do
    local ns = ns_ids[m.pal]
    local hl = ensure_hl(m.pal, m.slot)

    local sr, sc = m.sr, clamp_col(buf, m.sr, m.sc)
    local er, ec = m.er, clamp_col(buf, m.er, m.ec)
    if sc == ec then ec = ec + 1 end  -- never zero-width

    local id = api.nvim_buf_set_extmark(buf, ns, sr, sc, {
      end_row = er, end_col = ec, hl_group = hl,
      sign_text = "✎", sign_hl_group = "NumHiNoteSign",
      virt_text = (m.tags and #m.tags > 0)
        and { { "#" .. table.concat(m.tags, " #"), "NumHiNoteVirt" } } or nil,
      virt_text_pos = "eol",
    })
    if m.note then set_note(buf, id, m.note, m.tags or {}) end
    State.labels[m.pal] = State.labels[m.pal] or {}
    if m.label then State.labels[m.pal][m.slot] = m.label end
  end
end

local function tags_as_string(tags)
  if not tags or #tags == 0 then return "" end
  return "#" .. table.concat(tags, " #")
end

local function apply_tag_virt(buf, ns, id, show)
  local note = get_note(buf, id)
  if not note then return end
  local vt = show and tags_as_string(note.tags) or nil

  local pos = api.nvim_buf_get_extmark_by_id(buf, ns, id, { details = true })
  if not pos or not pos[1] then return end

  api.nvim_buf_set_extmark(
    buf, ns, pos[1], pos[2],
    {
      id       = id,
      end_row  = pos[3].end_row,
      end_col  = pos[3].end_col,
      hl_group = pos[3].hl_group,
      sign_text      = "✎",
      sign_hl_group  = "NumHiNoteSign",
      virt_text      = vt and { { vt, "NumHiNoteVirt" } } or nil,
      virt_text_pos  = "eol",
    }
  )
end

local function refresh_all_tag_vt(buf)
  local show = State.show_tags
  for pal, ns in pairs(ns_ids) do
    for id, _ in pairs(note_store(buf)) do
      apply_tag_virt(buf, ns, id, show)
    end
  end
end

function C.setup(top)
  State = top.state
  State.notes = State.notes or {}
  State.show_tags = true

  for _, pal in ipairs(State.opts.palettes) do
    ns_ids[pal] = api.nvim_create_namespace("numhi_" .. pal)
  end
  ensure_note_hl()

  api.nvim_create_autocmd("BufReadPost", {
    callback = function(ev) vim.schedule(function() load_metadata(ev.buf) end) end,
  })
end

local function word_range()
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  local line      = api.nvim_get_current_line()
  if col >= #line or not line:sub(col + 1, col + 1):match("[%w_]") then
    return col, col + 1
  end
  local s, e = col, col
  while s > 0         and line:sub(s,     s    ):match("[%w_]") do s = s - 1 end
  while e < #line - 1 and line:sub(e + 2, e + 2):match("[%w_]") do e = e + 1 end
  return s, e + 1
end

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

local function store_mark(buf, id, slot, sr, sc, er, ec, note, tags)
  return { buf, id, slot, sr, sc, er, ec, note, tags }
end

function C.highlight(slot)
  slot = tonumber(slot)
  if not slot or slot < 1 or slot > 99 then return end

  local pal   = State.active_palette
  local ns    = ns_ids[pal]
  local group = ensure_hl(pal, slot)
  local marks = {}

  local v_ok  = has_visual_marks()
  local mode  = fn.mode()

  local start_row, start_col, end_row, end_col

  if v_ok or mode:match("^[vV]") then
    local p1 = { unpack(fn.getpos("'<"), 2, 3) }
    local p2 = { unpack(fn.getpos("'>"), 2, 3) }
    p1[1], p1[2] = p1[1] - 1, p1[2] - 1
    p2[1], p2[2] = p2[1] - 1, p2[2] - 1
    if (p2[1] < p1[1]) or (p2[1] == p1[1] and p2[2] < p1[2]) then p1, p2 = p2, p1 end
    start_row, start_col, end_row, end_col = p1[1], p1[2], p2[1], p2[2] + 1
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  else
    local lnum, _ = unpack(api.nvim_win_get_cursor(0))
    start_row, end_row = lnum - 1, lnum - 1
    start_col, end_col = word_range()
  end

  local id = api.nvim_buf_set_extmark(
    0, ns, start_row, start_col,
    {
      end_row  = end_row,
      end_col  = end_col,
      hl_group = group,
    }
  )
  table.insert(marks, store_mark(0, id, slot, start_row, start_col, end_row, end_col))

  get_label(pal, slot)

  table.insert(State.history, { pal = pal, slot = slot, marks = marks })
  State.redo_stack = {}
  if #State.history > State.opts.history_max then table.remove(State.history, 1) end

  save_metadata(0)
end

function C.collect_digits()
  local digits = ""
  local function prompt()
    local pal = State.active_palette
    local txt = (#digits > 0) and digits or "_"
    local hl  = (#digits > 0) and ensure_hl(pal, tonumber(digits)) or "Comment"
    echo(string.format("NumHi %s ◈ slot: %s (1-99)  <CR> to confirm, <BS> to undo", pal, txt), hl)
  end
  prompt()
  while true do
    local ok, ch = pcall(fn.getchar)
    if not ok then return end
    if type(ch) == "number" then ch = fn.nr2char(ch) end
    if ch:match("%d") and #digits < 2 then
      digits = digits .. ch
      prompt()
    elseif ch == "\b" or ch == "\127" then  -- backspace / delete
      digits = digits:sub(1, -2)
      prompt()
    elseif ch == "\r" then
      local num = digits
      api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
      vim.schedule(function() C.highlight(num) end)
      echo("")
      return
    else
      echo("")  -- cancel
      return
    end
  end
end

function C.erase_under_cursor()
  local pal  = State.active_palette
  local ns   = ns_ids[pal]
  local l, c = unpack(api.nvim_win_get_cursor(0))
  local ids  = api.nvim_buf_get_extmarks(
    0, ns, { l - 1, c }, { l - 1, c + 1 }, { overlap = true, details = true })
  if #ids == 0 then return end

  local marks = {}
  for _, m in ipairs(ids) do
    local id, sr, sc, det = m[1], m[2], m[3], m[4]
    local note_tbl = note_store(0)[id]
    table.insert(marks, store_mark(0, id,
      tonumber(det.hl_group:match("_(%d+)$")),
      sr, sc, det.end_row, det.end_col,
      note_tbl and note_tbl.note, note_tbl and note_tbl.tags))

    api.nvim_buf_del_extmark(0, ns, id)
  end
  table.insert(State.history, { pal = pal, slot = nil, marks = marks })
  State.redo_stack = {}
  save_metadata(0)
end

local function recreate_mark(mark, pal)
  local buf, _, slot, sr, sc, er, ec, note, tags = unpack(mark)
  local ns   = ns_ids[pal]
  local hl   = ensure_hl(pal, slot)
  local id   = api.nvim_buf_set_extmark(buf, ns, sr, sc, {
    end_row = er, end_col = ec, hl_group = hl,
    sign_text = (note and "✎" or nil), sign_hl_group = "NumHiNoteSign",
    virt_text = (tags and #tags > 0) and { { tags_as_string(tags), "NumHiNoteVirt" } } or nil,
    virt_text_pos = "eol",
  })
  if note then set_note(buf, id, note, tags) end
  mark[2] = id  -- update stored id for possible further undo/redo
end

function C.undo()
  local entry = table.remove(State.history)
  if not entry then return end
  for _, m in ipairs(entry.marks) do
    local buf, id = m[1], m[2]
    local pal = entry.pal or State.active_palette
    local ns  = ns_ids[pal]
    local note_tbl = note_store(buf)[id]
    if note_tbl then
      m[8], m[9] = note_tbl.note, note_tbl.tags
    end
    api.nvim_buf_del_extmark(buf, ns, id)
  end
  table.insert(State.redo_stack, entry)
  save_metadata(0)
end

function C.redo()
  local entry = table.remove(State.redo_stack)
  if not entry then return end
  for _, m in ipairs(entry.marks) do recreate_mark(m, entry.pal) end
  table.insert(State.history, entry)
  save_metadata(0)
end

function C.cycle_palette(step)
  local list = State.opts.palettes
  local idx  = index_of(list, State.active_palette) or 1
  State.active_palette = list[((idx - 1 + step) % #list) + 1]

  local chunks = { { "NumHi → palette " .. State.active_palette .. "  ", "ModeMsg" } }
  for n = 1, 10 do
    local hl = ensure_hl(State.active_palette, n)
    table.insert(chunks, { tostring((n % 10 == 0) and 0 or n), hl })
    if n < 10 then table.insert(chunks, { " ", "" }) end
  end
  echo(chunks)
end

function C.show_label_under_cursor()
  local l, c = unpack(api.nvim_win_get_cursor(0))
  for _, pal in ipairs(State.opts.palettes) do
    local marks = api.nvim_buf_get_extmarks(
      0, ns_ids[pal], { l - 1, c }, { l - 1, c + 1 },
      { details = true, overlap = true })
    if #marks > 0 then
      local id     = marks[1][1]
      local slot   = tonumber(marks[1][4].hl_group:match("_(%d+)$"))
      local label  = State.labels[pal] and State.labels[pal][slot] or ""
      local note   = get_note(0, id)
      local hl     = ensure_hl(pal, slot)
      local msg    = ("NumHi  %s-%d"):format(pal, slot)
      if label and label ~= "" then msg = msg .. ("  →  %s"):format(label) end
      if note  then msg = msg .. "  ✎" end
      echo(msg, hl)
      return
    end
  end
end

function C.toggle_tag_display()
  State.show_tags = not State.show_tags
  refresh_all_tag_vt(0)
end

function C.edit_note()
  local l, c = unpack(api.nvim_win_get_cursor(0))

  for _, pal in ipairs(State.opts.palettes) do
    local ns     = ns_ids[pal]
    local marks  = api.nvim_buf_get_extmarks(
      0, ns, { l - 1, c }, { l - 1, c }, { details = true, overlap = true })
    if #marks > 0 then
      local m        = marks[1]
      local id       = m[1]
      local slot     = tonumber(m[4].hl_group:match("_(%d+)$"))
      local note_tbl = get_note(0, id) or { note = "", tags = {} }

      local bufname = ("NumHiNote:%d"):format(id)
      local buf     = fn.bufnr(bufname)
      if buf == -1 then
        buf = api.nvim_create_buf(false, true)
        api.nvim_buf_set_name(buf, bufname)
        api.nvim_buf_set_option(buf, 'buftype', 'acwrite')
        api.nvim_buf_set_option(buf, 'filetype', 'markdown')
        api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
        if note_tbl.note ~= "" then
          api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(note_tbl.note, "\n"))
        end
      end

      local width  = math.floor(vim.o.columns * 0.5)
      local height = math.max(3, math.floor(vim.o.lines * 0.3))
      local anchor = (l + height + 2 > vim.o.lines) and 'SW' or 'NW'
      local win = api.nvim_open_win(buf, true, {
        relative = 'cursor',
        row = (anchor == 'NW') and 1 or 0,
        col = 0,
        width  = width,
        height = height,
        style  = 'minimal',
        border = 'rounded',
        anchor = anchor,
      })

      local function save()
        local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
        local content = table.concat(lines, "\n")
        local tags = {}
        for _, line in ipairs(lines) do
          for tag in line:gmatch('#(%w+)') do tags[#tags + 1] = tag end
        end
        set_note(0, id, content, tags)
        apply_tag_virt(0, ns, id, State.show_tags)
        api.nvim_buf_set_option(buf, "modified", false)
        save_metadata(0)
      end

      api.nvim_create_autocmd({ 'BufWriteCmd' }, {
        buffer = buf,
        nested = true,
        callback = function() save() end,
      })
      api.nvim_create_autocmd({ 'BufLeave', 'WinClosed' }, {
        buffer = buf,
        nested = true,
        callback = function(ev)
          save()
          if ev.event ~= "BufLeave" and api.nvim_win_is_valid(win) then
            api.nvim_win_close(win, true)
          end
        end,
      })

      api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>write | close<CR>", { silent = true })

      return
    end
  end
  echo("No NumHi highlight under cursor")
end

C.ensure_hl = ensure_hl
function C.ns_for(pal) return ns_ids[pal] end

return C

```

```lua /home/svaughn/.config/nvim/lua/custom/plugins/init.lua

return {
  {
    "epwalsh/obsidian.nvim",
    version = "*",  -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "project_instructions",
          path = "/home/svaughn/Downloads/To Keep for sure/Vaults/WorkTest/Project Instructions",
        },
      },

    },
  },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("codecompanion").setup({
        adapters = {
          openai = function()
            return require("codecompanion.adapters").extend("openai", {
              env = { api_key = vim.env.OPENAI_API_KEY or "<YOUR_OPENAI_API_KEY>" },
              schema = {
                model = { default = "o3-mini" },
              },
            })
          end,
          openai_high = function()
            return require("codecompanion.adapters").extend("openai", {
              env = { api_key = vim.env.OPENAI_API_KEY or "<YOUR_OPENAI_API_KEY>" },
              schema = {
                model = { default = "o3-mini-high" },
              },
            })
          end,
          openai_gpt4 = function()
            return require("codecompanion.adapters").extend("openai", {
              env = { api_key = vim.env.OPENAI_API_KEY or "<YOUR_OPENAI_API_KEY>" },
              schema = {
                model = { default = "gpt-4o" },
              },
            })
          end,
          openai_gpt4mini = function()
            return require("codecompanion.adapters").extend("openai", {
              env = { api_key = vim.env.OPENAI_API_KEY or "<YOUR_OPENAI_API_KEY>" },
              schema = {
                model = { default = "4o-mini" },
              },
            })
          end,
          anthropic_claude = function()
            return require("codecompanion.adapters").extend("anthropic", {
              env = { api_key = vim.env.ANTHROPIC_API_KEY or "<YOUR_ANTHROPIC_API_KEY>"},
              schema = {
                model = { default = "claude-3-5-haiku-latest" }
              },
            })
          end,
          anthropic_claude = function()
            return require("codecompanion.adapters").extend("anthropic", {
              env = { api_key = vim.env.ANTHROPIC_API_KEY or "<YOUR_ANTHROPIC_API_KEY>"},
              schema = {
                model = { default = "claude-3-7-sonnet-latest" }
              },
            })
          end,
        },
        strategies = {
          chat = { adapter = "openai" },
          inline = { adapter = "openai" },
        },
        display = {
          chat = {
            window = {
              layout = "vertical",  -- default side buffer layout
              position = "right",   -- appears on the right side
              border = "single",
              height = 0.8,
              width = 0.5,
              relative = "editor",
            },
          },
        },
      })
      local map = vim.keymap.set
      map({ "n", "v" }, "<leader><leader>cc", function() require("codecompanion").toggle() end,
        { desc = "Toggle CodeCompanion chat" })
      map({ "n", "v" }, "<leader><leader>cca", "<CMD>CodeCompanionActions<CR>",
        { desc = "Open CodeCompanion Action Palette" })
      map("v", "<leader><leader>cci", ":'<,'>CodeCompanion ", { desc = "Inline assistant on selection" })
      map("n", "<leader><leader>cci", ":CodeCompanion ", { desc = "Inline assistant on current line" })
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    'saghen/blink.cmp',

    version = '*',

    opts = {
      keymap = {
        preset = 'default',

        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-e>'] = { 'hide', 'fallback' },

        ['<Tab>'] = { 'snippet_forward', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<C-k>'] = { 'select_prev', 'fallback_to_mappings' },
        ['<C-j>'] = { 'select_next', 'fallback_to_mappings' },

        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

        ['<C-n>'] = { 'show_signature', 'hide_signature', 'fallback' },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = 'mono'
      },

      sources = {
        default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },


      fuzzy = { implementation = "prefer_rust_with_warning" }
    },
    opts_extend = { "sources.default" }
  },
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvimtools/none-ls-extras.nvim",
      "jayp0521/mason-null-ls.nvim",
    },
    config = function()
      require("mason-null-ls").setup {
        ensure_installed = {
          "ruff",
          "prettier",
          "shfmt",
        },
        automatic_installation = true,
      }

      local null_ls = require("null-ls")
      local sources = {
        require("none-ls.formatting.ruff").with { extra_args = { "--extend-select", "I" } },
        require("none-ls.formatting.ruff_format"),
        null_ls.builtins.formatting.prettier.with { filetypes = { "json", "yaml", "markdown" } },
        null_ls.builtins.formatting.prettier.with { args = { "-i", "4" } },
      }

      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
      null_ls.setup {
        sources = sources,
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = augroup,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format { async = false }
              end,
            })
          end
        end,
      }
    end,
  },
  {
    "glacambre/firenvim",
    build = ":call firenvim#install(0)",
    config = function()
      vim.g.firenvim_config = {
        globalSettings = { alt = "all" },
        localSettings = {
          [".*"] = {
            cmdline  = "neovim",
            content  = "text",
            priority = 0,
            selector = "textarea",
            takeover = "never",
          },
          ["https?://[^/]+\\.co\\.uk/"] = { takeover = "never", priority = 1 },
        },
      }
    end,
  },
  {
    "subnut/nvim-ghost.nvim"
  },
  {
    "nvim-treesitter/playground",
    cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")

      local ui   = harpoon.ui
      local list = harpoon:list()
      harpoon:setup({
        settings = {
          save_on_toggle = false,   -- Save Harpoon list when toggling the UI
          sync_on_ui_close = false, -- Sync Harpoon list to disk when closing the UI
          key = function()
            return vim.loop.cwd()   -- Use the current working directory as the key
          end,
        },
      })

      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Add file to Harpoon" })

      vim.keymap.set("n", "<leader>e", function()
        ui:toggle_quick_menu(list, {
          on_select = function(_, item, _)
            local buf = vim.fn.bufnr(item.value, true)
            vim.fn.bufload(buf, { force = true })
            vim.api.nvim_set_current_buf(buf)
            ui:close_menu()
          end
        })
      end, { desc = "Harpoon menu (force)" })

      for i = 1, 6 do
        vim.keymap.set("n", ("<leader>%d"):format(i), function() list:select(i) end,
          { desc = ("Harpoon to file %d"):format(i) })
      end

      vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end, { desc = "Navigate to Previous Harpoon Mark" })
      vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end, { desc = "Navigate to Next Harpoon Mark" })
    end,
  },
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    version = "*",
    opts = {
      animate = {
        enabled = true,
        easing = "outInBounce",
        duration = 5,
        fps = 120
      },
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      indent = { enabled = false },
      input = { enabled = true },
      notifier = { enabled = true },
      picker = { enabled = true },
      quickfile = { enabled = true },
      scroll = { enabled = false },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      styles = {
        notification = {
        },
      },
    },
    keys = {
      { "<leader>z",  function() require("snacks").zen() end,              desc = "Toggle Zen Mode" },
      { "<leader>Z",  function() require("snacks").zen.zoom() end,         desc = "Toggle Zoom" },
      { "<leader><leader>.",  function() require("snacks").scratch() end,          desc = "Toggle Scratch Buffer" },
      { "<leader><leader>Ss", function() require("snacks").scratch.select() end, desc = "Select Scratch Buffer" },
      { "<leader><leader><leader>n",  function() require("snacks").notifier.show_history() end, desc = "Notification History" },
      { "<leader>bd", function() require("snacks").bufdelete() end,        desc = "Delete Buffer" },
      { "<leader>cR", function() require("snacks").rename.rename_file() end, desc = "Rename File" },
      { "<leader>gB", function() require("snacks").gitbrowse() end,        desc = "Git Browse", mode = { "n", "v" } },
      { "<leader>gb", function() require("snacks").git.blame_line() end,   desc = "Git Blame Line" },
      { "<leader>gf", function() require("snacks").lazygit.log_file() end, desc = "Lazygit Current File History" },
      { "<leader>gg", function() require("snacks").lazygit() end,          desc = "Lazygit" },
      { "<leader>gl", function() require("snacks").lazygit.log() end,      desc = "Lazygit Log (cwd)" },
      { "<leader>un", function() require("snacks").notifier.hide() end,    desc = "Dismiss All Notifications" },
      { "<c-/>",      function() require("snacks").terminal() end,         desc = "Toggle Terminal" },
      { "<c-_>",      function() require("snacks").terminal() end,         desc = "which_key_ignore" },
      {
        "]]",
        function() require("snacks").words.jump(vim.v.count1) end,
        desc = "Next Reference",
        mode = { "n", "t" },
      },
      {
        "[[",
        function() require("snacks").words.jump(-vim.v.count1) end,
        desc = "Prev Reference",
        mode = { "n", "t" },
      },
      {
        "<leader>N",
        desc = "Neovim News",
        function()
          require("snacks").win({
            file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
            width = 0.6,
            height = 0.6,
            wo = {
              spell = false,
              wrap = true,
              signcolumn = "yes",
              statuscolumn = " ",
              conceallevel = 3,
            },
          })
        end,
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          _G.dd = function(...)
            require("snacks.debug").inspect(...)
          end
          _G.bt = function()
            require("snacks.debug").backtrace()
          end

          vim.print = _G.dd

          local toggle = require("snacks.toggle")

          toggle.option("spell", { name = "Spelling" }):map("<leader>us")
          toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
          toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
          toggle.diagnostics():map("<leader>ud")
          toggle.line_number():map("<leader>ul")
          toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
          toggle.treesitter():map("<leader>uT")
          toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
          toggle.inlay_hints():map("<leader>uh")
          toggle.indent():map("<leader>ug")
          toggle.dim():map("<leader>uD")
        end,
      })
    end,
  },
  {
    "Vigemus/iron.nvim",
    config = function()
      local iron = require("iron.core")
      local view = require("iron.view")
      local common = require("iron.fts.common")

      iron.setup {
        config = {
          scratch_repl = true,
          repl_definition = {
            sh = { command = {"zsh"} },
            python = {
              command = { "python3" },
              format = common.bracketed_paste_python,
              block_deviders = { "# %%", "#%%" },
            },
          },
          repl_filetype = function(bufnr, ft)
            return ft
          end,
          repl_open_cmd = view.split.horizontal.botright(0.4),
        },
        keymaps = {
          toggle_repl = "<leader>rr",
          restart_repl = "<leader>rR",
          send_motion = "<leader>rsc",
          visual_send = "<leader>rsc",
          send_file = "<leader>rsf",
          send_line = "<leader>rsl",
          send_paragraph = "<leader>rsp",
          send_until_cursor = "<leader>rsu",
          send_mark = "<leader>rsm",
          send_code_block = "<leader>rsb",
          send_code_block_and_move = "<leader>rsn",
          mark_motion = "<leader>rmc",
          mark_visual = "<leader>rmc",
          remove_mark = "<leader>rmd",
          cr = "<leader>rs<cr>",
          interrupt = "<leader>rs <leader>",
          exit = "<leader>rsq",
          clear = "<leader>rcl",
        },
        highlight = { italic = true },
        ignore_blank_lines = true,
      }

      vim.keymap.set('n', '<leader>rf', '<cmd>IronFocus<cr>')
      vim.keymap.set('n', '<leader>rh', '<cmd>IronHide<cr>')
    end,
  },
  {
    "kmonad/kmonad-vim"
  },
  {
    "HiPhish/rainbow-delimiters.nvim"
  },
  {
    "RRethy/vim-illuminate" -- <-- Get the config info for this. might still be helpful. 
  },
  {
    "Mr-LLLLL/interestingwords.nvim",
    config = function()
      local interestingwords = require("interestingwords")
      interestingwords.setup({
        colors = {
          '#aeee00', '#ff0000', '#0000ff', '#b88823', '#8c006e', '#cc461e', '#842180',
          '#004628', '#462875', '#00649b', '#9a525a', '#808080', '#38c591', '#d8c839',
          '#472a03', '#007526', '#c9305e', '#464646', '#af91af', '#b8505a', '#b86946',
          '#450030', '#150056', '#132141', '#5a1735', '#404a14', '#2e5c4d', '#609040'},
        search_count = true,
        navigation = false,
        scroll_center = true,
        search_key = "<leader><leader>m",
        cancel_search_key = "<leader><leader>M",
        color_key = "<leader>k",
        cancel_color_key = "<leader>K",
        select_mode = "random",
      })
    end
  },
  {
    "uga-rosa/ccc.nvim",
    config = function()
      assert(vim.o.termguicolors == true)
      local ccc = require("ccc")
      local mapping = ccc.mapping

      ccc.setup({
        highlighter = {
          auto_enable = true,
          lsp = true,
        }
      })
    end
  },
  {
    "MunifTanjim/nui.nvim"
  },
  {
    "tpope/vim-repeat"
  },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    config = function()
      require('smart-splits').setup({
        ignored_buftypes = {
          'nofile',
          'quickfix',
          'prompt',
        },
        ignored_filetypes = { 'NvimTree' },
        default_amount = 3,
        at_edge = 'wrap',
        float_win_behavior = 'previous',
        move_cursor_same_row = false,
        cursor_follows_swapped_bufs = false,
        resize_mode = {
          quit_key = '<ESC>',
          resize_keys = { 'h', 'j', 'k', 'l' },
          silent = false,
          hooks = {
            on_enter = nil,
            on_leave = nil,
          },
        },
        ignored_events = {
          'BufEnter',
          'WinEnter',
        },
        multiplexer_integration = nil,
        disable_multiplexer_nav_when_zoomed = true,
        kitty_password = nil,
        log_level = 'info',
      })

      vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left)
      vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down)
      vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up)
      vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right)
      vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
      vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
      vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
      vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
      vim.keymap.set('n', '<C-\\>', require('smart-splits').move_cursor_previous)
      vim.keymap.set('n', '<leader><leader>h', require('smart-splits').swap_buf_left)
      vim.keymap.set('n', '<leader><leader>j', require('smart-splits').swap_buf_down)
      vim.keymap.set('n', '<leader><leader>k', require('smart-splits').swap_buf_up)
      vim.keymap.set('n', '<leader><leader>l', require('smart-splits').swap_buf_right)
    end
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",

    opts = {
      labels = "abcdefghijklmnopqrstuvwxyz",
      mode = {
        search = {
          enabled = true,
        },
      },
      search = {
        multi_window = true,
        forward = true,
        mode = "exact",
      },
      jump  = { offset = 0 },
      label = { rainbow = { enabled = true, shade = 5 } },
    },

    keys = {
      { "s", mode = { "n", "x", "o" },
        function() require("flash").jump() end,                         desc = "Flash" },
      { "S", mode = { "n", "x", "o" },
        function() require("flash").treesitter() end,                   desc = "Flash Treesitter" },

      { "f", mode = { "n", "x", "o" },
        function() require("flash").jump({ mode = "char", search = { forward = true  } }) end,
        desc = "Flash f" },
      { "F", mode = { "n", "x", "o" },
        function() require("flash").jump({ mode = "char", search = { forward = false } }) end,
        desc = "Flash F" },
      { "t", mode = { "n", "x", "o" },
        function() require("flash").jump({ mode = "char", search = { forward = true  }, jump = { offset = -1 } }) end,
        desc = "Flash t" },
      { "T", mode = { "n", "x", "o" },
        function() require("flash").jump({ mode = "char", search = { forward = false }, jump = { offset =  1 } }) end,
        desc = "Flash T" },

      { "w", mode = { "n", "x", "o" },
        function() require("flash").jump({ search = { mode = "search", forward = true,  wrap = false, max_length = 0 }, pattern = [[\<]],  label = { after = {0,0} } }) end,
        desc = "Flash → next word" },
      { "W", mode = { "n", "x", "o" },
        function() require("flash").jump({
          search  = { mode = "search", forward = true, wrap = false, max_length = 0 },
          pattern = [[\%(^\|\s\)\zs\S]],
          label   = { after = { 0, 0 } },
        }) end, desc = "Flash → next WORD" },

      { "b", mode = { "n", "x", "o" },
        function() require("flash").jump({ search = { mode = "search", forward = false, wrap = false, max_length = 0 }, pattern = [[\<]],  label = { after = {0,0} } }) end,
        desc = "Flash ← previous word" },
      { "B", mode = { "n", "x", "o" },
        function() require("flash").jump({
          search  = { mode = "search", forward = false, wrap = false, max_length = 0 },
          pattern = [[\%(^\|\s\)\zs\S]],
          label   = { after = { 0, 0 } },
        }) end, desc = "Flash ← previous WORD" },

      { "e", mode = { "n", "x", "o" },
        function() require("flash").jump({ search = { mode = "search", forward = true,  wrap = false, max_length = 0 }, pattern = [[\>]],  label = { after = {0,0} }, jump = { offset = -1 } }) end,
        desc = "Flash → word end" },
      { "E", mode = { "n", "x", "o" },
        function() require("flash").jump({ search = { mode = "search", forward = true,  wrap = false, max_length = 0 }, pattern = [[\S\zs\s\|\S$]], label = { after = {0,0} } }) end,
        desc = "Flash → WORD end" },
      { "ge", mode = { "n", "x", "o" },
        function() require("flash").jump({ search = { mode = "search", forward = false, wrap = false, max_length = 0 }, pattern = [[\>]],  label = { after = {0,0} }, jump = { offset = -1 } }) end,
        desc = "Flash ← word end" },
      { "gE", mode = { "n", "x", "o" },
        function() require("flash").jump({ search = { mode = "search", forward = false, wrap = false, max_length = 0 }, pattern = [[\S\zs\s\|\S$]], label = { after = {0,0} } }) end,
        desc = "Flash ← WORD end" },

      { "-", mode = { "n", "x", "o" },                                           -- line start
        function()
          require("flash").jump({
            search  = { mode = "search", max_length = 0 },
            label   = { after = { 0, 0 } },
            pattern = "^",
          })
        end,
        desc = "Jump to line beginning" },

      { "$", mode = { "n", "x", "o" },                                           -- line end (exclusive)
        function()
          require("flash").jump({
            search  = { mode = "search", max_length = 0 },
            label   = { after = { 0, 0 } },
            pattern = [[\ze$]],
          }) 
        end,
        desc = "Jump to line end (exclusive)" },

      { "_", mode = { "n", "x", "o" },                                           -- first non-blank
        function()
          require("flash").jump({
            search  = { mode = "search", max_length = 0 },
            label   = { after = { 0, 0 } },
            pattern = [[^\s*\zs\S]],
          })
        end,
        desc = "Jump to first non-blank" },

      { "r",       mode = "o",       function() require("flash").remote()             end, desc = "Remote Flash" },
      { "R",       mode = { "o","x" },function() require("flash").treesitter_search() end, desc = "Treesitter search" },
      { "<C-s>",   mode = "c",       function() require("flash").toggle()             end, desc = "Toggle Flash search" },



    },

    config = function(_, opts)
      require("flash").setup(opts)

      vim.api.nvim_create_user_command("StripUrl", function()
        vim.cmd([[silent %s#https\?://\S\+##ge]])
      end, { desc = "Remove all URLs from buffer" })

      vim.api.nvim_create_user_command("StripLinks", function()
        vim.cmd([[silent %s#\[\([^]\]\+\)\](https\?://[^)]\+)#\1#gI]])
        vim.cmd([[silent %s#\[\[\([^]|]\+\)|\?\([^]\]\+\)\]\]#\2#gI]])
      end, { desc = "Remove URLs in links, keep text" })
    end,
  },
  {
    "sphamba/smear-cursor.nvim",
    config = function()
      require("smear_cursor").setup({
        cursor_color = "none",
        stiffness = 0.5,
        trailing_stiffness = 0.1,
        distance_stop_animating = 0.5,
        time_interval = 8,
        stiffness_insert_mode = 0.2,
        trailing_stiffness_insert_mode = 0.1,
        trailing_exponent_insert_mode = 1,
        max_length = 35,
        hide_target_hack = true,
        lecacy_computing_symbols_support = true
      })
    end
  },
  {
    "NStefan002/screenkey.nvim",
    lazy = false,
    version = "*",
    config = function()
      local W = require("screenkey")
      W.setup({
        win_opts = {
          row      = 0,                         -- 0 == first editor row :contentReference[oaicite:0]{index=0}
          col      = vim.o.columns - 1,         -- right‑most screen column
          relative = "editor",
          anchor   = "NE",                      -- <‑‑ key bit ☝︎ :contentReference[oaicite:1]{index=1}
          width    = 100,
          height   = 1,
          border   = "single",
          title    = "Keyboard Input",
          title_pos= "center",
          style    = "minimal",
          focusable= false,
          noautocmd= false,
          zindex   = 60,                        -- keep it above most pop‑ups
        },

        compress_after = 6,      -- disable time‑based compression entirely
        clear_after    = 10,     -- keep the previous behaviour
        group_mappings = true,   -- treat “gg”, “cc”, etc. as a single combo :contentReference[oaicite:3]{index=3}
        disable        = {
          filetypes = {},
          buftypes  = {},
          events    = false,
        },
      })

      local ns = vim.api.nvim_create_namespace("screenkey_force_redraw")
      vim.on_key(function()
        if W.is_active() then
          vim.schedule(W.redraw)                -- run outside low‑level input
        end
      end, ns)

      vim.keymap.set(
        "n",
        "<leader><leader><leader>K",
        W.toggle,
        { desc = "Toggle Screenkey" }           -- helpful for which‑key lists
      )
    end,
  },
  {
    "OXY2DEV/markview.nvim",
    lazy = false,

    dependencies = {
      "saghen/blink.cmp"
    },
  },
  {
    "petertriho/nvim-scrollbar",
    config = function()
      local colors = require("tokyonight.colors").setup()
      require("scrollbar").setup({
        show = true,
        show_in_active_only = false,
        set_highlights = true,
        folds = 1000, -- handle folds, set to number to disable folds if no. of lines in buffer exceeds this
        max_lines = false, -- disables if no. of lines in buffer exceeds this
        hide_if_all_visible = true, -- Hides everything if all lines are visible
        throttle_ms = 100,
        handle = {
          text = " ",
          blend = 50, -- Integer between 0 and 100. 0 for fully opaque and 100 to full transparent. Defaults to 30.
          color = nil,
          color_nr = nil, -- cterm
          highlight = "CursorColumn",
          hide_if_all_visible = true, -- Hides handle if all lines are visible
        },
        marks = {
          Cursor = {
            text = "•",
            priority = 0,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = "Normal",
          },
          Search = {
            text = { "-", "=" },
            priority = 1,
            gui = nil,
            color = colors.orange,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = "Search",
          },
          Error = {
            text = { "-", "=" },
            priority = 2,
            gui = nil,
            color = colors.error,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = "DiagnosticVirtualTextError",
          },
          Warn = {
            text = { "-", "=" },
            priority = 3,
            gui = nil,
            color = colors.warning,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = "DiagnosticVirtualTextWarn",
          },
          Info = {
            text = { "-", "=" },
            priority = 4,
            gui = nil,
            color = colors.info,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = "DiagnosticVirtualTextInfo",
          },
          Hint = {
            text = { "-", "=" },
            priority = 5,
            gui = nil,
            color = colors.hint,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = "DiagnosticVirtualTextHint",
          },
          Misc = {
            text = { "-", "=" },
            priority = 6,
            gui = nil,
            color = colors.purple,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = "Normal",
          },
          GitAdd = {
            text = "┆",
            priority = 7,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = "GitSignsAdd",
          },
          GitChange = {
            text = "┆",
            priority = 7,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = "GitSignsChange",
          },
          GitDelete = {
            text = "▁",
            priority = 7,
            gui = nil,
            color = nil,
            cterm = nil,
            color_nr = nil, -- cterm
            highlight = "GitSignsDelete",
          },
        },
        excluded_buftypes = {
          "terminal",
        },
        excluded_filetypes = {
          "dropbar_menu",
          "dropbar_menu_fzf",
          "DressingInput",
          "cmp_docs",
          "cmp_menu",
          "noice",
          "prompt",
          "TelescopePrompt",
        },
        autocmd = {
          render = {
            "BufWinEnter",
            "TabEnter",
            "TermEnter",
            "WinEnter",
            "CmdwinLeave",
            "TextChanged",
            "VimResized",
            "WinScrolled",
          },
          clear = {
            "BufWinLeave",
            "TabLeave",
            "TermLeave",
            "WinLeave",
          },
        },
        handlers = {
          cursor = true,
          diagnostic = true,
          gitsigns = false, -- Requires gitsigns
          handle = true,
          search = false, -- Requires hlslens
          ale = false, -- Requires ALE
        },
      })
    end
  },
  {
    "y3owk1n/undo-glow.nvim",
    event = { "VeryLazy" },
    opts = {
      animation = {
        enabled = true,
        duration = 100,
        animtion_type = "zoom",
        window_scoped = true,
      },
      highlights = {
        undo = {
          hl_color = { bg = "#693232" }, -- Dark muted red
        },
        redo = {
          hl_color = { bg = "#2F4640" }, -- Dark muted green
        },
        yank = {
          hl_color = { bg = "#7A683A" }, -- Dark muted yellow
        },
        paste = {
          hl_color = { bg = "#325B5B" }, -- Dark muted cyan
        },
        search = {
          hl_color = { bg = "#5C475C" }, -- Dark muted purple
        },
        comment = {
          hl_color = { bg = "#7A5A3D" }, -- Dark muted orange
        },
        cursor = {
          hl_color = { bg = "#793D54" }, -- Dark muted pink
        },
      },
      priority = 2048 * 3,
    },
    keys = {
      {
        "u",
        function()
          require("undo-glow").undo()
        end,
        mode = "n",
        desc = "Undo with highlight",
        noremap = true,
      },
      {
        "U",
        function()
          require("undo-glow").redo()
        end,
        mode = "n",
        desc = "Redo with highlight",
        noremap = true,
      },
      {
        "p",
        function()
          require("undo-glow").paste_below()
        end,
        mode = "n",
        desc = "Paste below with highlight",
        noremap = true,
      },
      {
        "P",
        function()
          require("undo-glow").paste_above()
        end,
        mode = "n",
        desc = "Paste above with highlight",
        noremap = true,
      },
      {
        "n",
        function()
          require("undo-glow").search_next({
            animation = {
              animation_type = "strobe",
            },
          })
        end,
        mode = "n",
        desc = "Search next with highlight",
        noremap = true,
      },
      {
        "N",
        function()
          require("undo-glow").search_prev({
            animation = {
              animation_type = "strobe",
            },
          })
        end,
        mode = "n",
        desc = "Search prev with highlight",
        noremap = true,
      },
      {
        "*",
        function()
          require("undo-glow").search_star({
            animation = {
              animation_type = "strobe",
            },
          })
        end,
        mode = "n",
        desc = "Search star with highlight",
        noremap = true,
      },
      {
        "#",
        function()
          require("undo-glow").search_hash({
            animation = {
              animation_type = "strobe",
            },
          })
        end,
        mode = "n",
        desc = "Search hash with highlight",
        noremap = true,
      },
      {
        "gc",
        function()
          local pos = vim.fn.getpos(".")
          vim.schedule(function()
            vim.fn.setpos(".", pos)
          end)
          return require("undo-glow").comment()
        end,
        mode = { "n", "x" },
        desc = "Toggle comment with highlight",
        expr = true,
        noremap = true,
      },
      {
        "gc",
        function()
          require("undo-glow").comment_textobject()
        end,
        mode = "o",
        desc = "Comment textobject with highlight",
        noremap = true,
      },
      {
        "gcc",
        function()
          return require("undo-glow").comment_line()
        end,
        mode = "n",
        desc = "Toggle comment line with highlight",
        expr = true,
        noremap = true,
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("TextYankPost", {
        desc = "Highlight when yanking (copying) text",
        callback = function()
          require("undo-glow").yank()
        end,
      })

      vim.api.nvim_create_autocmd("CursorMoved", {
        desc = "Highlight when cursor moved significantly",
        callback = function()
          require("undo-glow").cursor_moved({
            animation = {
              animation_type = "slide",
            },
          })
        end,
      })

      vim.api.nvim_create_autocmd("FocusGained", {
        desc = "Highlight when focus gained",
        callback = function()
          local opts = {
            animation = {
              animation_type = "slide",
            },
          }

          opts = require("undo-glow.utils").merge_command_opts("UgCursor", opts)
          local pos = require("undo-glow.utils").get_current_cursor_row()

          require("undo-glow").highlight_region(vim.tbl_extend("force", opts, {
            s_row = pos.s_row,
            s_col = pos.s_col,
            e_row = pos.e_row,
            e_col = pos.e_col,
            force_edge = opts.force_edge == nil and true or opts.force_edge,
          }))
        end,
      })

      vim.api.nvim_create_autocmd("CmdLineLeave", {
        pattern = { "/", "?" },
        desc = "Highlight when search cmdline leave",
        callback = function()
          require("undo-glow").search_cmd({
            animation = {
              animation_type = "fade",
            },
          })
        end,
      })
    end,
  },
  {
    "josephburgess/nvumi",
    dependencies = { "folke/snacks.nvim" },
    opts = {
      virtual_text = "newline", -- or "inline"
      prefix = " 🚀 ", -- prefix shown before the output
      date_format = "iso", -- or: "uk", "us", "long"
      keys = {
        run = "<CR>", -- run/refresh calculations
        reset = "R", -- reset buffer
        yank = "<leader>oy", -- yank output of current line
        yank_all = "<leader>oY", -- yank all outputs
      },
      custom_conversions = {},
      custom_functions = {}
    }
  },
  {
    "karb94/neoscroll.nvim",
    opts = {
      easing = "circular",
      performance_mode = true,
      duration_multiplier = 1.0,
    },
  },
  {
    "meznaric/key-analyzer.nvim", opts = {}
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    opts = {
    }
  },
  {
    "hat0uma/csvview.nvim",
    opts = {
      parser = { comments = { "#", "//" } },
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
      },
    },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
  },
  {
    "stevearc/oil.nvim",
    lazy = false,        -- load eagerly so FileType=oil autocmds are predictable
    opts = {
      default_file_explorer = true,  -- keep netrw available
      view_options = {
        show_hidden = false,      -- list files that start with “.”
      },
      keymaps = {
        ["s"]        = false,                 -- free `s` for Flash
        ["-"]        = false,                 -- free `-` for Flash
        ["<BS>"]     = "actions.parent",      -- Backspace → parent dir
        ["<leader>s"] = "actions.change_sort", -- <leader>s → sort toggle
        ["g."] = "actions.toggle_hidden",
        ["<leader><C-s>"] = false,
        ["<leader><C-h>"] = false,
        ["<leader><C-l>"] = false,
        ["<C-h>"] = false,
        ["<C-k>"] = false,
        ["<C-l>"] = false,
        ["<C-j>"] = false,
      },
    },
    config = function(_, opts)
      require("oil").setup(opts)
    end
  },
  {
    "hsluv/hsluv-lua",
    name  = "hsluv",   -- lets `require('hsluv')` trigger lazy-load
    lazy  = true,
    init  = function(plugin)                  -- ← runs *before* NumHi
      local path = plugin.dir .. "/?.lua"
      if not package.path:find(path, 1, true) then
        package.path = package.path .. ";" .. path
      end
    end,
  },
  {
    dir   = vim.fn.stdpath("config") .. "/lua/numhi",
    name  = "numhi.nvim",   -- can stay
    dependencies = { "hsluv/hsluv-lua" },
    lazy = false,
    opts = {                -- <- still merged into the second arg
      palettes   = { "VID","PAS","EAR","MET","CYB" },
      key_leader = "<leader><leader>",
      statusline = true,
    },
    config = function(_, opts)   -- ② call the *real* module yourself
      require("numhi").setup(opts)
    end,
  },
  {
    "chrisbra/Recover.vim",
    event = "VeryLazy",  -- load on first file‑open
    init = function()
      vim.opt.shortmess:append("A")
    end,
  },
  {
    "roodolv/markdown-toggle.nvim",
    config = function()
      require("markdown-toggle").setup({
        use_default_keymaps = false,
        filetypes = { "markdown", "markdown.mdx" },

        list_table = { "-", "+", "*", "=" },
        cycle_list_table = false,

        box_table = { "x", "~", "!", ">" },
        cycle_box_table = false,
        list_before_box = false,

        heading_table = { "#", "##", "###", "####", "#####" },

        enable_blankhead_skip = true,
        enable_inner_indent = false,
        enable_unmarked_only = true,
        enable_autolist = false,
        enable_auto_samestate = false,
        enable_dot_repeat = true,
      })
    end,
  },
  {
    "ziontee113/icon-picker.nvim",
    config = function()
      require("icon-picker").setup({ disable_legacy_commands = true })

      local opts = { noremap = true, silent = true }

      vim.keymap.set("n", "<leader><leader>ip", "<cmd>IconPickerNormal<cr>", opts)
      vim.keymap.set("n", "<leader><leader>iy", "<cmd>IconPickerYank<cr>", opts) --> Yank the selected icon into register
      vim.keymap.set("i", "<C-i>", "<cmd>IconPickerInsert<cr>", opts)
    end
  },
  {
    "mbbill/undotree",
    vim.keymap.set('n', '<leader><F5>', vim.cmd.UndotreeToggle),
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"]               = true,
          ["cmp.entry.get_documentation"]                 = true,
        },
      },
      presets = {
        bottom_search        = true,
        command_palette      = true,
        long_message_to_split= true,
        inc_rename           = false,
        lsp_doc_border       = false,
      },

      routes = {
        {
          view   = "notify",          -- use nvim-notify popup
          filter = { event = "msg_showmode" }, -- only “-- INSERT --”, “-- VISUAL --”, etc.
        },
      },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
  },
  {
    "kkharji/sqlite.lua" 
  },
  {
    "AckslD/nvim-neoclip.lua",
    dependencies = {
      { "kkharji/sqlite.lua",  module = "sqlite" },       -- persistence  :contentReference[oaicite:0]{index=0}
      { "nvim-telescope/telescope.nvim" },                -- picker UI   :contentReference[oaicite:1]{index=1}
    },
    config = function()
      require("neoclip").setup({
        history                = 1000,      -- keep 1 000 items in RAM
        enable_persistent_history = true,   -- save to sqlite
        continuous_sync        = false,     -- manual db_push/db_pull
        preview = true,                     -- show a preview pane
      })

      local telescope = require("telescope")
      telescope.load_extension("neoclip")                 -- :contentReference[oaicite:2]{index=2}
      local clip = telescope.extensions.neoclip           -- exposes .default() .plus() .macro()

      local map  = vim.keymap.set
      local opts = { noremap = true, silent = true }

      map({ "n", "v" }, "<leader>fy", clip.default, vim.tbl_extend("force", opts,
        { desc = "Neoclip • open yank history picker" }))

      map({ "n", "v" }, "<leader>fY", clip.plus, vim.tbl_extend("force", opts,
        { desc = "Neoclip • +‑register history" }))

      map("n", "<leader>fc", require("neoclip").clear_history, vim.tbl_extend("force", opts, { desc = "Neoclip • clear history" }))        -- :contentReference[oaicite:4]{index=4}
      map("n", "<leader>fs", require("neoclip").db_push,       vim.tbl_extend("force", opts, { desc = "Neoclip • push DB → disk" }))       -- :contentReference[oaicite:5]{index=5}
      map("n", "<leader>fS", require("neoclip").db_pull,       vim.tbl_extend("force", opts, { desc = "Neoclip • pull DB ← disk" }))       -- :contentReference[oaicite:6]{index=6}
    end,
  },
  {
    dir  = vim.fn.stdpath("config") .. "/lua/custom/filetype_switcher",
    name = "filetype-switcher.nvim",
    lazy = false,                                    -- load immediately
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function() require("custom.filetype_switcher") end,
  },
}
```

```lua /home/svaughn/.config/nvim/lua/numhi/init.lua
local M = {}
local core
local default_opts = {
  palettes     = { "VID", "PAS", "EAR", "MET", "CYB" },
  key_leader   = "<leader><leader>",  -- root; NumHi adds an extra 'n'
  statusline   = true,
  history_max  = 500,
  hover_delay  = 400,
}

M.state = {
  active_palette = "VID",
  history        = {},
  redo_stack     = {},
  labels         = {},
  notes          = {},
  show_tags      = true,
  opts           = {},
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", default_opts, opts or {})
  M.state.opts = opts
  core = require("numhi.core")
  core.setup(M)

  if opts.statusline then M.attach_statusline() end
  M.create_keymaps()
  M.create_hover_autocmd()
end

for _, f in ipairs { "highlight","erase_under_cursor","undo","redo",
                     "cycle_palette","toggle_tag_display","collect_digits",
                     "edit_note","show_label_under_cursor" } do
  M[f] = function(...) return core[f](...) end
end

function M.create_keymaps()
  local leader_root = M.state.opts.key_leader .. "n"  -- << all NumHi under <leader><leader>n
  local map = function(lhs, rhs, desc, mode)
    vim.keymap.set(mode or { "n", "v" }, lhs, rhs, { silent = true, desc = desc })
  end

  map(leader_root .. "<CR>",          function() core.collect_digits() end, "NumHi: highlight with slot")
  map(leader_root .. "0<CR>",         M.erase_under_cursor,              "NumHi: erase mark under cursor")

  map(leader_root .. "u",             M.undo,                            "NumHi: undo")
  map(leader_root .. "<C-r>",         M.redo,                            "NumHi: redo")

  map(leader_root .. "nn",            function() core.edit_note() end,   "NumHi: create / edit note")
  map(leader_root .. "nt",            function() core.toggle_tag_display() end, "NumHi: toggle tag display")

  vim.keymap.set("n", leader_root .. "p", function() M.cycle_palette(1) end,
                 { silent = true, desc = "NumHi: next palette" })
end

function M.status_component()
  local pal = M.state.active_palette
  local base_hl = core.ensure_hl(pal, 1)
  local swatch = string.format("%%#%s#▉%%*", base_hl)
  local parts = {}
  for n = 1, 10 do
    local hl = core.ensure_hl(pal, n)
    parts[#parts + 1] = string.format("%%#%s#%s%%*", hl, (n % 10 == 0) and "0" or tostring(n))
  end
  return string.format("[%s %s %s]%%*", swatch, pal, table.concat(parts, ""))
end

local function attach_to_mini()
  local ok, mini = pcall(require, "mini.statusline")
  if not ok or mini.__numhi_patched then return ok end
  mini.__numhi_patched = true
  local orig = mini.section_location
  mini.section_location = function()
    return M.status_component() .. (orig and orig() or "")
  end
  return true
end

function M.attach_statusline()
  if attach_to_mini() then return end

  local function attach_lualine()
    local ok, lualine = pcall(require, "lualine")
    if not ok or lualine.__numhi_patched then return ok end
    lualine.__numhi_patched = true
    local comp = function() return M.status_component() end
    vim.schedule(function()
      local cfg = lualine.get_config and lualine.get_config() or {}
      cfg.sections = cfg.sections or {}
      cfg.sections.lualine_c = cfg.sections.lualine_c or {}
      table.insert(cfg.sections.lualine_c, 1, comp)
      lualine.setup(cfg)
    end)
    return true
  end

  if attach_lualine() then return end
  vim.o.statusline = "%{%v:lua.require'numhi'.status_component()%}" .. vim.o.statusline
end

function M.create_hover_autocmd()
  vim.api.nvim_create_autocmd("CursorHold", {
    desc     = "NumHi: show label under cursor",
    callback = core.show_label_under_cursor,
  })
  vim.opt.updatetime = math.min(vim.opt.updatetime:get(), M.state.opts.hover_delay)
end

return M

```

```lua /home/svaughn/.config/nvim/init.lua




vim.g.mapleader = ' '
vim.g.maplocalleader = ','
vim.g.loaded_netrw       = 1   -- hard-disable netrw runtime files
vim.g.loaded_netrwPlugin = 1

vim.g.have_nerd_font = true



vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.mouse = 'a'

vim.opt.showmode = false

vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

vim.opt.breakindent = true

vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.opt.undofile = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = 'yes'

vim.opt.updatetime = 250
vim.opt.timeoutlen = 250

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.opt.inccommand = 'split'

vim.opt.cursorline = true
vim.opt.cursorcolumn = false

vim.opt.scrolloff = 10


vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set("n", "<leader>on", "<CMD>Nvumi<CR>", { desc = "[O]pen [N]vumi" })

vim.keymap.set({ 'n', 'x', 'o' }, '<leader>-', '-')

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.api.nvim_set_keymap("n", "<leader><leader>as", ":ASToggle<CR>", {})


vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })



vim.keymap.set("n", "<leader>pv", function()
  local dir = vim.fn.expand("%:p:h")  -- current file’s directory
  if dir == "" then
    dir = vim.loop.cwd()              -- fallback: CWD
  end
  require("oil").open(dir)            -- Oil handles both cases
end, { desc = "Open Oil file-explorer" })


vim.keymap.set("n", "J", "mzJ`z", { desc = "Join with next line, re-center cursor" })


vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down half page and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up half page and center" })
vim.keymap.set("n", "{", "{zz", { desc = "Move up by whitespace between paragraphs." })
vim.keymap.set("n", "}", "}zz", { desc = "Move down by whitespace between parargraphs" })

vim.keymap.set("n", "n", "nzzzv", { desc = "Next search result, center screen" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous search result, center screen" })


vim.keymap.set("x", "<leader>p", "\"_dP", { desc = "Paste over selection without overwriting register" })

vim.keymap.set("n", "<leader>y", "\"+y", { desc = "Yank line to system clipboard" })
vim.keymap.set("v", "<leader>y", "\"+y", { desc = "Yank selection to system clipboard" })
vim.keymap.set("n", "<leader>Y", "\"+Y", { desc = "Yank to end of line to system clipboard" })

vim.keymap.set("n", "<leader><leader>d", "\"_d", { desc = "Delete into void register" })
vim.keymap.set("v", "<leader><leader>d", "\"_d", { desc = "Delete selection into void register" })

vim.keymap.set("n", "<leader><leader><leader>f", function()
  vim.lsp.buf.format()
end, { desc = "Format buffer via LSP" })


vim.keymap.set("n", "<leader><leader><leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", {
  desc = "Search & replace word under cursor"
})

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make current file executable" })

vim.api.nvim_create_autocmd("FileType", {
  desc = "markdown-toggle.nvim keymaps",
  pattern = { "markdown", "markdown.mdx" },
  callback = function(args)
    local opts = { silent = true, noremap = true, buffer = args.buf }
    local toggle = require("markdown-toggle")


    vim.keymap.set({ "n", "x" }, "<CR>", toggle.checkbox, opts)
    vim.keymap.set({ "n", "x" }, "<M-CR>", toggle.checkbox_cycle, opts)

  end,
})




local state  = vim.fn.stdpath("state")           -- ~/.local/state/nvim
local roots  = { swap  = state.."/swap-tree"
               , undo  = state.."/undo-tree"
               , back  = state.."/backup-tree" }

for _,dir in pairs(roots) do vim.fn.mkdir(dir, "p") end

local function tree_dir(root, absfile)
  local rel = absfile:gsub("^/","")              -- kill leading slash
  local dir = root .. "/" .. vim.fn.fnamemodify(rel, ":h")
  vim.fn.mkdir(dir, "p")                         -- mkdir -p
  return dir
end

vim.api.nvim_create_autocmd({"BufReadPre","BufNewFile"},{
  callback = function(ev)
    local full = vim.fn.fnamemodify(ev.file, ":p")
    if full == "" then return end

    vim.opt_local.directory = { tree_dir(roots.swap, full) }     -- swap
    vim.opt_local.undodir   = { tree_dir(roots.undo, full) }     -- undo
    vim.opt_local.backupdir = { tree_dir(roots.back, full) }     -- backups
    vim.opt_local.undofile  = true                               -- keep undo
  end
})


vim.g.virtual_text_enabled = true


function ToggleVirtualText()
    vim.g.virtual_text_enabled = not vim.g.virtual_text_enabled
    vim.diagnostic.config({ virtual_text = vim.g.virtual_text_enabled })
    print("Virtual text " .. (vim.g.virtual_text_enabled and "enabled" or "disabled"))
end

vim.api.nvim_set_keymap(
    "n",
    "<leader><leader>vt",
    ":lua ToggleVirtualText()<CR>",
    { noremap = true, silent = true }
)




vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically


  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },


  { -- Useful plugin to show you pending keybinds.
    'folke/which-key.nvim',
    event = 'VimEnter', -- Sets the loading event to 'VimEnter'
    opts = {
      delay = 0,
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },

      spec = {
        { '<leader><leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader><leader>d', group = '[D]ocument' },
        { '<leader><leader>r', group = '[R]ename' },
        { '<leader><leader>s', group = '[S]earch' },
        { '<leader><leader>w', group = '[W]orkspace' },
        { '<leader><leader>t', group = '[T]oggle' },
        { '<leader><leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },


  { -- Fuzzy Finder (files, lsp, etc)
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        'nvim-telescope/telescope-fzf-native.nvim',

        build = 'make',

        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },

      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()

      require('telescope').setup {
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader><leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader><leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader><leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader><leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader><leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader><leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader><leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader><leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader><leader>sR.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader><leader><leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader><leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = '[S]earch [/] in Open Files' })

      vim.keymap.set('n', '<leader><leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',

      { 'j-hui/fidget.nvim', opts = {} },

    },
    config = function()

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          map('<leader>Rn', vim.lsp.buf.rename, '[R]e[n]ame')

          map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })

            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })


      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('blink.cmp').get_lsp_capabilities())

      local servers = {
        pylsp = {
          settings = {
            pylsp = {
              pyflakes = { enabled = false },
              pycodestyle = { enabled = false },
              autopep8 = { enabled = false },
              yapf = { enabled = false },
              mccabe = { enabled = false },
              pylsp_mypy = { enabled = false },
              pylsp_black = { enabled = false },
              pylsp_isort = { enabled = false }
            },
          },
        },

        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
              diagnostics = {
                globals = { 'vim' },
                disable = { 'missing-fields' },
              },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
              },
            },
          },
        },
      }

      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        'stylua', -- Used to format Lua code
      })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },

  { -- TokyoNight colorscheme with full default options, updated to be transparent.
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    init = function()
      require("tokyonight").setup({
        style = "night",        -- Available styles: "night", "storm", "moon", "day"
        light_style = "day",    -- The theme is used when vim.o.background is set to light
        transparent = true,     -- Enable transparent background
        terminal_colors = true, -- Configure the colors used in the terminal
        styles = {
          comments = { italic = true },
          keywords = { bold = false },
          functions = { bold = true},
          variables = { italic = true },
          sidebars = "dark",
          floats = "dark",
        },
        day_brightness = 0.3,
        dim_inactive = true,
        lualine_bold = false,
        on_colors = function(colors)
        end,
        on_highlights = function(highlights, colors)
        end,
        cache = true,
        plugins = {
          all = package.loaded.lazy == nil,
          auto = true,
        },
      })
      vim.cmd.colorscheme 'tokyonight-night'
      vim.cmd.hi 'Comment gui=none'
    end,
  },

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.move').setup({

        mappings = {
          left = '<M-S-h>',
          right = '<M-S-l>',
          down = '<M-S-j>',
          up = '<M-S-k>',

          line_left = '<M-S-h>',
          line_right = '<M-S-l>',
          line_down = '<M-S-j>',
          line_up = '<M-S-k>',
        },

        options = {
          reindent_linewise = true,
        },

      })

      require('mini.surround').setup {
          mappings = {
              add = '<leader>sa', -- Add surrounding in Normal and Visual modes
              delete = '<leader>sd', -- Delete surrounding
              find = '<leader>sf', -- Find surrounding (to the right)
              find_left = '<leader>sF', -- Find surrounding (to the left)
              highlight = '<leader>sh', -- Highlight surrounding
              replace = '<leader>sr', -- Replace surrounding
              update_n_lines = '<leader>sn', -- Update `n_lines`

              suffix_last = '<leader>l', -- Suffix to search with "prev" method
              suffix_next = '<leader>n', -- Suffix to search with "next" method
          },
      }



      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      statusline.section_location = function()
        return '%2l:%-2v'
      end

    end,
  },
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs', -- Sets main module to use for opts
    opts = {
      ensure_installed = { 'python', 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    },
  },


  require 'kickstart.plugins.debug',
  require 'kickstart.plugins.indent_line',
  require 'kickstart.plugins.lint',
  require 'kickstart.plugins.autopairs',
  require 'kickstart.plugins.neo-tree',

  { import = 'custom.plugins' },
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "norg",
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})

do
  local mirror_root = vim.fn.expand("~/Documents/NVIM_CONFIG_MIRRORS")
  vim.fn.mkdir(mirror_root, "p")            -- ensure tree exists

  local BUNDLE = mirror_root .. "/user_neovim_config_complete_collection_w-filepaths.md"

  local mirrors = {
    [vim.fn.expand(vim.fn.stdpath("config") .. "/init.lua")] =
      mirror_root .. "/init(home-dotconfig-nvim).lua",

    [vim.fn.expand(vim.fn.stdpath("config") .. "/lua/custom/plugins/init.lua")] =
      mirror_root .. "/lua/custom/plugins/init(home-dotconfig-nvim-lua-custom-plugins).lua",

    [vim.fn.expand(vim.fn.stdpath("config") .. "/lua/numhi/core.lua")] =
      mirror_root .. "/lua/numhi/core(home-dotconfig-nvim-lua-numhi).lua",

    [vim.fn.expand(vim.fn.stdpath("config") .. "/lua/numhi/init.lua")] =
      mirror_root .. "/lua/numhi/init(home-dotconfig-nvim-lua-numhi).lua",

    [vim.fn.expand(vim.fn.stdpath("config") .. "/lua/numhi/palettes.lua")] =
      mirror_root .. "/lua/numhi/palettes(home-dotconfig-nvim-lua-numhi).lua",

    [vim.fn.expand(vim.fn.stdpath("config") .. "/lua/numhi/ui.lua")] =
      mirror_root .. "/lua/numhi/ui(home-dotconfig-nvim-lua-numhi).lua",
  }

  local function read_code_without_full_comments(path)
    local cleaned, inside_block = {}, false
    for line in io.lines(path) do
      local ltrim = line:match("^%s*(.*)$") or ""
      if ltrim:find("^%-%-%[%[") then
        inside_block = true
      elseif inside_block and ltrim:find("%]%]") then
        inside_block = false
      elseif not inside_block and not ltrim:find("^%-%-") then
        table.insert(cleaned, line)
      end
    end
    return cleaned
  end

  local function rebuild_markdown_bundle()
    local md_parts = {}
    for src, _ in pairs(mirrors) do
      if vim.fn.filereadable(src) == 1 then
        table.insert(md_parts, ("```lua %s"):format(src))
        vim.list_extend(md_parts, read_code_without_full_comments(src))
        table.insert(md_parts, "```")
        table.insert(md_parts, "")          -- blank line between fences
      end
    end
    local fh = assert(io.open(BUNDLE, "w"))
    fh:write(table.concat(md_parts, "\n"))
    fh:close()
  end

  for src, dst in pairs(mirrors) do
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = src,
      callback = function()
        local dst_dir = vim.fn.fnamemodify(dst, ":h")
        vim.fn.mkdir(dst_dir, "p")
        vim.fn.system({ "cp", "--", src, dst })

        rebuild_markdown_bundle()
      end,
      desc = "Mirror " .. vim.fn.fnamemodify(src, ":t") .. " + rebuild bundle",
    })
  end

  rebuild_markdown_bundle()
end


```

```lua /home/svaughn/.config/nvim/lua/numhi/palettes.lua
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
