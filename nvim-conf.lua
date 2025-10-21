 -- Vim opts
vim.opt.autoindent = true
vim.opt.shiftwidth=2
vim.opt.softtabstop=2
vim.opt.tabstop=2
vim.wo.number = true
vim.wo.relativenumber = true
vim.opt.wrap = false
vim.opt.spell = true
vim.opt.ve=block
vim.opt.expandtab = true
vim.opt.list = true
vim.opt.clipboard='unnamedplus'
vim.cmd("colorscheme onedark")

-- Mostly Telescope/Buffer Keybindings
vim.keymap.set('n', 'ff', ':Telescope find_files<CR>', {})
vim.keymap.set('n', 'fb', ':Telescope buffers<CR>', {})
vim.keymap.set('n', 'fn', ':bNext<CR>', {})
vim.keymap.set('n', 'fm', ':bprevious<CR>', {})
vim.keymap.set('n', 'fs', ':Telescope live_grep<CR>', {})
vim.keymap.set('n', 'fS', ':Telescope current_buffer_fuzzy_find<CR>', {})
vim.keymap.set('n', 'fc', ':Bwipeout<CR>', {})
vim.keymap.set('n', 'fj', ':Telescope jumplist<CR>', {})
vim.keymap.set('n', 'fg', ':Telescope git_status<CR>', {})
vim.keymap.set('n', '<C-s>', '<Esc>:w<CR>', {})
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>', {})

-- Tree sitter highlighting
require'nvim-treesitter.configs'.setup {
  highlight = {
    enable = true,
  }
}
-- 250ms to trigger autocommands
vim.o.updatetime = 250

-- No virtual i.e. off to the right text and underline settings
vim.diagnostic.config({
  underline = {
    severity = { min = vim.diagnostic.severity.WARN }
  },
  virtual_text = false,
})

-- Set the icon in the gutter when LSP errors are present
vim.fn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })

-- On cursor hold pop the error message on errored line
vim.cmd [[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]

-- All lsps inherit
-- Run :checkhealth
vim.lsp.config('*', {
  autostart = true,
  single_file_support = true
})

-- C/C++
vim.lsp.config('ccls', {
  cmd = {'ccls'},
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = { "compile_commands.json", ".ccls", ".git" },
  offset_encoding = "utf-32",
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspCclsSwitchSourceHeader', function()
      switch_source_header(client, bufnr)
    end, { desc = 'Switch between source/header' })
  end
})

-- Nix
vim.lsp.enable('ccls')
vim.lsp.config('nil_ls', {})
vim.lsp.enable('nil_ls')
vim.lsp.config('rust-analyzer', {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = {"Cargo.toml", ".git"},
  settings = {
    ['rust-analyzer'] = {
      diagnostics = {
        enable = false;
      }
    }
  }
})
vim.lsp.enable('rust-analyzer')
