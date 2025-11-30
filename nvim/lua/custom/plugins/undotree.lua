return {
  'mbbill/undotree',
  lazy = false,
  vim.keymap.set('n', '<leader><F5>', '<CMD>UndotreeToggle<CR>', { noremap = true, nowait = true, desc = 'Toggle Undotree' }),
  -- keys = require('mappings').undotree,
  config = function()
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.loaded_undotree = 1
    vim.api.nvim_create_autocmd('Filetype', {
      group = vim.api.nvim_create_augroup('UndotreeMappings', { clear = true }),
      pattern = 'undotree',
      callback = function()
        vim.keymap.set('n', '<up>', '<plug>UndotreeNextState', { buffer = 0, noremap = true, silent = true, nowait = true, desc = 'Undo -> State' })
        vim.keymap.set('n', '<down>', '<plug>UndotreePreviousState', { buffer = 0, noremap = true, silent = true, nowait = true, desc = 'Undo <- State' })
        vim.keymap.set('n', '<left>', '<plug>UndotreeNextSavedState', { buffer = 0, noremap = true, silent = true, nowait = true, desc = 'Undo -> SAVED' })
        vim.keymap.set('n', '<right>', '<plug>UndotreePreviousSavedState', { buffer = 0, noremap = true, silent = true, nowait = true, desc = 'Undo <- SAVED' })
        vim.keymap.set('n', '<c-c>', '<plug>UndotreeClose', { buffer = 0, noremap = true, silent = true, nowait = true, desc = 'Close Undotree' })
      end,
    })
  end,
}
