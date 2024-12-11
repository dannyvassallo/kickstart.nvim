-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
--
local function augroup(name)
  return vim.api.nvim_create_augroup('mnv_' .. name, { clear = true })
end

-- See `:help vim.highlight.on_yank()`
-- local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
local highlight_group = augroup 'YankHighlight'
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  group = augroup 'checktime',
  command = 'checktime',
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Auto toggle hlsearch
local ns = vim.api.nvim_create_namespace 'toggle_hlsearch'
local function toggle_hlsearch(char)
  if vim.fn.mode() == 'n' then
    local keys = { '<CR>', 'n', 'N', '*', '#', '?', '/' }
    local new_hlsearch = vim.tbl_contains(keys, vim.fn.keytrans(char))

    if vim.opt.hlsearch:get() ~= new_hlsearch then
      vim.opt.hlsearch = new_hlsearch
    end
  end
end
vim.on_key(toggle_hlsearch, ns)

-- windows to close
vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    'OverseerForm',
    'OverseerList',
    'floggraph',
    'fugitive',
    'git',
    'help',
    'lspinfo',
    'man',
    'neotest-output',
    'neotest-summary',
    'oil',
    'qf',
    'query',
    'Scratch',
    'spectre_panel',
    'startuptime',
    'toggleterm',
    'tsplayground',
    'vim',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
  end,
})

vim.api.nvim_command 'autocmd VimResized * wincmd ='

-- ensure we always have a transparent background when we change themes :)
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    local highlights = {
      'Normal',
      'LineNr',
      'Folded',
      'NonText',
      'SpecialKey',
      'VertSplit',
      'SignColumn',
      'EndOfBuffer',
      'TablineFill', -- this is specific to how I like my tabline to look like
    }
    for _, name in pairs(highlights) do
      vim.cmd.highlight(name .. ' guibg=none ctermbg=none')
    end
  end,
})

--vim.api.nvim_create_autocmd('VimEnter', {
--callback = function()
-- vim.cmd("<cmd>Telescope diagnostics<cr>")
--vim.cmd "lua require('telescope.builtin').find_files()"
--end,
--})

-- allow for 2 space indenting for some files
local setIndent = augroup 'setIndent'
vim.api.nvim_create_autocmd('Filetype', {
  group = setIndent,
  pattern = { 'xml', 'html', 'xhtml', 'css', 'scss', 'javascript', 'typescript', 'jsx', 'tsx', 'typescriptreact', 'javascriptreact' },
  command = 'setlocal shiftwidth=2 tabstop=2',
})

-- no more annoying eol issues when comparing buffers
vim.api.nvim_create_autocmd({ 'FileType' }, {
  pattern = { 'json', 'yaml', 'txt', '.sarif' },
  command = 'setlocal noeol binary shiftwidth=2 tabstop=2 expandtab smartindent fileformats=mac,unix,dos',
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'LazyVimStarted',
  callback = function()
    vim.schedule(function()
      require('telescope.builtin').find_files()
    end)
  end,
})

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
