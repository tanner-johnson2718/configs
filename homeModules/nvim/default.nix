{pkgs, config, lib, ...}:
let
  cfg = config.nvim;
in
{
  options = {
    nvim.enable = lib.mkEnableOption "Enable nvim module";
    nvim.extraConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    nvim.extraLuaConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    nvim.extraPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.pkgs;
      default = [];
    };
  };

  config = lib.mkIf cfg.enable{	  
    home.packages = with pkgs; [
      nil
      ccls
    ];

    programs.neovim = {
      enable       = true;
      viAlias      = true;
      vimAlias	 = true;
      vimdiffAlias = true;

      coc.enable = true;
      coc.settings = {
	languageserver = {
	  nix = {
	    command = "nil";
	    filetypes = [ "nix" ];
	    rootPatterns = [ "flake.nix" ];
	  };
	ccls =  {
	  command = "ccls";
	  filetypes = ["c"  "cc"  "cpp"  "c++"  "objc"  "objcpp"];
	  rootPatterns = [".ccls"  "compile_commands.json" ".git/" ".hg/"];
	};
      };
    };

      extraConfig = ''
	set autoindent
	set shiftwidth=2
	set softtabstop=2
	set number
	set nowrap
	set spell
	set ve=block

	nnoremap ff :Telescope find_files<CR>
	nnoremap fb :Telescope buffers<CR>
	nnoremap fn :bNext<CR>
	nnoremap fm :bprevious<CR>
	nnoremap fs :Telescope live_grep<CR>
	nnoremap fc :bd<CR>
	nnoremap fd :Gdiffsplit<CR>
	nnoremap mp :MarkdownPreview<CR>
	nnoremap <C-PageUp> :bprevious<CR>
	nnoremap <C-PageDown> :bNext<CR>

	vnoremap f :VBox<CR>
      '' + cfg.extraConfig;
      extraLuaConfig = ''
	local c = require('vscode.colors').get_colors()
	require('vscode').setup({
	    -- Alternatively set style in setup
	    -- style = 'light'

	    -- Enable transparent background 
	    transparent = true,

	    -- Enable italic comment
	    italic_comments = true,

	    -- Underline `@markup.link.*` variants
	    underline_links = true,

	    -- Disable nvim-tree background color
	    disable_nvimtree_bg = true,

	    -- Override colors (see ./lua/vscode/colors.lua)
	    color_overrides = {
		vscLineNumber = '#FFFFFF',
	    },

	    -- Override highlight groups (see ./lua/vscode/theme.lua)
	    group_overrides = {
		-- this supports the same val table as vim.api.nvim_set_hl
		-- use colors from this colorscheme by requiring vscode.colors!
	    }
	  })
	  -- require('vscode').load()

	  -- load the theme without affecting devicon colors.
	  vim.cmd.colorscheme "vscode"
	  vim.opt.clipboard = "unnamedplus"

	  require'nvim-treesitter.configs'.setup {
	    highlight = {
	      enable = true,
	    }
	  }
	'' + cfg.extraLuaConfig;

      plugins = 
      let
	addPlugIn = (name: { plugin = pkgs.vimPlugins."${name}"; });
      in
      [
	(addPlugIn "vscode-nvim")
	(addPlugIn "telescope-nvim")
	(addPlugIn "git-blame-nvim")
	(addPlugIn "vim-fugitive")
	(addPlugIn "render-markdown-nvim")
	(addPlugIn "markdown-preview-nvim")
	(addPlugIn "venn-nvim")
	pkgs.vimPlugins.nvim-treesitter.withAllGrammars
      ] ++ cfg.extraPlugins;
    };
  };
}
