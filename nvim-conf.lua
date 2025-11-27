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

vim.keymap.set('n', '<C-h>', '<C-w>h', {})
vim.keymap.set('n', '<C-j>', '<C-w>j', {})
vim.keymap.set('n', '<C-k>', '<C-w>k', {})
vim.keymap.set('n', '<C-l>', '<C-w>l', {})

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
-- Most configs pulled from https://github.com/neovim/nvim-lspconfig
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
vim.lsp.enable('ccls')

-- Nix
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
vim.lsp.enable('nix_ls')

Rust
local function reload_workspace(bufnr)
  local clients = vim.lsp.get_clients { bufnr = bufnr, name = 'rust_analyzer' }
  for _, client in ipairs(clients) do
    vim.notify 'Reloading Cargo Workspace'
    ---@diagnostic disable-next-line:param-type-mismatch
    client:request('rust-analyzer/reloadWorkspace', nil, function(err)
      if err then
        error(tostring(err))
      end
      vim.notify 'Cargo workspace reloaded'
    end, 0)
  end
end

local function is_library(fname)
  local user_home = vim.fs.normalize(vim.env.HOME)
  local cargo_home = os.getenv 'CARGO_HOME' or user_home .. '/.cargo'
  local registry = cargo_home .. '/registry/src'
  local git_registry = cargo_home .. '/git/checkouts'

  local rustup_home = os.getenv 'RUSTUP_HOME' or user_home .. '/.rustup'
  local toolchains = rustup_home .. '/toolchains'

  for _, item in ipairs { toolchains, registry, git_registry } do
    if vim.fs.relpath(item, fname) then
      local clients = vim.lsp.get_clients { name = 'rust_analyzer' }
      return #clients > 0 and clients[#clients].config.root_dir or nil
    end
  end
end

vim.lsp.config('rust-analyzer', {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local reused_dir = is_library(fname)
    if reused_dir then
      on_dir(reused_dir)
      return
    end

    local cargo_crate_dir = vim.fs.root(fname, { 'Cargo.toml' })
    local cargo_workspace_root

    if cargo_crate_dir == nil then
      on_dir(
        vim.fs.root(fname, { 'rust-project.json' })
          or vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
      )
      return
    end

    local cmd = {
      'cargo',
      'metadata',
      '--no-deps',
      '--format-version',
      '1',
      '--manifest-path',
      cargo_crate_dir .. '/Cargo.toml',
    }

    vim.system(cmd, { text = true }, function(output)
      if output.code == 0 then
        if output.stdout then
          local result = vim.json.decode(output.stdout)
          if result['workspace_root'] then
            cargo_workspace_root = vim.fs.normalize(result['workspace_root'])
          end
        end

        on_dir(cargo_workspace_root or cargo_crate_dir)
      else
        vim.schedule(function()
          vim.notify(('[rust_analyzer] cmd failed with code %d: %s\n%s'):format(output.code, cmd, output.stderr))
        end)
      end
    end)
  end,
  capabilities = {
    experimental = {
      serverStatusNotification = true,
      commands = {
        commands = {
          'rust-analyzer.showReferences',
          'rust-analyzer.runSingle',
          'rust-analyzer.debugSingle',
        },
      },
    },
  },
  before_init = function(init_params, config)
    -- See https://github.com/rust-lang/rust-analyzer/blob/eb5da56d839ae0a9e9f50774fa3eb78eb0964550/docs/dev/lsp-extensions.md?plain=1#L26
    if config.settings and config.settings['rust-analyzer'] then
      init_params.initializationOptions = config.settings['rust-analyzer']
    end
    ---@param command table{ title: string, command: string, arguments: any[] }
    vim.lsp.commands['rust-analyzer.runSingle'] = function(command)
      local r = command.arguments[1]
      local cmd = { 'cargo', unpack(r.args.cargoArgs) }
      if r.args.executableArgs and #r.args.executableArgs > 0 then
        vim.list_extend(cmd, { '--', unpack(r.args.executableArgs) })
      end

      local proc = vim.system(cmd, { cwd = r.args.cwd })

      local result = proc:wait()

      if result.code == 0 then
        vim.notify(result.stdout, vim.log.levels.INFO)
      else
        vim.notify(result.stderr, vim.log.levels.ERROR)
      end
    end
  end,
  on_attach = function(_, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspCargoReload', function()
      reload_workspace(bufnr)
    end, { desc = 'Reload current cargo workspace' })
  end,
})

vim.lsp.enable('rust-analyzer')

-- Lua
vim.lsp.config('lua_ls' ,{
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
        path ~= vim.fn.stdpath('config')
        and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
      then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using (most
        -- likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        -- Tell the language server how to find Lua modules same way as Neovim
        -- (see `:h lua-module-load`)
        path = {
          'lua/?.lua',
          'lua/?/init.lua',
        },
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME
          -- Depending on the usage, you might want to add additional paths
          -- here.
          -- '${3rd}/luv/library'
          -- '${3rd}/busted/library'
        }
        -- Or pull in all of 'runtimepath'.
        -- NOTE: this is a lot slower and will cause issues when working on
        -- your own configuration.
        -- See https://github.com/neovim/nvim-lspconfig/issues/3189
        -- library = {
        --   vim.api.nvim_get_runtime_file('', true),
        -- }
      }
    })
  end,
  settings = {
    Lua = {}
  }
})
vim.lsp.enable('lua_ls')
