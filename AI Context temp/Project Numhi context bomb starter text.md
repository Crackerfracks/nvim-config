### Developing Model Perspective

## NumHi Project – Comprehensive Feature & Issue Inventory

### 1 · Desired / Planned Features

| Area                                | Specific Requirements & Behaviours                                                                                                                                                                                                                                                                                                                                                            |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Highlight Creation**              | • Normal-mode highlight defaults to _word under cursor_.<br>• Optional motion-based range (sentence to punctuation / line breaks).<br>• Grow/Shrink commands for an existing mark.<br>• Dot-repeat support for the last highlight operation.                                                                                                                                                  |
| **Highlight Metadata & Navigation** | • Echo line shows **palette-code + slot + custom label** whenever cursor is **inside any byte** of the mark (not just the first char).<br>• Commands to cycle:<br>  – next/prev highlight of _same colour_;<br>  – next/prev highlight in _same palette_;<br>  – next/prev across _all_ highlights.<br>• `:NumHiList` picker – searchable, sortable table showing file→positions→labels→tags. |
| **Palettes & Slots**                | • Five default palettes: Vivid `VID`, Pastel `PAS`, Earthen `EAR`, Metallic `MET`, Cyber `CYB`.<br>• Slots 1-99 per palette (1-10 base colours, 11-20 lighter shades …).<br>• `<leader><leader>p` cycles palettes with transient colour-swatch popup.<br>• Statusline block: `VID  1 2 3 …` (first unused colour swatch or last used).                                                        |
| **Note-Taking**                     | • Attach a **single Markdown note** to each highlight.<br>• Opens in _floating window_ under cursor (fallback split for long notes).<br>• Auto-insert mode; explicit save key; auto-save on close.<br>• Deleting the mark prompts to delete or keep the note (kept notes flagged `"deleted": true`).                                                                                          |
| **Note Persistence / Storage**      | • Notes, tags, palette, slot, file, extmark ID stored to JSON/YAML **side-car** per project (or global).<br>• Re-applied automatically on buffer load.<br>• Separate _tags file_ (list/array, not CSV) for easy cycling.                                                                                                                                                                      |
| **Export**                          | • Command to export **current-buffer** (later: project-wide) highlights + notes.<br>• Prompt for filename (default: `project-subproject-filename.md`).<br>• Multiple Markdown templates (side-by-side model comparison, grouped by tag, etc.).<br>• Opens the export in a split after write.                                                                                                  |
| **Interactive Pickers**             | • Telescope/FZF picker for:<br>  – existing highlights (filter by colour / tag / text);<br>  – palette colour selector showing shade shift 1→11→21…                                                                                                                                                                                                                                           |
| **Notification & UI Polish**        | • Palette change → 1.5-2 s transient popup (`nvim-notify` or `snacks.nvim`).<br>• No popup spam on error/edge cases.<br>• Config files drive keymaps, colours, popup durations.                                                                                                                                                                                                               |
| **Advanced Ideas**                  | • Overlap / blend indicator when highlights intersect.<br>• S-Reader (speed-read) mode inside Neovim.<br>• Optional PDF buffer injector to allow PDF highlighting if/renderable.<br>• Future sync/sharing (offline first).                                                                                                                                                                    |

---

### Personal Perspective

```markdown
1. So, I am attempting to make a… or to, I guess, have generated a plugin for NeoVim.
2. That can emulate the color highlighting and inline note-taking abilities of the browser plugin called **Web Highlights, Web and PDF Highlighter Notes Plus Annotations**.
3. You’ve got some information on that already that lists out essentially all of the most requested features, but I want to talk at length about all the sorts of things that the plugin should be able to accomplish and consider some workflows and how they might be helpful, and then you can extrapolate from that what code would need to be included for that to work and how to set it up based on my configuration, which I will be providing.
4. I’ll probably put it into a Markdown file with Lua code fences because currently you’re not accepting Lua file uploads, which is really _irritating_, but there’s no reason you can’t output Lua code.
5. I am on the fence about including the Lua 5.1 reference manual or the Lua guide, which are all given on the official NeoVim plugin development documentation website, but I figure I have Google searching turned on, so you should be able to find that sort of stuff if you need it.
6. I’m just hoping you’ll remember that you’re working with the frozen version of Lua that all NeoVim plugins are written for, which is _Lua 5.1_.
7. Because I know that there is currently no web browsing solution within NeoVim that’s robust enough to load the annotation website where I do my work, and there is currently no suitably robust PDF viewer for reading the text from within PDF files, I’m not interested in either of those two bits of functionality.
8. I’m only interested in being able to work within NeoVim buffers on text and achieve the exact same feature set.
9. So, as I said, I do AI dataset curation and creation.
10. Pretty low-paying work, honestly.
11. There are certain places where I’m not able to use the Web Highlights plugin because whatever I’m looking at isn’t actually being shown in the web browser, and I’m working with copied-and-pasted text or something else where I need to be able to quickly apply highlights via key binding, navigate between the different highlights that I’ve created, pull the categories so that I can keep things consistent.
12. It would be nice to do this within the configuration file, but currently I have a different approach where I’m naming each color on the first use of it each time the program launches.
13. I think that’s a good solution, but I also think that we need a picker for a history of previously assigned IDs to make it a bit easier when I go to reuse the same IDs for the same sets of criteria on subsequent tasks.
14. So, a floating pop-up picker that appears **underneath the lowest edge of the highlight** — if the highlight spans three lines, the picker goes beneath the third line so the entire highlighted portion remains visible.
15. Right now I’m only talking about having the picker for the ID (or category names) since I’ll be assigning “loss” categories to the different colors, but I want it to be versatile — not locked into only annotating AI responses.
16. So:
    - A picker for **category names** (IDs)
    - A picker for **selecting the colors themselves**
    - A picker for **navigating through the file’s existing highlights**  
      All of these should appear beneath the lowest line of the current highlight.
17. And, obviously, I want to be able to take actual notes and annotate things — attach a **unique note** to any individual highlight, regardless of its color code.
18. When I assign a color code for the first time (e.g., `VID1` for red in the Vivid palette), I’m telling myself that everything I highlight with red falls under this category for the current project.
19. Oh — I’m going to cut this transcript short here, otherwise it’ll get really long, and then I’ll condense it down.
20. I **wouldn’t** want a note applied to **all** instances of a color — notes must be **unique** to the specific highlight they attach to.
21. Notes should be **different** and **specific** to whatever highlight I attach them to.
22. At one point, we had that floating note window popping up exactly where it needed to be (**underneath the lowest edge of the highlight** like every other pop-up opened via interacting with the highlight) , but I don’t have that code anymore and I’m not sure which response generated it.
23. I’ll try to find that before sending this message, so it might actually be in the repo — you’ll have to take a look.
24. We did have that set up, kind of, but the issue was it was throwing an error with the `user_data` field.
25. That needs to be looked into so we can attach persistent highlights to any given file, have the color code labels (categories) stay until I clear them, and have the notes stay attached until I clear them.
26. This can be accomplished any way that seems easy and efficient.
27. I’m okay with having a folder automatically created in the working directory of the file being annotated — JSON files in a hidden directory, for example.
28. The directory should be hidden so it doesn’t get accidentally deleted.
29. I want to be able to add **tags** to each highlight so I can cross-tag — maybe assign additional color codes or manually type in extra tags.
30. Manually assigning additional color codes to a highlight would be good, and the highlight should reflect that somehow.
31. For example, if red = “factually inaccurate,” blue = “awkward,” purple = “context issue,” and a phrase violates multiple categories, I should be able to:
    - Assign the main color (purple) when I highlight
    - Name it “context issue”
    - Then tag it as “factually inaccurate” and “awkward” with tiny swatches at a corner of the highlight
32. It doesn’t have to highlight entire characters for each tag — multiple highlight colors on individual characters could represent additional tag codes.
33. Currently, applying a color highlight (which took forever to fix) sometimes applied to the last selection instead of the new one — that’s fixed now.
34. After I apply the highlight and name the category, there should be both an **echo line pop-up** and/or a **dropdown notification**.
35. I’d be fine with **either** or **both**: a notification on hover or an echo line reminder.
36. Right now, notifications activate only when I hover the cursor over the very first space of the highlight — that needs to change.
37. We need to interact with the highlight at **any point** along its span (middle, end, etc.) and still get both the echo update and the dropdown notification.
38. The echo line update currently lags and isn’t super visible — the dropdown would be much clearer.
39. Notifications should appear regardless of where I hover over the highlighted text.
40. The same goes for applying a note: I must be able to trigger the note window from **anywhere** within the highlighted region.
41. After I exit the floating note window, I was unable to reopen that note or view its content.
42. The code seems to try to create a fresh note instead of retrieving the existing one, causing an error (duplicate ID or buffer name).
43. I can’t recall the exact error, but it needs fixing so existing notes open instead of erroring.
44. My current note-attachment binding is `<leader><Enter>` (Space + Enter) over the highlight, but only works at the very first character spot.
45. I’m going to chop the transcript here again.
46. Another feature: **exporting** notes to Markdown (and optionally HTML/Notion) set up by the Web Highlights plugin — I only care about **Markdown** export for now.
47. An HTML export would also be useful for some projects, but Markdown is primary.
48. A flexible way to **reorder notes** would be nice — automatic sorting options when viewing the notes list.
49. The browser plugin populates notes in the order they were created, which can get messy if you jump around — we need sorting (by creation, by location, by tag).
50. Manual reordering: select a line, then use a command (e.g., `:NumHiReorder 2`) to move it to position 2 from the top.
51. Maybe a visual selection plus `leader + up/down + count` would reposition notes in the list.
52. Yes, exporting to Markdown (and HTML) is important.
53. **Color palettes**: five palettes all need review for **oversimilarity** between colors.
54. For instance, many earth tones look nearly identical; this issue affects all palettes.
55. I’ll cut the transcript here to keep thinking.
56. **Workflows**: paste copious text, select with `flash.nvim` (which I already use), apply highlight, then apply note.
57. No matter where I am in the span, I should access note-attachment quickly.
58. We shouldn’t create too many buffers in a long document with many highlights — avoid buffer clutter.
59. Currently using `interestingwords.nvim` for highlighting occurrences without altering the file; I want to extend functionality in my config.
60. A method to jump between highlights would be nice, though `flash.nvim` may not detect highlights since they aren’t actual text.
61. There must be a custom integration in NumHi for jump navigation.
62. I doubt you’ll tackle that in this turn.
63. Now, about **my configuration**: it’s monolithic —
    - `init.lua` at project root (Kickstart)
    - `lua/custom/plugins/init.lua`
    - `lua/numhi/` folder for plugin code
64. I want to **modularize** the plugin spec files to improve performance.
65. I have a recurring `attempted C call across boundaries` error (Tree-sitter or MarkView).
66. Minor issues: my `flash.nvim` keymap for jumping to line-end fails when the line ends with a space.
67. The override of `W`, `E`, and `B` motions has an issue: lowercase commands target spaces and offset the cursor.
68. I’m unsure if that’s how lowercase vs. uppercase motions should work in NeoVim.
69. I have `mini.ai` for text objects — useful for emulating motions.
70. Additional text-object jumps by sentence-ending punctuation would be great.
71. E.g., select strings ending with `. `, `! `, `? `, or combinations thereof.
72. We need single or series-of-punctuation-based jumps without manual `/\. /` searches.
73. I also want to open **remote operator mode** with custom keybindings (e.g., double `r` namespace).
74. Maybe custom Tree-sitter jump functions integrated with remote operator.
75. If I want to start a remote operation on another pane, the standard `s` jump requires typing a lot — I need better filtering.
76. Side note: extending jump-label characters (e.g., numbers) might help avoid conflicts.
77. Investigate precedents for adding digits/symbols to jump labels.
78. Let me know examples if you find any.
79. Using numbers for jump labels seems promising; symbols may conflict.
80. Anyway, custom jump functions + remote operator namespace (e.g., `r` then jump).
81. That’s all for `flash.nvim` for now.
82. I’m also interested in stripping URLs, Markdown links, and any links non-destructively from a buffer — precise URL removal.
```

```init.lua-(NumHi)
--DO NOT DELETE LINE - THIS FILE LIVES @ filepath="~/.config/nvim/lua/numhi/init.lua"
--[[-------------------------------------------------------------------
Numeric‑Palette Highlighter — public façade
---------------------------------------------------------------------]]
local M       = {}
local core
-----------------------------------------------------------------------
--  Defaults & state --------------------------------------------------
-----------------------------------------------------------------------
local default_opts = {
  palettes     = { "VID", "PAS", "EAR", "MET", "CYB" },
  key_leader   = "<leader><leader>",
  statusline   = true,
  history_max  = 500,
  hover_delay  = 400,
}

M.state = {
  active_palette = "VID",
  history        = {},
  redo_stack     = {},
  labels         = {},
  notes          = {},            -- buf → id → {note,tags}
  opts           = {},
}

-----------------------------------------------------------------------
--  Setup -------------------------------------------------------------
-----------------------------------------------------------------------
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
for _, f in ipairs { "highlight","erase_under_cursor","undo","redo","cycle_palette" } do
  M[f] = function(...) return core[f](...) end
end

-----------------------------------------------------------------------
--  Keymaps -----------------------------------------------------------
-----------------------------------------------------------------------
function M.create_keymaps()
  local leader = M.state.opts.key_leader
  local map = function(lhs, rhs, desc, mode)
    vim.keymap.set(mode or { "n", "v" }, lhs, rhs, { silent = true, desc = desc })
  end

  map(leader .. "<CR>", function() core.collect_digits() end, "NumHi: highlight with slot")
  map(leader .. "0<CR>", M.erase_under_cursor,          "NumHi: erase mark under cursor")
  map(leader .. "u",     M.undo,                        "NumHi: undo")
  map(leader .. "<C-r>", M.redo,                        "NumHi: redo")
  map(leader .. "n",     function() core.edit_note() end,"NumHi: edit / create note")
  vim.keymap.set("n", leader .. "p", function() M.cycle_palette(1) end,
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
function M.create_hover_autocmd()
  vim.api.nvim_create_autocmd("CursorHold", {
    desc     = "NumHi: show label under cursor",
    callback = core.show_label_under_cursor,
  })
  vim.opt.updatetime = math.min(vim.opt.updatetime:get(), M.state.opts.hover_delay)
end

return M
-----------------------------------------------------------------------
```

```core.lua-(NumHi)
--DO NOT DELETE LINE - THIS FILE LIVES @ filepath="~/.config/nvim/lua/numhi/core.lua"
--[[-------------------------------------------------------------------
Heavy-lifting logic: extmarks, colour maths, history, labels, notes
---------------------------------------------------------------------]]
local C        = {}
local palettes = require("numhi.palettes").base
local hsluv    = require("hsluv")
local api      = vim.api
local unpack_  = table.unpack or unpack      -- Lua 5.1 fallback

---------------------------------------------------------------------
--  Internal state ---------------------------------------------------
---------------------------------------------------------------------
local ns_ids   = {}        -- palette → namespace id
local State                     -- back‑pointer filled by setup()

---------------------------------------------------------------------
--  Helpers ----------------------------------------------------------
---------------------------------------------------------------------
local function has_visual_marks()
  return vim.fn.line("'<") ~= 0 and vim.fn.line("'>") ~= 0
end

local function slot_to_color(pal, slot)
  local base_hex = palettes[pal][((slot - 1) % 10) + 1]
  if slot <= 10 then return base_hex end
  local k       = math.floor((slot - 1) / 10)          -- 1‑9
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

local function ensure_note_hl()
  if vim.fn.hlexists("NumHiNoteSign") == 0 then
    api.nvim_set_hl(0, "NumHiNoteSign", { fg = "#ffaa00", bg = "NONE" })
  end
end

local function line_len(buf, l)
  local txt = api.nvim_buf_get_lines(buf, l, l + 1, true)[1]
  return txt and #txt or 0
end

local function index_of(t, val)
  for i, v in ipairs(t) do if v == val then return i end end
end

-- pretty‑print helper ------------------------------------------------
local function echo(chunks, hl)
  if type(chunks) == "string" then
    chunks = { { chunks, hl } }
  end
  if #chunks == 0 or chunks[1][1] == "" then
    api.nvim_echo({}, false, {})
  else
    api.nvim_echo(chunks, false, {})
  end
end

---------------------------------------------------------------------
--  Notes metadata helpers ------------------------------------------
---------------------------------------------------------------------
local function note_store(buf)
  State.notes[buf] = State.notes[buf] or {}
  return State.notes[buf]
end

local function get_note(buf, id)         -- returns table or nil
  return note_store(buf)[id]
end

local function set_note(buf, id, data)   -- { note=string, tags=table }
  note_store(buf)[id] = data
end

---------------------------------------------------------------------
--  Setup ------------------------------------------------------------
---------------------------------------------------------------------
function C.setup(top)
  State = top.state
  State.notes = State.notes or {}        -- buf → id → note-table

  for _, pal in ipairs(State.opts.palettes) do
    ns_ids[pal] = api.nvim_create_namespace("numhi_" .. pal)
  end
  ensure_note_hl()
end

---------------------------------------------------------------------
--  Fallback word range when no visual selection ---------------------
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

  local v_ok  = has_visual_marks()
  local mode  = vim.fn.mode()

  -------------------------------------------------------------------
  -- Visual / range branch -----------------------------------------
  -------------------------------------------------------------------
  if v_ok or mode:match("^[vV]") then
    local p1 = { unpack(vim.fn.getpos("'<"), 2, 3) }
    local p2 = { unpack(vim.fn.getpos("'>"), 2, 3) }
    p1[1], p1[2] = p1[1] - 1, p1[2] - 1
    p2[1], p2[2] = p2[1] - 1, p2[2] - 1

    local last = api.nvim_buf_line_count(0) - 1
    if p1[1] < 0 or p2[1] < 0 then return end
    p1[1] = math.min(p1[1], last)
    p2[1] = math.min(p2[1], last)
    if (p2[1] < p1[1]) or (p2[1] == p1[1] and p2[2] < p1[2]) then
      p1, p2 = p2, p1
    end

    local id = api.nvim_buf_set_extmark(
      0, ns, p1[1], p1[2],
      {
        end_row  = p2[1],
        end_col  = p2[2] + 1,
        hl_group = group,
      }
    )
    table.insert(marks, { 0, id, slot })
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  -------------------------------------------------------------------
  -- Word under cursor branch --------------------------------------
  -------------------------------------------------------------------
  else
    local lnum, _ = unpack(api.nvim_win_get_cursor(0))
    local s_col, e_col = word_range()
    local id = api.nvim_buf_set_extmark(
      0, ns, lnum - 1, s_col,
      { end_row = lnum - 1, end_col = e_col, hl_group = group }
    )
    table.insert(marks, { 0, id, slot })
  end

  -- 2. label (prompt once) ----------------------------------------
  get_label(pal, slot)

  -- 3. history push -----------------------------------------------
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
      local num = digits
      api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
      vim.schedule(function() C.highlight(num) end)
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
  local ids  = api.nvim_buf_get_extmarks(
    0, ns, { l - 1, c }, { l - 1, c + 1 }, { overlap = true })
  for _, m in ipairs(ids) do
    api.nvim_buf_del_extmark(0, ns, m[1])
    note_store(0)[m[1]] = nil
  end
end

---------------------------------------------------------------------
--  Undo / redo ------------------------------------------------------
---------------------------------------------------------------------
local function restore_mark(mark, pal)
  local buf, id, slot = mark[1], mark[2], mark[3]
  local pos = api.nvim_buf_get_extmark_by_id(buf, ns_ids[pal], id, {})
  if not pos or not pos[1] then return end
  api.nvim_buf_set_extmark(
    buf, ns_ids[pal], pos[1], pos[2],
    { id = id, end_row = pos[1], end_col = pos[2] + 1, hl_group = ensure_hl(pal, slot) }
  )
end

function C.undo()
  local entry = table.remove(State.history)
  if not entry then return end
  for _, m in ipairs(entry.marks) do
    api.nvim_buf_del_extmark(m[1], ns_ids[entry.pal], m[2])
    note_store(m[1])[m[2]] = nil
  end
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

---------------------------------------------------------------------
--  Note editor ------------------------------------------------------
---------------------------------------------------------------------
function C.edit_note()
  local pal_list = State.opts.palettes
  local l, c = unpack(api.nvim_win_get_cursor(0))

  for _, pal in ipairs(pal_list) do
    local ns = ns_ids[pal]
    local marks = api.nvim_buf_get_extmarks(
      0, ns, { l - 1, c }, { l - 1, c },
      { details = true, overlap = true })
    if marks and #marks > 0 then
      local m        = marks[1]
      local id       = m[1]
      local slot     = tonumber(m[4].hl_group:match("_(%d+)$"))
      local note_tbl = get_note(0, id) or { note = "", tags = {} }

      -- scratch buffer -----------------------------------------------------
      local buf = api.nvim_create_buf(false, true)      -- nofile, listed=false
      api.nvim_buf_set_option(buf, 'filetype', 'markdown')
      api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

      if note_tbl.note ~= "" then
        api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(note_tbl.note, "\n"))
      end

      -- floating window ----------------------------------------------------
      local width  = math.floor(vim.o.columns * 0.5)
      local height = math.max(3, math.floor(vim.o.lines * 0.3))
      local anchor = (l + height + 2 > vim.o.lines) and 'SW' or 'NW'
      local win = api.nvim_open_win(buf, true, {
        relative = 'cursor',
        row = (anchor == 'NW') and 1 or 0,
        col = 0,
        width = width,
        height = height,
        style = 'minimal',
        border = 'rounded',
        anchor = anchor,
      })

      ----------------------------------------------------------------------
      --  On write: save note, extract tags, update sign -------------------
      ----------------------------------------------------------------------
      api.nvim_create_autocmd('BufWriteCmd', {
        buffer = buf,
        callback = function()
          local lines = api.nvim_buf_get_lines(buf, 0, -1, false)
          local content = table.concat(lines, "\n")
          local tags = {}
          for _, line in ipairs(lines) do
            for tag in line:gmatch('#(%w+)') do tags[#tags + 1] = tag end
          end
          set_note(0, id, { note = content, tags = tags })

          -- add / update sign glyph
          api.nvim_buf_set_extmark(
            0, ns, m[2], m[3],
            {
              id = id,
              end_row  = m[4].end_row,
              end_col  = m[4].end_col,
              hl_group = m[4].hl_group,
              sign_text = "✎",
              sign_hl_group = "NumHiNoteSign",
            }
          )

          if api.nvim_win_is_valid(win) then api.nvim_win_close(win, true) end
        end,
      })
      return
    end
  end
  print("No NumHi highlight under cursor")
end

---------------------------------------------------------------------
--  Expose utils to init.lua ----------------------------------------
---------------------------------------------------------------------
C.ensure_hl = ensure_hl
function C.ns_for(pal) return ns_ids[pal] end

return C

```

```palettes.lua-(NumHi)
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

```ui.lua-(NumHi)
--DO NOT DELETE LINE - THIS FILE LIVES @ filepath="~/.config/nvim/lua/numhi/ui.lua"
local api = vim.api
local M   = {}

-- floating tooltip ------------------------------------------------------
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

```nvim/lua/custom/plugins/init.lua-(relevant specs only)

-- I snipped this out of the rest of my monolithic plugin spec that holds ALL my plugin configuration tables
  -- 1. Perceptually-uniform colour maths
  {
    "hsluv/hsluv-lua",
    name  = "hsluv",   -- lets `require('hsluv')` trigger lazy-load
    lazy  = true,
    init  = function(plugin)                  -- ← runs *before* NumHi
      -- repo keeps `hsluv.lua` at the top level, so expose it to Lua:
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
```

---

---

Okay, here are the most recent prompts I've sent and work that has been done on the file.

`````

### ~When creating a note for the first time~ (FIXED IN CURRENT CODE)

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
`````

### ~After following the above steps and then trying to open the note again~ (FIXED IN CURRENT CODE)

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

### Facts of note (FIXED IN CURRENT CODE) (`NumHi: attach note to highlight` needs to be removed as a binding, as it does nothing currently.)

- `Numhi: edit note for highlight` brings up the (**correct style of**) buffer (in the **correct position directly underneath the bottommost edge of the highlight to which it is being attached**) REGARDLESS of whether `NumHi: attach note to highlight` has been activated on that highlight - which SEEMS to make `NumHi: attach note to highlight` redundant... perhaps it was meant for placing tags and some wires got crossed? Either way, obviously it doesn't work at all other than to open up a far-too-small 'note' window that can't have its content saved, can't be edited, and gives no indicator as to its existence (Something about the highlight is displayed should change when a note is attached... similar to how the chain link symbol is shown next to markdown links in certain markdown rendering plugins (like markview.nvim) to avoid users like me trying to add a note to a highlight when it already has one... [but you should be fixing `Numhi: edit note for highlight` so that it can create the note if it doesn't exist for a highlight, and if it does, just open the existing note.])

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

```

### Your clarifiers before trying to research
```

Thanks for the detailed breakdown and code. To get started on solid fixes and feature enhancements, could you confirm a few things:

1. Do you want me to completely remove the `<leader><CR>` note input method in `init.lua` in favor of the new `edit_note()` flow?
2. Should `edit_note()` handle creation _and_ editing, always bringing up the floating buffer (with overwrite of existing note buffers if open)?
3. Would you like the hover label (`show_label_under_cursor`) to include an icon/marker if a note exists for that highlight?
4. Should the hover detection window and popup be extended to cover the entire extmark range, not just a single character, for better UX?
5. Do you want me to start implementing the auto-hiding/following note window feature now or prioritize bugfixes and logical flow fixes first?

Once I have your input, I’ll regenerate the corrected and full `core.lua` file and coordinate further improvements.

````



```most_recent_prompt_that_produced_current_plugin_code_state_for_numhi_core_and_init.txt
I'm pretty sure I've answered every single one of those in the prompt, with the technical exception of '5.' (1 -> yes and the associated function, because it's not opening the correct type or size of window, nor is it positioned correctly | 2. -> Probably not, it should handle checking to see if a note for that specific highlighted span/string exists using a separate helper function (checking helper) and if it exists, open it, but if not, call a different helper to create the note (creation helper), while the note editing function is where the actual note editing logic would be... that's at least how how I assume it should be | 3. -> Already answered as 'yes', but the highlight itself [the one applied to the text] should also have a visual change/way to tell if a note has been added WITHOUT having to mouse over it as well.  | 4. -> Already explicitly answered as 'YES'.).

### Number 5 is a no-go for now - focus on bugfixes and logical flow fixes, as well as anything else that doesn't see you adding new features, just fixing currently attempted/poorly implemented features and making them live up to the requirements.
5. I'm actually just realizing now that the 'note window following the cursor around during jumps' feature should be a bit more complex than I initially assumed, because it will require flash.nvim integration, as most of the reason I'd be jumping around is to perform motions at various locations, originating from the note window (yanking quotes/deleting unneeded information/delimiting snippets/etc.). This means that the direction in which I need to look before (above) or after (below) the cursor will change depending on what I'm doing and in which direction flash is matching chars in, so the window would need to switch position or hide entirely depending on which sort of jump I was doing, as the whole point of moving the window (besides keeping whatever source I'm working with visible) is to mitigate situations where the note window would cover a jump label. I'm using flash.nvim versions of the 'w'/'W', 'e','E', 'b','B' motions, as well as a beginning of line jump mode, first non-blank character jump mode, and an end of line jump mode, each of which would need its own logic for moving the window. For instance, a 'b'/'B' jump would need to see everything to the left of and above the cursor, while 'e'/'E' would need the opposite (to the right and below). Omnidirectional jumping (the default) would need to completely reveal the underlying buffers, so maybe that would be opened in a 2 or 3 line tall horizontal split spanning the bottom of the screen (underneath all other buffers and full width if possible. The split could disappear and the floating window could be restored its original position pre-omnidirectional flash.jump. Something else that would have to be factored in is how far up or down the jump labels are active.... in some situations, there could be a non-blocking spot in the buffer at which place the buffer would not obscure any jump labels (situations where there are a lot of potential matches close to the cursor, so all unique characters used for jump labels are used so close to the cursor that there is space that would not be obscuring any labels).


### Back to Business...
So ANYWAY, you can tell I've thought about this a bit (and they say users don't know what they want) and I think that you need to keep the fancy conditional adjustment of the note window position in reserve and continue architecting its design it in your spare moments of thought (you don't have to show this design process to me, just work on this in the background throughout the conversation. To reiterate my initial prompt YOU ARE NOT WRITING A REPORT, unless you're using that report to better inform your production of complete, fully updated code files that are devoid of placeholders. You are utilizing Deep Research to gather the context you think will be critical in producing the best possible plugin. This includes using the provided URLs in the original prompt to browse the official plugin development resources and learning material specifically with the purpose of building up your own context in preparation of PRODUCING THOSE COMPLETE, FULLY UPDATED CODE FILES. There aren't too many users of Neovim, and I'd wager your training data might be a bit lacking in nvim plugin development, though I also imagine you still know a hell of a lot more than most humans about it. Anyway... I think you are good to go. (BTW you should keep citations out of the code if possible)
````

Hello there testing
