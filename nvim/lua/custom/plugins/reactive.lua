return {
  'rasulomaroff/reactive.nvim',
  opts = {
    builtin = {
      cursorline = false,
      cursor = false,
      modemsg = true,
    },
    configs = {
      submodes = {
        modes = {
          InsertRemoteOps = {
            hl = {
              ModeMsg = { link = 'WarningMsg' },
            },
          },
          WordMotionRestore = {
            hl = {
              ModeMsg = { link = 'Question' },
            },
          },
        },
      },
    },
  },
}
