return {
  'pogyomo/submode.nvim',
  event = 'VeryLazy',
  config = function()
    local submode = require('submode')
    local remote = require('custom.remote_ops')

    local function leave_and(fn)
      return function()
        submode.leave()
        fn()
      end
    end

    local function trigger(event, data)
      vim.api.nvim_exec_autocmds('User', { pattern = event, data = data or {} })
    end

    local function create_insert_remote()
      submode.create('InsertRemoteOps', {
        mode = 'i',
        enter = '<Tab>',
        leave = { '<Esc>', '<Tab>', '<CR>' },
        leave_when_mode_changed = true,
        hook = {
          on_enter = function()
            trigger('InsertRemoteOpsEnter')
          end,
          on_leave = function()
            trigger('InsertRemoteOpsLeave')
          end,
        },
        default = function(register)
          register('p', leave_and(remote.start_put_after))
          register('P', leave_and(remote.start_put_before))
          register('y', leave_and(remote.start_yank))
          register('d', leave_and(remote.start_delete))
          register('c', leave_and(remote.start_change))
          register('r', leave_and(remote.start_replace))
          register('R', leave_and(remote.start_replace_mode))

          register('<leader>sa', leave_and(remote.start_surround_a))
          register('<leader>sd', leave_and(remote.start_surround_d))
          register('<leader>sf', leave_and(remote.start_surround_f))
          register('<leader>sF', leave_and(remote.start_surround_F))
          register('<leader>sh', leave_and(remote.start_surround_h))
          register('<leader>sr', leave_and(remote.start_surround_r))
        end,
      })
    end

    local word_guard_ns = vim.api.nvim_create_namespace('submode-word-motion-guard')
    local allowed = {
      w = true,
      W = true,
      e = true,
      E = true,
      b = true,
      B = true,
    }
    local guard_active = false

    local function attach_guard()
      if guard_active then
        return
      end
      guard_active = true
      vim.on_key(function(char)
        if submode.mode() ~= 'WordMotionRestore' then
          return
        end
        local key = vim.fn.keytrans(char)
        if not allowed[key] then
          submode.leave()
        end
      end, word_guard_ns)
    end

    local function detach_guard()
      if not guard_active then
        return
      end
      guard_active = false
      vim.on_key(nil, word_guard_ns)
    end

    local function feed_normal(keys)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'n', false)
    end

    local function create_word_restore()
      submode.create('WordMotionRestore', {
        mode = 'n',
        enter = '<Tab>',
        leave = { '<Esc>', '<Tab>' },
        leave_when_mode_changed = true,
        hook = {
          on_enter = function()
            attach_guard()
            trigger('WordMotionRestoreEnter')
          end,
          on_leave = function()
            detach_guard()
            trigger('WordMotionRestoreLeave')
          end,
        },
        default = function(register)
          local function passthrough(key)
            register(key, function()
              feed_normal(key)
            end)
          end

          passthrough('w')
          passthrough('W')
          passthrough('e')
          passthrough('E')
          passthrough('b')
          passthrough('B')
          register('<Tab>', function()
            submode.leave()
          end)
        end,
      })
    end

    create_insert_remote()
    create_word_restore()
  end,
}
