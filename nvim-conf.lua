 -- Vim opts
vim.opt.autoindent = true
vim.opt.shiftwidth=2
vim.opt.softtabstop=2
vim.opt.tabstop=2
vim.wo.number = true
vim.wo.relativenumber = true
vim.opt.wrap = false
vim.opt.spell = true
vim.opt.ve= 'block'
vim.opt.expandtab = true
vim.opt.list = true
vim.opt.clipboard='unnamedplus'
vim.cmd("colorscheme onedark")

-- Mostly Telescope Keybindings
vim.keymap.set('n', 'ff', ':Telescope find_files<CR>', {})
vim.keymap.set('n', 'fb', ':Telescope buffers<CR>', {})
vim.keymap.set('n', 'fs', ':Telescope live_grep<CR>', {})
vim.keymap.set('n', 'fS', ':Telescope current_buffer_fuzzy_find<CR>', {})
vim.keymap.set('n', 'fj', ':Telescope jumplist<CR>', {})
vim.keymap.set('n', 'fg', ':Telescope git_status<CR>', {})
vim.keymap.set('n', 'fw', 'yiw:Telescope live_grep<CR><Space><Esc><S-p><S-a><BS>', {})
vim.keymap.set('n', 'fW', 'yiw:Telescope find_files<CR><Space><Esc><S-p><S-a><BS>', {})
vim.keymap.set('n', '<C-s>', '<Esc>:w<CR>', {})
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>', {})

-- Make changing windows better
vim.keymap.set('n', '<C-h>', '<C-w>h', {})
vim.keymap.set('n', '<C-j>', '<C-w>j', {})
vim.keymap.set('n', '<C-k>', '<C-w>k', {})
vim.keymap.set('n', '<C-l>', '<C-w>l', {})
vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-w>h', {})
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-w>j', {})
vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-w>k', {})
vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', {})
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', {})

-- Screen Set Up
vim.api.nvim_create_user_command('Layout', function()
  local n_win = #vim.api.nvim_tabpage_list_wins(0)
  if n_win == 1 then
    vim.cmd('split')
    vim.cmd('vsplit')
    vim.cmd('wincmd j')
    vim.cmd('term')
    vim.cmd('vsplit')
    vim.cmd('wincmd l')
    vim.cmd('term')
    vim.cmd('resize 20')
  else
    print("Only use with single window open!")
  end
end ,{})

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

vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
    callback = function()
        if vim.bo.buftype == 'terminal' then
            vim.cmd('startinsert')
        end
    end,
})
