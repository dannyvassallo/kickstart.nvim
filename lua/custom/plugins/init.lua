-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
--
return {
  -- Add Dracula theme
  { 'Mofiqul/dracula.nvim' },

  -- Configure LazyVim to load Dracula
  {
    'LazyVim/LazyVim',
    opts = {
      colorscheme = 'dracula',
    },
  },

  -- Add snacks.nvim
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      notifier = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
  },

  -- Add nvim-tree
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false, -- Load immediately on startup
    config = function()
      require('nvim-tree').setup {
        view = {
          width = 30,
          side = 'left',
        },
        renderer = {
          icons = {
            show = {
              file = true,
              folder = true,
              folder_arrow = true,
              git = true,
            },
          },
        },
        diagnostics = {
          enable = true,
        },
        git = {
          enable = true,
        },
        update_focused_file = {
          enable = true,
          update_cwd = true,
        },
      }

      -- Automatically open the file tree when starting Neovim
      local function open_nvim_tree()
        -- Check if the buffer is empty (no file opened yet)
        local bufnr = vim.api.nvim_get_current_buf()
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname == '' then
          require('nvim-tree.api').tree.open()
        end
      end

      vim.api.nvim_create_autocmd({ 'VimEnter' }, { callback = open_nvim_tree })
    end,
  },

  -- Optional: Disable Neo-tree if used by LazyVim
  {
    'nvim-neo-tree/neo-tree.nvim',
    enabled = false,
  },

  -- Add null-ls for linting and formatting
  {
    'jose-elias-alvarez/null-ls.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    lazy = false,
    config = function()
      local null_ls = require 'null-ls'
      null_ls.setup {
        sources = {
          null_ls.builtins.formatting.prettier,
          null_ls.builtins.diagnostics.eslint,
          null_ls.builtins.code_actions.eslint,
        },
      }
    end,
  },

  -- Add Treesitter for syntax highlighting and bracket colorization
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup {
        highlight = {
          enable = true,
        },
        rainbow = {
          enable = true,
          extended_mode = true,
        },
      }
    end,
  },

  -- YAML language server for schema validation
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    config = function()
      require('lspconfig').yamlls.setup {
        settings = {
          yaml = {
            schemas = {
              ['file:///path/to/schema.json'] = '**/definition.yaml',
            },
          },
        },
      }
    end,
  },
}
