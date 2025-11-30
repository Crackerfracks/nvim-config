return {
  'bullets-vim/bullets.vim',
  lazy = false,
  config = function()
    vim.g.loaded_bullets = 1
    vim.g.bullets_enable_in_empty_buffers = 1
    vim.g.bullets_checkbox_markers = ' ?-X'
  end,
}
