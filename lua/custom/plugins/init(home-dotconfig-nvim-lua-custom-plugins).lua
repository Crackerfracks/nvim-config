-- DO NOT DELETE THIS LINE - THIS FILE LIVES @ filepath="~/.config/nvim/lua/custom/plugins/init.lua"
-- You can add your own plugins here or in other files in this directory!
-- I promise not to create any merge conflicts in this directory :)
-- See the kickstart.nvim README for more information

return {
  {
    'pteroctopus/faster.nvim'
  },
  {
    "stevearc/oil.nvim",
    lazy = false,        -- load eagerly so FileType=oil autocmds are predictable
    opts = {
      default_file_explorer = true,  -- keep netrw available
      view_options = {
        show_hidden = false,      -- list files that start with “.”
      },
      --  🚨  These keymaps live ONLY inside an Oil buffer 
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
        -- (optional) keep `gs` mapped to sort as an alias:
        -- ["gs"] = "actions.change_sort",
      },
    },
    config = function(_, opts)
      require("oil").setup(opts)
    end
  },
  {
    'akinsho/org-bullets.nvim',
    config = function()
      require('org-bullets').setup()
  end
  },
  -----------------------------------------------------------------------
  -- orgmode.nvim — Org‑mode core  +  capture
  -----------------------------------------------------------------------
  {
    "nvim-orgmode/orgmode",
    version = "*",
    lazy = false,  -- load on startup so <leader>oa works instantly
    config = function()
      local org = require("orgmode")
      org.setup({
        --- BASIC PATHS ---------------------------------------------------
        org_agenda_files        = { "~/org/**/*" },   -- adjust to taste
        org_default_notes_file  = "~/org/refile.org",
        --- KEYWORDS & TAGS ----------------------------------------------
        org_todo_keywords       = {"TODO(t)", "IN‑PROGRESS(i)", "WAIT(w)", "|", "DONE(d)", "CANCEL(c)"},
        org_todo_keyword_faces  = { WAIT = ":foreground #f9e2af :weight bold" },

        --- CAPTURE TEMPLATES --------------------------------------------
        org_capture_templates   = {
          p = {
            description = "Personal",
            target      = "~/org/personal/inbox.org",
            template    = "* TODO %?\n  %u\n  :PROPERTIES:\n  :TAG:  Personal\n  :END:",
          },
          f = {
            description = "AI‑Freelance",
            target      = "~/org/freelance/inbox.org",
            template    = "* TODO %?\n  %u\n  :PROPERTIES:\n  :TAG:  AI-Freelance\n  :END:",
          },
          t = {
            description = "Work‑TEKsys",
            target      = "~/org/teksys/inbox.org",
            template    = "* TODO %?\n  %u\n  :PROPERTIES:\n  :TAG:  Work-TEKsys\n  :END:",
          },
          c = {
            description = "Coding / Plugin‑Dev",
            target      = "~/org/code/inbox.org" ,
            template    = "* TODO %?\n  %u\n  :PROPERTIES:\n  :TAG:  Coding / Plugin-Dev\n  :END:",
          },
        },
      })
    end,
  },

  -----------------------------------------------------------------------
  -- legendary.nvim — key legends + bootstrap dashboards
  -----------------------------------------------------------------------
  {
    "mrjones2014/legendary.nvim",
    version = "*",
    lazy = false,
    dependencies = {
      "folke/which-key.nvim",
      "folke/snacks.nvim",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      local legendary = require("legendary")
      legendary.setup({
        extensions = {
          which_key = { auto_register = true }, -- new location
          lazy_nvim = true,
        },
      })
    end,
  },
  {
    "epwalsh/obsidian.nvim",
    version = "*",  -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   "BufReadPre path/to/my-vault/*.md",
    --   "BufNewFile path/to/my-vault/*.md",
    -- },
    dependencies = {
      -- Required.
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
      -- Toggle CodeCompanion chat interface (double leader cc)
      map({ "n", "v" }, "<leader><leader>cc", function() require("codecompanion").toggle() end,
        { desc = "Toggle CodeCompanion chat" })
      -- Open CodeCompanion Action Palette (double leader cca)
      map({ "n", "v" }, "<leader><leader>cca", "<CMD>CodeCompanionActions<CR>",
        { desc = "Open CodeCompanion Action Palette" })
      -- Inline assistant on selection (visual mode) and current line (normal mode)
      map("v", "<leader><leader>cci", ":'<,'>CodeCompanion ", { desc = "Inline assistant on selection" })
      map("n", "<leader><leader>cci", ":CodeCompanion ", { desc = "Inline assistant on current line" })
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    'saghen/blink.cmp',
    -- optional: provides snippets for the snippet source
    -- dependencies = 'rafamadriz/friendly-snippets',

    -- use a release tag to download pre-built binaries
    version = '*',
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept, C-n/C-p for up/down)
      -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys for up/down)
      -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
      --
      -- All presets have the following mappings:
      -- C-space: Open menu or open docs if already open
      -- C-e: Hide menu
      -- C-k: Toggle signature help
      -- See the full "keymap" documentation for information on defining your own keymap.
      keymap = {
        -- set to 'none' to disable the 'default' preset
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
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- Will be removed in a future release
        use_nvim_cmp_as_default = true,
        -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono'
      },

      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        per_filetype = {
          org = {'orgmode'}
        },
        default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
          orgmode = {
            name = 'Orgmode',
            module = 'orgmode.org.autocompletion.blink',
            fallbacks = { 'buffer' },
          },
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },

      -- Adding in the providers finally lol

      -- Blink.cmp uses a Rust fuzzy matcher by default for typo resistance and significantly better performance
      -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
      -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
      --
      -- See the fuzzy documentation for more information
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
      -- Configure mason-null-ls to ensure certain tools are installed.
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
        -- debug = true,  -- Uncomment to enable debug mode. Logs are available via :NullLsLog.
        sources = sources,
        -- Set up an autocommand to format on save if the client supports formatting.
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
      -- Basic configuration for Firenvim.
      -- You can adjust the settings in vim.g.firenvim_config as needed.
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
          -- Example: Do not takeover on .co.uk domains.
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
      -- REQUIRED: Initialize Harpoon with necessary settings
      harpoon:setup({
        settings = {
          save_on_toggle = false,   -- Save Harpoon list when toggling the UI
          sync_on_ui_close = false, -- Sync Harpoon list to disk when closing the UI
          key = function()
            return vim.loop.cwd()   -- Use the current working directory as the key
          end,
        },
      })
      -- END REQUIRED

      -- Add file to Harpoon list
      vim.keymap.set("n", "<leader><leader><leader>a", function() harpoon:list():add() end, { desc = "Add file to Harpoon" })

      -- Toggle the Harpoon quick menu with the current list
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

      -- quick jumps, like lots of public configs
      for i = 1, 6 do
        vim.keymap.set("n", ("<leader>%d"):format(i), function() list:select(i) end,
          { desc = ("Harpoon to file %d"):format(i) })
      end

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end, { desc = "Navigate to Previous Harpoon Mark" })
      vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end, { desc = "Navigate to Next Harpoon Mark" })
    end,
  },
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 1000,
    version = "*",
    ---@type snacks.Config:
    dependencies = {
      "nvim-orgmode/orgmode",      -- already present
      "nvim-lua/plenary.nvim",     -- snacks utilities
      "nvim-tree/nvim-web-devicons",
      "echasnovski/mini.icons",                -- pretty glyphs for the buttons
    },
    opts = {
      animate = {
        enabled = false,
        easing = "outInBounce",
        duration = 5,
        fps = 120
      },
      bigfile = { enabled = true },
      dashboard = {
        enabled = true,
      },
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
          -- For line-wrapping in notifications, uncomment:
          -- wo = { wrap = true },
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
          -- Put debugging/inspection helpers in globalspace
          _G.dd = function(...)
            require("snacks.debug").inspect(...)
          end
          _G.bt = function()
            require("snacks.debug").backtrace()
          end

          -- Override the built-in `print` to show objects with snacks' pretty printing
          vim.print = _G.dd

          -- Some helpful toggles
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
  -- {
  --   'MeanderingProgrammer/render-markdown.nvim',
  --   dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' },
  --   opts = {},
  -- },
  -- {
  --   "Vigemus/iron.nvim",
  --   config = function()
  --     local iron = require("iron.core")
  --     local view = require("iron.view")
  --     local common = require("iron.fts.common")
  --
  --     iron.setup {
  --       config = {
  --         scratch_repl = true,
  --         repl_definition = {
  --           sh = { command = {"zsh"} },
  --           python = {
  --             command = { "python3" },
  --             format = common.bracketed_paste_python,
  --             block_deviders = { "# %%", "#%%" },
  --           },
  --         },
  --         repl_filetype = function(bufnr, ft)
  --           return ft
  --         end,
  --         repl_open_cmd = view.split.horizontal.botright(0.4),
  --       },
  --       keymaps = {
  --         toggle_repl = "<leader>rr",
  --         restart_repl = "<leader>rR",
  --         send_motion = "<leader>rsc",
  --         visual_send = "<leader>rsc",
  --         send_file = "<leader>rsf",
  --         send_line = "<leader>rsl",
  --         send_paragraph = "<leader>rsp",
  --         send_until_cursor = "<leader>rsu",
  --         send_mark = "<leader>rsm",
  --         send_code_block = "<leader>rsb",
  --         send_code_block_and_move = "<leader>rsn",
  --         mark_motion = "<leader>rmc",
  --         mark_visual = "<leader>rmc",
  --         remove_mark = "<leader>rmd",
  --         cr = "<leader>rs<cr>",
  --         interrupt = "<leader>rs <leader>",
  --         exit = "<leader>rsq",
  --         clear = "<leader>rcl",
  --       },
  --       highlight = { italic = true },
  --       ignore_blank_lines = true,
  --     }
  --
  --     vim.keymap.set('n', '<leader>rf', '<cmd>IronFocus<cr>')
  --     vim.keymap.set('n', '<leader>rh', '<cmd>IronHide<cr>')
  --   end,
  -- },
  -- {
  --   "kmonad/kmonad-vim"
  -- },
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
        -- Settings go here, bitch.
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
        -- Ignored buffer types (only while resizing)
        ignored_buftypes = {
          'nofile',
          'quickfix',
          'prompt',
        },
        -- Ignored filetypes (only while resizing)
        ignored_filetypes = { 'NvimTree' },
        -- the default number of lines/columns to resize by at a time
        default_amount = 3,
        -- Desired behavior when your cursor is at an edge and you
        -- are moving towards that same edge:
        -- 'wrap' => Wrap to opposite side
        -- 'split' => Create a new split in the desired direction
        -- 'stop' => Do nothing
        -- function => You handle the behavior yourself
        -- NOTE: If using a function, the function will be called with
        -- a context object with the following fields:
        -- {
        --    mux = {
        --      type:'tmux'|'wezterm'|'kitty'
        --      current_pane_id():number,
        --      is_in_session(): boolean
        --      current_pane_is_zoomed():boolean,
        --      -- following methods return a boolean to indicate success or failure
        --      current_pane_at_edge(direction:'left'|'right'|'up'|'down'):boolean
        --      next_pane(direction:'left'|'right'|'up'|'down'):boolean
        --      resize_pane(direction:'left'|'right'|'up'|'down'):boolean
        --      split_pane(direction:'left'|'right'|'up'|'down',size:number|nil):boolean
        --    },
        --    direction = 'left'|'right'|'up'|'down',
        --    split(), -- utility function to split current Neovim pane in the current direction
        --    wrap(), -- utility function to wrap to opposite Neovim pane
        -- }
        -- NOTE: `at_edge = 'wrap'` is not supported on Kitty terminal
        -- multiplexer, as there is no way to determine layout via the CLI
        at_edge = 'wrap',
        -- Desired behavior when the current window is floating:
        -- 'previous' => Focus previous Vim window and perform action
        -- 'mux' => Always forward action to multiplexer
        float_win_behavior = 'previous',
        -- when moving cursor between splits left or right,
        -- place the cursor on the same row of the *screen*
        -- regardless of line numbers. False by default.
        -- Can be overridden via function parameter, see Usage.
        move_cursor_same_row = false,
        -- whether the cursor should follow the buffer when swapping
        -- buffers by default; it can also be controlled by passing
        -- `{ move_cursor = true }` or `{ move_cursor = false }`
        -- when calling the Lua function.
        cursor_follows_swapped_bufs = false,
        -- resize mode options
        resize_mode = {
          -- key to exit persistent resize mode
          quit_key = '<ESC>',
          -- keys to use for moving in resize mode
          -- in order of left, down, up' right
          resize_keys = { 'h', 'j', 'k', 'l' },
          -- set to true to silence the notifications
          -- when entering/exiting persistent resize mode
          silent = false,
          -- must be functions, they will be executed when
          -- entering or exiting the resize mode
          hooks = {
            on_enter = nil,
            on_leave = nil,
          },
        },
        -- ignore these autocmd events (via :h eventignore) while processing
        -- smart-splits.nvim computations, which involve visiting different
        -- buffers and windows. These events will be ignored during processing,
        -- and un-ignored on completed. This only applies to resize events,
        -- not cursor movement events.
        ignored_events = {
          'BufEnter',
          'WinEnter',
        },
        -- enable or disable a multiplexer integration;
        -- automatically determined, unless explicitly disabled or set,
        -- by checking the $TERM_PROGRAM environment variable,
        -- and the $KITTY_LISTEN_ON environment variable for Kitty.
        -- You can also set this value by setting `vim.g.smart_splits_multiplexer_integration`
        -- before the plugin is loaded (e.g. for lazy environments).
        multiplexer_integration = nil,
        -- disable multiplexer navigation if current multiplexer pane is zoomed
        -- this functionality is only supported on tmux and Wezterm due to kitty
        -- not having a way to check if a pane is zoomed
        disable_multiplexer_nav_when_zoomed = true,
        -- Supply a Kitty remote control password if needed,
        -- or you can also set vim.g.smart_splits_kitty_password
        -- see https://sw.kovidgoyal.get/kitty/conf/#opt-kitty.remote_control_password
        kitty_password = nil,
        -- default logging level, one of: 'trace'|'debug'|'info'|'warn'|'error'|'fatal'
        log_level = 'info',
      })

      vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left)
      vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down)
      vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up)
      vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right)
      -- moving between splits
      vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
      vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
      vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
      vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
      vim.keymap.set('n', '<C-\\>', require('smart-splits').move_cursor_previous)
      -- swapping buffers between windows
      vim.keymap.set('n', '<leader><leader>h', require('smart-splits').swap_buf_left)
      vim.keymap.set('n', '<leader><leader>j', require('smart-splits').swap_buf_down)
      vim.keymap.set('n', '<leader><leader>k', require('smart-splits').swap_buf_up)
      vim.keymap.set('n', '<leader><leader>l', require('smart-splits').swap_buf_right)
    end
  },
   -- ─────────────────────────────────────────────────────────────────────────────
  --  Advanced flash.nvim specification
  --  * full set of word / WORD and char motions (w/W b/B e/E ge/gE f/F t/T)
  --  * line-boundary & first-non-blank jumps
  --  * Treesitter, remote, toggle (kept)
  --  * buffer-wide URL / link cleaners
  -- ─────────────────────────────────────────────────────────────────────────────
  {
    "folke/flash.nvim",
    event = "VeryLazy",

    ---@type Flash.Config
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

    -- stylua: ignore
    keys = {
      ----------------------------------------------------------------------------
      -- basic Flash
      ----------------------------------------------------------------------------
      { "s", mode = { "n", "x", "o" },
        function() require("flash").jump() end,                         desc = "Flash" },
      { "S", mode = { "n", "x", "o" },
        function() require("flash").treesitter() end,                   desc = "Flash Treesitter" },

      ----------------------------------------------------------------------------
      -- character motions (f/F/t/T) — Flash “char” mode
      ----------------------------------------------------------------------------
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

      ----------------------------------------------------------------------------
      -- word / WORD motions (w/W b/B) ------------------------------------------
      ----------------------------------------------------------------------------
      { "w", mode = { "n", "x", "o" },
        function() require("flash").jump({ search = { mode = "search", forward = true,  wrap = false, max_length = 0 }, pattern = [[\<]],  label = { after = {0,0} } }) end,
        desc = "Flash → next word" },
    -- "W"  – next WORD start (first non-blank char after whitespace or SOL)
      { "W", mode = { "n", "x", "o" },
        function() require("flash").jump({
          search  = { mode = "search", forward = true, wrap = false, max_length = 0 },
          pattern = [[\%(^\|\s\)\zs\S]],
          label   = { after = { 0, 0 } },
        }) end, desc = "Flash → next WORD" },

      { "b", mode = { "n", "x", "o" },
        function() require("flash").jump({ search = { mode = "search", forward = false, wrap = false, max_length = 0 }, pattern = [[\<]],  label = { after = {0,0} } }) end,
        desc = "Flash ← previous word" },
      -- "B"  – previous WORD start
      { "B", mode = { "n", "x", "o" },
        function() require("flash").jump({
          search  = { mode = "search", forward = false, wrap = false, max_length = 0 },
          pattern = [[\%(^\|\s\)\zs\S]],
          label   = { after = { 0, 0 } },
        }) end, desc = "Flash ← previous WORD" },

      ----------------------------------------------------------------------------
      -- word-end motions (e/E ge/gE) -------------------------------------------
      ----------------------------------------------------------------------------
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

      ----------------------------------------------------------------------------
      -- line boundary / first non-blank ----------------------------------------
      ----------------------------------------------------------------------------
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
            pattern = [[\_$]],
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

      ----------------------------------------------------------------------------
      -- Treesitter / remote / toggle -------------------------------------------
      ----------------------------------------------------------------------------
      { "r",       mode = "o",       function() require("flash").remote()             end, desc = "Remote Flash" },
      { "R",       mode = { "o","x" },function() require("flash").treesitter_search() end, desc = "Treesitter search" },
      { "<C-s>",   mode = "c",       function() require("flash").toggle()             end, desc = "Toggle Flash search" },

      ----------------------------------------------------------------------------
      -- Misc / QoL  -------------------------------------------
      ----------------------------------------------------------------------------

      -- START WITH "INITIATE FLASH WITH WORD UNDER CURSOR" <- Implement using snippet from flash.nvim readme included above my config spec snippet

    },

    ----------------------------------------------------------------------
    -- extra setup (buffer-wide cleaners) --------------------------------
    ----------------------------------------------------------------------
    config = function(_, opts)
      require("flash").setup(opts)

      vim.api.nvim_create_user_command("StripUrl", function()
        -- remove bare URLs (http/https)
        vim.cmd([[silent %s#https\?://\S\+##ge]])
      end, { desc = "Remove all URLs from buffer" })

      vim.api.nvim_create_user_command("StripLinks", function()
        -- collapse Markdown and Norg links to plaintext label
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
        max_length = 15,
        -- transparent_bg_fallback_color = "#303030"
        hide_target_hack = true,
        lecacy_computing_symbols_support = true
      })
    end
  },
  --------------------------------------------------------------------------------
  -- Screenkey.nvim – custom settings -------------------------------------------
  --------------------------------------------------------------------------------
  -- NOTE: paste the whole block; no further edits required
  -- {
  --   "NStefan002/screenkey.nvim",
  --   lazy = false,
  --   version = "*",
  --   config = function()
  --     ---------------------------------------------------------------------------
  --     -- 1.  Window in TOP‑RIGHT corner (anchor = "NE") -------------------------
  --     ---------------------------------------------------------------------------
  --     local W = require("screenkey")
  --     W.setup({
  --       win_opts = {
  --         -- put the *north‑east* corner of the float at the very top‑right cell
  --         row      = 0,                         -- 0 == first editor row :contentReference[oaicite:0]{index=0}
  --         col      = vim.o.columns - 1,         -- right‑most screen column
  --         relative = "editor",
  --         anchor   = "NE",                      -- <‑‑ key bit ☝︎ :contentReference[oaicite:1]{index=1}
  --         width    = 100,
  --         height   = 1,
  --         border   = "single",
  --         title    = "Keyboard Input",
  --         title_pos= "center",
  --         style    = "minimal",
  --         focusable= false,
  --         noautocmd= false,
  --         zindex   = 60,                        -- keep it above most pop‑ups
  --       },
  --
  --       ------------------------------------------------------------------------
  --       -- 2.  Make every keypress trigger a redraw ----------------------------
  --       ------------------------------------------------------------------------
  --       -- Screenkey already intercepts <Esc>, <CR> … but some plugins feed
  --       -- input through low‑level APIs that never reach it.  By piggy‑backing
  --       -- on Neovim ≥ 0.10’s `vim.on_key()` we can refresh on *all* input
  --       -- (the callback fires *before* mappings are applied) :contentReference[oaicite:2]{index=2}
  --       ------------------------------------------------------------------------
  --       -- redrawing      = true,   -- (fictional option to remind ourselves)
  --       compress_after = 6,      -- disable time‑based compression entirely
  --       clear_after    = 10,     -- keep the previous behaviour
  --       group_mappings = true,   -- treat “gg”, “cc”, etc. as a single combo :contentReference[oaicite:3]{index=3}
  --       disable        = {
  --         filetypes = {},
  --         buftypes  = {},
  --         events    = false,
  --       },
  --     })
  --
  --     -- Force‑redraw hook
  --     local ns = vim.api.nvim_create_namespace("screenkey_force_redraw")
  --     vim.on_key(function()
  --       if W.is_active() then
  --         vim.schedule(W.redraw)                -- run outside low‑level input
  --       end
  --     end, ns)
  --
  --     --------------------------------------------------------------------------
  --     -- 3.  Keybinding: <leader><leader><leader> toggles Screenkey ------------
  --     --------------------------------------------------------------------------
  --     vim.keymap.set(
  --       "n",
  --       "<leader><leader><leader>K",
  --       W.toggle,
  --       { desc = "Toggle Screenkey" }           -- helpful for which‑key lists
  --     )
  --   end,
  -- },
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    config = function()
      require("markview.extras.checkboxes").setup({
        --- Default checkbox state(used when adding checkboxes).
        ---@type string
        default = "X",

        --- Changes how checkboxes are removed.
        ---@type
        ---| "disable" Disables the checkbox.
        ---| "checkbox" Removes the checkbox.
        ---| "list_item" Removes the list item markers too.
        remove_style = "disable",

        --- Various checkbox states.
        ---
        --- States are in sets to quickly change between them
        --- when there are a lot of states.
        ---@type string[][]
        states = {
          { " ", "/", "X" },
          { "<", ">" },
          { "?", "!", "*" },
          { '"' },
          { "l", "b", "i" },
          { "S", "I" },
          { "p", "c" },
          { "f", "k", "w" },
          { "u", "d" }
        }
      })
    end,
    -- For blink.cmp's completion
    -- source
    dependencies = {
      "saghen/blink.cmp"
    },
  },
  -- {
  --   "petertriho/nvim-scrollbar",
  --   config = function()
  --     local colors = require("tokyonight.colors").setup()
  --     require("scrollbar").setup({
  --       show = true,
  --       show_in_active_only = false,
  --       set_highlights = true,
  --       folds = 1000, -- handle folds, set to number to disable folds if no. of lines in buffer exceeds this
  --       max_lines = false, -- disables if no. of lines in buffer exceeds this
  --       hide_if_all_visible = true, -- Hides everything if all lines are visible
  --       throttle_ms = 100,
  --       handle = {
  --         text = " ",
  --         blend = 50, -- Integer between 0 and 100. 0 for fully opaque and 100 to full transparent. Defaults to 30.
  --         color = nil,
  --         color_nr = nil, -- cterm
  --         highlight = "CursorColumn",
  --         hide_if_all_visible = true, -- Hides handle if all lines are visible
  --       },
  --       marks = {
  --         Cursor = {
  --           text = "•",
  --           priority = 0,
  --           gui = nil,
  --           color = nil,
  --           cterm = nil,
  --           color_nr = nil, -- cterm
  --           highlight = "Normal",
  --         },
  --         Search = {
  --           text = { "-", "=" },
  --           priority = 1,
  --           gui = nil,
  --           color = colors.orange,
  --           cterm = nil,
  --           color_nr = nil, -- cterm
  --           highlight = "Search",
  --         },
  --         Error = {
  --           text = { "-", "=" },
  --           priority = 2,
  --           gui = nil,
  --           color = colors.error,
  --           cterm = nil,
  --           color_nr = nil, -- cterm
  --           highlight = "DiagnosticVirtualTextError",
  --         },
  --         Warn = {
  --           text = { "-", "=" },
  --           priority = 3,
  --           gui = nil,
  --           color = colors.warning,
  --           cterm = nil,
  --           color_nr = nil, -- cterm
  --           highlight = "DiagnosticVirtualTextWarn",
  --         },
  --         Info = {
  --           text = { "-", "=" },
  --           priority = 4,
  --           gui = nil,
  --           color = colors.info,
  --           cterm = nil,
  --           color_nr = nil, -- cterm
  --           highlight = "DiagnosticVirtualTextInfo",
  --         },
  --         Hint = {
  --           text = { "-", "=" },
  --           priority = 5,
  --           gui = nil,
  --           color = colors.hint,
  --           cterm = nil,
  --           color_nr = nil, -- cterm
  --           highlight = "DiagnosticVirtualTextHint",
  --         },
  --         Misc = {
  --           text = { "-", "=" },
  --           priority = 6,
  --           gui = nil,
  --           color = colors.purple,
  --           cterm = nil,
  --           color_nr = nil, -- cterm
  --           highlight = "Normal",
  --         },
  --         GitAdd = {
  --           text = "┆",
  --           priority = 7,
  --           gui = nil,
  --           color = nil,
  --           cterm = nil,
  --           color_nr = nil, -- cterm
  --           highlight = "GitSignsAdd",
  --         },
  --         GitChange = {
  --           text = "┆",
  --           priority = 7,
  --           gui = nil,
  --           color = nil,
  --           cterm = nil,
  --           color_nr = nil, -- cterm
  --           highlight = "GitSignsChange",
  --         },
  --         GitDelete = {
  --           text = "▁",
  --           priority = 7,
  --           gui = nil,
  --           color = nil,
  --           cterm = nil,
  --           color_nr = nil, -- cterm
  --           highlight = "GitSignsDelete",
  --         },
  --       },
  --       excluded_buftypes = {
  --         "terminal",
  --       },
  --       excluded_filetypes = {
  --         "dropbar_menu",
  --         "dropbar_menu_fzf",
  --         "DressingInput",
  --         "cmp_docs",
  --         "cmp_menu",
  --         "noice",
  --         "prompt",
  --         "TelescopePrompt",
  --       },
  --       autocmd = {
  --         render = {
  --           "BufWinEnter",
  --           "TabEnter",
  --           "TermEnter",
  --           "WinEnter",
  --           "CmdwinLeave",
  --           "TextChanged",
  --           "VimResized",
  --           "WinScrolled",
  --         },
  --         clear = {
  --           "BufWinLeave",
  --           "TabLeave",
  --           "TermLeave",
  --           "WinLeave",
  --         },
  --       },
  --       handlers = {
  --         cursor = true,
  --         diagnostic = true,
  --         gitsigns = false, -- Requires gitsigns
  --         handle = true,
  --         search = false, -- Requires hlslens
  --         ale = false, -- Requires ALE
  --       },
  --     })
  --   end
  -- },
  {
    "y3owk1n/undo-glow.nvim",
    event = { "VeryLazy" },
    ---@type UndoGlow.Config
    opts = {
      animation = {
        enabled = true,
        duration = 50,
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
          -- This is an implementation to preserve the cursor position
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

      -- This only handles neovim instance and do not highlight when switching panes in tmux
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

      -- This will handle highlights when focus gained, including switching panes in tmux
      vim.api.nvim_create_autocmd("FocusGained", {
        desc = "Highlight when focus gained",
        callback = function()
          ---@type UndoGlow.CommandOpts
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
      -- see below for more on custom conversions/functions
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
      -- add any custom options here
    }
  },
  -- {
  --   "hat0uma/csvview.nvim",
  --   ---@module "csvview"
  --   ---@type CsvView.Options
  --   opts = {
  --     parser = { comments = { "#", "//" } },
  --     keymaps = {
  --       -- Text objects for selecting fields
  --       textobject_field_inner = { "if", mode = { "o", "x" } },
  --       textobject_field_outer = { "af", mode = { "o", "x" } },
  --       -- Excel-like navigation:
  --       -- Use <Tab> and <S-Tab> to move horizontally between fields.
  --       -- Use <Enter> and <S-Enter> to move vertically between rows and place the cursor at the end of the field.
  --       -- Note: In terminals, you may need to enable CSI-u mode to use <S-Tab> and <S-Enter>.
  --       jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
  --       jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
  --       jump_next_row = { "<Enter>", mode = { "n", "v" } },
  --       jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
  --     },
  --   },
  --   cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
  -- },
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
  {
    "chrisbra/Recover.vim",
    event = "VeryLazy",  -- load on first file‑open
    init = function()
      -- optional: skip the standard prompt entirely and let the plugin handle it
      vim.opt.shortmess:append("A")
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
      -- ── existing options ─────────────────────────────────────────────
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

      -- ── ✨ new bit: route msg_showmode → nvim-notify ─────────────────
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
      ------------------------------------------------------------------
      -- 1. Core plugin settings (tweak to taste)
      ------------------------------------------------------------------
      require("neoclip").setup({
        history                = 1000,      -- keep 1 000 items in RAM
        enable_persistent_history = true,   -- save to sqlite
        continuous_sync        = false,     -- manual db_push/db_pull
        preview = true,                     -- show a preview pane
      })

      ------------------------------------------------------------------
      -- 2. Load the Telescope extension *once* and alias it locally
      ------------------------------------------------------------------
      local telescope = require("telescope")
      telescope.load_extension("neoclip")                 -- :contentReference[oaicite:2]{index=2}
      local clip = telescope.extensions.neoclip           -- exposes .default() .plus() .macro()

      ------------------------------------------------------------------
      -- 3. Key‑maps – all silent/non‑recursive with nice descriptions
      ------------------------------------------------------------------
      local map  = vim.keymap.set
      local opts = { noremap = true, silent = true }

      -- Yank history picker (unnamed/") – think “Fuzzy Yank”
      map({ "n", "v" }, "<leader>fy", clip.default, vim.tbl_extend("force", opts,
        { desc = "Neoclip • open yank history picker" }))

      -- System clipboard (+ register) only
      map({ "n", "v" }, "<leader>fY", clip.plus, vim.tbl_extend("force", opts,
        { desc = "Neoclip • +‑register history" }))

      -- Utility helpers that ship with neoclip
      map("n", "<leader>fc", require("neoclip").clear_history, vim.tbl_extend("force", opts, { desc = "Neoclip • clear history" }))        -- :contentReference[oaicite:4]{index=4}
      map("n", "<leader>fs", require("neoclip").db_push,       vim.tbl_extend("force", opts, { desc = "Neoclip • push DB → disk" }))       -- :contentReference[oaicite:5]{index=5}
      map("n", "<leader>fS", require("neoclip").db_pull,       vim.tbl_extend("force", opts, { desc = "Neoclip • pull DB ← disk" }))       -- :contentReference[oaicite:6]{index=6}
    end,
  },
  -- ── File-type Switcher (local plugin) ────────────────────────────────────
  {
    dir  = vim.fn.stdpath("config") .. "/lua/custom/filetype_switcher",
    name = "filetype-switcher.nvim",
    lazy = false,                                    -- load immediately
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function() require("custom.filetype_switcher") end,
  },
}
