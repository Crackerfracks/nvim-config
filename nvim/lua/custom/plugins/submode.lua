return {
  'pogyomo/submode.nvim',
  event = 'VeryLazy',
  dependencies = {
    'folke/flash.nvim',
  },
  config = function()
    local submode = require('submode')
    local remote = require('custom.remote_ops')

    local function leave()
      submode.leave()
      remote.cancel()
    end

    submode.create('InsertRemoteOps', {
      mode = 'i',
      show_mode = true,
      enter = '<Tab>',
      leave = { '<Esc>' },
      leave_when_mode_changed = true,
      register = function(register)
        register('<Esc>', leave)
        register('<Tab>', function()
          if not remote.finish_at_cursor() then
            leave()
          end
        end)
        register('<CR>', function()
          if not remote.finish_at_cursor() then
            leave()
          end
        end)
        register('p', function()
          remote.start_put('p', { from_insert = true })
        end)
        register('P', function()
          remote.start_put('P', { from_insert = true })
        end)
        register('y', remote.operator('y', { from_insert = true }))
        register('Y', remote.operator('y', { from_insert = true, register = '+' }))
        register('d', remote.operator('d', { from_insert = true }))
        register('c', remote.operator('c', { from_insert = true }))
        register('r', remote.execute_normal('r', { from_insert = true }))
        register('R', remote.execute_normal('R', { from_insert = true }))
        register('<leader>sa', remote.execute_normal('<leader>sar', { from_insert = true }))
        register('<leader>sd', remote.execute_normal('<leader>sdr', { from_insert = true }))
        register('<leader>sf', remote.execute_normal('<leader>sfr', { from_insert = true }))
        register('<leader>sF', remote.execute_normal('<leader>sFr', { from_insert = true }))
        register('<leader>sh', remote.execute_normal('<leader>shr', { from_insert = true }))
        register('<leader>sr', remote.execute_normal('<leader>srr', { from_insert = true }))
      end,
    })

    submode.create('WordMotionRestore', {
      mode = 'n',
      show_mode = true,
      enter = '<Tab>',
      leave = { '<Esc>' },
      leave_when_mode_changed = true,
      register = function(register)
        register('<Tab>', leave)
        register('w', 'w')
        register('W', 'W')
        register('e', 'e')
        register('E', 'E')
        register('b', 'b')
        register('B', 'B')
      end,
    })
  end,
}
