-- ─────────────────────────────────────────────────────────────────────────────
--  Advanced flash.nvim specification
--  * full set of word / WORD and char motions (w/W b/B e/E ge/gE f/F t/T)
--  * line-boundary & first-non-blank jumps
--  * Treesitter, remote, toggle (kept)
--  * buffer-wide URL / link cleaners
-- ─────────────────────────────────────────────────────────────────────────────
return {
  'folke/flash.nvim',
  lazy = false,
  -- event = 'VeryLazy',

  ---@type Flash.Config
  opts = {
    labels = 'abcdefghijklmnopqrstuvwxyz',
    mode = {
      search = {
        enabled = true,
      },
    },
    search = {
      multi_window = true,
      forward = true,
      mode = 'exact',
    },
    jump = {
      offset = 0,
    },
    label = {
      rainbow = {
        enabled = true,
        shade = 4,
      },
    },
    remote_op = {
      restore = true,
      motion = true,
    },
    modes = {
      remote = {
        jump = {
          autojump = false,
        },
        label = {
          autojump = false,
        },
        remote_op = {
          restore = true,
          motion = true,
        },
      },
    },
  },
  -- stylua: ignore
  keys = {
    ----------------------------------------------------------------------------
    -- basic Flash
    ----------------------------------------------------------------------------
    {
      "s",
      mode = {
        "n",
        "x",
        "o",
      },
      function()
        require("flash").jump()
      end,
      desc = "Flash"
    },
    {
      "S",
      mode = {
        "n",
        "x",
        "o",
      },
      function()
        require("flash").treesitter()
      end,
      desc = "Flash Treesitter"
    },

    -- {
    --   "<tab>",
    --   mode = {
    --     "n",
    --   },
    --   function() -- <-- Why are some functions defined as variables, some are given names as an actual function, and still others like this are passed raw?
    --     local Flash = require("flash")
    --
    --     ---@param opts Flash.Format
    --     local function format(opts)
    --       -- always show first and second label
    --       return {
    --         { opts.match.label1, "FlashMatch" },
    --         { opts.match.label2, "FlashLabel" },
    --       }
    --     end
    --
    --     Flash.jump({
    --       search = { mode = "search" },
    --       label = { after = false, before = { 0, 0 }, uppercase = false, format = format },
    --       pattern = [[\<]],
    --       action = function(match, state)
    --         state:hide()
    --         Flash.jump({
    --           search = { max_length = 0 },
    --           highlight = { matches = false },
    --           label = { format = format },
    --           matcher = function(win)
    --             -- limit matches to the current label
    --             return vim.tbl_filter(function(m)
    --               return m.label == match.label and m.win == win
    --             end, state.results)
    --           end,
    --           labeler = function(matches)
    --             for _, m in ipairs(matches) do
    --               m.label = m.label2 -- use the second label
    --             end
    --           end,
    --         })
    --       end,
    --       labeler = function(matches, state)
    --         local labels = state:labels()
    --         for m, match in ipairs(matches) do
    --           match.label1 = labels[math.floor((m - 1) / #labels) + 1]
    --           match.label2 = labels[(m - 1) % #labels + 1]
    --           match.label = match.label1
    --         end
    --       end,
    --     })
    --   end
    -- },

    ----------------------------------------------------------------------------
    -- character motions (f/F/t/T) — Flash “char” mode
    ----------------------------------------------------------------------------
    {
      "f",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          mode = "char",
          search = {
            forward = true
          }
        })
      end,
      desc = "Flash f"
    },
    {
      "F",
      mode = {
        "n",
        "x",
        "o",
      },
      function()
        require("flash").jump({
          mode = "char",
          search = {
            forward = false
          }
        })
      end,
      desc = "Flash F"
    },
    {
      "t",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          mode = "char",
          search = {
            forward = true,
          },
          jump = {
            offset = -1
          }
        })
      end,
      desc = "Flash t"
    },
    {
      "T",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          mode = "char",
          search = {
            forward = false
          },
          jump = {
            offset = 1
          }
        })
      end,
      desc = "Flash T"
    },
    ----------------------------------------------------------------------------
    -- word / WORD motions (w/W b/B) ------------------------------------------
    ----------------------------------------------------------------------------
   
    {
      "w",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          search = {
            mode = "search",
            forward = true,
            wrap = false,
            max_length = 0
          },
          pattern = [[\<]],
          label = {
            after = {
              0,
              1
            }
          }
        })
      end,
      desc = "Flash → next word"
    },
    -- "W"  – next WORD start (first non-blank char after whitespace or SOL)
    {
      "W",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          search  = {
            mode = "search",
            forward = true,
            wrap = false,
            max_length = 0
          },
          pattern = [[\%(^\|\s\)\zs\S]],
          label   = {
            after = {
              0,
              0
            }
          },
        })
      end,
      desc = "Flash → next WORD"
    },
    {
      "b",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          search = {
            mode = "search",
            forward = false,
            wrap = false,
            max_length = 0
          },
          pattern = [[\<\zs]],
          label = {
            offset = -1,
            after = {
              0,
              1
            }
          },
        })
      end,
      desc = "Flash ← previous word"
    },
    -- "B"  – previous WORD start
    {
      "B",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          search  = {
            mode = "search",
            forward = false,
            wrap = false,
            max_length = 0
          },
          pattern = [[\%(^\|\s\)\zs\S]],
          label   = {
            after = {
              0,
              0
            }
          },
        })
      end,
      desc = "Flash ← previous WORD"
    },
    ----------------------------------------------------------------------------
    -- word-end motions (e/E ge/gE) -------------------------------------------
    --- > [!IMPORTANT] Apparently all bindings involving 
    ----------------------------------------------------------------------------
    {
      "e",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          search = {
            mode = "search",
            forward = true,
            wrap = false,
            max_length = 0
          },
          pattern = [[\>]],
          label = {
            after = {
              0,
              0
            }
          },
          jump = {
            offset = -1
          }
        })
      end,
      desc = "Flash → word end"
    },
    {
      "E",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          search = {
            mode = "search",
            forward = true,
            wrap = false,
            max_length = 0
          },
          pattern = [[\S\zs\s\|\S$]],
          label = {
            after = {
              0,
              0
            }
          }
        })
      end,
      desc = "Flash → WORD end"
    },
    {
      "ge",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          search = {
            mode = "search",
            forward = false,
            wrap = false,
            max_length = 0
          },
          pattern = [[\>]],
          label = {
            after = {
              0,
              0
            }
          },
          jump = {
            offset = -1
          }
        })
      end,
      desc = "Flash ← word end"
    },
    {
      "gE",
      mode = {
        "n",
        "x",
        "o"
      },
      function()
        require("flash").jump({
          search = {
            mode = "search",
            forward = false,
            wrap = false,
            max_length = 0
          },
          pattern = [[\S\zs\s\|\S$]],
          label = {
            after =
            { 0,
              0
            }
          }
        })
      end,
      desc = "Flash ← WORD end"
    },
    ----------------------------------------------------------------------------
    -- line boundary / first non-blank ----------------------------------------
    ----------------------------------------------------------------------------
    {
      "-",
      mode = {
        "n",
        "x",
        "o"
      },   -- line start
      function()
        require("flash").jump({
          search  = {
            mode = "search",
            max_length = 0
          },
          label   = {
            after = {
              0,
              0
            }
          },
          pattern = [[^]],
        })
      end,
      desc = "Jump to line beginning"
    },
    {
      "$",
      mode = {
        "n",
        "x",
        "o"
      },   -- line end (exclusive)
      function()
        require("flash").jump({
          search  = {
            mode = "search",
            max_length = 0
          },
          label   = {
            after = {
              0,
              1 }
          },
          pattern = [[\_$]],
          jump    = {
            offset = -1
          },
        })
      end,
      desc = "Jump to line end (exclusive)"
    },
    {
      "_",
      mode = {
        "n",
        "x",
        "o"
      },   -- first non-blank
      function()
        require("flash").jump(
          {
            search  = {
              mode = "search",
              max_length = 0
            },
            label   = {
              after = {
                0,
                0
              }
            },
            pattern = [[^\s*\zs\S]],
          }
        )
      end,
      desc = "Jump to first non-blank"
    },

    ----------------------------------------------------------------------------
    -- Treesitter / remote / toggle -------------------------------------------
    ----------------------------------------------------------------------------
    {
      "r",
      mode = "o",
      function()
        require("flash").remote()
      end,
      desc = "Remote Flash"
    },
    {
      "R",
      mode = {
        "o",
        "x"
      },
      function()
        require("flash").treesitter_search()
      end,
      desc = "Treesitter search"
    },
    {
      "<C-s>",
      mode = "c",
      function()
        require("flash").toggle()
      end,
      desc = "Toggle Flash search"
    },
    ----------------------------------------------------------------------------
    -- Misc / QoL  -------------------------------------------
    ----------------------------------------------------------------------------
    --- Your current magnum opus lol - Recursively target brace delimited content with vim search pattern.
    --- ```vim-regex
    --- \v-{,1}\zs(([{])|(\[)|([(]))\s{0,}\n{0,}(^{0,}-@!.{2,},{0,}\n{0,}){0,}\s{0,}(([)])|(\])|([}]))\ze
    -- ```
    {
      "*",
      mode = {
        "n",
        "x",
        "o"
      },   -- line end (exclusive)
      function()
        require("flash").jump({
          search  = {
            mode = "search",
            max_length = 0
          },
          label   = {
            after = {
              0,
              0
            }
          },
          pattern = vim.fn.expand("<cword>"),
        })
      end,
      desc = "Jump to word under cursor"
    },
    {
      "(",
      mode = {
        "n",
        "x",
        "o"
      },   -- line end (exclusive)
      function()
        require("flash").jump(
          {
            search  = {
              mode = "search",
              max_length = 0
            },
            label   = {
              after = {
                0,
                0
              }
            },
            pattern = [[\v-{,1}(([{])|(\[)|([(]))\ze\s{0,}\n{0,}(^{0,}-@!.{2,},{0,}\n{0,}){0,}\s{0,}(([)])|(\])|([}]))]],
          }
        )
      end,
      desc = "Jump to open bracket of delimited content (recursive)"
    },
    {
      ")",
      mode = {
        "n",
        "x",
        "o"
      },   -- line end (exclusive)
      function()
        require("flash").jump(
          {
            search  = {
              mode = "search",
              max_length = 0
            },
            label   = {
              after = {
                0,
                0
              }
            },
            pattern =
            [[\v((\s{0,}([{]+|[(]+)+((\n=<\W{0,}\w+\W{0,}>\n=)+\s{1,})+([)]{0,}|[}]{0,}){1,},\n))*([)]{1,}|[}]{1,})]],
            -- pattern = [[\v(\(|\[|\{)(^=.{2,},{0,}\n{0,}){0,}\s{0,}(\}|\]|\))\ze]],
          }
        )
      end,
      desc = "Jump to Closing bracket of delimited content (recursive)"
    },
    -- START WITH "INITIATE FLASH WITH WORD UNDER CURSOR" <- Implement using snippet from flash.nvim readme included above my config spec snippet
  },
}
