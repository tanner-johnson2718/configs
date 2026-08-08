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
vim.opt.scrolloff = 5
vim.opt.mouse = ""
vim.cmd("colorscheme onedark")

vim.g.clipboard = {
  name = 'OSC 52',
  copy = {
    ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
    ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
  },
  paste = {
    ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
    ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
  },
}

-- Search Word
vim.keymap.set('n', 'sw', 'yiw:Telescope live_grep<CR><Space><Esc><S-p><S-a><BS>', {})

-- Search String
vim.keymap.set('n', 'ss', ':Telescope live_grep<CR>', {})

-- Search Files
vim.keymap.set('n', 'sf', ':Telescope find_files<CR>', {})

-- Search Path
vim.keymap.set('n', 'sp', 'yiw:Telescope find_files<CR><Space><Esc><S-p><S-a><BS>', {})

-- Search Buffer
vim.keymap.set('n', 'sb', ':Telescope current_buffer_fuzzy_find<CR>', {})

-- Search word here
vim.keymap.set('n', 'sh', 'yiw:Telescope current_buffer_fuzzy_find<CR><Space><Esc><S-p><S-a><BS>', {})

-- Search jump list
vim.keymap.set('n', 'sj', ':Telescope jumplist<CR>', {})

-- Search Git
vim.keymap.set('n', 'sg', ':Telescope git_status<CR>', {})

-- Exit inset and term mode
vim.keymap.set('i', 'jj', '<Esc>:w<CR>', {})

-- C-s to save in normal mode
vim.keymap.set('n', '<C-s>', '<Esc>:w<CR>', {})

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
vim.keymap.set('t', 'jj', '<C-\\><C-n>', {})

-- Disable arrow keys in Normal, Visual, and Select modes
local modes = { 'n', 'i', 'v', 'c' }
local arrows = { '<Up>', '<Down>', '<Left>', '<Right>' }

for _, mode in ipairs(modes) do
    for _, arrow in ipairs(arrows) do
        vim.keymap.set(mode, arrow, '<Nop>', { noremap = true, silent = true })
    end
end

-- Screen Set Up
vim.api.nvim_create_user_command('Layout', function()
  local n_win = #vim.api.nvim_tabpage_list_wins(0)
  if n_win == 1 then
    vim.cmd('split')
    vim.cmd('wincmd j')
    vim.cmd('term')
    vim.cmd('resize 20')
    vim.cmd('wincmd k')
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

-- On cursor hold pop the error message on errored line
vim.cmd [[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]

vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
    callback = function()
        if vim.bo.buftype == 'terminal' then
            vim.cmd('startinsert')
        end
    end,
})

-- Completion
require("blink.cmp").setup({
    keymap = {
      preset = "enter",
      ["<Tab>"] = { "select_next", "fallback" },
      ["<S-Tab>"] = { "select_prev", "fallback" },
    },
  })
