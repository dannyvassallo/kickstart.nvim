-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- Indent with Cmd+]
vim.keymap.set('v', '<D-]>', '>gv', { noremap = true, silent = true })

-- Outdent with Cmd+[
vim.keymap.set('v', '<D-[>', '<gv', { noremap = true, silent = true })

--
--
-- auto commands
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

-- Utils
local M = {}

function M.EqualizeSplits()
  vim.cmd 'wincmd =' -- Equalize the size of all windows
end

function M.SmartDelete()
  if vim.fn.getline '.' == '' then
    return '"_dd'
  end
  return 'dd'
end

-- ty @ https://github.com/adibhanna/nvim/blob/main/lua/config/utils.lua
function M.CopyFilePathAndLineNumber()
  local current_file = vim.fn.expand '%:p'
  local current_line = vim.fn.line '.'
  local is_git_repo = vim.fn.system('git rev-parse --is-inside-work-tree'):match 'true'

  if is_git_repo then
    local current_repo = vim.fn.systemlist('git remote get-url origin')[1]
    local current_branch = vim.fn.systemlist('git rev-parse --abbrev-ref HEAD')[1]

    -- Convert Git URL to GitHub web URL format
    current_repo = current_repo:gsub('git@github.com:', 'https://github.com/')
    current_repo = current_repo:gsub('%.git$', '')

    -- Remove leading system path to repository root
    local repo_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
    if repo_root then
      current_file = current_file:sub(#repo_root + 2)
    end

    local url = string.format('%s/blob/%s/%s#L%s', current_repo, current_branch, current_file, current_line)
    vim.fn.setreg('+', url)
    print('Copied to clipboard: ' .. url)
  else
    -- If not in a Git directory, copy the full file path
    vim.fn.setreg('+', current_file .. '#L' .. current_line)
    print('Copied full path to clipboard: ' .. current_file .. '#L' .. current_line)
  end
end

-- Lazyvim config

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
  --{
  --'nvim-neo-tree/neo-tree.nvim',
  --enabled = false,
  --},

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

  { 'mg979/vim-visual-multi' },
  --

  {
    'https://git.sr.ht/~swaits/zellij-nav.nvim',
    lazy = true,
    event = 'VeryLazy',
    keys = {
      { '<c-h>', '<cmd>ZellijNavigateLeftTab<cr>', { silent = true, desc = 'navigate left or tab' } },
      { '<c-j>', '<cmd>ZellijNavigateDown<cr>', { silent = true, desc = 'navigate down' } },
      { '<c-k>', '<cmd>ZellijNavigateUp<cr>', { silent = true, desc = 'navigate up' } },
      { '<c-l>', '<cmd>ZellijNavigateRightTab<cr>', { silent = true, desc = 'navigate right or tab' } },
    },
    opts = {},
  },

  {
    'numToStr/Comment.nvim',
    opts = {},
    keys = {
      -- Add this line to map Cmd+/ for both normal and visual modes
      { '<D-/>', mode = { 'n', 'v' }, desc = 'Comment toggle' },
    },
    config = function(_, opts)
      require('Comment').setup(opts)

      local api = require 'Comment.api'

      vim.keymap.set('n', '<D-/>', api.toggle.linewise.current, { desc = 'Comment toggle current line' })
      vim.keymap.set('x', '<D-/>', function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'nx', false)
        api.toggle.linewise(vim.fn.visualmode())
      end, { desc = 'Comment toggle linewise (visual)' })
    end,
  },

  -- LSP Configuration for TypeScript
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      'jose-elias-alvarez/typescript.nvim', -- TypeScript utilities
    },
    config = function()
      require('lspconfig').tsserver.setup {
        on_attach = function(client, bufnr)
          local bufmap = function(keys, func)
            vim.keymap.set('n', keys, func, { buffer = bufnr })
          end
          bufmap('<leader>co', ':TypescriptOrganizeImports<CR>')
          bufmap('<leader>cR', ':TypescriptRenameFile<CR>')
        end,
      }
    end,
  },

  -- Tailwind CSS and Colorizer for Autocomplete
  {
    'roobert/tailwindcss-colorizer-cmp.nvim',
    dependencies = { 'hrsh7th/nvim-cmp' },
    config = function()
      require('tailwindcss-colorizer-cmp').setup()
    end,
  },

  -- Prettier Formatter
  {
    'MunifTanjim/prettier.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    config = function()
      require('prettier').setup {
        bin = 'prettier',
        filetypes = {
          'javascript',
          'typescript',
          'css',
          'html',
          'json',
          'markdown',
          'react',
          'typescriptreact',
        },
      }
    end,
  },

  -- Treesitter for better syntax highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = { 'javascript', 'typescript', 'tsx', 'html', 'css', 'json' },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },

  -- Telescope for fuzzy finding
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = 'Telescope',
    keys = {
      { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find Files' },
      { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Live Grep' },
    },
  },

  -- Git integration
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end,
  },

  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup {
        options = { theme = 'auto' },
      }
    end,
  },

  {
    'nvim-telescope/telescope.nvim',
    keys = {
      -- Add this line to map Cmd+P to Telescope live_grep
      { '<C-f>', '<cmd>Telescope live_grep<cr>', desc = 'Grep Files' },
      { '<D-p>', '<cmd>Telescope find_files<cr>', desc = 'Find Files' },
    },
    -- Keep any existing options and configuration you might have
    opts = {
      -- Your existing Telescope options here (if any)
    },
    config = function(_, opts)
      require('telescope').setup(opts)

      -- Add an additional keymap for ctrl+f
      vim.keymap.set('n', '<C-f>', function()
        require('telescope.builtin').live_grep()
      end, { desc = 'Grep Files (ctrl+F)' })

      -- Add an additional keymap for Cmd+F
      vim.keymap.set('n', '<D-p>', function()
        require('telescope.builtin').find_files()
      end, { desc = 'Find Files (Cmd+P)' })
    end,
  },
}
